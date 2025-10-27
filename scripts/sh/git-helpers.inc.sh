#!/bin/sh

# check git repositories for uncommitted files, missing remotes, commits not pushed
# can also be used standalone

FIND=/usr/bin/find
GIT=/usr/bin/git

SHHDIR=$(dirname $0)
if [ -h $0 ]; then
    SHHDIR=$(dirname $(readlink $0))
fi

. $SHHDIR/sh-helpers.inc.sh || exit 254

# use a dir $GITREPOS and place links where you want to scan.
# $GITREPOS/ignorelist contains dirs that are ignored entirely.
GITREPOS=$HOME/.config/gitrepos

# if it's sourced
if [ "$(basename $0)" != "git-helpers.inc.sh" ]; then
    NOOP=1
fi

git_annex_find_broken_content () {
    if [ ! -d .git/annex ];then
        echo "this only works in git repository root with annex present"
        return 127
    fi

    $GIT annex find --unlocked | while read f; do
      if file $f | grep -q "ASCII text\$"; then
          #FIXME: this is somewhat weak if other hash mechanisms are used
          # probably accept this is a moving target
          if cat $f | head -1 | grep -q "^/annex/objects/SHA"; then
              echo "annex broken content: $f"
          fi
      fi
    done
}

git_uncommitted () {

    [ -e $GITREPOS/ignore-uncommitted ] && return 0

    local d2=$1
    local tmpfile=$(mktemp)

    $GIT status --porcelain=v1 >>$tmpfile 2>/dev/null

    # Annex repo
    if [ -z "$ignoreannex" -a -d .git/annex ]; then
        git_annex_find_broken_content
        $GIT annex find --not --copies 1 --format 'Annex not enough copies: ${file}\n' >>$tmpfile 2>/dev/null
    fi

    if [ -s $tmpfile ];then
        echo 
        echo "Uncommitted changes in $d2:"
        echo "--"
        echo
        cat $tmpfile | sed 's,$,  ,g'
        echo "  "
     fi

     rm $tmpfile
}

git_ahead () {

    [ -e $GITREPOS/ignore-ahead ] && return 0

    local d2=$1

    GITSTATUS=$(git status -sb)
    # replace ... so . may appear in the branch. The second sed expression is to filter " [ahead n]".
    # FIXME: perhaps this should just use git remote -v
    REMOTE=$(echo "$GITSTATUS" | grep "\.\.\." | sed -e 's,\.\.\.,|,g' -e 's, \[.\+\]$,,g' | cut -d'|' -f 2 )

    if [ -z "$REMOTE" ]; then
        echo
        echo "$d2 has some unrecognised remote config (${GITSTATUS})."
        echo
        return 1
    fi

    REMOTENAME=$(echo $REMOTE | cut -f 1 -d /)

    # allow ignoring certain remotes for 2 weeks
    # e.g. local addresses when on the road
    # apparently the second cut works both if @ is present or not
    REMOTEADDR=$($GIT remote get-url "$REMOTENAME" | cut -d : -f 1 | cut -d @ -f 2-)
    find $GITREPOS/ -maxdepth 1 -name ignore-ahead-${REMOTEADDR} -a -mtime -14 | grep -q '.*' && return

    # list anything that is not pushed, but exclude annex's views and things starting with _PR_,
    # use the latter locally to review other people's PRs.
    out=$(git log --exclude=views\* --exclude=\*.bak --exclude=git-annex --exclude=_PR_\* --exclude=_pr_\* --branches --not --remotes --pretty="format:%h %d %s (%aN)". 2>&1)
    if [ -z "$out" ]; then
        return
    fi

    echo 
    echo "Commits not pushed to remote in $d2:"
    echo "--"
    echo
    echo "$out" | sed 's,$,  ,g'
    echo
}

git_remotes () {

    local d2=$1

    [ -e $GITREPOS/ignore-remotes ] && return 0

    if [ -z "$($GIT remote -v )" ]; then
        echo
        echo "$d2 has no remotes"
        echo
        continue
    fi
}

git_loop () {
    local mode=
    local dir
    case $1 in
        uncommitted|remotes|ahead)
            mode=$1
            ;;
        *)
            _usage
            return 240
            ;;
    esac
    $FIND $GITREPOS/*/ -type d -a -iname .git 2>/dev/null | while read dir; do
        if echo $dir | grep -q -f $GITREPOS/ignorelist ; then
            continue
        fi

        ignoreannex=
        if echo $dir | grep -q -f $GITREPOS/annex-ignorelist ; then
            ignoreannex=1
        fi

        if [ -L "$dir" ];then
            dir=$(readlink -f $dir)
        fi
        dir=${dir%%.git}
        cd $dir

        eval "git_${mode} $dir"

    done

}

if [ -n "$NOOP" ];then
    return 0
fi

cmd=cmd_${1}
shift
case $cmd in
    cmd_loop)
        git_loop "$@" 
        ;;
    cmd_ahead)
        cd $1
        git_ahead "$@"
        cd -
        ;;
    cmd_uncommitted)
        cd $1
        git_uncommitted "$@"
        cd -
        ;;
    *)
        #FIXME: help
        _usage
        exit 220
        ;;
esac

