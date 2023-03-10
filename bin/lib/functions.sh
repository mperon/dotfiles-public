#!/usr/bin/env bash
#vim: ts=4 sw=4 et ft=sh

FUNCTIONS_SH=1

[[ "${BASH_SOURCE-}" == "$0" ]] && echo "You must source this script: \$ source $BASH_SOURCE" >&2 && exit 33

e_newline() { printf "\n"; }
e_header()  { printf "\r\033[1m%s\033[0m\n" "$*"; }
e_success() { printf " \033[1;32m✔\033[0m  %s\n" "$*"; }
e_error()   { printf " \033[1;31m✖\033[0m  %s\n" "$*" 1>&2; }
e_arrow()   { printf " \033[1;34m➜\033[0m  %s\n" "$*"; }

command_exists() {
    command -v "$1" > /dev/null 2>&1
    return $?
}

clipboard() {
    if command_exists xdg-open; then
        if [[ ! -t 0 ]]; then
            xclip -selection clipboard -in
        else
            xclip -selection clipboard -out
        fi
    elif [[ "$OSTYPE" == darwin* ]]; then
        if [[ ! -t 0 ]]; then
            pbcopy
        else
            pbpaste
        fi
    elif [[ "$OSTYPE" == cygwin* ]] || [[ "$OSTYPE" == *msys* ]]; then
        if [[ ! -t 0 ]]; then
            tee > /dev/clipboard
        else
            cat /dev/clipboard
        fi
    elif [[ $OSTYPE == linux* ]] && [[ -r /proc/version ]] && [[ $(< /proc/version) == *microsoft* ]]; then
        if [[ ! -t 0 ]]; then
            clip.exe
        else
            powershell.exe -Command Get-Clipboard
        fi
    fi
}
