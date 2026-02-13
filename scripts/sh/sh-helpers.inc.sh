
_usage () {
    _help_from_annotations "$@"
}

_usage_and_exit () {
    local rv
    rv=$1
    shift
    _help_from_annotations "$@"
    exit $rv
}


_check_rv () {
    local rv
    rv=$1
    if [ $rv -gt 0 ];then
        exit $rv
    fi
}

# check if internet connection available
# e.g. prevent spam from commands that require an internet connection
# and produce error messages otherwise
# 0 if ping successful, non-0 otherwise
_ping_8888 () {
    ping -q -c1 -W5 8.8.8.8 >/dev/null
}

#annotations
# can be:
# - _cmd_something)
#        ## annotation here (use this for parameters)
#        ### annotation here (use this for descriptions)
#
_help_from_annotations () {

    echo Usage:
    _cmd=$0
    _basecmd=$(basename $0)

    _pattern0="###"
    _pattern1="cmd"
    _pattern2="##"

    _pattern="^[[:space:]]*\(_${_pattern1}\|${_pattern0}\|${_pattern2}\)"

    cat $_cmd | grep "$_pattern" \
        | sed \
        -e 's,\s\+_'${_pattern1}'_\(\w\+\)),\n\t'${_basecmd}' \1,g' \
        -e 's,'${_pattern0}'\s*,\t\t,g' \
        -e 's,'${_pattern2}'\s*,\t,g' \

        echo
}

# should be portable for /bin/sh
_is_func () {
    command -V "$1" 2>/dev/null | grep -qwi function
}

# source alternative
# reads key=value pairs. comments possible. Whitespace around the = is stripped
# as well as as trailing whitespace.
_read_key_value () {
    local fn
    fn=$1
    if [ ! -f "$fn" ]; then
        echo "$fn does not exist" >&2
        return 1
    fi

    while read -r line ; do
        line=$(echo "$line" | sed -e 's,\s*\(#.\+\)\?$,,g' -e 's,\s*=\s*,=,g' -e 's,",\\\\",g')
        if echo "$line" | grep -q '^\s*$'; then
            continue
        fi
        if ! echo "$line" | grep -q '^[a-zA-Z0-9_]\+=.\+$'; then
            echo "warning: ignoring malformed line: $line" >&2
            continue
        fi
        echo "$line"
        eval $(echo "$line" | cut -d = -f 1)=\""$(echo "$line" | cut -d = -f 2)\""
    done < "$fn"
}

# Associative array emulation functions - probably taken from here:
#  https://unix.stackexchange.com/questions/111397/associative-arrays-in-shell-scripts

# Declare an empty associative array named STEM.
ainit () {
  eval "__aa__${1}=' '"
}

# akeys STEM
# List the keys in the associatve array named STEM.
akeys () {
  eval "echo \"\$__aa__${1}\""
}

# aget STEM KEY VAR
# Set VAR to the value of KEY in the associative array named STEM.
# If KEY is not present, unset VAR.
aget () {
  eval "unset $3
        case \$__aa__${1} in
          *\" $2 \"*) $3=\$__aa__${1}__$2;;
        esac"
}

# aset STEM KEY VALUE
# Set KEY to VALUE in the associative array named STEM.
aset () {
  eval "__aa__${1}__${2}=\$3
        case \$__aa__${1} in
          *\" $2 \"*) :;;
          *) __aa__${1}=\"\${__aa__${1}}$2 \";;
        esac"
}

# aunset STEM KEY
# Remove KEY from the associative array named STEM.
aunset () {
  eval "unset __aa__${1}__${2}
        case \$__aa__${1} in
          *\" $2 \"*) __aa__${1}=\"\${__aa__${1}%%* $2 } \${__aa__${1}#* $2 }\";;
        esac"
}

# YAML functions
# use eval $(parse_yaml <filename> <variableprefix>
# does not support nested arrays or multi-line strings
parse_yaml () {

    test -f "$1" || _output error "$1 not found"

    local prefix=$2
    local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
    sed -ne "s|#.+$||g" \
        -e "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
    awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
    }'

}

# Some vars

COLOR_GREEN="\e[1;32m"
COLOR_YELLOW="\e[1;33m"
COLOR_NORMAL="\e[0m"

