# -*- mode: bash -*-
##
## Functions from .shell/functions
####
[[ ${_comps[man]} ]] && compdef pman=man
[[ ${_comps[git]} ]] && compdef diff=git
[[ ${_comps[rclone]} ]] && compdef rclean=rclone
[[ ${_comps[code]} ]] && compdef vcode=code vscode=code || compdef '_directories' vcode vscode
[[ ${_comps[find]} ]] && compdef ifind=find fhere=find ffhere=find
[[ ${_comps[cd]} ]] && compdef cl=cd
[[ ${_comps[less]} ]] && compdef cless=less
[[ ${_comps[nice]} ]] && compdef low=nice
[[ ${_comps[nohup]} ]] && compdef run=nohup

# command [directory]
compdef '_directories' is_git_dir find_virtualenv activate_venv mkgo
#functions no arguments
#compdef _no_args

# functions with few arguments
compdef '_arguments -S "1::length:"' genpwd
compdef '_arguments -S "1::command:"' cmd_exists
compdef "_files -g '*(.)'" numerize
compdef '_arguments -S "1::type a commit message"' dotf-save
compdef '_arguments -S "1::text to search on duck2go:"' duckgo

compdef '_arguments -S "*::command:"' explain
compdef '_files' readlinkf mime-get
compdef '_arguments -S "1::url:_urls"' translate
compdef '_arguments -S "*::mathematical problem:"' calc

# darwin functions
compdef '_arguments -S "1::_files"' zipf
compdef '_pgrep' find-pid
[[ ${_comps[ps]} ]] && compdef my-ps=ps
compdef '_no_args' quit relaunch
compdef '_directories' no-index

# os dependant
if [[ $OS == 'darwin' ]]; then
    #darwin exclusive
    [[ ${_comps[brew]} ]] && compdef reinstall=brew
    compdef '_arguments -S "1::application name:"' bundleid

elif [[ $0S == 'linux' ]]; then
    #linux exclusive
    [[ ${_comps[apt-get]} ]] && compdef reinstall=apt-get
    compdef installed=grep
    compdef '_no_args' apt-unlock apt-reset mkfonts hacker
    compdef '_pgrep' total-procmem
    compdef '_arguments -s "1::hash:"' apt-addkey
fi

# my home/bin definitions

