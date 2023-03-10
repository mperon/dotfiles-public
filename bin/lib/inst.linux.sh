INST_LINUX_SH=1

[[ "${BASH_SOURCE-}" == "$0" ]] \
    && echo "You must source this script: \$ source $BASH_SOURCE" >&2 \
    && exit 33

########################################
#    APT-GET functions                 #
########################################
function check_apt_transport() {
    if [[ ! -f /usr/lib/apt/methods/https ]]; then
        # need install
        repo_inst apt-transport-https
    fi
}

function repo_add() {
    local install=y
    local repo="$1" repoDir="/etc/apt/sources.list.d" repoPath=
    iprint "$repo" "[$repo] Adding Repository ..."
    if [[ "${repo:0:3}" == "ppa" ]]; then
        repoPath=$(repoNameToPath "$repo")
        [[ -z "${repoPath// }" ]] && istatus 4 && return 4
        [[ -f "$repoDir/$repoPath" ]] && install=n && istatus 0
    fi
    #add only if dont exists
    if [[ "${install}" == "y" ]]; then
        sudo add-apt-repository "$repo" -y || istatus 4
        return $?
    fi
    return 0
}

function repo_webadd() {
    local name="$1" ret=
    local arquivo="/etc/apt/sources.list.d/$name.list"
    local url="$2"
    if [ ! -f "$arquivo" ]; then
        wget -qO - "$url" | sudo tee "$arquivo" > /dev/null
        ret="${PIPESTATUS[0]}"
        APT_NEED_UPD=y
        return $ret
    fi
    return 0
}

# repo_manualadd "name" "text"
function repo_manualadd() {
    local name="$1"
    local content="$2"
    local arquivo="/etc/apt/sources.list.d/$name.list"
    if [ ! -f "$arquivo" ]; then
        echo "$content" | sudo tee "$arquivo" > /dev/null
        [[ "$?" -eq 0 ]] && APT_NEED_UPD=y
    fi
    return 0
}

function repo_upd() {
    [[ "$APT_NEED_UPD" == "y" ]] && sudo apt-get update -qq -y "$@"
    APT_NEED_UPD=n
    return $?
}

function repo_fix() {
    sudo apt-get -y --fix-broken --fix-missing install
    sudo dpkg --configure -a
}

#repo_key [url]
function repo_key() {
    wget  --no-check-certificate -qO - "$1" | sudo apt-key add -
}

#repo_key_asc [name] [url]
function repo_key_trusted() {
    [[ -f /etc/apt/trusted.gpg.d/${1}.gpg ]] && return 0
    wget --no-check-certificate -qO - "$2" | gpg --dearmor | sudo tee "/etc/apt/trusted.gpg.d/${1}.gpg" > /dev/null
}

#repo_key_asc [name] [url]
function repo_key_asc() {
    repo_key_trusted "$@"
}

function repo_keyserver() {
    local server="$1"
    local key="$2"
    if [[ -z "$2" ]]; then
        server="hkp://keyserver.ubuntu.com:80"
        key="$1"
    fi
    sudo apt-key adv --keyserver "$server" --recv-keys "$key"
}

#install deb files manually
#   repo_inst_manual name [urls]
function repo_inst_manual() {
    local name="$1"
    local tmpd="/tmp/inst/$name"
    if [[ ! -d "$tmpd" ]]; then
        mkdir -p "$tmpd"
    fi
    local arg_count="$#"
    for ((i=2;i<=$arg_count;i++)); do
        fname="${name}_${i}.deb"

        if [[ ! -f "$tmpd/$fname" ]]; then
            arg="${!i}"
            wget --no-check-certificate -O "$tmpd/$fname" "$arg"
        fi
    done
    #all files was downloaded, install all
    sudo dpkg -i $tmpd/*.deb \
        && rm -rf "$tmpd"
    repo_fix
}

#repo_down_to [url] [to] [root]

function repo_down_to() {
    local from="$1"
    local to="$2"
    local useSudo="$3"
    if [[ -z "$3" ]]; then
        wget --no-check-certificate -O "$to" "$from"
    else
        sudo wget --no-check-certificate -O "$to" "$from"
    fi
}


#repo_webadd [name] [url]
# [name] name of repository
# [url] url of repository

function repo_autoremove() {
    sudo apt-get autoremove -y "$@"
    return $?
}

function repo_upgrade() {
    sudo apt-get dist-upgrade "$@"
    return $?
}

function repo_inst() {
    local ret=0 _status=
    local args=()
    local parms=()
    local arg_count="$#"
    for ((i=1;i<=$arg_count;i++)); do
        local arg="${!i}"
        if [[ "$arg" == "-"* ]]; then
            parms+=($arg)
        else
            args+=($arg)
        fi
    done
    for v in "${args[@]}"
    do
        iprint "$v" "[$v] Installing ..."
        sudo NEEDRESTART_SUSPEND=y NEEDRESTART_MODE=a DEBIAN_FRONTEND=noninteractive \
            apt-get -qq -y -f -m "${parms[@]}" install "$v"
        _status="$?"; [[ $_status -ne 0 ]] && ret=1
        istatus "$_status"
    done
    return $ret
}

function repo_remove() {
    local ret=0 _status=
    local args=()
    local parms=()
    local arg_count="$#"
    for ((i=1;i<=$arg_count;i++)); do
        local arg="${!i}"
        if [[ "$arg" == "-"* ]]; then
            parms+=($arg)
        else
            args+=($arg)
        fi
    done
    for v in "${args[@]}"
    do
        iprint "$v" "[$v] Removing ..."
        sudo apt-get -y "${parms[@]}" remove "$v"
        _status="$?"; [[ $_status -ne 0 ]] && ret=1
        istatus "$_status"
    done
    return $ret
}

function repo_purge() {
    local ret=0 _status=
    local args=()
    local parms=()
    local arg_count="$#"
    for ((i=1;i<=$arg_count;i++)); do
        local arg="${!i}"
        if [[ "$arg" == "-"* ]]; then
            parms+=($arg)
        else
            args+=($arg)
        fi
    done
    for v in "${args[@]}"
    do
        iprint "$v" "[$v] Purging ..."
        sudo apt-get --yes "${parms[@]}" purge "$v"
        _status="$?"; [[ $_status -ne 0 ]] && ret=1
        istatus "$_status"
    done
    return $ret
}

########################################
#    UTILITY functions                 #
########################################

# check if equipment is notebook or not
#   isLaptop
function isLaptop() {
    local bateria=""
    for f in /sys/class/power_supply/BAT*/status; do bateria=$f; done
    if [[ -f "$bateria" ]]; then
        return 0
    fi
    return 1
}

# check if is native linux or wsl
function isWSL() {
    if grep -qi microsoft /proc/version; then
        return 0
    else
        return 1
    fi
}

# Get total memory of computer in bytes
#   getMemorySize
function getMemorySize() {
    awk '/^MemTotal:/{print $2}' /proc/meminfo
}

# Check if memory is bigger than
#   memoryBigThan "sizeInBytes"
function memoryBigThan() {
    local _mem=$(getMemorySize)
    if [[ "$_mem" -gt "$1" ]]; then
        return 0
    fi
    return 1
}

# From repository name, gets installed path
#   repoNameToPath "repo"
function repoNameToPath() {
    local _repo="$1" _repoStr= _repoId= _repoUser= _repoFile=
    if [[ "${_repo:0:3}" == "ppa" ]]; then
        _repoStr="${_repo:4}"
        _repoId="${_repoStr##*\/}"
        _repoUser="${_repoStr%\/*}"
        _repoUser="${_repoUser//./_}"
        if [[ -n "${_repoId// }" ]] && [[ -n "${_repoUser// }" ]]; then
            _repoFile="${_repoUser}-${ID}-${_repoId}-${UBUNTU_CODENAME}.list"
            echo "$_repoFile"
            return 0
        fi
    fi
    return 4
}

########################################
#   PRINT functions                    #
########################################

#prints colorfull message
#   inst_print "package" "message"
#   inst_print "message"
function inst_print() {
    iprint "$@"
}

#prints colorfull message
#   iprint "package" "message"
#   iprint "message"
function iprint() {
    if [[ "$#" -gt 1 ]]; then
        I_PACK="$1"
        shift
        I_TEXT="$*"
    fi
    echo -e "${I_BLUE}${I_BOLD}${I_TEXT}${I_NORMAL}"
}

#show status messages
#   istatus statuscode
function istatus() {
    local logm=
    if [[ "$1" -eq 0 ]]; then
        iok
        logm="[SUCCESS]: $I_PACK was instaled"
    else
        ifail
        logm=" [FAILED]: $I_PACK was not installed"
    fi
    _log "$logm"
}

#prints OK message
#   iok "message"
function iok() {
    L_T_SIZE=$(expr length "Done! $I_TEXT")
    C_COL=$(expr $I_COL - $L_T_SIZE)
    printf "${I_GREEN}%s%*s${I_NORMAL}\n" "OK: $I_TEXT" $C_COL " [OK]  "
}

#prints FAIL message
#   ifail "message"
function ifail() {
    L_T_SIZE=$(expr length "Done! $I_TEXT")
    C_COL=$(expr $I_COL - $L_T_SIZE)
    printf "${I_RED}%s%*s${I_NORMAL}\n" "Ups: $I_TEXT" $C_COL "[FAIL] "
}

# Makes log from message
#   _log "content"
function _log() {
    if [[ -n "$LOG_TO" ]]; then
        local dt=$(date '+%y-%m-%d %H:%M:%S')
        echo "$dt $@" >> $LOG_TO
    fi
}
