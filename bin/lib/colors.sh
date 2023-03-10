#!/usr/bin/env bash
#vim: ts=4 sw=4 et ft=sh

BASH_CL_SH=1

[[ "${BASH_SOURCE-}" == "$0" ]] && echo "You must source this script: \$ source $BASH_SOURCE" >&2 && exit 33

#colors
I_RED='\033[0;31m'
I_GREEN='\033[0;32m'
I_BLUE='\033[0;34m'
I_BOLD='\033[1m'
I_NORMAL='\033[0m'
I_CYAN='\033[0;36m'
tty -s && I_COL=$(tput cols) || I_COL=80


_printf() {
    local _fmt=
    if [[ "$#" -gt 1 ]]; then _fmt="$1"; fi
    if [[ -z "${_fmt// }" ]]; then
        for arg in "$@";do _fmt="${_fmt}%s"; done
    else shift; fi

    #color support
    

    printf "${_fmt/# /}" "$@"
}

_println() {
    _printf "$@" && printf "\n"
}
