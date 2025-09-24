#!/bin/sh

# can be used as browser replacement. Asks which browser is to be used for a URL, based on CONF file listing browsers.
# The idea is to use chrome, quotebrowser, and firefox with different profiles for job, private stuff, finance, etc.

SHHDIR=$(dirname $0)
if [ -h $0 ]; then
    SHHDIR=$(dirname $(readlink $0))
fi

. $SHHDIR/sh-helpers.inc.sh || exit 254

#FIXME: there has to be something better than this
if [ -z "$DMENU" ];then
    DMENU="dmenu"
fi

CONF=$HOME/.config/launch-with-browser.conf
OVERRIDECONF=$HOME/.config/launch-with-browser-override.conf

[ -e "$CONF" ] || { echo "$CONF not found. It should contain a list of browser executables." >&2; exit 254;  }

_u="$@"

CACHEFILE=$HOME/.cache/launch-with-browser.cache

if [ -z "$_u" ];then
    _u=$(cat $CACHEFILE | $DMENU -p "enter URL to open")
    _exitcode=$?
    if [ $_exitcode -gt 0 ];then 
        exit $_exitcode
    fi
    #FIXME: URL validity check
fi

if [ -e "$OVERRIDECONF" ];then
    _b=$(cat "$OVERRIDECONF")
else
    _b=$(cat "$CONF" | $DMENU)
fi

_exitcode=$?
if [ $_exitcode -gt 0 ];then 
    exit $_exitcode
fi

if ! grep -q "^${_u}\$" $CACHEFILE ; then
    echo $_u >> $CACHEFILE
fi

_tp=
if echo $_b | grep -q "firefox"; then
  _tp=--new-tab
fi

exec $_b $_tp "$_u"

