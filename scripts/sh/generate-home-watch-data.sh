#!/bin/sh

# records files not in locations that are synced (cloud or git)

BASEDIR=${HOME}/.cache/watch-data

SHHDIR=$(dirname $0)
if [ -h $0 ]; then
    SHHDIR=$(dirname $(readlink $0))
fi

. $SHHDIR/sh-helpers.inc.sh
. $SHHDIR/git-helpers.inc.sh

if [ ! -d $BASEDIR ]; then
    mkdir -p $BASEDIR || { echo "$BASEDIR creation failed"; exit 254; }
fi

FIND=/usr/bin/find

git_loop uncommitted > $BASEDIR/git-uncommitted
git_loop ahead > $BASEDIR/git-ahead
git_loop remotes > $BASEDIR/git-remotes

#TODO: das geht sicher schöner ;)
DOCS="${HOME}/Dokumente"
if [ -e "$DOCS" ]; then
  $FIND "$DOCS" -maxdepth 1 -type f > $BASEDIR/files-documents
  $FIND "$DOCS" -mindepth 1 -maxdepth 1 -type d -o -type l | grep -v "\(\.oneim\|_annex\|_games\|_projects\|_sync\|TraktorPro3\|_volatile\|LINQPad\)" >> $BASEDIR/files-documents
fi 

PICS="${HOME}/Bilder"
if [ -e "$PICS" ]; then
  $FIND $PICS -maxdepth 1 -type f > $BASEDIR/files-pictures
  $FIND $PICS -mindepth 1 -maxdepth 1 -type d -o -type l | grep -v "\(_annex\|_games\|_projects\|OpenBoard\|Screenshots\|_sync\|_volatile\)" >> $BASEDIR/files-pictures
fi

DL="${HOME}/Downloads"
if [ -e "$DL" ]; then
  $FIND $DL -maxdepth 1 -type f > $BASEDIR/files-downloads
  $FIND $DL -mindepth 1 -maxdepth 1 -type d -o -type l | grep -v "\(_annex\|_games\|_projects\|DL-.\+\|_sync\|_volatile\)" >> $BASEDIR/files-downloads
fi

VIDS="${HOME}/Videos"
if [ -e "$VIDS" ]; then
  $FIND $HOME/Videos -maxdepth 1 -type f > $BASEDIR/files-videos
  $FIND $HOME/Videos -mindepth 1 -maxdepth 1 -type d -o -type l | grep -v "\(_annex\|_games\|_projects\|OpenBoard\|_sync\|_volatile\)" >> $BASEDIR/files-videos
fi

exit 0
