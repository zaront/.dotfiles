
################
# Config Helpers
################

# source only once
[ -n "$_cfg_sourced" ] && return 0
_cfg_sourced=1

_cfg_config_dir="$DOTFILES/config/${DOTFILES_CMD##*/}" 

_cfg_parse_key() {
    _cfg_key="$1"
    _cfg_val="$2"

    # parse the key
    IFS='/' read -r _cfg_file _cfg_section _cfg_key <<EOF
$_cfg_key
EOF
    _cfg_file="$_cfg_config_dir/${_cfg_file}.ini"
}


# Usage:  get_value "ros/default/distro"
# $1: key  -format: [filename]/[section]/[key]
get_value() {
    _cfg_parse_key "$1" "$2"

    # validate file
    [ -f "$_cfg_file" ] || return 0

    # read value
    awk -F= -v sec="[$_cfg_section]" -v k="$_cfg_key" '
        $0 ~ "^\\[" { in_sec = ($0 == sec || $0 == "["sec"]") }
        in_sec && $1 ~ "^[ \t]*"k"[ \t]*$" {
            val = substr($0, length($1) + 2)
            gsub(/^[ \t]*[\x27\x22]|[\x27\x22][ \t]*$/, "", val)
            print val
            exit
        }
    ' "$_cfg_file"
}


# Usage:  set_value "ros/default/distro" "humble"
# $1: key  -format: [filename]/[section]/[key]
# $2: value
set_value() {
    _cfg_parse_key "$1" "$2"

    # insure the directory and file exist
    _cfg_dir="${_cfg_file%/*}"
    mkdir -p "$_cfg_dir"
    touch "$_cfg_file"

    # copy to temp file
    _cfg_temp="${_cfg_file}.tmp.$$.$(date +%s)"

    # update the temp file and replace
    awk -F= -v sec="[$_cfg_section]" -v k="$_cfg_key" -v v="$_cfg_val" '
        BEGIN { found_sec = 0; found_key = 0 }
        $0 ~ "^[ \t]*\\[" {
            if (found_sec && !found_key) {
                print k "=" v
                found_key = 1
            }
            found_sec = ($0 == sec || $0 == "["sec"]" || $0 ~ "^\\[" substr(sec, 2, length(sec)-2) "\\]")
        }
        found_sec && $1 ~ "^[ \t]*"k"[ \t]*$" {
            print k "=" v
            found_key = 1
            next
        }
        { print $0 }
        END {
            if (!found_sec && !found_key) {
                print ""
                print sec
                print k "=" v
            } else if (found_sec && !found_key) {
                print k "=" v
            }
        }
    ' "$_cfg_file" > "$_cfg_temp" && mv "$_cfg_temp" "$_cfg_file"
}



# Check if a flag file exists
# $1: flag file name
get_flag() {
    if [ -f "$_cfg_config_dir/${1}.flag" ]; then
        return 0  # Success
    else
        return 1  # Failure
    fi
}

# Create a flag file and its parent directories if they don't exist
# $1: flag file name
set_flag() {
    mkdir -p "$_cfg_config_dir"
    touch "$_cfg_config_dir/${1}.flag"
}

# $1: flag file name
unset_flag() {
    rm -f "$_cfg_config_dir/${1}.flag"
}



_cfg_s_dir="$DOTFILES/config/startup.d"

# check if a startup script exists
# $1: key
get_startup() {
    _cfg_s_file="${_cfg_s_dir}/${DOTFILES_CMD##*/}/${1}.sh"
    if [ -f "$_cfg_s_file" ]; then
        return 0  # Success
    else
        return 1  # Failure
    fi
}

# $1: key
# $2|<stdin: startup script block
set_startup() {
    _cfg_s_file="${_cfg_s_dir}/${DOTFILES_CMD##*/}/${1}.sh"
    _cfg_s_block="$2"

    # ensure directory
    mkdir -p "${_cfg_s_file%/*}"
    # create or replace file
    if [ ! -t 0 ]; then # if stdin is piped
        cat > "$_cfg_s_file"
    else
        printf '%s\n' "$_cfg_s_block" > "$_cfg_s_file"
    fi
}

# $1: key
unset_startup() {
    _cfg_s_file="${_cfg_s_dir}/${DOTFILES_CMD##*/}/${1}.sh"

    # remove the startup script
    rm -f "$_cfg_s_file"
}


get_template() {
    _cfg_s_src_file="${0%/*}/$1.template" # template path
    [ -f "$_cfg_s_src_file" ] || return 1
    
    # Read to global variable
    # The 'x' pattern guarantees trailing blank lines are preserved
    TEMPLATE=$(cat "$_cfg_s_src_file"; printf 'x')
    TEMPLATE="${TEMPLATE%x}"
}
