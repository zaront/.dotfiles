# common helper functions for dotfiles


##############
# Sub Commands
##############


# Pure POSIX compliant meta-tag options parser.
# Works in any standard 'sh' shell environment.

_pmt_render_help() {
    _pmt_file_target="$1"
    _pmt_header_data="$2"
    _pmt_base_name=$(basename "$_pmt_file_target" .sh)
    
    printf -- "Usage: %s" "$_pmt_base_name"

    echo "$_pmt_header_data" | grep "@SWITCH:" | while read -r _pmt_line; do
        _pmt_raw=$(echo "$_pmt_line" | sed 's/.*@SWITCH: //' | cut -d, -f1)
        case "$_pmt_raw" in
            ??*) printf -- " [--%s]" "$_pmt_raw" ;;
            *)   printf -- " [-%s]" "$_pmt_raw" ;;
        esac
    done
    
    echo "$_pmt_header_data" | grep "@OPTION:" | while read -r _pmt_line; do
        _pmt_clean=$(echo "$_pmt_line" | sed 's/.*@OPTION: //')
        _pmt_raw=$(echo "$_pmt_clean" | cut -d, -f1)
        case "$_pmt_clean" in
            *,*,*,*) _pmt_var_name=$(echo "$_pmt_clean" | cut -d, -f2) ;;
            *)       _pmt_var_name="value" ;;
        esac
        case "$_pmt_line" in *,required*) _pmt_req="required" ;; *) _pmt_req="optional" ;; esac
        case "$_pmt_raw" in ??*) _pmt_flag="--$_pmt_raw" ;; *) _pmt_flag="-$_pmt_raw" ;; esac

        if [ "$_pmt_req" = "required" ]; then
            printf -- " %s <%s>" "$_pmt_flag" "$_pmt_var_name"
        else
            printf -- " [%s <%s>]" "$_pmt_flag" "$_pmt_var_name"
        fi
    done

    echo "$_pmt_header_data" | grep "@PARAM:" | while read -r _pmt_line; do
        _pmt_clean=$(echo "$_pmt_line" | sed 's/.*@PARAM: //')
        _pmt_param_name=$(echo "$_pmt_clean" | cut -d, -f1)
        case "$_pmt_line" in *,required*) _pmt_req="required" ;; *) _pmt_req="optional" ;; esac
        if [ "$_pmt_req" = "required" ]; then
            printf -- " <%s>" "$_pmt_param_name"
        else
            printf -- " [<%s>]" "$_pmt_param_name"
        fi
    done

    printf -- "\n\nDescription:\n"
    _pmt_desc=$(echo "$_pmt_header_data" | grep "@META_DESC" | sed 's/.*@META_DESC: //')
    if [ -z "$_pmt_desc" ]; then
        _pmt_desc=$(echo "$_pmt_header_data" | grep "# *desc:" | sed 's/^# *desc: *//')
    fi
    printf -- "  %s\n" "$_pmt_desc"

    if echo "$_pmt_header_data" | grep -E -q "@SWITCH:|@OPTION:|@PARAM:"; then
        printf -- "\nOptions & Parameters:\n"
        echo "$_pmt_header_data" | grep -E "@SWITCH:|@OPTION:|@PARAM:" | while read -r _pmt_line; do
            case "$_pmt_line" in
                *@PARAM:*)
                    _pmt_clean_line=$(echo "$_pmt_line" | sed 's/.*@PARAM: //')
                    _pmt_p_name=$(echo "$_pmt_clean_line" | cut -d, -f1)
                    _pmt_p_desc=$(echo "$_pmt_clean_line" | cut -d, -f2)
                    case "$_pmt_line" in *,required*) _pmt_p_req="required" ;; *) _pmt_p_req="optional" ;; esac
                    _pmt_col1=$(printf -- "<%s>" "$_pmt_p_name")
                    if [ "$_pmt_p_req" = "required" ]; then
                        printf -- "  %-25s %s (**required)\n" "$_pmt_col1" "$_pmt_p_desc"
                    else
                        printf -- "  %-25s %s\n" "$_pmt_col1" "$_pmt_p_desc"
                    fi
                    ;;
                *)
                    _pmt_tag_type="SWITCH"
                    case "$_pmt_line" in *@OPTION:*) _pmt_tag_type="OPTION" ;; esac
                    _pmt_clean_line=$(echo "$_pmt_line" | sed "s/.*@\($_pmt_tag_type\): //")
                    _pmt_raw=$(echo "$_pmt_clean_line" | cut -d, -f1)
                    case "$_pmt_line" in *,required*) _pmt_req="required" ;; *) _pmt_req="optional" ;; esac
                    case "$_pmt_clean_line" in
                        *,*,*,*) 
                            _pmt_long=$(echo "$_pmt_clean_line" | cut -d, -f2)
                            _pmt_desc=$(echo "$_pmt_clean_line" | cut -d, -f3)
                            _pmt_col1=$(printf -- "-%s, --%s" "$_pmt_raw" "$_pmt_long")
                            ;;
                        *)
                            _pmt_desc=$(echo "$_pmt_clean_line" | cut -d, -f2)
                            case "$_pmt_raw" in
                                ??*) _pmt_col1=$(printf -- "--%s" "$_pmt_raw") ;;
                                *)   _pmt_col1=$(printf -- "-%s" "$_pmt_raw") ;;
                            esac
                            ;;
                    esac
                    if [ "$_pmt_req" = "required" ]; then
                        printf -- "  %-25s %s (**required)\n" "$_pmt_col1" "$_pmt_desc"
                    else
                        printf -- "  %-25s %s\n" "$_pmt_col1" "$_pmt_desc"
                    fi
                    ;;
            esac
        done
    fi
}

parse_meta_tags() {
    _pmt_target_file="$1"
    shift 
    
    _pmt_header=$(sed -n '/^#/p; /^[^#]/q' "$_pmt_target_file")
    echo "$_pmt_header" | grep "@META" >/dev/null 2>&1 || return 0

    # Intercept help requests right away before normal argument evaluation
    for _pmt_arg in "$@"; do
        if [ "$_pmt_arg" = "-h" ] || [ "$_pmt_arg" = "--help" ]; then
            _pmt_render_help "$_pmt_target_file" "$_pmt_header"
            exit 0
        fi
    done

    # CLI argument processing loop
    _pmt_param_count=0
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -*)
                _pmt_clean_arg=$(echo "$1" | sed 's/^-*//')
                _pmt_match_switch=$(echo "$_pmt_header" | grep "@SWITCH: " | grep -E ",$_pmt_clean_arg,|^# @SWITCH: $_pmt_clean_arg,")
                _pmt_match_option=$(echo "$_pmt_header" | grep "@OPTION: " | grep -E ",$_pmt_clean_arg,|^# @OPTION: $_pmt_clean_arg,")
                if [ -n "$_pmt_match_switch" ]; then
                    _pmt_var_name=$(echo "$_pmt_match_switch" | sed 's/.*@SWITCH: //' | cut -d, -f2)
                    eval "$_pmt_var_name=true"
                elif [ -n "$_pmt_match_option" ]; then
                    _pmt_var_name=$(echo "$_pmt_match_option" | sed 's/.*@OPTION: //' | cut -d, -f2)
                    if [ -z "$2" ] || case "$2" in -*) true ;; *) false ;; esac; then
                        printf -- "Error: Option --%s requires a matching value.\n" "$_pmt_clean_arg" >&2
                        exit 1
                    fi
                    eval "$_pmt_var_name=\"\$2\""
                    shift
                else
                    printf -- "Error: Unknown option '%s'. Use --help for usage.\n" "$1" >&2
                    exit 1
                fi
                ;;
            *)
                _pmt_param_count=$((_pmt_param_count + 1))
                _pmt_param_match=$(echo "$_pmt_header" | grep "@PARAM:" | sed -n "${_pmt_param_count}p")
                if [ -n "$_pmt_param_match" ]; then
                    _pmt_param_name=$(echo "$_pmt_param_match" | sed 's/.*@PARAM: //' | cut -d, -f1)
                    eval "$_pmt_param_name=\"\$1\""
                else
                    printf -- "Error: Unexpected argument '%s'.\n" "$1" >&2
                    exit 1
                fi
                ;;
        esac
        shift
    done

    # Validation pipelines
    _pmt_validation_failed=false
    echo "$_pmt_header" | grep "@OPTION:" | while read -r _pmt_line; do
        case "$_pmt_line" in *,required*) _pmt_requirement="required" ;; *) _pmt_requirement="optional" ;; esac
        if [ "$_pmt_requirement" = "required" ] ; then
            _pmt_clean_line=$(echo "$_pmt_line" | sed 's/.*@OPTION: //')
            case "$_pmt_clean_line" in
                *,*,*,*) _pmt_var_name=$(echo "$_pmt_clean_line" | cut -d, -f2) ;;
                *)       _pmt_var_name=$(echo "$_pmt_clean_line" | cut -d, -f1) ;;
            esac
            eval "_pmt_current_val=\"\$$_pmt_var_name\""
            if [ -z "$_pmt_current_val" ]; then
                printf -- "Error: Mandatory option value mapping for '%s' is missing.\n" "$_pmt_var_name" >&2
                exit 1 
            fi
        fi
    done || _pmt_validation_failed=true

    echo "$_pmt_header" | grep "@PARAM:" | while read -r _pmt_line; do
        case "$_pmt_line" in *,required*) _pmt_requirement="required" ;; *) _pmt_requirement="optional" ;; esac
        if [ "$_pmt_requirement" = "required" ]; then
            _pmt_clean_line=$(echo "$_pmt_line" | sed 's/.*@PARAM: //')
            _pmt_param_name=$(echo "$_pmt_clean_line" | cut -d, -f1)
            eval "_pmt_current_val=\"\$$_pmt_param_name\""
            if [ -z "$_pmt_current_val" ]; then
                printf -- "Error: Mandatory parameter <%s> is missing.\n" "$_pmt_param_name" >&2
                exit 1
            fi
        fi
    done || _pmt_validation_failed=true

    if [ "$_pmt_validation_failed" = true ]; then
        exit 1
    fi
}


# Pure POSIX compliant subcommand routing engine.
# Works in any standard 'sh' shell environment.

_pmt_render_commands_help() {
    _pmt_file_target="$1"
    _pmt_base_dir=$(dirname "$_pmt_file_target")
    _pmt_wrapper_name=$(basename "$_pmt_file_target")
    _pmt_clean_name="${_pmt_wrapper_name%.sh}"
    _pmt_cmds_dir="$_pmt_base_dir/${_pmt_clean_name}_cmds"

    _pmt_main_desc=$(sed -n "s/^# *desc: *//p" "$_pmt_file_target" 2>/dev/null)
    if [ -n "$_pmt_main_desc" ]; then
        printf "%s\n\n" "$_pmt_main_desc"
    fi

    printf "Usage: %s [command] [arguments...]\n\n" "$_pmt_wrapper_name"
    printf "Available commands:\n"

    if [ -d "$_pmt_cmds_dir" ]; then
        for _pmt_file in "$_pmt_cmds_dir"/*.sh; do
            if [ -f "$_pmt_file" ]; then
                _pmt_full_name="${_pmt_file##*/}"
                _pmt_cmd_name="${_pmt_full_name%.sh}"
                _pmt_desc=$(sed -n "s/^# *desc: *//p" "$_pmt_file" 2>/dev/null)
                
                if [ -z "$_pmt_desc" ]; then
                    _pmt_desc=$(sed -n "s/.*@META_DESC: //p" "$_pmt_file" 2>/dev/null)
                fi
                [ -z "$_pmt_desc" ] && _pmt_desc="No description available."
                
                printf "  %-15s %s\n" "$_pmt_cmd_name" "$_pmt_desc"
            fi
        done
    else
        printf "  (No commands found. Directory %s_cmds does not exist)\n" "$_pmt_clean_name"
    fi
}

run_subcommand() {
    _pmt_script_path="$1"
    shift
    
    _pmt_base_dir=$(dirname "$_pmt_script_path")
    _pmt_wrapper_name=$(basename "$_pmt_script_path")
    _pmt_clean_name="${_pmt_wrapper_name%.sh}"
    _pmt_cmds_dir="$_pmt_base_dir/${_pmt_clean_name}_cmds"

    # Route help requests right away to the flat helper function
    if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        _pmt_render_commands_help "$_pmt_script_path"
        return 0
    fi

    _pmt_sub_cmd="$1"
    shift
    _pmt_cmd_path="$_pmt_cmds_dir/${_pmt_sub_cmd}.sh"

    # Intercept and hand over script execution context
    if [ -f "$_pmt_cmd_path" ]; then
        exec sh "$_pmt_cmd_path" "$@"
    else
        printf "Error: '%s' is not a valid %s command.\n" "$_pmt_sub_cmd" "$_pmt_wrapper_name" >&2
        printf "Run '%s --help' to see available options.\n" "$_pmt_wrapper_name" >&2
        return 1
    fi
}





##############
# Config Helpers
##############

# Read a value from a specific section and key in an INI file
# Usage: get_ini_value "section" "key" "/path/to/file.ini"
get_ini_value() {
    SECTION="$1"
    KEY="$2"
    FILE="$3"

    # Gracefully exit if the file does not exist (returns nothing, exit code 0)
    [ -f "$FILE" ] || return 0

    # Awk loops lines: finds the [section], then returns the value for the matching key
    awk -F= -v sec="[$SECTION]" -v k="$KEY" '
        $0 ~ "^\\[" { in_sec = ($0 == sec || $0 == "["sec"]") }
        in_sec && $1 ~ "^[ \t]*"k"[ \t]*$" {
            val = substr($0, length($1) + 2)
            gsub(/^[ \t]*[\x27\x22]|[\x27\x22][ \t]*$/, "", val)
            print val
            exit
        }
    ' "$FILE"
}

# Update or insert a key-value pair under a specific section in an INI file
# Usage: set_ini_value "section" "key" "value" "/path/to/file.ini"
set_ini_value() {
    SECTION="$1"
    KEY="$2"
    VAL="$3"
    FILE="$4"

    # Automatically create the parent directory structure if it doesn't exist
    DIR_NAME=$(dirname "$FILE")
    mkdir -p "$DIR_NAME"

    # Safely create/touch the file if it doesn't exist
    touch "$FILE"

    TMP_FILE=$(mktemp)
    
    # Awk updates the file streaming line by line into a temporary file
    awk -F= -v sec="[$SECTION]" -v k="$KEY" -v v="$VAL" '
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
    ' "$FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$FILE"
}



# Check if a flag file exists
get_flag() {
  [ -f "$DOTFILES/config/${1}.flag" ]
}

# Create a flag file and its parent directories if they don't exist
set_flag() {
  mkdir -p "$DOTFILES/config"
  touch "$DOTFILES/config/${1}.flag"
}

unset_flag() {
  rm -f "$DOTFILES/config/${1}.flag"
}