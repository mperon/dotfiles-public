#!/usr/bin/env bash
#vim: ts=4 sw=4 et ft=sh

BASH_FN_SH=1

[[ "${BASH_SOURCE-}" == "$0" ]] && \
    echo "You must source this script: \$ source $BASH_SOURCE" >&2 && exit 33

#identify OS
[[ -f /etc/os-release ]] && source /etc/os-release
[[ -z "$MY_OS" ]] && MY_OS=$(uname -s | cut -d"_" -f1 | head -n 1 | tr '[:upper:]' '[:lower:]')

#default variables
_DEBUG=$(echo "$*" | grep -qF -- "--debug" && echo "y" || echo "")
_SILENT=$(echo "$*" | grep -qF -- "--silent" && echo "y" || echo "")
_LOG=${_LOG:-"/dev/null"}
_LOG_DATE=${_LOG_DATE:-"+%y-%m-%d %H:%M:%S"}
_LOG_SCRIPT=${_LOG_SCRIPT:-""}
_ERR=
E_PASSW=
E_ANSWER=

#colors
I_RED='\033[0;31m'
I_GREEN='\033[0;32m'
I_BLUE='\033[0;34m'
I_BOLD='\033[1m'
I_NORMAL='\033[0m'
I_CYAN='\033[0;36m'
tty -s && I_COL=$(tput cols) || I_COL=80

# creates a progress bar
function ProgressBar {
    # Process data
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*5)/10
    let _left=50-$_done
    # Build progressbar string lengths
    _done=$(printf "%${_done}s")
    _left=$(printf "%${_left}s")

    # 1.2 Build progressbar strings and print the ProgressBar line
    # 1.2.1 Output example:
    # 1.2.1.1 Progress : [########################################] 100%
    printf "\rProgress : [${_done// /\#}${_left// /-}] ${_progress}%% ${3} ${4} "
}

#functions
function_exists() {
    declare -f -F $1 > /dev/null 2>&1
    return $?
}

command_exists() {
    local cmd=
    for cmd in "$@"; do
        command -v $cmd > /dev/null 2>&1
        if [[ "${PIPESTATUS[0]}" -ne 0 ]]; then
            return 1
        fi
    done
    return 0
}

alias_exists() {
    alias $1 > /dev/null 2>&1
    [[ "${PIPESTATUS[0]}" -ne 0 ]] && return 1
    return 0

}

__isCygwin() {
    [[ "${MY_OS}" == "cygwin" ]] && return 0 || return 1
}

__isLinux() {
   [[ "${MY_OS}" == "linux" ]] && return 0 || return 1
}

__isMacOS() {
    [[ "${MY_OS}" == "darwin" ]] && return 0 || return 1
}

__print() {
    local _fmt=
    if [[ "$#" -gt 1 ]]; then _fmt="$1"; fi
    if [[ -z "${_fmt// }" ]]; then
        for arg in "$@";do _fmt="${_fmt}%s"; done
    else shift; fi
    __printf "${_fmt/# /}\n" "$@"
}

__printf() {
    __log "$@"
    [[ "${_SILENT}" != "y" ]] && printf "$@"
}

__info() {
    local _fmt=
    if [[ "$#" -gt 1 ]]; then _fmt="$1"; fi
    if [[ -z "${_fmt// }" ]]; then
        for arg in "$@";do _fmt="${_fmt}%s"; done
    else shift; fi
    __printf "[INFO] ${_fmt/# /}\n" "$@"
}

__warn() {
    local _fmt=
    if [[ "$#" -gt 1 ]]; then _fmt="$1"; fi
    if [[ -z "${_fmt// }" ]]; then
        for arg in "$@";do _fmt="${_fmt}%s"; done
    else shift; fi
    __printf "[WARN] ${_fmt/# /}\n" "$@"
}

__error() {
    local _fmt=
    if [[ "$#" -gt 1 ]]; then _fmt="$1"; fi
    if [[ -z "${_fmt// }" ]]; then
        for arg in "$@";do _fmt="${_fmt}%s"; done
    else shift; fi
    __printf "[ERROR] ${_fmt/# /}\n" "$@"
}

__set_err() {
    _ERR="$*"
    return 0
}

__debug() {
    if [[ -n "$_DEBUG" ]]; then
        local _fmt=
        if [[ "$#" -gt 1 ]]; then _fmt="$1"; fi
        if [[ -z "${_fmt// }" ]]; then
            for arg in "$@";do _fmt="${_fmt}%s"; done
        else shift; fi
        __printf "[DEBUG] ${_fmt/# /}\n" "$@"
    fi
    return 0
}

__repeat() {
    seq  -f $1 -s '' $2; echo
}

__logRun() {
    __log "%s" "$*"
    if [[ -n "$_DEBUG" ]]; then
        eval $@ 2>&1 | tee "$_LOG"
        return "${PIPESTATUS[0]}"
    else
        eval $@ >> "$_LOG" 2>&1
        return "${PIPESTATUS[0]}"
    fi
}

__log() {
    if [[ -n "$_LOG" ]] && [[ "$_LOG" != "/dev/null" ]]; then
       local log= logt=
        if [[ -n "$_LOG_DATE" ]]; then
            logt=$(date "$_LOG_DATE")
            log="$logt "
        fi
        [[ -n "$_LOG_SCRIPT" ]] && log="$log[$_LOG_SCRIPT]"
        local _fmt="$log$1"
        shift
        printf "${_fmt}" "$@" >> "$_LOG" 2>&1
    fi
}


#print message with sstatus
#   __print_red "ERROR" "Instalacao feita com sucesso!"
__print_red() {
    local stats="$1"; shift
    print_msg "$*" "$I_RED" "[$stats]"
}

#   __print_red "OK" "Instalacao feita com sucesso!"
__print_green() {
    local stats="$1"; shift
    print_msg "$*" "$I_GREEN" "[$stats]"
}

function print_msg() {
    local txt="$1"
    local color="$2"
    local msg="$3"
    local size=$(expr $I_COL - ${#msg} - 2)
    for ((i=0; i<${#txt}; i+=$size)); do
        local str="${txt:$i:$size}"
        if [[ "${#str}" -eq "$size" ]]; then
            __printf "${I_NORMAL}%s\n" "${txt:$i:$size}"
        else
            local txtLen=$(expr ${#str})
            local nBlank=$(expr $I_COL - $txtLen)
            __printf "${I_NORMAL}%s${color}%*s${I_NORMAL}\n" "$str" $nBlank " $msg "
        fi
    done
}

function __join_by { local IFS="$1"; shift; echo "$*"; }

__boolean_value() {
    if [[ -z "$1" ]]; then return 1; fi
    case "${1}" in
        true|T|t|s|y|yes|sim) return 0;;
       false|f|f|n|no|nao) return 1;;
        *) return 2;;
    esac
}

__to_sep() {
    myarr=( "$@" )
    arrl=${#myarr[@]}
    local sep=""
    local res=""
    for (( i=0; i<${arrl}; i++ )); do
        afullname=$(realpath "${myarr[$i]}")
        res="${res}${sep}${afullname}"
        if [[ -z "$sep" ]]; then sep=","; fi
    done
    echo "$res"
}

#runs a function each file line by line
#passes to function $line $filename
__readfile() {
    local rfl_c_file="$1"
    local rfl_c_func="$2"
    shift 2
    while IFS='' read -r rfline || [[ -n "$rfline" ]]; do
        function_exists "$rfl_c_func" && $rfl_c_func "$rfline" "$rfl_c_file" "$@"
    done < "$rfl_c_file"
}


##################################################
# USER INTERACTION
__confirm() {
    local msgConf="${1-Você tem certeza?}"
    local actionYes="$2"
    local actionNo="$3"
    read -p "$msgConf [y/N] " -n 1; echo;
    if __boolean_value "$REPLY"; then
        [[ -n "${actionYes// }" ]] && function_exists "$actionYes" && $actionYes
        [[ -n "${actionYes// }" ]] && command_exists "$actionYes" && $actionYes
        return 0
    else
        [[ -n "${actionNo// }" ]] && function_exists "$actionNo" && $actionNo
        [[ -n "${actionNo// }" ]] && command_exists "$actionNo" && $actionNo
        return 1
    fi
}


#runs a function each file line by line
#passes to function $line $filename
__ini_list() {
    local config="$1"
    local vars=$(cat "$config" \
        | sed -e "s/^[[:space:]]\+//g" -e '/^ +$/d' -e '/^$/d' -e '/^[#;]/d' \
        | sed  -rn "s/\[(.*)\]/\1/p" | tr '\n' ':' | sed -e 's/:$//')
    echo $vars
}

#runs a function each file line by line
#passes to function $line $filename
__ini_section()  {
    local config="$1" section="$2" name="$3"
    local name=${name:-$section}
    local vars=$(__ini_to_var $config $section)
    declare -gA "$name=($vars)"
}

__ini_sections()  {
    local config="$1" sections="$2" name="$3"
    local secArray= sec= vars= secVar=
    IFS=',' read -r -a secArray <<< "$sections"
    for sec in ${secArray[@]}; do
        secVar=$(__ini_to_var $config $sec)
        vars="$vars $secVar"
    done
    local name=${name:-$sec}
    declare -gA "$name=($vars)"
}

# Read one conf in all sections
# __ini_all_sections $config "Conf"
__ini_all_sections() {
    local config="$1"
    local _var="$2"
    local _varSize=$((${#_var} + 1))
    local section= vars= _dep=
    while IFS='' read -r line || [[ -n "${line// }" ]]; do
        if [[ "${line:0:1}" == "[" ]]; then
            section=$line
            continue
        fi
        if [[ "${line:0:$_varSize}" == "${_var}=" ]]; then
            if [[ -n "$section" ]]; then
                _dep="${line#*=}"
                if [[ "${_dep:0:1}" != "\"" ]]; then _dep="\"$_dep\""; fi
                vars="$vars ${section}=${_dep}"
                section=
            fi
        fi
    done < <(cat "$config" | sed -e "s/^[[:space:]]\+//g" \
             | sed -nE "/^(\[|$_var)/p" )
    echo "$vars"
}

__ini_to_var() {
    local config="$1" section="$2"
    local section=$(echo "$section" | sed -e 's/[]\/$*.^[]/\\&/g')
    local vars=$(cat "$config" | sed -e "s/^[[:space:]]\+//g" \
         | sed -nr "/^\[$section\]/ { :l /^[^#;].*/ p; n; /^\[/ q; b l; }" \
         | grep "^[^\[]" | sed -e "s/^[^=]*/\[\0\]/" \
         | sed -e "s/'/\"/g" -e "s/=/='/" -e "s/$/'/" \
         | tr '\n' ' '
    )
    echo "$vars"
}

__getRealUser() {
    [[ "$SUDO_USER" != "" && "$USER" = "root" ]] && echo "$SUDO_USER" || echo "$USER"
}

__parseURL() {
    local uuser= uhost= upath= pathStr="$1"
    uuser=$(echo "$pathStr" | grep "@" | cut -d@ -f1)
    if [[ -n "$uuser" ]]; then pathStr="${pathStr/${uuser}@/}"; fi
    uhost=$(echo "${pathStr}" | grep ":" | cut -d: -f1)
    if [[ -n "$uhost" ]]; then pathStr="${pathStr/${uhost}:/}"; fi
    unset _pURL
    declare -gA "_pURL"
    _pURL[user]="$uuser"
    _pURL[host]="$uhost"
    _pURL[path]="$pathStr"
}

__parseProxyURL() {
    local purl="$1"
    local pproto= puser= pport= ppath= phost=
    unset _pURL
    declare -gA "_pURL"
    # Extract the protocol (includes trailing "://").
    pproto="$(echo "$purl" | sed -nr 's,^(.*://).*,\1,p')"
    purl="${purl/$pproto/}"
    # Extract the user (includes trailing "@").
    puser=$(echo "$purl"  | sed -nr 's,^(.*@).*,\1,p')
    purl="${purl/$puser/}"
    [[ "$puser" == *:* ]] && ppass=$(echo "$puser" | cut -d":" -f2)
    puser=$(echo "$puser" | cut -d":" -f1)
    # Extract the port (includes leading ":").
    pport=$(echo "$purl" | sed -nr 's,.*(:[0-9]+).*,\1,p' )
    purl="${purl/$pport}"
    #extract the path
    ppath=$(echo "$purl" | sed -nr 's,[^/:]*([/:].*),\1,p' )
    purl="${purl/$ppath/}"
    phost="$purl"
    _pURL[proto]="${pproto%:\/\/}"
    _pURL[user]="${puser%@}"
    _pURL[pass]="${ppass%@}"
    _pURL[host]="${phost}"
    _pURL[port]="${pport#:}"
    _pURL[path]="${ppath}"
}

__is_subdir() {
    local DIR_A="$2"
    local DIR_B="$1"
    local home=${a_home:-$HOME}
    DIR_A=${DIR_A/#\~/$home}
    DIR_B=${DIR_B/#\~/$home}
    if [[ -z "$3" ]]; then
        DIR_A=$( readlinkf "$DIR_A" )
        DIR_B=$(echo "$DIR_B" | sed -e "s|./|$PWD/|" -e "s|~/|$home|" )
    fi
    if [[ "${DIR_A:0:${#DIR_B}}" == "$DIR_B" ]]; then
        return 0
    else
        return 1
    fi
}

__dir_in() {
    local dir="$1"
    local result=1
    while IFS=',' read -ra FOLDERS; do
        for F in "${FOLDERS[@]}"; do
            if [[ "${dir:0:${#F}}" == "$F" ]]; then
                result=0
                break
            fi
        done
    done <<< "$2"
    unset FOLDERS F
    return $result
}

__envSubst() {
    declare data="$1"
    declare delimiter="__apply_shell_expansion_delimiter__"
    declare command="cat <<$delimiter"$'\n'"$data"$'\n'"$delimiter"
    eval "$command"
}

function __changeConfig() {
    local _regex="$1"
    local _replace="$2"
    local _file="$3"
    local _sudow= _sudor=
    [[ ! -f "${_file}" ]] && touch "${_file}"
    [[ -w "${_file}" ]] && _sudow="sudo"
    [[ -r "${_file}" ]] && _sudor="sudo"

    local _line=$(cat "${_file}" | \
        sed -e "s/^[[:space:]]\+//g" -e "s/[[:space:]]\+$//g" | \
        grep -Fx "${_replace}")
    #if line doesnt exists exactly
    if [[ -z "${_line// }" ]]; then
        #remove lines with regex
        if [[ -n "${_regex// }" ]]; then
            $_sudor sed -r -i'.bak' "/${_regex}/d" "${_file}"
        fi
        #add new content there
        echo "${_replace}" | $_sudor tee -a "${_file}" > /dev/null 2>&1
    fi
}

__inArray() {
    local n=$#
    local value="${!n}"
    for (( i=1; i<$#; i++ )); do
        if [ "${!i}" == "${value}" ]; then
            echo "y"
            return 0
        fi
    done
    echo "n"
    return 1
}

__toCmdArray() {
    local str="$1" char= char1= quote= strT=
    declare -ag toCmdArray=()
    str=$(echo "$str" | sed -Ee 's/["]+/"/g' -e "s/[']+/'/g")
    local strL=${#str}
    for (( i=0; i<$strL; i++ )); do
        char="${str:$i:1}"
        if [[ "$char" = '"' ]] || [[ "$char" = "'" ]]; then
            if [[ "$char1" != '\' ]]; then
                if [[ "$quote" == "$char" ]]; then
                    quote=
                else
                    quote="$char"
                fi
                continue
            fi
        fi
        #espaco e nao esta dentro de aspas
        if [[ "$char" == " " ]] && [[ -z "$quote" ]]; then
            if [[ -n "$strT" ]]; then
#                strT=$(echo "$strT" | sed -e 's/[][" `~!@#$%^&*():;<>.,?/\|{}=+-]/\\&/g')
                toCmdArray+=("$strT")
            fi
            strT=
            continue
        fi
        strT="${strT}${char}"
        char1="$char"
    done
    if [[ -n "$strT" ]]; then
#        strT=$(echo "$strT" | sed -e 's/[][" `~!@#$%^&*():;<>.,?/\|{}=+-]/\\&/g')
        toCmdArray+=("$strT")
    fi
    return 0
}

__humanToByte() {
  for v in "${@}"; do
    echo $v | awk \
      'BEGIN{IGNORECASE = 1}
       function pp(n,b,p) {printf "%u\n", n*b^p; next}
       /[0-9]$/{print $1;next};
       /K(iB)?$/{pp($1,  2, 10)};
       /M(iB)?$/{pp($1,  2, 20)};
       /G(iB)?$/{pp($1,  2, 30)};
       /T(iB)?$/{pp($1,  2, 40)};
       /KB$/{    pp($1, 10,  3)};
       /MB$/{    pp($1, 10,  6)};
       /GB$/{    pp($1, 10,  9)};
       /TB$/{    pp($1, 10, 12)}'
  done
}

__numberCompare() {
    local A="$1" OP="$2" B="$3" ret=1
    case "$OP" in
        ">"|"bigThan"|"gt")
            [[ "$A" -gt "$B" ]] && ret=0;;
        ">="|"equalOrBigThan"|"ge")
            [[ "$A" -ge "$B" ]] && ret=0;;
        "="|"=="|"equal"|"eq")
            [[ "$A" -eq "$B" ]] && ret=0;;
        "<"|"lowerThan"|"lt")
            [[ "$A" -lt "$B" ]] && ret=0;;
        "<="|"equalOrLowerThan"|"le")
            [[ "$A" -le "$B" ]] && ret=0;;
        "!="|"notEqual"|"ne")
            [[ "$A" -ne "$B" ]] && ret=0;;
    esac
    return $ret
}

__trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}


__countFilesSilent() {
    local _dir="${1:-.}"
    local _dirname=$(readlinkf "$_dir")
    shift
    local _total=$(find "${_dirname}" -type f "$@" -printf '\n' 2>/dev/null | wc -l)
    printf "$_total"
}

function join_by {
    local IFS="$1"; shift; echo "$*";
}

#compatibility layer
# readlink on macs
_readlinkf() {
    perl -MCwd -le 'print Cwd::abs_path shift' "$1";
}

# Ask user for input
# __ask "qual seu nome?"
__ask() {
    unset E_ANSWER
    local question="${1}"
    read -p "${1:-Informe:} " _answer
    printf "\n"
    [[ -n "${_answer// }" ]] && E_ANSWER="$_answer" && return 0 || return 1
}


__askPassword() {
    unset E_PASSW
    local _def="Enter Password"
    local prompt="${1:-$_def}: "
    local _pass=
    read -s -p "${prompt}" _pass
    printf "\n"
    [[ -n "${_pass// }" ]] && E_PASSW="$_pass" && return 0 || return 1
}

__confirmPasswordTries() {
    local times=${1:-3}
    shift
    for (( i=1; i<$times; i++ )); do
        __confirmPassword "$@"
        ret=$?
        [[ "$ret" -eq 4 ]] && return 4
        [[ "$ret" -eq 0 ]] && return 0
        echo "Try again (${i}/${times})"
    done
    return 1
}

__confirmPassword() {
    if __askPassword "$@"; then
        local tmp_p="$E_PASSW"
        [[ -z "$E_PASSW" ]] && unset E_PASSW && return 4
        if __askPassword "Confirm Password"; then
            if [[ "$tmp_p" == "$E_PASSW" ]]; then
                return 0
            fi
            echo "Passwords did not match..."
            return 1
        fi
        echo "Confirmation is empty..."
        return 1
    fi
    [[ -z "$E_PASSW" ]] && unset E_PASSW && return 4
    unset E_PASSW
    return 1
}

# keeps sudo while script is running
__keep_sudo() {
    # Ask for the administrator password upfront
    sudo -v
    # Keep-alive: update existing `sudo` time stamp until `.macos` has finished
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
}
