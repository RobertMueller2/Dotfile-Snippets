#!/bin/sh

SCRIPT=$(readlink -f $0)
MSGPREFIX="example-extraction $(basename "$SCRIPT"):"

if [ -n "$(git status --porcelain)" ];then
    echo "${MSGPREFIX} skipping post-commit hook because repository is dirty."
    exit 0
fi

echo "${MSGPREFIX}: Running just extract-all to update Dotfile-Snippets..."
(cd $(dirname "${SCRIPT}") && just extract-all && just commit "auto-update" && just push) 

