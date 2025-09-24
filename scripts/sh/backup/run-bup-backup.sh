#!/bin/sh

SCRIPTDIR=$(CDPATH= cd -- $(dirname -- "$0") && pwd)
. ${SCRIPTDIR}/_common.inc.sh

TARGET="/vol/backup/bupdisk"
REPO="${TARGET}/bup_repo"
SNAPMOUNT="/vol/backup/snapshot"

mkdir -p $SNAPMOUNT

# do not backup snapshots and all that, so take the mountpoints directly rather than the main volume
find /vol/nas -maxdepth 2 -mindepth 2 -type d | grep -v "main\$" | while read v; do

  if mount | grep -q " $TARGET ";then
    echo "running bup $v -> $TARGET"
    SNAP="_bup_$(date +%Y%m%d_%H%M%S)"
    BASENAME=$(basename $v)
    SNAPLOC="$(echo $v | sed -e s,/${BASENAME}\$,/main,g )/${BASENAME}${SNAP}"
    BAKNAME="nas_backup_$(echo $v | cut -d / -f 4 )_${BASENAME}"

    btrfs subvolume snapshot -r $v $SNAPLOC

    bup -d $REPO index $SNAPLOC
    bup -d $REPO save --name $BAKNAME $SNAPLOC

    btrfs subvolume delete $SNAPLOC
  fi
done
