#!/bin/sh

usage () {
cat <<EOF
$0 <device|volume>
EOF
}

SCRIPTDIR=$(CDPATH= cd -- $(dirname -- "$0") && pwd)
. ${SCRIPTDIR}/_common.inc.sh

[ $# -eq 1 ] || { usage ; exit 200; }

INPUT=$1

if check_valid_device "$INPUT" && check_valid_block_device "$INPUT" ; then
  DEVICE=$INPUT  
  VOL_NAME=$(device_to_volume $DEVICE)
elif check_valid_volume "$INPUT"; then
  VOL_NAME=$INPUT
  DEVICE=$(volume_to_device $VOL_NAME)
  if [ -z "$DEVICE" ]; then
    echo "Error: No device found with label '$VOL_NAME'" >&2
    exit 2
  fi
else
  echo "${INPUT} is neither a valid device nor a valid volume";
  exit 3
fi

cryptsetup isLuks $DEVICE || { echo "not a luks partition"; exit 203; }

PASSPHRASE=$(read_passphrase)

TARGET="${BACKUPROOT}/${VOL_NAME}"

[ -d ${TARGET:-} ] || { echo "$TARGET does not exist."; exit 204; }

echo $PASSPHRASE | cryptsetup open $DEVICE $VOL_NAME - || exit 206

mount /dev/mapper/${VOL_NAME} ${TARGET}

echo "Mounted /dev/mapper/${VOL_NAME} at ${TARGET}"
