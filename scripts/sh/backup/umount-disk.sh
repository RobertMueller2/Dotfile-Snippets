#!/bin/sh

usage () {
cat <<EOF
$0 <volume>
EOF
}

SCRIPTDIR=$(CDPATH= cd -- $(dirname -- "$0") && pwd)
. ${SCRIPTDIR}/_common.inc.sh

[ $# -eq 1 ] || { usage ; exit 200; }

VOLUME=$1

check_valid_volume $VOLUME || exit 208;

mount | grep -q "${BACKUPROOT}/${VOLUME}" || { echo "volume not mounted"; exit 207;  }

DEVICE=$(volume_to_device $VOLUME)
if [ -z "$DEVICE" ]; then
  echo "Error: No device found for label '$VOLUME'" >&2
  exit 2
fi


cryptsetup isLuks $DEVICE || { echo "not a luks partition"; exit 203; }

sync

umount "${BACKUPROOT}/${VOLUME}"

cryptsetup close $VOLUME || exit 206

read -p "eject disk? [y/ANY] " -r do_eject

case "$do_eject" in
    y|Y)
        MAINDEVICE=$(echo $DEVICE | cut -d / -f 3 | cut -c -3)
        echo disconnecting $device
        echo "offline" > /sys/block/${MAINDEVICE}/device/state
        echo 1 > /sys/block/${MAINDEVICE}/device/delete
	;;
    *)
	:
	;;
esac
