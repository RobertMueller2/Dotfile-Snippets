#!/bin/sh

# @extract-docs
# used by waybar-wayland-helper.sh for custom process watch module
# the basic idea is:
#  - kernel building is always watched
#  - it's possible to add processes to be watched. It works by creating a link
#    to the related entry in /proc. 
#  - if anything is found, it's displayed on STDOUT so this can be evaluated
#    by waybar-wayland-helper.sh

SHHDIR=$(dirname $0)
if [ -h $0 ]; then
    SHHDIR=$(dirname $(readlink $0))
fi

. "${SHHDIR}/sh-helpers.inc.sh" || exit 254

name_pattern="_ps_user_watch.$(id -u)."
path_pattern="/tmp/${name_pattern}"

do_watch() {
    # part 1: watch for kernel building lockfile
    find "$HOME/Progs/src/linux-kernel" -maxdepth 1 \( -name deb-pkg.lock \
        -o -name bindeb-pkg.lock \)

    # part 2: user defined watch links managed by the commands below
    for WP in $(find /tmp -maxdepth 1 -type l -a -name "${name_pattern}*"); do
        LINKTARGET=$(readlink "$WP" 2>/dev/null)

        if [ ! $(dirname "$LINKTARGET") = "/proc" ];then
            echo "$WP does not point to /proc but $LINKTARGET, consider cleanup" >&2
            continue
        fi

        if [ ! -d "$LINKTARGET" ]; then
            echo "$LINKTARGET does not exist, consider cleanup" >&2
            continue
        fi

        ps -fo uname=,pid=,ppid=,args=,start_time=,%cpu= "$(basename $LINKTARGET)"
    done
}


case _cmd_${1} in
    _cmd_add)
        ## <pid>
        ### adds a process id to watch
        process=$2
        if [ -z "$process" ];then
            _usage
            exit 253
        fi

        if [ ! -e "/proc/$process" ];then
            echo "Error: $process does not exist"
            exit 252
        fi

        ln -s /proc/$process ${path_pattern}${process}
        echo "Now watching $process via ${path_pattern}${process}."
        ;;
    _cmd_cleanup)
		### removes stale watch links
		find /tmp -maxdepth 1 -type l -name "${name_pattern}*" | while read -r link; do
			if ! [ -d "$(readlink "$link" 2>/dev/null)" ]; then
				echo "Cleaning up stale watch: $link" >&2
				rm "$link"
			fi
		done
        ;;
	_cmd_list)
		### shows currently watched processes
		find /tmp -maxdepth 1 -type l -name "${name_pattern}*" -exec ls -l {} \;
		;;
    _cmd_remove)
        ## <pid|watchfile>
        ### removes a watched process
        process_or_watchfile=$2
        if echo "$process_or_watchfile" | grep -q "^[0-9]\+\$"; then # it's a process. probably.
            target="${path_pattern}${process_or_watchfile}"
        elif echo "$process_or_watchfile" | grep -q "^${path_pattern}" && [ -h "$process_or_watchfile" ]; then
            target=$process_or_watchfile
        else
            echo "Error: unknown type $process_or_watchfile, not suitable for this command."
            exit 251
        fi

        link=$(readlink "$target" 2>/dev/null)
        dir="$(dirname "$link")"
        if [ ! "$dir" = "/proc" ]; then
            echo "$target doesn't point to /proc but $link, clean up manually."
            exit 250
        fi

        echo "removing $target"
        rm "$target"
        ;;
    _cmd_watch)
        ### performs watching, used by waybar/ironbar
        do_watch
        ;;
    _cmd_help)
        ### shows this help
        _usage
        ;;
    *)
        _usage
        exit 254
        ;;
esac

# add more as needed...
