#!/bin/sh

BASEDIR=${HOME}/.cache/watch-data

SHHDIR=$(dirname $0)
if [ -h $0 ]; then
    SHHDIR=$(dirname $(readlink $0))
fi

cat_if_not_empty() {
    fn=$1
    sep=$2
    if [ -s "$fn" ];then
        echo "${fn}:"
        echo "=="
        echo
        cat $fn
        if [ -n "$sep" ]; then
            echo
            echo $sep
            echo
        fi
    fi
}

# Curly braces expansions is not covered by POSIX
for x in bilder documents downloads videos ; do
    cat_if_not_empty "${BASEDIR}/files-${x}" "___"
done

for x in ahead remotes uncommitted  ; do
    cat_if_not_empty "${BASEDIR}/git-${x}" "___"
done

