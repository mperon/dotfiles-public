#!/usr/bin/env bash
#vim: ts=4 sw=4 et ft=sh

# Global Variable
ENSURE_VENV_SH=1

# Default variables
P_VENV_DIR= P_VENV_NAME= P_VENV= P_VENV_SCRIPT= P_VERSION="python3"
P_VENV_PATH= P_VENV_PKGS= P_VENV_UPGRADE=$VENV_UPGRADE


py_exists() {
    $P_VERSION -c "import $1" > /dev/null 2>&1
    return ${PIPESTATUS[0]}
}

cmd_exists() {
    hash "$1" &> /dev/null; return $?
}

#basic functions
_load_venv() {
    if [[ -z "$VIRTUAL_ENV" ]]; then
        [[ ! -f "$P_VENV/$P_VENV_SCRIPT" ]] && echo "Broken virtualenv $P_VENV .." \
            && return 4
        # try to load
        source "$P_VENV/$P_VENV_SCRIPT" || return 4
    fi
    [[ -n "$VIRTUAL_ENV" ]] && return 0
    echo "Error trying to load virtual environment.. "
    return 4
}

_upgrade() {
    if [[ -z "$P_VENV_UPGRADED" ]]; then
        $P_VERSION -m pip install --upgrade pip venv build > /dev/null 2>&1
        P_VENV_UPGRADED=y
    fi
}

_check_pkg() {
    [[ -z $VIRTUAL_ENV ]] && source "$P_VENV/$P_VENV_SCRIPT"
    [[ -z $P_VENV_UPGRADE ]] && return 0
    if [[ -n $VIRTUAL_ENV ]]; then
        # check if all packages are installed
        _upgrade
        if [[ -n "${P_VENV_PKGS}" ]]; then
            $P_VERSION -m pip install ${P_VENV_PKGS} > /dev/null 2>&1 || return 4
        fi
        return 0
    fi
    return 4
}

# makes sure you have python and a working virtual environment
_check_venv() {
    P_VENV="${1:-${P_VENV_DIR}/${P_VENV_NAME}}"
    [[ -d "${P_VENV_DIR}" ]] && mkdir -p "${P_VENV_DIR}"

    # ensure python
    if ! cmd_exists $P_VERSION || ! py_exists "pip"; then
        echo "No $P_VERSION or pip installed in your system.."
        return 4
    fi

    # ensure virtualenv
    if ! py_exists venv; then
        echo "Trying to install venv on you system.."
        $P_VERSION -m pip install --upgrade pip venv build > /dev/null 2>&1
        [[ ${PIPESTATUS[0]} -ne 0 ]] && echo "Cannot install venv.." && return 4
    fi

    # check if you already be in an virtual environment
    if [[ -n "$VIRTUAL_ENV" ]]; then
        [[ "$VIRTUAL_ENV" == "$P_VENV" ]] && return 0
        echo "You already in an enviroment: ${VIRTUAL_ENV} . "
        return 4
    fi

    # check virtualenv directory
    if [[ ! -d "$P_VENV" ]]; then
        echo "Enviroment doesnt exits! "
        echo "  Creating: $P_VENV .."
        $P_VERSION -m venv "$P_VENV" > /dev/null 2>&1 || return 4
        _load_venv || return 4
        _upgrade
        if [[ -n "${P_VENV_PKGS}" ]]; then
            echo "Installing packages..."
            echo "  $P_VENV_PKGS "
            $P_VERSION -m pip install ${P_VENV_PKGS} > /dev/null 2>&1 || return 4
        fi
        echo "Installed! Running..."
    fi
    _load_venv || return 4
    # ensure modules is installed
    return 0
}

_check_path() {
    if [[ -n "$P_VENV_PATH" ]]; then
        export PYTHONPATH="$PYTHONPATH:$P_VENV_PATH"
    fi
    return 0
}

ensure_venv() {
    P_VENV_DIR="${P_VENV_DIR:-$HOME/.cache/venvs}"
    P_VENV_NAME="${P_VENV_NAME:-}"
    P_VENV="${P_VENV_DIR}/${P_VENV_NAME}"
    P_VENV_SCRIPT="bin/activate"
    P_VERSION="python3"
    P_VENV_PATH="${P_VENV_PATH:-}"
    P_VENV_PKGS="${P_VENV_PKGS:-}"
    _check_venv && _check_pkg && _check_path && return 0
    return 4
}

force_venv() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        [[ "$VIRTUAL_ENV" == "$P_VENV" ]] && return 0
        deactivate_venv
    fi

    # check if out of venv
    if [[ -z "$VIRTUAL_ENV" ]]; then
        ensure_venv "$@"
        return $?
    fi
}

deactivate_venv() {
    unset -f pydoc > /dev/null 2>&1 || true
    if ! [ -z "${_OLD_VIRTUAL_PATH:+_}" ]
    then
        PATH="$_OLD_VIRTUAL_PATH"
        export PATH
        unset _OLD_VIRTUAL_PATH
    fi
    if ! [ -z "${_OLD_VIRTUAL_PYTHONHOME+_}" ]
    then
        PYTHONHOME="$_OLD_VIRTUAL_PYTHONHOME"
        export PYTHONHOME
        unset _OLD_VIRTUAL_PYTHONHOME
    fi
    hash -r 2> /dev/null
    if ! [ -z "${_OLD_VIRTUAL_PS1+_}" ]
    then
        PS1="$_OLD_VIRTUAL_PS1"
        export PS1
        unset _OLD_VIRTUAL_PS1
    fi
    unset VIRTUAL_ENV
    if [ ! "${1-}" = "nondestructive" ]
    then
        unset -f deactivate
    fi
}



