#!/bin/sh

SCRIPTDIR=$(CDPATH= cd -- $(dirname -- "$0") && pwd)
. ${SCRIPTDIR}/_common.inc.sh

cat $VOLUMES | while read v ; do

  TARGET=/vol/backup/${v}
  if mount | grep -q " $TARGET ";then
    echo "running backup for $TARGET"
    btrbk -v run $v
  fi
done
