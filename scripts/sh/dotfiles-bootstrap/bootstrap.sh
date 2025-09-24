#!/bin/sh

# creates files from btpl - usually gitignored files that are supposed to be
# changed locally, for which I provide initial templates. 

# make sure we're in the repository root.
cd $(dirname $0)
cd ..

find . -type f -a -name '*.btpl' | while read f ; do
    target=${f%%.btpl}
    if [ ! -f "$target" ];then
        echo "$f -> $target"
        cp $f $target
    fi
done
