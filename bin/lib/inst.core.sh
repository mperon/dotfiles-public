#!/usr/bin/env bash
#vim: ts=4 sw=4 et ft=sh

INST_CORE_SH=1

[[ "${BASH_SOURCE-}" == "$0" ]] \
    && echo "You must source this script: \$ source $BASH_SOURCE" >&2 \
    && exit 33

[[ -z "$BASH_FN_SH" ]] && source "${BASH_SOURCE%/*}/bashFn.sh"

#Global variables
LOG_TO=/tmp/inst.log
VERBOSE=
APT_NEED_UPD=n
PROTECT=(/bin /boot /cdrom /dev /proc /sbin /run /sys /var /init /lib64 /lib /lib32 /lost+found)
PROGRAMS=(awk tee wget git perl lspci)
_INSTALLFROM=
ARCH=$(uname -m)

[[ -z "$_SOURCES" ]] && _SOURCES=("$0") || _SOURCES+=("$BASH_SOURCE")

########################################
#   GROUP installers                   #
########################################
function __installers() {
    local target="$1" action="$2" g=
    if [[ -n "$target" ]] && [[ "${target}" != *":"* ]]; then
        target="$target:auto"
    fi
    while IFS='' read -r line || [[ -n "${line// }" ]]; do
        if [[ "$line" =~ ^([a-zA-Z0-9_-]+)\(\)[[:space:]]*\{[[:space:]]*\#([a-zA-Z0-9_:,-]+) ]]; then
            local _fnName="${BASH_REMATCH[1]}" _fnGroups="${BASH_REMATCH[2]}" _arrGroups=()
            IFS=',' read -r -a _arrGroups <<< "$_fnGroups"

            # if no target
            if [[ -z "$target" ]]; then
                $action "$target" "$_fnName" "$g" "${_arrGroups[@]}"
                continue
            fi

            #normalize search groups
            local gL=${#_arrGroups[@]}
            for (( i=0; i<$gL; i++ )); do
                [[ "${_arrGroups[$i]}" == *":"* ]] || _arrGroups[$i]="${_arrGroups[$i]}:auto"
            done
            for g in "${_arrGroups[@]}"; do
                if [[ "$g" == *"$target"* ]]; then
                    $action "$target" "$_fnName" "$g" "${_arrGroups[@]}"
                    break
                fi
            done
        fi
    done < <(cat "${_SOURCES[@]}" | grep -E "() { #" \
                | sed -e "s/^[[:space:]]\+//g")
}

function __print() {
    local _fnName="$2"
    local _fnGroup="$3"
    shift 3
    local _fnGroups=("$@")
    printf "Fuction: %s\tMatch: %s\tAll Groups: %s\n" "$_fnName" "$_fnGroup" "${_fnGroups[*]}"
}

function __list() {
    local _fnName="$2"
    local _fnGroup="$3"
    shift 3
    local _fnGroups=("$@")
    printf "\t%s\n" "$_fnName"
}

function __install() {
    local _fnName="$2"
    printf "Running %s:\n" "$_fnName ..."
    $_fnName
}

function __installfrom() {
    local _fnName="$2"
    if [[ ! -z "${_INSTALLFROM// }" ]]; then
        if [[ "$_fnName" == "${_INSTALLFROM}" ]]; then
            _INSTALLFROM=""
            __install "$@"
        else
            printf "Skipping %s \n" "$_fnName"
        fi
    else
        __install "$@"
    fi
}

function __ls() {
    __installers "$1" __list
}

function __lsa() {
    __installers "$1" __print
}

function __run() {
    echo "Running installers for: $1"
    __installers "$1" __install
}

function __runfrom() {
    _INSTALLFROM="$2"
    echo "Running installers after: $2 for $1"
    __installers "$1" __installfrom
}

function __inst_category() {
    __installers "core:auto" __install
    __installers "$1:auto" __install
    printf "You can install this optional software manually:\n"
    __ls "core:manual"
    __ls "$1:manual"
    printf "You can do this manually:\n"
    __installers "print" __install
}

inst_desktop() { #category
    __inst_category "desktop"
}

inst_fresh() { #category
 __inst_category "fresh"
}

inst_categories() { #categories
    printf "These are selection of softwares based on categories :\n"
    __installers "category:auto" __list
    __installers "category:manual" __list
    printf "If you want to see whats in one, execute: \n"
    printf "   $ inst ls [category]\n"
}

inst_advice() { #category
    __installers "print" __install
}

inst_server() { #category
    __inst_category "server"
}

inst_programming() { #category
    #warning first
    echo "Attention!"
    echo "You need to install core tools before install programming!!"
    echo ""
    __installers "programming:auto" __install
    printf "You can install this optional software manually:\n"
    __ls "programming:manual"
}

########################################
#                                      #
#           Main Function              #
#                                      #
########################################
function main() {
    local ret=0
    while (( "$#" )); do
        arg="${1}"
        shift
        [[ "${arg:0:1}" == "-" ]] && continue
        if [[ $(type -t "$arg") != "function" ]]; then
            if  [[ "$arg" == ls* ]] ||  [[ "$arg" == run* ]]; then
                function_exists "__$arg" && "__$arg" "$@" || echo "Function $arg doesnt exists!"
                ret=$?
                break
            elif [[ ! "$arg" == inst_* ]]; then
                if function_exists "inst_$arg"; then
                    echo "Running: inst_$arg"
                    "inst_"$arg "$@"
                    [[ $? -ne 0 ]] && ret=1
                    continue
                else
                    echo "$arg: functions desnt exists!"
                    continue
                fi
            else
                echo "$arg: doesnt exists!"
                continue
            fi
        else
            if [[ "$arg" == repo_* ]]; then
                echo "Running: $arg ${@}"
                $arg "$@"
                ret=$?
            else
                echo "Running: $arg"
                $arg
                [[ $? -ne 0 ]] && ret=1
            fi
        fi
    done
    return $ret
}

#prints help messages
#   ajuda
function ajuda() {
    cat "${_SOURCES[@]}" | grep -Eo "^[a-z0-9_-]+[(][)]" | tr '()' '  ' | sort
}

#prints help messages
#   help
function help() {
    ajuda
}

#prints help messages
#   h
function h() {
    ajuda
}
