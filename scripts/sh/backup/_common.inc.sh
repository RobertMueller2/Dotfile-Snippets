#!/bin/sh

BACKUPROOT="/vol/backup"
VOLUMES="${BACKUPROOT}/Volumes"

read_passphrase() {
    local passphrase confirmation

    if [ -t 0 ]; then
        stty -echo
        read -p "Enter Passphrase: " -r passphrase

        if [ "$1" = "confirm" ]; then
            read -p "Confirm passphrase: " -r confirmation

            if [ "$passphrase" != "$confirmation" ]; then
                echo "Error: Passphrases do not match." >&2
		stty echo
                exit 1
            fi
        fi

	stty echo
        echo "$passphrase"
    else
	# read passphrase from pipe if present
        cat
    fi
}

check_valid_device() {
    # check if device name follows pattern
    echo $1 | grep -q "/dev/sd.1" || { echo "not a valid device name" >&2; return 1; }
    return 0
}

check_valid_block_device() {
    [ -b $1 ] || { echo "not a valid block device" >&2; return 1; }
    return 0
}

check_valid_volume() {
    grep -q "^${1}\$" "$VOLUMES" || { echo "not a valid volume" >&2; return 1; }
    return 0
}

device_to_volume() {
    blkid -o value -s LABEL $1
}

volume_to_device() {
    lsblk -rno NAME,LABEL | grep "^sd.1 ${1}\$" | awk '{print "/dev/" $1}'
}
