# common helper functions for dotfiles

# Pure POSIX compliant.
# Works in any standard 'sh' shell environment.

# will always be the root command
DOTFILES_CMD="${DOTFILES_CMD:-$0}"

##########################
# Parse options & commands
##########################

# EXAMPLE METADATA: - should be added to the top of the script

# @DESC: My custom configuration script.
# @SWITCH: v,verbose,Enable verbose debugging
# @SWITCH: f,,Full output mode
# @SWITCH: t,testing,Testing mode
# @OPTION: ,user,The deployment database user account
# @OPTION: d,,Data,required
# @PARAM: target_env,The name of the target server environment,required
# @PARAM: log_dir,Path to write transaction logs

# @DESC format: description
# @SWITCH format: [short],[long],description
# @OPTION format: [short],[long],description[,required]
# @PARAM format: name,description[,required]

_p_show_help() {
    _p_file_target="$1"
    _p_header_data="$2"
    _p_base_name=$(basename "$_p_file_target" .sh)
    
    # print usage
    printf -- "Usage:  %s" "$_p_base_name"
    # switches (format: short,long,description)
    echo "$_p_switch_lines" | while read -r _p_line; do
        _p_clean=$(echo "$_p_line" | sed 's/.*@SWITCH: //')
        _p_short=$(echo "$_p_clean" | cut -d, -f1)
        _p_long=$(echo "$_p_clean" | cut -d, -f2)
        if [ -n "$_p_long" ]; then
            printf -- " [--%s]" "$_p_long"
        elif [ -n "$_p_short" ]; then
            printf -- " [-%s]" "$_p_short"
        fi
    done
    # options (format: short,long,description[,required])
    echo "$_p_option_lines" | while read -r _p_line; do
        _p_clean=$(echo "$_p_line" | sed 's/.*@OPTION: //')
        _p_short=$(echo "$_p_clean" | cut -d, -f1)
        _p_long=$(echo "$_p_clean" | cut -d, -f2)
        _p_desc=$(echo "$_p_clean" | cut -d, -f3)
        case "$_p_line" in *,required*) _p_req="required" ;; *) _p_req="optional" ;; esac
        # display flag: prefer long name, otherwise short
        if [ -n "$_p_long" ]; then
            _p_flag="--$_p_long"
            _p_var_name="$_p_long"
        elif [ -n "$_p_short" ]; then
            _p_flag="-$_p_short"
            _p_var_name="value"
        else
            _p_flag=""
            _p_var_name="value"
        fi

        if [ "$_p_req" = "required" ]; then
            printf -- " %s <%s>" "$_p_flag" "$_p_var_name"
        else
            printf -- " [%s <%s>]" "$_p_flag" "$_p_var_name"
        fi
    done
    # command
    if [ -d "$_p_cmds_dir" ]; then
        if [ -n "$_p_param_lines" ]; then
            printf -- " [COMMAND]"
        else
            printf -- " COMMAND"
        fi
    fi
    # parameters
    if [ -n "$_p_param_lines" ]; then
        echo "$_p_param_lines" | while read -r _p_line; do
            _p_clean=$(echo "$_p_line" | sed 's/.*@PARAM: //')
            _p_param_name=$(echo "$_p_clean" | cut -d, -f1)
            case "$_p_line" in *,required*) _p_req="required" ;; *) _p_req="optional" ;; esac
            if [ "$_p_req" = "required" ]; then
                printf -- " <%s>" "$_p_param_name"
            else
                printf -- " [<%s>]" "$_p_param_name"
            fi
        done
    fi
    printf -- "\n"

    # print description
    _p_desc="$_p_meta_desc"
    if [ -n "$_p_desc" ]; then
        printf -- "\n%s\n" "$_p_desc"
    fi

    # print commands
    if [ -d "$_p_cmds_dir" ]; then
        printf "\nCommands:\n"
        for _p_s_file in "$_p_cmds_dir"/*.sh; do
            if [ -f "$_p_s_file" ]; then
                _p_s_header=$(sed -n '/^#/p; /^[^#]/q' "$_p_s_file" 2>/dev/null || true)
                _p_s_desc=$(echo "$_p_s_header" | sed -n 's/.*@DESC: //p' 2>/dev/null || true)
                printf "  %-15s %s\n" "$(basename "$_p_s_file" .sh)" "$_p_s_desc"
            fi
        done
    fi

    # print options
    if echo "$_p_header" | grep -E -q "@SWITCH:|@OPTION:|@PARAM:"; then
        printf -- "\nOptions:\n"
        echo "$_p_header" | grep -E "@SWITCH:|@OPTION:|@PARAM:" | while read -r _p_line; do
            case "$_p_line" in
                *@PARAM:*)
                    _p_clean_line=$(echo "$_p_line" | sed 's/.*@PARAM: //')
                    _p_p_name=$(echo "$_p_clean_line" | cut -d, -f1)
                    _p_p_desc=$(echo "$_p_clean_line" | cut -d, -f2)
                    case "$_p_line" in *,required*) _p_p_req="required" ;; *) _p_p_req="optional" ;; esac
                    _p_col1=$(printf -- "<%s>" "$_p_p_name")
                    if [ "$_p_p_req" = "required" ]; then
                        printf -- "  %-25s %s (**required)\n" "$_p_col1" "$_p_p_desc"
                    else
                        printf -- "  %-25s %s\n" "$_p_col1" "$_p_p_desc"
                    fi
                    ;;
                *)
                    _p_tag_type="SWITCH"
                    case "$_p_line" in *@OPTION:*) _p_tag_type="OPTION" ;; esac
                    _p_clean_line=$(echo "$_p_line" | sed "s/.*@\($_p_tag_type\): //")
                    _p_raw=$(echo "$_p_clean_line" | cut -d, -f1)
                    case "$_p_line" in *,required*) _p_req="required" ;; *) _p_req="optional" ;; esac
                    case "$_p_clean_line" in
                        *,*,*,*) 
                            _p_long=$(echo "$_p_clean_line" | cut -d, -f2)
                            _p_desc=$(echo "$_p_clean_line" | cut -d, -f3)
                            _p_col1=$(printf -- "-%s, --%s" "$_p_raw" "$_p_long")
                            ;;
                        *)
                            _p_desc=$(echo "$_p_clean_line" | cut -d, -f2)
                            case "$_p_raw" in
                                ??*) _p_col1=$(printf -- "--%s" "$_p_raw") ;;
                                *)   _p_col1=$(printf -- "-%s" "$_p_raw") ;;
                            esac
                            ;;
                    esac
                    if [ "$_p_req" = "required" ]; then
                        printf -- "  %-25s %s (**required)\n" "$_p_col1" "$_p_desc"
                    else
                        printf -- "  %-25s %s\n" "$_p_col1" "$_p_desc"
                    fi
                    ;;
            esac
        done
    fi
}


parse_options() {
    _p_target_file="$1"
    shift
    _p_base_dir=$(dirname "$_p_target_file")
    _p_wrapper_name=$(basename "$_p_target_file")
    _p_clean_name="${_p_wrapper_name%.sh}"
    _p_cmds_dir="$_p_base_dir/${_p_clean_name}_cmds"
    
    # extract header - all # lines at the top
    _p_header=$(sed -n '/^#/p; /^[^#]/q' "$_p_target_file" 2>/dev/null || true)
    
    # parse header
    _p_meta_desc=$(echo "$_p_header" | sed -n 's/.*@DESC: //p' 2>/dev/null || true)
    _p_switch_lines=$(echo "$_p_header" | grep "@SWITCH:" 2>/dev/null || true)
    _p_option_lines=$(echo "$_p_header" | grep "@OPTION:" 2>/dev/null || true)
    _p_param_lines=$(echo "$_p_header" | grep "@PARAM:" 2>/dev/null || true)

    command=""
    _p_command_path=""
    _p_command_args=""

    # show help if there are subcommands and no arguments
    if [ -d "$_p_cmds_dir" ] && [ "$#" -eq 0 ]; then
        _p_show_help "$_p_target_file" "$_p_header"
        if [ -z "$continue_after_showing_help" ]; then
            exit 0
        fi
    fi

    # CLI argument processing loop
    _p_param_count=0
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -*)
                # parse switch & option (new metadata format: short,long,description)
                _p_clean_arg=$(echo "$1" | sed 's/^-*//')
                _p_match_switch=$(echo "$_p_header" | grep "@SWITCH: " | grep -E ",$_p_clean_arg,|^# @SWITCH: $_p_clean_arg,")
                _p_match_option=$(echo "$_p_header" | grep "@OPTION: " | grep -E ",$_p_clean_arg,|^# @OPTION: $_p_clean_arg,")
                if [ -n "$_p_match_switch" ]; then
                    _p_clean_switch=$(echo "$_p_match_switch" | sed 's/.*@SWITCH: //')
                    _p_switch_short=$(echo "$_p_clean_switch" | cut -d, -f1)
                    _p_switch_long=$(echo "$_p_clean_switch" | cut -d, -f2)
                    if [ -n "$_p_switch_long" ]; then
                        _p_var_name="$_p_switch_long"
                    else
                        _p_var_name="$_p_switch_short"
                    fi
                    eval "$_p_var_name=true"
                elif [ -n "$_p_match_option" ]; then
                    _p_clean_option=$(echo "$_p_match_option" | sed 's/.*@OPTION: //')
                    _p_opt_short=$(echo "$_p_clean_option" | cut -d, -f1)
                    _p_opt_long=$(echo "$_p_clean_option" | cut -d, -f2)
                    if [ -n "$_p_opt_long" ]; then
                        _p_var_name="$_p_opt_long"
                    else
                        _p_var_name="$_p_opt_short"
                    fi
                    if [ -z "$2" ] || case "$2" in -*) true ;; *) false ;; esac; then
                        printf -- "Error: Option --%s requires a matching value.\n" "$_p_clean_arg" >&2
                        exit 1
                    fi
                    eval "$_p_var_name=\"\$2\""
                    shift
                else
                    # handle -h/--help: show root help only if no command found yet
                    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
                        if [ -z "$_p_command_path" ]; then
                            # no command found - show root help
                            _p_show_help "$_p_target_file" "$_p_header"
                            if [ -z "$continue_after_showing_help" ]; then
                                exit 0
                            fi
                        else
                            # command already found - pass -h/--help to subcommand
                            _p_command_args="${_p_command_args}${_p_command_args:+
}$1"
                        fi
                    else
                        printf -- "Error: Unknown option '%s'. Use --help for usage.\n" "$1" >&2
                        exit 1
                    fi
                fi
                ;;
            *)
                # parse command
                if [ -d "$_p_cmds_dir" ] && [ -z "$_p_command_path" ]; then
                    _p_candidate="$1"
                    _p_candidate_path="$_p_cmds_dir/${_p_candidate}.sh"
                    if [ -f "$_p_candidate_path" ]; then
                        # command found
                        command="$1"
                        _p_command_path="$_p_candidate_path"
                        shift
                        # collect remaining arguments - swap out spaces for newlines
                        _p_command_args=""
                        while [ "$#" -gt 0 ]; do
                            _p_command_args="${_p_command_args}${_p_command_args:+
}$1"
                            shift
                        done
                        break
                    fi
                    # show command error if there are no params
                    if [ -z "$_p_param_lines" ]; then
                        printf "Error: '%s' is not a valid %s command.\n" "$1" "$_p_clean_name" >&2
                        printf "Run '%s --help' to see available options.\n" "$_p_clean_name" >&2
                        exit 1
                    fi
                fi  
                # parse params - if not a command it must be a param
                _p_param_count=$((_p_param_count + 1))
                _p_param_match=$(echo "$_p_header" | grep "@PARAM:" | sed -n "${_p_param_count}p")
                if [ -n "$_p_param_match" ]; then
                    _p_param_name=$(echo "$_p_param_match" | sed 's/.*@PARAM: //' | cut -d, -f1)
                    eval "$_p_param_name=\"\$1\""
                else
                    printf -- "Error: Unexpected argument '%s'.\n" "$1" >&2
                    exit 1
                fi
                ;;
        esac
        shift
    done


    # Validation
    if [ -z "$_p_option_lines" ] && [ -z "$_p_param_lines" ]; then
        return 0
    fi
    _p_validation_failed=false
    # validate required options
    printf "%s\n" "$_p_option_lines" | while read -r _p_line; do
        case "$_p_line" in *,required*) _p_requirement="required" ;; *) _p_requirement="optional" ;; esac
        if [ "$_p_requirement" = "required" ] ; then
            _p_clean_line=$(echo "$_p_line" | sed 's/.*@OPTION: //')
            _p_opt_short=$(echo "$_p_clean_line" | cut -d, -f1)
            _p_opt_long=$(echo "$_p_clean_line" | cut -d, -f2)
            if [ -n "$_p_opt_long" ]; then
                _p_var_name="$_p_opt_long"
            else
                _p_var_name="$_p_opt_short"
            fi
            eval "_p_current_val=\$$_p_var_name"
            if [ -z "$_p_current_val" ]; then
                printf -- "Error: Mandatory option value mapping for '%s' is missing.\n" "$_p_var_name" >&2
                exit 1 
            fi
        fi
    done || _p_validation_failed=true
    # validate required parameters
    printf "%s\n" "$_p_param_lines" | while read -r _p_line; do
        case "$_p_line" in *,required*) _p_requirement="required" ;; *) _p_requirement="optional" ;; esac
        if [ "$_p_requirement" = "required" ]; then
            _p_clean_line=$(echo "$_p_line" | sed 's/.*@PARAM: //')
            _p_param_name=$(echo "$_p_clean_line" | cut -d, -f1)
            eval "_p_current_val=\$$_p_param_name"
            if [ -z "$_p_current_val" ]; then
                printf -- "Error: Mandatory parameter <%s> is missing.\n" "$_p_param_name" >&2
                exit 1
            fi
        fi
    done || _p_validation_failed=true
    # exit with error if a validation failed
    if [ "$_p_validation_failed" = true ]; then
        exit 1
    fi
}


exec_command() {
    # validate
    if [ -z "$command" ]; then
        return 0
    fi

    # get arguments back into $@ for the command - swap out newlines for spaces
    _p_prev_ifs=$IFS
    IFS='
'
    set -f
    set -- $_p_command_args
    set +f
    IFS=$_p_prev_ifs

    # run the command - include the root command in env
    DOTFILES_CMD="$DOTFILES_CMD" exec sh "$_p_command_path" "$@"
}


run_subcommand() {
  shift
  parse_options "$0" "$@"
  exec_command
}




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
    [ -f "$_s_file" ] || return 1
    
    awk -v block="$1" '
        { file_content = file_content $0 "\n" }
        END { exit (index(file_content, block) ? 0 : 1) }
    ' "$_s_file"
}

set_startup() { 
    # validate
    _s_dir="${_s_file%/*}"
    mkdir -p "$_s_dir"
    touch "$_s_file"

    # add the startup script
    if ! get_startup "$1"; then 
        printf '%s\n' "$1" >> "$_s_file" 
    fi 
}

unset_startup() { 
    # validate
    [ -f "$_s_file" ] || return 0
    
    # remove the startup script
    _s_tmp="${_s_file}.tmp.$$.$(date +%s)"
    awk -v block="$1" '
        BEGIN {
            # Add a trailing newline to the block to match the printf format on disk
            block = block "\n"
        }
        { file_content = file_content $0 "\n" }
        END {
            pos = index(file_content, block)
            if (pos > 0) {
                before = substr(file_content, 1, pos - 1)
                after = substr(file_content, pos + length(block))
                file_content = before after
            }
            printf "%s", file_content
        }
    ' "$_s_file" > "$_s_tmp" && mv "$_s_tmp" "$_s_file"
}

read_template() {
    _s_src_file="$(dirname "$0")/$1.template"
    echo "Reading template from $_s_src_file"
    [ -f "$_s_src_file" ] || return 1
    
    # Read to global variable
    # The 'x' pattern guarantees trailing blank lines are preserved
    TEMPLATE=$(cat "$_s_src_file"; printf 'x')
    TEMPLATE="${TEMPLATE%x}"
    printf "%s" "$TEMPLATE"
}




################
# Prompt Helpers
################


prompt_choice() {
    # Isolate the first argument as a custom title header
    _title="$1"
    shift # Remove the title from the argument stack so only options remain
    
    while true; do 
        # Display the custom title safely
        printf '%s\n' "" "=== $_title ===" 
        
        # 1. Dynamically loop through arguments to print the menu numbers 
        _index=1 
        for _opt in "$@"; do 
            printf '%d) %s\n' "$_index" "$_opt" 
            _index=$((_index + 1)) 
        done 
        
        printf '%s\n' '--------------------------------' 
        printf 'Choice [1-%d]: ' "$#" 
        
        # 2. Read user input safely 
        read -r REPLY 
        
        # 3. Validate that the input is a positive integer within bounds 
        case "$REPLY" in 
            # Match only pure digits 
            *[!0-9]*|"") 
                echo "Invalid input. Please enter a valid number." 
                ;; 
            *) 
                # Explicitly check against the total argument count ($#) 
                if [ "$REPLY" -ge 1 ] && [ "$REPLY" -le "$#" ]; then 
                    # Output the selected number and exit success 
                    printf '%s\n' "$REPLY" 
                    return 0 
                else 
                    # Display the true maximum boundary ($#) to the user 
                    echo "Out of range. Please choose between 1 and $#." 
                fi 
                ;; 
        esac 
    done 
}





prompt_confirm() {
    printf '%s [Y/n] ' "$1"
    read -r REPLY
    [ -z "$REPLY" ] || [ "$REPLY" = 'y' ] || [ "$REPLY" = 'Y' ] && REPLY="y" || REPLY="n"
}