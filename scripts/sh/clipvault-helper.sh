#!/bin/sh

SHHDIR=$(dirname $0)
if [ -h $0 ]; then
    SHHDIR=$(dirname $(readlink $0))
fi

. $SHHDIR/sh-helpers.inc.sh || exit 254

# if it's sourced
if [ "$(basename $0)" != "clipvault-helper.sh" ]; then
    NOOP=1
fi

# inspired by https://github.com/Rolv-Apneseth/clipvault/blob/main/extras/clipvault_wofi.sh
thumbnails_dir="${XDG_CACHE_HOME:-$HOME/.cache}/clipvault/thumbs"

ensure_cache_dir() {
    test -d "$thumbnails_dir" || mkdir -p "$thumbnails_dir"
}

purge_thumbnail_cache() {
    find "$thumbnails_dir" -type f | while IFS= read -r thumbnail; do
        item_id="thumbnail$(basename "${thumbnail%.*}")"
        if ! echo "$list" | grep -q "^${item_id}\s\[\[ binary data image"; then
            rm "$thumbnail"
        fi
    done
}

generate_thumbnails() {
    local THUMB_SIZE
    THUMB_SIZE=32

    echo "$list" | grep -o "^[[:digit:]]\+\s\+\[\[ binary data image/\(jpg\|jpeg\|png\|bmp\|webp\|tif\|gif\)" 2>/dev/null | while read i e; do

        e=$(echo $e | cut -d "/" -f 2)
        # always use png, no idea if clever
        fn="${thumbnails_dir}/thumbnail${i}.png"
        if [ -f "$fn" ];then
            continue
        fi
        echo $i | clipvault get | convert -auto-orient -strip -thumbnail "${THUMB_SIZE}x${THUMB_SIZE}" - "$fn"  2>/dev/null

    done
    
}

build_menu_stream() {
    echo "$list" | while read -r idx r ; do
        filetype=
        fn=
        ft=

        if echo "$r" | grep -q "^\[\[ binary data [[:alnum:]]\+/[[:alnum:]]\+" 2>/dev/null; then
            filetype=$(echo "$r" | cut -d " " -f 4 | cut -d "]" -f 1)
            case $filetype in
                image/jpg|image/jpeg|image/png|image/bmp|image/bmp|image/webp|image/tif|image/gif)
                    fn="${thumbnails_dir}/thumbnail${idx}.png"
                    ;;
                application/pdf) # doesn't really work yet
                    ft="application-pdf"
            esac
            if [ -n "$fn" -a -f "$fn" ];then
                # *shakes fist*
                /usr/bin/echo -en "${idx} [[${filetype}]]\0icon\x1f${fn}\n"
                continue
            elif [ -n "$ft" ];then
                /usr/bin/echo -en "${idx} [[${filetype}]]\0icon\x1f${ft}\n"
                continue
            fi

        fi
        echo "$idx $r"
    done
}

get_item() {
    if [ -n "$DEBUG" ];then
        build_menu_stream >&2
    fi
    ITEM=$(build_menu_stream | $DMENU -p "clipvault ${MODE}:")
}

maintain() {
    ensure_cache_dir
    purge_thumbnail_cache
    generate_thumbnails
}

if [ -n "$NOOP" ];then
    exit 0
fi

MODE="${1}"
shift

if [ -n "$1" -a "$1" = "debug" ];then
    DEBUG=1
    shift
fi

list=$(clipvault list $@)

case "_cmd_${MODE}" in
    _cmd_ask)
        ## [debug]
        ### shows a dmenu prompt for clipvault operation
        NEXTMODE=$(echo "copy\ncopy --reverse\ndelete\ndelete --reverse" | $DMENU -p "clipvault:")
        _check_rv $?
        mode=$(echo "$NEXTMODE" | cut -d " " -f 1)
        listflags=$(echo "$NEXTMODE" | cut -sd " " -f 2-)
        exec "$0" "$mode" "${DEBUG:+debug}" "$listflags"
        ;;

    _cmd_copy)
        ## [debug] [clipvault list flags]
        ### shows a dmenu prompt for clipvault items to copy
        maintain
        get_item
        _check_rv $?
        ITEM=$(echo "$ITEM" | cut -d " " -f 1)
        clipvault get "$ITEM" | wl-copy
        ;;

    _cmd_delete)
        ## [debug] [clipvault list flags]
        ### shows a dmenu prompt for clipvault items to delete
        maintain
        get_item
        _check_rv $?
        ITEM=$(echo "$ITEM" | cut -d " " -f 1)
        echo $ITEM
        clipvault delete "$ITEM"
        exec "$0" "delete" "${DEBUG:+debug}" "$@"
        ;;

    _cmd_maintain)
        ### performs maintenance
        maintain
        ;;

    _cmd_help)
        _usage
        ;;

    *)
        _usage_and_exit 250
        ;;
esac

