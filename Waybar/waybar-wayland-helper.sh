#!/bin/sh
# @extract-docs

SHHDIR=$(dirname $0)
if [ -h $0 ]; then
    SHHDIR=$(dirname $(readlink $0))
fi

. $SHHDIR/sh-helpers.inc.sh || exit 254
. $SHHDIR/git-helpers.inc.sh || exit 254

CMD=$1
shift

ASUS_SYS_DIR="/sys/devices/platform/asus-nb-wmi/hwmon/hwmon7"
WATCH_DATA_DIR="${HOME}/.cache/watch-data"

_waybar_json_output() {
    printf '{"text":"%s", "tooltip":"%s", "class":"%s", "percentage":%u}\n' "$1" "$2" "$3" "$4"
}

case _cmd_${CMD} in
    _cmd_custom_asusfan)
        ### helper for custom asusfan module
        ### legacy because hardware changed, remains here for reference purposes

        _freq=$(cat ${ASUS_SYS_DIR}/fan1_input)
        _fanmode=$(cat ${ASUS_SYS_DIR}/pwm1_enable)

        case $_fanmode in
            2)
                _fanmode="automatic"
                ;;
            1)
                # shouldn't happen, seems to be locked
                _fanmode="manual"
                ;;
            0)
                c=${c:-fullspeed}
                _fanmode="full speed"
                _t1=6001
                _t2=6101
                ;;
            *)
                _fanmode="invalid"
        esac

        _policy=$(cat ${ASUS_SYS_DIR}/device/throttle_thermal_policy)

        case $_policy in
            2)
                _policy_name="silent"
                class=${c:-silent}
                _t1=${_t1:-2500}
                _t2=${_t1:-3000}
                ;;
            1)
                _policy_name="overboost"
                class=${c:-overboost}
                _t1=${_t1:-3300}
                _t2=${_t1:-4000}
                ;;
            0)
                _policy_name="normal"
                ;;
            *)
                _policy_name="invalid"
                ;;
        esac

        if [ ${_freq:-0} -gt ${_t1:-2800} ]; then
            text=$_freq
            class="warning"

            if [ ${_freq:-0} -gt ${_t2:-3500} ]; then
                class="critical"
            fi
        fi
 
        _label=$(cat ${ASUS_SYS_DIR}/fan1_label)
        tooltip="${_label}: ${_freq} (${_fanmode}/${_policy_name})"
        # don't remember what I wanted to do here, or whether this is sensible.
        # It might make more sense to have percentage set along with the classes
        # above. Since I can't test it now, I'll leave it like this. 
        pc=$(($_policy * 50))
        _waybar_json_output "$text" "$tooltip"  "$class" "$pc"
        ;;

    _cmd_custom_df)
        ### helper for custom df module

        if [ -e /etc/default/diskfullwarn ]; then
            . /etc/default/diskfullwarn
        fi

        EXCLUDE_LIST="${EXCLUDE_LIST}${EXCLUDE_LIST:+|}Filesystem|Dateisystem|tmpfs|cdrom|none"

        df -h 2>/dev/null | gawk -v excl="${EXCLUDE_LIST}" -v bigl="${BIG_LIST}" '
                BEGIN {
                    gsub("/","\\/",excl)
                    pc=0
                    tooltip=""
                    class="normal"
                }
                $1 !~ excl && $6 !~ excl {
                    # build tooltip
                    tooltip = tooltip $5 " " $6 "\\n"

                    # + 0 needed because otherwise it is a string
                    p = gensub("%","","g",$5) + 0
                    # this is a hack for big filesystems like /home to avoid a full rewrite at this point ;)
                    if ($6 ~ bigl) {
                        p = p - 4
                    }
                    if (p > pc) pc=p
                    if (p < 90) next
                    fs[$6] = $5 " " $6
                }
                END {
                    text=""
                    sep=""

                    if (pc >= 90) class = "warning"
                    if (pc >= 95) class = "critical"

                    PROCINFO["sorted_in"] = "@val_num_desc"
                    for (f in fs) {
                        text=text sep fs[f] " "
                        sep="| "
                    }
                    printf "{\"text\" : \"%s\", \"tooltip\" : \"%s\", \"class\": \"%s\", \"percentage\" : \"%u\"}", text, tooltip, class, pc
                }
    
            '
        ;;
        
    _cmd_custom_watch_summary)
        ### helper for watch summary module
        text=0
        tooltip=""
        class="normal"
        pc=0
        for f in ${WATCH_DATA_DIR}/* ; do
            if [ -s "$f" ]; then
                text=$((${text} + 1))
                tooltip="${tooltip}${f##*/}: $(wc -l < "$f")\n"
                class="warning"
                pc=50
            fi
        done
        _waybar_json_output "$text" "$tooltip" "$class" "$pc"
        ;;

    #FIXME: threshold for warning and critical
    _cmd_custom_watch)
        ## <target> <pattern>
        ### helper for individual watch modules
        test $# -ge 1 || { _usage; exit 239; }
        target=$1
        pattern=$2
        file="${WATCH_DATA_DIR}/$target"
        if [ ! -s "$file" ]; then
            text=0
            tooltip=""
            class="normal"
            pc="100"
        else
           if [ -z "$pattern" ]; then
               text=$(cat "$file" | wc -l) 
           else
               text=$(cat "$file" | grep "$pattern" | wc -l)
           fi
            tooltip=$(sed -E -e ':a;N;$!ba;s,\r?\n,\\n,g' -e 's,\",\\",g' "$file")
            class="warning"
            pc=50
        fi

        _waybar_json_output "$text" "$tooltip" "$class" "$pc"
        ;;

    _cmd_custom_uptime)
        ### gets uptime for uptime module
        uptime -p | sed -e "s, minutes\?,\',g" \
            -e "s, hours\?,h,g" \
            -e "s, days\?,d,g" \
            -e "s, weeks\?,w,g" \
            -e "s, years\?,y,g" \
            -e "s, decades\?,dd,g" \
            -e "s,up ,⇈,g" \
            -e "s/,//g"
        exit 0
        ;;

    _cmd_custom_waitpid)
        ### watches for non-empty process watch output
        # This is used to watch long running processes, e.g. kernel package build
        $HOME/Progs/bin/watch-processes.sh cleanup
        processes=$($HOME/.config/waybar/watch-processes.sh watch)
        processes=$(printf %s "${processes}") # I needed this printf to work around something, but I don't remember what it was.

        if [ -n "$processes" ]; then
            class="warning"
            pc="50"
            text=""
            tooltip=${processes}
        else
            class="normal"
            pc=100
            text=""
        fi

        _waybar_json_output "$text" "$tooltip" "$class" "$pc"
        exit 0
        ;;

    _cmd_start_waybar)
        ### changes WD to .config/waybar and starts waybar in path
        cd $HOME/.config/waybar
        exec waybar "$@"
        ;;

    _cmd_help)
        ### shows this help
        _usage
        ;;

    *)
        _usage
        exit 254
        ;;
esac
