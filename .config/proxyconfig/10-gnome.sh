#!/bin/bash

#
#	Sets the gnome enviroment settings..
#
__gnomeProxyEnable() {
	! __hasGnome && return 4
	gsettings set org.gnome.system.proxy mode "$PK_MODE"
	gsettings set org.gnome.system.proxy autoconfig-url "$PK_AUTOPROXY"
}

__gnomeProxyDisable() {
	! __hasGnome && return 4
  	gsettings set org.gnome.system.proxy mode 'none'
  	gsettings set org.gnome.system.proxy autoconfig-url ''
}

#internal command
__hasGnome() {
	[[ -z "$DISPLAY" ]] && return 4
	! command_exists "gsettings" && return 4
	return 0
}