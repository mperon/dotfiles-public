#!/usr/bin/env bash
#vim: ts=4 sw=4 et ft=sh

BASH_OPEN_SH=1

[[ "${BASH_SOURCE-}" == "$0" ]] && \
	echo "You must source this script: \$ source $BASH_SOURCE" >&2 \
	&& exit 33

system_open() {
    case "$OSTYPE" in
        cygwin*) 
            /usr/bin/cygstart "$@" 
            ;;
        linux*) 
            [[ -n "$WSL_DISTRO_NAME" ]] && wslview "$@" || xdg-open "$@"
            ;;
        darwin*)
            /usr/bin/open "$@"
            ;;
        *)
            echo "Unsupported OS: ${OSTYPE}"
            return 4
            ;;
    esac
    return 0
}
