#!/usr/bin/env bash
#vim: ts=4 sw=4 et ft=sh

T_GIT_HTTP_URL=https://github.com/mperon/dotfiles.git
T_GIT_SSH_URL=git@github.com:mperon/dotfiles.git

[[ -z "$T_GIT_DIR" ]] && T_GIT_DIR=$HOME/.config/dotfiles
[[ -z "$T_WORK_TREE" ]] && T_WORK_TREE=$HOME
[[ -z "$T_FORCE" ]] && T_FORCE=
[[ -z "$T_HTTP" ]] && T_GIT_URL=$T_GIT_SSH_URL \
    || T_GIT_URL=$T_GIT_HTTP_URL
T_ARGV=

#OS that will be installed
[[ -z "${OS}" ]] && OS=$(uname -s | cut -d"_" -f1 | tr '[:upper:]' '[:lower:]')

# functions
ifind() {
    ( LC_ALL=C find "$@" 3>&2 2>&1 1>&3 | grep -v 'Permission denied' >&3; ) 3>&2 2>&1
}

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

dot_cfg() {
    /usr/bin/git --git-dir=$T_GIT_DIR --work-tree=$T_WORK_TREE "$@"
}

# write_config ZSH zshrc
# write_config BASH bash_profile bashrc
write_config() {
    local shell=$1 name=$2 src=${3:-$2}

    [[ ! -f $HOME/.${name} ]] && touch $HOME/.${name}
    if ! grep -F "# -* Peron DotFiles -*" $HOME/.${name} > /dev/null 2>&1; then
        [[ ! -s $HOME/.${name} ]] && cp $HOME/.${name} $HOME/.${name}_old \
            && echo "Backing up old .${name} to .${name}_old"

        echo "Configuring ${shell} to load dotfiles.. Done!"
        # peron dotfiles is not configured
        cat <<EndOfConfig > $HOME/.${name}

# -* Peron DotFiles -*
# Avaliable at: $T_GIT_HTTP_URL

OS=${OS}

if [[ -f "\$HOME/.shell/${src}" ]]; then
    source "\$HOME/.shell/${src}"
fi
# -* End DotFiles -*
EndOfConfig
else
    echo "${shell} is already configured to load dotfiles. Skipping!"
fi
}

#create git dir
mkdir -p $(dirname "$T_GIT_DIR")

#first things first

# check ssh and git install
command_exists git || ( echo "you do not have git installed!" && exit 4 )
command_exists ssh || ( echo "you do not have ssh client installed!" && exit 4 )

#check if user has ssh configured
if [[ -z "$T_HTTP" ]]; then
    pk_count=$(ifind $HOME/.ssh -iname '*.pub' -type f -print | wc -l)
    if [[ "$pk_count" -lt "1" ]]; then
        # configuring ssh
        echo "You dont have a ssh key. We gona create one!"
        a_name=$(hostname)
        a_user="$USER"
        ssh-keygen -t ed25519 -f $HOME/.ssh/id_ed25519 \
                    -C "${a_user}@${a_name}" >/dev/null 2>&1
        if [[ "${PIPESTATUS[0]}" -ne 0 ]]; then
           echo "Error generating the key..."
           exit 4
        fi
        ssh-add $HOME/.ssh/id_ed25519
        # now print the key, add to clibpoard an suggest to add to github
        echo "Key created!"
        echo "Please, go to: https://github.com/settings/keys"
        echo ""
        echo "and add this key to authorized ssh keys:"
        echo ""
        cat "$HOME/.ssh/id_ed25519.pub"
        echo ""

        clipboard < $HOME/.ssh/id_ed25519.pub
        echo "Copied to Clipboard!"
    fi
fi
# git dir doesnt exists, clone the repo
if [[ ! -d "$T_GIT_DIR" ]]; then
    git clone --bare $T_GIT_URL "$T_GIT_DIR"
    if [[ "${PIPESTATUS[0]}" -ne 0 ]]; then
        echo "An error ocurred when cloning repository. Check:"
        echo "   1) If you have saved the ssh key into authorized keys"
        echo ""
        cat "$HOME/.ssh/id_rsa.pub"
        echo ""

        if [[ -z "$T_HTTP" ]]; then
            clipboard < $HOME/.ssh/id_rsa.pub
            echo "Copied to Clipboard!"
        fi
        # just exits
        exit 4
    fi
    # clone was sucessfull, continue
fi

if [[ ! -d "$T_GIT_DIR" ]]; then
    echo "Error ocurred with $HOME/.config/dotfiles "
    echo "The directory was not created!"
    exit 4
fi

if ! dot_cfg rev-parse --git-dir 2> /dev/null; then
    echo "directory $T_GIT_DIR exists but is not a valid git dir.."
    echo "manually delete it for be recreated!"
    echo "using: rm -rf $T_GIT_DIR"

    echo "rm -rf $T_GIT_DIR"  | clipboard
    echo "Copied to Clipboard!"
    exit 4
fi

dot_cfg fetch --all
[[ -n "$T_FORCE" ]] && T_ARGV="-f"
dot_cfg checkout $T_ARGV
if [[ $? -ne 0 ]]; then
    [[ -n "$T_FORCE" ]] && echo "Unknown error ocurred!" && exit 4
    echo "You have files that will be overritten from this script."
    echo "If you are sure that you will want to continue, please:"
    echo "  1) Backup and move files that will be overritten"
    echo "  2) Run this script with T_FORCE=y (curl ... | T_FORCE=y bash)"
    exit 1
fi

#CONFIGURE GIT
#local repo configuration
#CONFIGURE GIT
#local repo configuration
dot_cfg config --local status.showUntrackedFiles no
dot_cfg config --local credential.helper store
# copy git config file and link to .config/gitconfig
if [[ -f "$HOME/.config/gitconfig" ]]; then
    if ! git config --list | grep -F "include.path=~/.config/gitconfig" > /dev/null 2>&1; then
        #back up current git file
        [[ -f "$HOME/.gitconfig" ]] && mv "$HOME/.gitconfig" "$HOME/.gitconfig_old"
        #copy from sample
        if [[ -f "$HOME/.gitconfig_sample"  ]]; then
            cp "$HOME/.gitconfig_sample" "$HOME/.gitconfig"
        else
            cat << EndOfConfig > $HOME/.gitconfig
[include]
    path = ~/.config/gitconfig
#[user]
#    signingkey = "ssh-rsa <publickey>"
#[commit]
#    gpgsign = true
#[gpg]
#    format = ssh
EndOfConfig
        fi
    fi
fi
# check if has signature and config
if [[ $HOME/.ssh/id_ed25519.pub ]]; then
    git config --global user.signingkey "$(tr '\n' ' ' < $HOME/.ssh/id_ed25519.pub)"
    git config --global commit.gpgsign true
    git config --global gpg.format ssh
    echo "Configuring git signingkey using id_ed25519. Done!"
elif [[ -f $HOME/.ssh/id_rsa.pub ]]; then
    git config --global user.signingkey "$(tr '\n' ' ' < $HOME/.ssh/id_rsa.pub)"
    git config --global commit.gpgsign true
    git config --global gpg.format ssh
    echo "Configuring git signingkey using id_rsa. Done!"
else
    echo "[Failed] Git signingkey not found"
    echo "You will need to configure manually! "
fi

# configure ZSH, BASH and Profile
write_config "ZSH" "zshrc"
write_config "BASH" "bashrc"
write_config "PROFILE" "profile"
write_config "BASH_PROFILE" "bash_profile" "bashrc"

echo "Everything is DONE! Reload your session to enable-it!"
# DONE CONFIGURING ZSH AND BASH

# -------------------
# Install using curl:
# -------------------
#    $ curl -fsSL https://mperon.org/dotfiles/private.sh | bash
#
# Options:
# If you want to use http connection, sets T_HTTP=y
#    $ T_HTTP=y curl -fsSL https://mperon.org/dotfiles/private.sh | bash
#
# -------------------
# Install using wget:
# -------------------
#    $ wget -qO- https://mperon.org/dotfiles/private.sh | bash
#
# Options:
# If you want to use http connection, sets T_HTTP=y
#    $ T_HTTP=y wget -qO- https://mperon.org/dotfiles/private.sh | bash
#
# ----------------
# Generic Options:
# ----------------
# If you want to force install and replace local files, use T_FORCE=y before command.
# curl:
#   $ T_FORCE=y curl -fsSL https://mperon.org/dotfiles/private.sh | bash
# wget:
#   $ T_FORCE=y wget -qO- https://mperon.org/dotfiles/private.sh | bash
