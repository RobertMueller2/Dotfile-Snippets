#!/bin/sh

# this creates a symlink, but the script takes reversed parameter order.
# This is easier to manage links for e.g. latest wine versions.
# $ ln -s wine-10.5-staging-tkg-amd64 wine-staging-default
# vs 
# update-link.sh wine-staging-default wine-10.5-staging-tkg-amd64
#
# The latter is (IMO) easier to change for the new version from shell history.

usage() {
    echo "$(basename $0) [--dry] <link> <target>"
}

check() {
    if [ ! -L "$LINK" ]; then
        echo "${LINK} is not a symbolic link"
        exit 10
    fi
    if [ ! -e "$TARGET" ];then
        echo "${TARGET} does not exist"
        exit 20
    fi
}

DRY=0

while [ $# -gt 0 ];do
    case "$1" in
        "--dry")
            DRY=1
            shift
            ;;
        "--help")
            usage
            exit 0
            ;;
        *)
            if [ -z "$LINK" ];then
                LINK=$1
            elif [ -z "$TARGET" ];then
                TARGET=$1
            else
                echo "superfluous parameter ${1}"
                usage
                exit 1
            fi
            shift
            ;;
    esac
done

check

CMD="ln -sfT"

if [ $DRY -eq 1 ];then
    CMD="echo ${CMD}"
fi

$CMD "$TARGET" "$LINK"

