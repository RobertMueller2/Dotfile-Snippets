#!/bin/sh

# provide access to snippets

SNIPPETS=$HOME/.config/snippets

CMD=$1
test -z "$CMD" && CMD=wtype

FILE=$(ls $SNIPPETS | $DMENU -p "select snippet")

if [ $? -gt 0 ]; then
    exit $?
fi

$CMD -- "$(cat $SNIPPETS/$FILE)"

