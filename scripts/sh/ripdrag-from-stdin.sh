#!/bin/sh

script="${0}"

# FIXME: reuse
usage() {
    echo "${script} [menu]"
}

_run() {
  f="${1}"
  if [ ! -s "$f" ];then
      echo "${script}: ${f} is empty" > /dev/stderr
      return 1
  fi

  EXT=$(file --brief --extension "$f" | cut -d "/" -f 1)

  if echo "$EXT" | grep -q "^[a-zA-Z0-9]\+$" ; then
    FILE2="${f}.${EXT}"
    mv "$f" "$FILE2"
    f="$FILE2"
  fi

  ripdrag "$f"
}

case "$1" in
    menu)
        #FIXME: these should be centralised somehow
        LIST=$(clipvault list | fuzzel --dmenu)
        if [ $? -gt 0 ];then
            exit 5
        fi
        # use sensitive to prevent recording into clipvault again
        clipvault get "${LIST}" | wl-copy --sensitive
        ;;
    "")
        :
        ;;
    *)
        usage
esac

FILE=$(mktemp)
wl-paste > "$FILE"
_run "$FILE"
rm "$FILE"

