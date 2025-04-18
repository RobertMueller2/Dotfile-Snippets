#!/bin/sh
#
# link as .git/hooks/post-commit

_script=$0

echo "${_script}: Running just extract-all to update Dotfile-Snippets..."
# this isn't good at all, but GIT_DIR isn't exactly reliable...
(cd ${HOME}/Workdir/Config-Dotfiles/examples && just extract-all && just commit "auto-update" && just push) 

