#!/bin/bash

_sublf="$PK_PROFILED/sublime_text"

#supporting cygwin and windows sublime text
if [[ "${ID}" == "CYGWIN" ]]; then
	_subl_c=$(cygpath "${APPDATA}/Sublime Text 3")
else
	_subl_c="$HOME/.config/sublime-text-3"
fi

_subld="${_subl_c}/Packages/User"
_sublf="Preferences.sublime-settings"
_sublff="$_subld/$_sublf"
_sublft="$_subld/Preferences.sublime-settings.tmp"

#
#	Sets the sublime enviroment settings..
#
__sublProxyEnable() {
	__sublCheck || return 4
	local httpProxy=$(__getFirstProxyVariable "HTTP_PROXY")
	local httpsProxy=$(__getFirstProxyVariable "HTTPS_PROXY")

	local a_count=$(cat "$_sublff" | grep -F '"http_proxy": "$httpProxy"' | wc -l)
	[[ "$a_count" -gt 0 ]] && return 0
	local lline=$(tail -n 1 "$_subld/$_sublf")
	if [[ "${lline// }" == "}" ]]; then
		#so remover a ultima linha e adicionar os textos
		cat "$_sublff" | sed -E '/^\s+[,]?\"(http_proxy|https_proxy)\"/d' | head -n -1 > "$_sublft"
		echo "    ,\"http_proxy\": \"$httpProxy\"," >> "$_sublft"
		echo "    \"https_proxy\": \"$httpsProxy\"" >> "$_sublft"
		echo "}" >> "$_sublft"
		cat "$_sublft" > "$_sublff"
		__fixSettings
		rm -f "$_sublft"
	fi
}


__sublProxyDisable() {
	__sublCheck || return 4
	[[ -f "$_subld/$_sublf" ]] || return 4
	local a_count=$(cat "$_sublff" | grep -F '"http_proxy": ' | wc -l)
	local a_counts=$(cat "$_sublff" | grep -F '"https_proxy": ' | wc -l)
	[[ "$a_counts" -eq 0 ]] && [[ "$a_count" -eq 0 ]] && return 0

	# remove this settings
	sed -i -E '/^\s+\"(http_proxy|https_proxy)\"/d' "$_subld/$_sublf"
	__fixSettings
}

__sublProxyOn() {
	:
}

__sublProxyOff() {
	:
}

#internal command
__fixSettings() {
	perl -0777 -i -pe 's/,\n}$/\n}/gis' "$_sublff"
}

__sublCheck() {
	local _subp='/cygdrive/c/Program Files/Sublime Text 3/sublime_text.exe'
	if __isCygwin; then
		[[ -f "$_subp" ]] && return 0 || return 4
	else
		[[ -f "/usr/bin/subl" ]] && return 0 || return 4
	fi
}