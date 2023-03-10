#!/usr/bin/env bash
#vim: ts=4 sw=4 et ft=sh

[[ "${BASH_SOURCE-}" == "$0" ]] && echo "You must source this script: \$ source $BASH_SOURCE" >&2 && exit 33

SEARCH_SH=1

[[ -z "$BASH_FN_SH" ]] && source "${BASH_SOURCE%/*}/bashFn.sh"


# _search folder command (search args)
#			 $1     $2       $3-*
_search() {
    _search_int "" "$@"
}

# _search folder command (search args)
#			 $1     $2       $3-*
_search_pbar() {
    _search_int ":pbar:" "$@"
}

# _search_formats folder command  formats (search args)
#	                $1     $2       $3        $4-*
_search_formats() {
    _search_formats_int "" "$@"
}

# _search_formats_pbar folder command  formats (search args)
#	                     $1     $2       $3        $4-*
_search_formats_pbar() {
    _search_formats_int ":pbar:" "$@"
}

# _search_formats_int options folder command extensions (search args)
#			             $1     $2     $3       $4          $5-*
_search_formats_int() {
    local a_opts="$1" a_dir="$2" a_cmd="$3"
    local a_formats=$(join_by '|' $4)
    shift 4
    _search_int "$a_opts" "$a_dir" "$a_cmd" -maxdepth 1 -regextype "posix-extended" -iregex "^.*\.($a_formats)\$" "$@"
}

# _search_int options folder command (search args)
#			    $1      $2     $3       $4-*
_search_int() {
    local a_opts="$1" a_dir="$2" a_cmd="$3" a_line=
    local tmp_file= a_total= a_count=
    shift 3

    [[ ! -d "$a_dir" ]] && __error "directory '$a_dir' doesnt exists!!" && return 4

    # create temp file for processing
    tmp_file=$(mktemp)
    trap "rm -f $tmp_file" EXIT

    # search for files
    find "$a_dir" "$@" -print > $tmp_file
    if [[ $? -ne 0 ]]; then
        __error "Error on search!"
        __error "Command:"
        __error find "$a_dir" "$@" -print
        return 4
    fi

    #count lines
    read a_total n <<< $(wc -l $tmp_file)

    if [[ "$a_opts" == *:pbar:* ]]; then
        __info "Total Files: $a_total"
    fi
    a_count=0 a_line=0
    while IFS= read -r a_line ;do
        ((a_count++))
        [[ "$a_opts" == *:pbar:* ]] && ProgressBar $a_count $a_total "| $a_count of $a_total    "
        $a_cmd "$a_line" "$a_count" "$a_total"
    done < $tmp_file
    [[ "$a_opts" == *:pbar:* ]] && echo ""
    return 0
}
