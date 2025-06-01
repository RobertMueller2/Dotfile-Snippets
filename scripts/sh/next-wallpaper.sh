#!/bin/sh

# gets the next wallpaper for wallpaper rotation hotkey

WCACHE=$HOME/.cache/wallpapers.cache
LASTFILE=$HOME/.cache/wallpaper-last.cache
touch $LASTFILE

LASTBG=$(cat ${LASTFILE})

find $HOME/Sync0/Sync/Bilder/Wallpaper-Rotation -type f | sort > $WCACHE
LEN=$(wc -l $WCACHE | cut -d " " -f 1)

if [ -n "$LASTBG" ];then
    LINE=$(grep -n $LASTBG $WCACHE | cut -d: -f 1)
    LINE=$((LINE + 1))
fi

if [ -z "$LINE" ];then
    LINE=1
fi

if [ "$LINE" -gt "$LEN" ];then
    LINE=1
fi

NEWIMG=$(sed -n ${LINE}p $WCACHE)

echo $NEWIMG > $LASTFILE
echo $NEWIMG
