#!/bin/bash

#
#	Sets the GIT enviroment
#
__gitProxyEnable() {
	! __hasGit && return 4
	local httpProxy=$(__getFirstProxyVariable "HTTP_PROXY")
	local httpsProxy=$(__getFirstProxyVariable "HTTPS_PROXY")

	__debug "Setting GIT config http.proxy to '$httpProxy'"
	__debug "Setting GIT config https.proxy to '$httpsProxy'"	
    git config --global http.proxy "$httpProxy"
    git config --global https.proxy "$httpsProxy"
}

__gitProxyDisable() {
	! __hasGit && return 4
	__debug "Unsetting GIT configs https.proxy and https.proxy"
	git config --unset --global http.proxy
	git config --unset --global https.proxy
}

__hasGit() {
	! command_exists "git" && return 4
	return 0
}