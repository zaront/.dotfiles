
################
# Config Helpers
################

# source only once
[ -n "$_cfg_sourced" ] && return 0
_cfg_sourced=1


_cfg_config_dir="$DOTFILES/config/$(basename "$DOTFILES_CMD")"

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
# the key format is: [filename]/[section]/[key]
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
# the key format is: [filename]/[section]/[key]
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
get_flag() {
    [ -f "_cfg_config_dir/${1}.flag" ]
}

# Create a flag file and its parent directories if they don't exist
set_flag() {
    mkdir -p "$_cfg_config_dir"
    touch "$_cfg_config_dir/${1}.flag"
}

unset_flag() {
    rm -f "$_cfg_config_dir/${1}.flag"
}



_cfg_s_file="$DOTFILES/config/startup.sh"

get_startup() {
    _cfg_s_key="$1"
    # Fall back to default path if the optional third argument isn't provided
    _cfg_s_target="${2:-$_cfg_s_file}"
    [ -f "$_cfg_s_target" ] || return 1
    
    # Check for the presence of the unique key marker in the file footprint
    awk -v marker="# >>> START: ${_cfg_s_key} >>>" '
        { file_content = file_content $0 "\n" }
        END { exit (index(file_content, marker) ? 0 : 1) }
    ' "$_cfg_s_target"
}

set_startup() {
    _cfg_s_key="$1"
    _cfg_s_block="$2"
    _cfg_s_target="${3:-$_cfg_s_file}"

    # validate
    _cfg_s_dir="${_cfg_s_target%/*}"
    mkdir -p "$_cfg_s_dir"
    touch "$_cfg_s_target"

    # Automatically drop the old block matching this key to allow for updates
    unset_startup "$_cfg_s_key" "$_cfg_s_target"

    # add the startup script wrapped in structured comment blocks with 2 trailing blank lines
    printf '# >>> START: %s >>>\n%s\n# <<< END: %s <<<\n\n\n' "$_cfg_s_key" "$_cfg_s_block" "$_cfg_s_key" >> "$_cfg_s_target"
}

unset_startup() {
    _cfg_s_key="$1"
    _cfg_s_target="${2:-$_cfg_s_file}"

    # validate
    [ -f "$_cfg_s_target" ] || return 0
    
    # remove the startup script
    _cfg_s_tmp="${_cfg_s_target}.tmp.$$.$(date +%s)"
    awk -v key="$_cfg_s_key" '
        # Read the entire file into a single string variable
        { file_content = file_content $0 "\n" }
        
        END {
            # Target the block and the exact 2 trailing blank lines (\n\n) following it
            target = "# >>> START: " key " >>>\n.*\n# <<< END: " key " <<<\n\n\n"
            
            # Delete the matching chunk from the text string
            gsub(target, "", file_content)
            
            # Output the remaining content
            printf "%s", file_content
        }
    ' "$_cfg_s_target" > "$_cfg_s_tmp" && mv "$_cfg_s_tmp" "$_cfg_s_target"
}

get_template() {
    _cfg_s_src_file="$(dirname "$0")/$1.template"
    [ -f "$_cfg_s_src_file" ] || return 1
    
    # Read to global variable
    # The 'x' pattern guarantees trailing blank lines are preserved
    TEMPLATE=$(cat "$_cfg_s_src_file"; printf 'x')
    TEMPLATE="${TEMPLATE%x}"
}
