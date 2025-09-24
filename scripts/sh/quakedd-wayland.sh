#!/bin/sh

TMUX=/usr/bin/tmux

if $TMUX has-session -t quakedd 2>/dev/null ; then

    $TMUX attach-session -t quakedd

else

    $TMUX new-session -s quakedd ";" set-option -s remain-on-exit on ";" new-window -n log 'tail -n +0 -f ~/.wayland_errors'  ";" set-option -s remain-on-exit on ";"  new-window -n htop 'htop' ";" set-option -s remain-on-exit on ";" select-window -t 1 ";"

fi
