#!/bin/bash

#
#	Sets the GIT enviroment
#
_sshf="$HOME/.ssh/config"
_sshd="$HOME/.ssh/config.d"

PK_SSH_DEFAULT_HOSTS=("bitbucket.org" "github.com" "gitlab.com")
[[ -z "${PK_SSH_HOSTS// }" ]] && PK_SSH_HOSTS=("${PK_SSH_DEFAULT_HOSTS[@]}")

[[ ! -f "$_sshf" ]] && echo "Include ~/.ssh/config.d/*" > "$_sshf"
[[ ! -d "$_sshd" ]] && mkdir -p "$_sshd" && touch "$_sshd/.gitkeep"

__sshProxyEnable() {
	local a_host=
	if [[ "${PK_SSH_HOSTS[*]// }" == "disabled" ]]; then
		rm -f $_sshd/*
	else
		__sshCheck
		for a_host in "${PK_SSH_HOSTS[@]}"; do
			__sshCreateFile "$a_host"
		done
	fi
	__sshFilePermissions
}

__sshFilePermissions() {
	#fix permissions
	chmod 700 $HOME/.ssh > /dev/null 2>&1
	chmod 644 $HOME/.ssh/authorized_keys > /dev/null 2>&1
	chmod 644 $HOME/.ssh/known_hosts > /dev/null 2>&1
	chmod 644 $HOME/.ssh/config > /dev/null 2>&1
	chmod 644 $HOME/.ssh/config.d/* > /dev/null 2>&1
	chmod 600 $HOME/.ssh/id_rsa > /dev/null 2>&1
	chmod 644 $HOME/.ssh/*_rsa.pub > /dev/null 2>&1
	chmod 600 $HOME/.ssh/*_rsa > /dev/null 2>&1
}

__sshProxyDisable() {
	local a_host=
	for a_host in "${PK_SSH_HOSTS[@]}"; do
		__sshRemoveFile "$a_host"
	done
	__sshFilePermissions
}

__sshCheck() {
	if [[ ! -n "${PK_PROXY_HOST// }" ]]; then
		#finds first variable with proxy settings
		proxyUrl=$(__getFirstProxyVariable)
		__parseProxyURL "$proxyUrl"
		PK_PROXY_HOST="${_pURL[host]}"
		PK_PROXY_PORT="${_pURL[port]:-80}"
	fi
}

__sshCreateFile() {
	local a_host="$1"
	local a_file="10_proxy_${a_host%.*}"
	local a_full_f="$_sshd/$a_file"
	echo "" > "$a_full_f"
	echo "Host $a_host" >> "$a_full_f"
    echo "  Hostname $a_host" >> "$a_full_f"
    echo "  ProxyCommand /usr/bin/corkscrew $PK_PROXY_HOST $PK_PROXY_PORT %h %p" >> "$a_full_f"
    echo "" >> "$a_full_f"
}

__sshRemoveFile() {
	local a_host="$1"
	local a_file="10_proxy_${a_host%.*}"
	local a_full_f="$_sshd/$a_file"
	[[ -f "$a_full_f" ]] && rm -f "$a_full_f"
}