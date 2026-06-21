#!/bin/sh

SHHDIR=$(dirname $0)
if [ -h $0 ]; then
    SHHDIR=$(dirname $(readlink $0))
fi

. $SHHDIR/sh-helpers.inc.sh || exit 254
. $SHHDIR/git-helpers.inc.sh || exit 253

set_var_and_exit() {
    ironbar var set "$1" "$2" >/dev/null
    exit $?
}

CMD=$1
shift
case _cmd_${CMD} in
    _cmd_toggle-var)
        ## checks ironbar for variable and adjusts it in order
        ### <variable> <first value> [further values...]
        if [ $# -lt  2 ]; then
            _usage_and_exit 199
        fi
        varname="$1"
        shift

        currentvalue=
        currentvalue=$(ironbar var get "$varname" 2>/dev/null)
        # var is currently not set, set it to the first value
        if [ $? -gt 0 ];then
            set_var_and_exit "$varname" "$1"
        fi

        orig_first=$1

        while [ $# -ge 2 ]; do
            if [ "$currentvalue" = "$1" ];then
                set_var_and_exit "$varname" "$2"
            fi
            shift
        done

        if [ "$currentvalue" != "$orig_first" ];then
            set_var_and_exit "$varname" "$orig_first"
        fi

        ;;
    _cmd_set-var-dependent)
        ## checks ironbar for variable for 1/true and sets second var to first or second value
        ### <check_variable> <variable> <value_true> <value_false>
        if [ $# -ne  4 ]; then
            _usage_and_exit 199
        fi
        varname_check="$1"
        varname_set="$2"
        content_true="$3"
        content_false="$4"

        currentvalue=$(ironbar var get "$varname_check" 2>/dev/null)
        # check var is currently not set, assume it's false
        if [ $? -gt 0 ];then
            currentvalue="0"
        fi

        if [ "$currentvalue" = "1" -o "$currentvalue" = "true" ];then
            set_var_and_exit "$varname_set" "$content_true"
        fi

        set_var_and_exit "$varname_set" "$content_false"
        ;;
    _cmd_systemd-failed)
        ## generates content or tooltip for systemd failed units
        ### <content|tooltip>
        #FIXME: yes, this shouldn't happen before we check if the argument is correct
        f=$(systemctl --failed --no-legend --plain 2>/dev/null)
        u=$(systemctl --user --failed --no-legend --plain 2>/dev/null)

        case $1 in
            label)
                fc=$(echo "$f" | wc -l)
                uc=$(echo "$u" | wc -l)
                test $((fc+uc)) -gt 0 && printf '✗ %dS %dU' $fc $uc || echo '✓'
                ;;
            tooltip)
                if [ -n "$f" ];then
                    echo "Failed system units:"
                    echo
                    echo "$f"
                    echo
                fi
                if [ -n "$u" ];then
                    echo "Failed user units:"
                    echo
                    echo "$u"
                    echo
                fi
                ;;
            *)
                _usage_and_exit 198
        esac
        ;;
    _cmd_help)
        _usage
        ;;
    *)
        _usage_and_exit 250
        ;;
esac
