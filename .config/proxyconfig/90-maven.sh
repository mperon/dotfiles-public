#!/bin/bash

_mavenf="$PK_PROFILED/mavensettings"
PK_MAVEN_DEFAULT_NOPROXY="localhost,localaddress,*.localdomain.com,127.0.0.1,127.0.1.1"
[[ -z "${PK_MAVEN_NOPROXY// }" ]] && PK_MAVEN_NOPROXY="${PK_MAVEN_DEFAULT_NOPROXY}"


__mavenProxyEnable() {
	__mavenCheck && return 4

	printf "#!/bin/bash\n" > "$_mavenf"
    printf "# Maven Proxy Automatic Session on Profile.\n" >> "$_mavenf"
    printf "# Do not delete or edit this file \n\n" >> "$_mavenf"
    printf 'if [[ -f "%s" ]]; then \n' "$HOME/.proxy" >> "$_mavenf"
    local _mvnOpts=$(__buildMavenOptions)
    printf '    export %s="%s"\n' "MAVEN_OPTS" "$_mvnOpts" >> "$_mavenf"
    printf "fi\n"  >> "$_mavenf"
    chmod +x "$_mavenf"

}

__mavenProxyDisable() {
    if [[ -f "$_mavenf" ]]; then
        rm -f "$_mavenf"
    fi
}

__mavenProxyOn() {
    if [[ -f "$_mavenf" ]]; then
        source $_mavenf
    fi
}

__mavenProxyOff() {
	unset MAVEN_OPTS
}

__buildMavenOptions() {
	local builded="-Dhttp.proxyHost=$PK_PROXY_HOST"
	builded+=" -Dhttp.proxyPort=$PK_PROXY_PORT"
	builded+=" -Dhttps.proxyHost=$PK_PROXY_HOST"
	builded+=" -Dhttps.proxyPort=$PK_PROXY_PORT"
	echo "$builded"
}

#internal command
__mavenCheck() {
	command_exists "mvn" || return 4
	if [[ ! -n "${PK_PROXY_HOST// }" ]]; then
		#finds first variable with proxy settings
		proxyUrl=$(__getFirstProxyVariable)
		__parseProxyURL "$proxyUrl"
		PK_PROXY_HOST="${_pURL[host]}"
		PK_PROXY_PORT="${_pURL[port]:-80}"
	fi
	return 0
}
