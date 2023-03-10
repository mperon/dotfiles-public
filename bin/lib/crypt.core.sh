#!/usr/bin/env bash
#vim: ts=4 sw=4 et ft=sh

BASH_FN_CRYPT=1

[[ -z "$BASH_FN_SH" ]] && source "${BASH_SOURCE%/*}/bashFn.sh"
[[ -z "$PGETOPT_SH" ]] && source "${BASH_SOURCE%/*}/pgetopt.sh"

E_PASSW=

a_files=() a_dry= a_no_recursive= a_dest= a_output= a_passwd= a_key=
a_progress= a_decrypt=$CRYPT_CORE_DECRYPT a_line= a_total= a_default_algo=
a_dir=$PWD a_first_run=

[[ -f $HOMEBREW_PREFIX/opt/openssl/bin/openssl ]] && BK_OPENSSL=$HOMEBREW_PREFIX/opt/openssl/bin/openssl \
    || BK_OPENSSL=$(command -v openssl)

__main() {
    local a_file=
    # force set of destdir
    [[ -z "$a_dest" ]] && a_dest="$PWD"
    a_dest=$(_readlinkf "$a_dest")

    # first check password, if not, ask
    if [[ -z "$a_passwd" ]] && [[ -z "$a_key" ]]; then
        if [[ -n "$a_decrypt" ]]; then
            __askPassword && a_passwd="$E_PASSW"    
        else
            __confirmPasswordTries && a_passwd="$E_PASSW"
        fi
        if [[ -z "$a_passwd" ]]; then
            __error "You did not provide a password or give an invalid one!"
            return 4
        fi
    fi

    for a_file in "${a_files[@]}"; do

        if [[ -f "${a_file}" ]]; then
            # process as a file
            __process_file "${a_file}"
        else
            # process as a folder
            __search "${a_file}" __execute
        fi

    done
}

__process_file() {
    local input="${1}"
    local a_name=$(basename "${input}")
    local tdir=$(dirname "${input}")

    #first go to dir
    pushd "${tdir}" > /dev/null

    __execute "./${a_name}"

    popd > /dev/null
}

__search() {
    local tmpf=$(mktemp)
    local tdir="${1}"
    local e_args=() e_neg= e_ext=gpg

    # check if directory exsits
    [[ ! -d "${tdir}" ]] && __error "Directory: ${tdir} doesnt exists!!" && return 4

    #check limit of find
    [[ -n "${a_no_recursive}" ]] && e_args+=("-maxdepth" "1")

    #first go to dir
    pushd "${tdir}" > /dev/null

    #search all files and make some action
    [[ -z "$a_decrypt" ]] && e_neg="!"
    [[ -n "$a_key" ]] && e_ext='enc'
    find . "${e_args[@]}" -type f $e_neg -name "*.${e_ext}" | sort > $tmpf

    read TOTAL_F n <<< $(wc -l $tmpf)
    echo "Total Files: $TOTAL_F"
    COUNT=0
    a_line=0
    a_total=$TOTAL_F
    while IFS= read -r line ;do
        ((COUNT++))
        a_line=$COUNT
        [[ -n "${a_progress}" ]] && ProgressBar $COUNT $TOTAL_F "| $COUNT of $TOTAL_F    "
        $2 "$line"

    done < $tmpf

    popd > /dev/null

    rm -f $tmpf
}

__execute() {
    local input="${1}"
    local output= outdir= tdname= e_args=() algo=
    local e_ext= e_name="Decrypting"
    if [[ -z "$a_decrypt" ]]; then
        e_ext=".gpg"
        [[ -n "$a_key" ]] && e_ext=".enc"
    fi
    if [[ -n "${a_output}" ]]; then
        output="${a_output}"
    else
        if [[ -n "$a_dest" ]]; then
            output="${a_dest/%\//}/${input/#\.\//}${e_ext}"
        else
            output="${input}${e_ext}"
        fi
    fi
    if [[ -n "$a_key" ]]; then
        # use key here
        # __error "KEY crypto not working at the moment!!"
        # return 4
        __key_process "$input" "$output"
    else
        __password_process "$input" "$output"
    fi
}

__password_process() {
    local input="${1}" output="$2"
    local outdir= tdname= e_args=() algo=
    local e_ext= e_name="Decrypting"
    [[ -z "$a_decrypt" ]] && e_ext=".gpg" e_name="Encripting"

    [[ -z "$a_default_algo" ]] && algo="--cipher-algo AES256"
    if [[ -n "$a_decrypt" ]]; then
        output="${output%${e_ext}}"
        e_args+=("--decrypt")
    else
        e_args+=("--symmetric")
    fi
    outdir=$(dirname "$output")
    [[ -z "${a_dry}" ]] && [[ ! -d "$outdir" ]] && mkdir -p "$outdir"

    if [[ -n "${a_dry}" ]]; then
        echo "($a_line/$a_total) ${e_name}: ${input} ..: (--dry-run is set)"
        __debug "gpg --batch $algo --no-tty --yes --passphrase-fd 0 -o '$output' ${e_args[@]} '$input'"
    else
        [[ -n "${a_progress}" ]] || __debug "($a_line/$a_total) ${e_name}: ${input}"
        __debug "gpg --batch $algo --no-tty --yes --passphrase-fd 0 -o '$output' ${e_args[@]} '$input'"
        echo "$a_passwd" | gpg --batch $algo --no-tty --yes --passphrase-fd 0 -o "$output" "${e_args[@]}" "$input"
    fi
}

__check_private_key() {
    # checking private key is valid
    BK_HEAD=$(cat $a_key | head -1)
    if [[ "$BK_HEAD" != "-----BEGIN RSA PRIVATE KEY-----" ]]; then
        #need conversion
        echo "You private key is on invalid format. we are gonna to convert!"
        cp "$BK_PRIV_KEY" "${BK_PRIV_KEY}.bak"
        ssh-keygen -p -m PEM -f $a_key
    fi
}

__key_process() {
    local input="${1}" output="$2"
    local inputf=$(_readlinkf "$input")
    local tmpd2=$(mktemp -d)
    trap "rm -rf $tmpd2" EXIT
    cd "$tmpd2"
    outdir=$(dirname "$output")
    [[ -z "${a_dry}" ]] && [[ ! -d "$outdir" ]] && mkdir -p "$outdir"

    if [[ -n "$a_decrypt" ]]; then
        a_key="${a_key%.pub}"
        [[ -z "$a_first_run" ]] && __check_private_key
    else
        if [[ ! "${a_key: -4}" == ".pem" ]]; then
            ssh-keygen -f "$a_key" -e -m pem > $tmpd2/pub.pem
            a_original_key=$a_key
            a_key=$tmpd2/pub.pem
        fi
    fi

    if [[ -n "$a_decrypt" ]]; then
        #decrypt
        tar --overwrite -xf "$inputf"
        if [[ ! -f "key.enc" ]] || [[ ! -f "content.enc" ]]; then
            __error "Invalid archive! Do you use keys to encript?"
            return 4
        fi
        openssl pkeyutl -decrypt -inkey $a_key \
            -in $tmpd2/key.enc -out $tmpd2/key
        openssl enc -aes-256-cbc -d -a -md sha512 -pbkdf2 -iter 1000000 -salt \
            -in "content.enc" -out "${output%.enc}" -pass file:$tmpd2/key
    else
        #encript
        openssl rand -base64 256 > $tmpd2/key
        openssl enc -aes-256-cbc -a -md sha512 -pbkdf2 -iter 1000000 -salt \
            -in "$inputf" -out "content.enc" -pass file:$tmpd2/key
        openssl pkeyutl -encrypt -inkey $a_key \
            -pubin -in $tmpd2/key -out $tmpd2/key.enc
        tar -cf "$output" "content.enc" "key.enc"
    fi
}

__sanitize() {
    #do somenthing here for not appearing on history
    :
}

########################################
#                                      #
#      Command Line Arguments Parser   #
#                                      #
########################################
__parse() {
    local OPTIONS=eDp:k:o:d:bRASl:v
    local LONGOPTIONS=encrypt,decrypt,password:,key:,output:,dest:,progress,no-recursive,default-algo,dry-run,log:,debug

    local argv=$(pgetopt -o $OPTIONS -l $LONGOPTIONS -n "$0" -- "$@")
    [[ $? -ne 0 ]] && exit 2
    eval set -- "$argv"
    # Debug arguments
    __debug "" "Parsed Getopts: $*"

    # defaults to encrypt or decrypt
    [[ "${0##*/}" == "decrypt" ]] && a_decrypt="y" || a_decrypt=

    # now enjoy the options in order and nicely split until we see --
    while true; do
        case "$1" in
            -e|--encrypt)
                a_decrypt=; shift;;
            -D|--decrypt)
                a_decrypt="y"; shift;;
            -p|--password)
                a_passwd="$2"; shift 2;;
            -k|--key)
                a_key="$2"; shift 2;;
            -o|--output)
                a_output="$2"; shift 2;;
            -d|--dest)
                a_dest="$2"; shift 2;;
            -b|--progress)
                a_progress="y"; shift;;
            -R|--no-recursive)
                a_no_recursive="y"; shift;;
            -A|--default-algo)
                a_default_algo="y"; shift;;
            -S|--dry-run)
                a_dry="y"; shift;;
            -l|--log)
                _LOG="$2"; shift 2;;
            -v|--debug)
                _DEBUG=y; shift;;
            --)
                shift; a_files=( "$@" ); break;;
            h  ) __usage;;
            \? ) __error "Unknown option: -$OPTARG" >&2; __usage;;
            :  ) __error "Missing option argument for -$OPTARG" >&2; __usage;;
            *  ) __error "Unimplemented option: -$OPTARG" >&2; __usage;;
        esac
    done

    # validate input parameters
    [[ "${#a_files[@]}" -eq 0 ]] \
        && __error "You must provide an input [file or folder]" \
        && __usage

    [[ "${#a_files[@]}" -gt 1 ]] && [[ -n "$a_output" ]] \
        && __error "You cannot use -o|--output with folder input or multiple files.." \
        && __usage

    # validates key input
    if [[ -n "${a_key}" ]]; then
        if [[ "$a_key" = "rsa" ]]; then
            a_key=$HOME/.ssh/id_rsa.pub
        fi
        [[ ! -f $a_key ]]\
            && __error "The key supplied is invalid or inexistent!.." \
            && __usage
    fi

    #checking all files if they exists..
    local a_file=
    for a_file in "${a_files[@]}"; do

        [[ ! -f "${a_file}" ]] && [[ ! -d "${a_file}" ]] \
            && __error "${a_file} is not a file or a directory!" \
            && __usage
    done
}


__usage() {
    cat <<HELP_USAGE
    $0
       [-e|-D] [-RSl] [-o output] [-d dest_dir] file_or_folder [file_or_folder] ...

    -e|--encrypt        Encrypt
    -D|--decrypt        Decrypt
    -d|--dest [folder]  Folder where encripted files will be saved (same structrure as origin)
    -p|--password       Use this password (not safe, please prefer interactively)
    -k|--key [file]     Use this public key to encrypt.
    -o|--output         Output file name (only works if file_or_folder is a File!)
    -b|--progress       Show progressbar
    -R|--non-recursive  Specify that input directory is non recursive.
    -A|--default-algo   Encrypt/Decrypt as Apple Default
    -S|--dry-run        Only show what is gonna happen, dont make the encription
    -l|--log [file]     Specify log file (default Off)
    -v|--debug          Show Debug information
    -h|--help           Show help
HELP_USAGE
    exit 4
}

if [[ -n "$_DEBUG" ]]; then __print "Parsing command line arguments.."; fi

__parse "$@"

__debug "Command Line Arguments: "
__debug "   [files]:  ${a_files[@]}"
__debug " --decrypt:  $a_decrypt"
__debug "--password:  $a_dest"
__debug "    --dest:  $a_dest"
__debug "  --output:  $a_output"
__debug " --dry-run:  $a_dry"
__debug "     --log:  $_LOG"
__debug "   --debug:  $_DEBUG"
__debug ""
__debug "Running main code: "
__main "$@"

__sanitize

exit $?
