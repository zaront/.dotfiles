
################
# Config Helpers
################


_i_config_dir="$DOTFILES/config/$(basename "$DOTFILES_CMD")"

_i_parse_key() {
    _i_key="$1"
    _i_val="$2"

    # parse the key
    IFS='/' read -r _i_file _i_section _i_key <<EOF
$_i_key
EOF
    _i_file="$_i_config_dir/${_i_file}.ini"
}


# Usage:  get_value "ros/default/distro"
# the key format is: [filename]/[section]/[key]
get_value() {
    _i_parse_key "$1" "$2"

    # validate file
    [ -f "$_i_file" ] || return 0

    # read value
    awk -F= -v sec="[$_i_section]" -v k="$_i_key" '
        $0 ~ "^\\[" { in_sec = ($0 == sec || $0 == "["sec"]") }
        in_sec && $1 ~ "^[ \t]*"k"[ \t]*$" {
            val = substr($0, length($1) + 2)
            gsub(/^[ \t]*[\x27\x22]|[\x27\x22][ \t]*$/, "", val)
            print val
            exit
        }
    ' "$_i_file"
}


# Usage:  set_value "ros/default/distro" "humble"
# the key format is: [filename]/[section]/[key]
set_value() {
    _i_parse_key "$1" "$2"

    # insure the directory and file exist
    _i_dir="${_i_file%/*}"
    mkdir -p "$_i_dir"
    touch "$_i_file"

    # copy to temp file
    _i_temp="${_i_file}.tmp.$$.$(date +%s)"

    # update the temp file and replace
    awk -F= -v sec="[$_i_section]" -v k="$_i_key" -v v="$_i_val" '
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
    ' "$_i_file" > "$_i_temp" && mv "$_i_temp" "$_i_file"
}



# Check if a flag file exists
get_flag() {
    [ -f "_i_config_dir/${1}.flag" ]
}

# Create a flag file and its parent directories if they don't exist
set_flag() {
    mkdir -p "$_i_config_dir"
    touch "$_i_config_dir/${1}.flag"
}

unset_flag() {
    rm -f "$_i_config_dir/${1}.flag"
}



_s_file="$DOTFILES/config/startup.sh"

get_startup() {
    _s_key="$1"
    # Fall back to default path if the optional third argument isn't provided
    _s_target="${2:-$_s_file}"
    [ -f "$_s_target" ] || return 1
    
    # Check for the presence of the unique key marker in the file footprint
    awk -v marker="# >>> START: ${_s_key} >>>" '
        { file_content = file_content $0 "\n" }
        END { exit (index(file_content, marker) ? 0 : 1) }
    ' "$_s_target"
}

set_startup() {
    _s_key="$1"
    _s_block="$2"
    _s_target="${3:-$_s_file}"

    # validate
    _s_dir="${_s_target%/*}"
    mkdir -p "$_s_dir"
    touch "$_s_target"

    # Automatically drop the old block matching this key to allow for updates
    unset_startup "$_s_key" "$_s_target"

    # add the startup script wrapped in structured comment blocks with 2 trailing blank lines
    printf '# >>> START: %s >>>\n%s\n# <<< END: %s <<<\n\n\n' "$_s_key" "$_s_block" "$_s_key" >> "$_s_target"
}

unset_startup() {
    _s_key="$1"
    _s_target="${2:-$_s_file}"

    # validate
    [ -f "$_s_target" ] || return 0
    
    # remove the startup script
    _s_tmp="${_s_target}.tmp.$$.$(date +%s)"
    awk -v key="$_s_key" '
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
    ' "$_s_target" > "$_s_tmp" && mv "$_s_tmp" "$_s_target"
}

get_template() {
    _s_src_file="$(dirname "$0")/$1.template"
    [ -f "$_s_src_file" ] || return 1
    
    # Read to global variable
    # The 'x' pattern guarantees trailing blank lines are preserved
    TEMPLATE=$(cat "$_s_src_file"; printf 'x')
    TEMPLATE="${TEMPLATE%x}"
}
