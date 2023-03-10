#!/bin/bash

_javaf="$PK_PROFILED/javasettings"

PK_JAVA_DEFAULT_NOPROXY="localhost,localaddress,*.localdomain.com,127.0.0.1,127.0.1.1"
[[ -z "${PK_JAVA_NOPROXY// }" ]] && PK_JAVA_NOPROXY="${PK_JAVA_DEFAULT_NOPROXY}"

#
#	Sets the gnome enviroment settings..
#
__javaProxyEnable() {
	__javaCheck  || return 4
    printf "#!/bin/bash\n" > "$_javaf"
    printf "# vim: ts=4 sw=4 et ft=sh\n\n" >> "$_javaf"	
    printf "# Java Proxy Automatic Session on Profile.\n" >> "$_javaf"
    printf "# Do not delete or edit this file \n\n" >> "$_javaf"
    printf 'if [[ -f "%s" ]]; then \n' "$HOME/.proxy" >> "$_javaf"
    local _javaOpts=$(__buildJavaOptions)
    printf '    export %s="%s"\n' "JAVA_OPTS" "$_javaOpts" >> "$_javaf"
    printf "fi\n"  >> "$_javaf"
    chmod +x "$_javaf"
}


__javaProxyDisable() {
    if [[ -f "$_javaf" ]]; then
        rm -f "$_javaf"
    fi
}

__javaProxyOn() {
    if [[ -f "$_javaf" ]]; then
        source "$_javaf"
    fi
}

__javaProxyOff() {
	unset JAVA_OPTS
}

__buildJavaOptions() {
	local builded="-Dhttp.proxyHost=$PK_PROXY_HOST"
	builded+=" -Dhttp.proxyPort=$PK_PROXY_PORT"
	builded+=" -Dhttps.proxyHost=$PK_PROXY_HOST"
	builded+=" -Dhttps.proxyPort=$PK_PROXY_PORT"
	echo "$builded"
}

#internal command
__javaCheck() {
	! command_exists "java" && return 4
	if [[ ! -n "${PK_PROXY_HOST// }" ]]; then
		#finds first variable with proxy settings
		proxyUrl=$(__getFirstProxyVariable)
		__parseProxyURL "$proxyUrl"
		PK_PROXY_HOST="${_pURL[host]}"
		PK_PROXY_PORT="${_pURL[port]:-80}"
	fi
	return 0
}
