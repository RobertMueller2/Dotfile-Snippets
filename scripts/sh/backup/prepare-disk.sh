#!/bin/sh

usage () {
cat <<EOF
$0 <device> <medium>
EOF
}

SCRIPTDIR=$(CDPATH= cd -- $(dirname -- "$0") && pwd)
. ${SCRIPTDIR}/_common.inc.sh

[ $# -eq 2 ] || { usage ; exit 200; }

DEVICE=$1
MEDIUMNAME=$2
FSLABEL=${MEDIUMNAME}_FS

PP=$(read_passphrase confirm)

if [ -z "$PP" ];then
  echo "Empty passphrase not permitted."
fi

grep -q "^${MEDIUMNAME}.*" ${VOLUMES} || { echo "not a valid volume"; exit 204;}

check_valid_device $DEVICE && check_valid_block_device $DEVICE || exit 208

# check if the blkid output looks sensible for a new disk
blkid $DEVICE | grep -q "${DEVICE}: PARTUUID=\"[0-9a-f-]\+\"" || { echo "not an empty partition"; exit 203; }

echo "Setting up encrypted volume"
echo "$PP" | cryptsetup luksFormat $DEVICE ${STDIN:+-} || exit 205
cryptsetup config $DEVICE --label $MEDIUMNAME

echo "$PP" | cryptsetup open $DEVICE $MEDIUMNAME ${STDIN:+-} || exit 206

mkfs.btrfs -L $FSLABEL /dev/mapper/${MEDIUMNAME} || exit 207

cryptsetup close $MEDIUMNAME

echo "You can now mount the backup medium with mount-disk.sh."
