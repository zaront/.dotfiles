
##########################
# Parse options & commands
##########################

# source only once
[ -n "$_cmd_sourced" ] && return 0
_cmd_sourced=1

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


# will always be the root command
DOTFILES_CMD="${DOTFILES_CMD:-$0}"

_cmd_show_help() {
    _cmd_file_target="$1"
    _cmd_header_data="$2"
    _cmd_base_name=$(basename "$_cmd_file_target" .sh)
    
    # print usage
    printf -- "Usage:  %s" "$_cmd_base_name"
    # switches (format: short,long,description)
    echo "$_cmd_switch_lines" | while read -r _cmd_line; do
        _cmd_clean=$(echo "$_cmd_line" | sed 's/.*@SWITCH: //')
        _cmd_short=$(echo "$_cmd_clean" | cut -d, -f1)
        _cmd_long=$(echo "$_cmd_clean" | cut -d, -f2)
        if [ -n "$_cmd_long" ]; then
            printf -- " [--%s]" "$_cmd_long"
        elif [ -n "$_cmd_short" ]; then
            printf -- " [-%s]" "$_cmd_short"
        fi
    done
    # options (format: short,long,description[,required])
    echo "$_cmd_option_lines" | while read -r _cmd_line; do
        _cmd_clean=$(echo "$_cmd_line" | sed 's/.*@OPTION: //')
        _cmd_short=$(echo "$_cmd_clean" | cut -d, -f1)
        _cmd_long=$(echo "$_cmd_clean" | cut -d, -f2)
        _cmd_desc=$(echo "$_cmd_clean" | cut -d, -f3)
        case "$_cmd_line" in *,required*) _cmd_req="required" ;; *) _cmd_req="optional" ;; esac
        # display flag: prefer long name, otherwise short
        if [ -n "$_cmd_long" ]; then
            _cmd_flag="--$_cmd_long"
            _cmd_var_name="$_cmd_long"
        elif [ -n "$_cmd_short" ]; then
            _cmd_flag="-$_cmd_short"
            _cmd_var_name="value"
        else
            _cmd_flag=""
            _cmd_var_name="value"
        fi

        if [ "$_cmd_req" = "required" ]; then
            printf -- " %s <%s>" "$_cmd_flag" "$_cmd_var_name"
        else
            printf -- " [%s <%s>]" "$_cmd_flag" "$_cmd_var_name"
        fi
    done
    # command
    if [ -d "$_cmd_cmds_dir" ]; then
        if [ -n "$_cmd_param_lines" ]; then
            printf -- " [COMMAND]"
        else
            printf -- " COMMAND"
        fi
    fi
    # parameters
    if [ -n "$_cmd_param_lines" ]; then
        echo "$_cmd_param_lines" | while read -r _cmd_line; do
            _cmd_clean=$(echo "$_cmd_line" | sed 's/.*@PARAM: //')
            _cmd_param_name=$(echo "$_cmd_clean" | cut -d, -f1)
            case "$_cmd_line" in *,required*) _cmd_req="required" ;; *) _cmd_req="optional" ;; esac
            if [ "$_cmd_req" = "required" ]; then
                printf -- " <%s>" "$_cmd_param_name"
            else
                printf -- " [<%s>]" "$_cmd_param_name"
            fi
        done
    fi
    printf -- "\n"

    # print description
    _cmd_desc="$_cmd_meta_desc"
    if [ -n "$_cmd_desc" ]; then
        printf -- "\n%s\n" "$_cmd_desc"
    fi

    # print commands
    if [ -d "$_cmd_cmds_dir" ]; then
        printf "\nCommands:\n"
        for _cmd_s_file in "$_cmd_cmds_dir"/*.sh; do
            if [ -f "$_cmd_s_file" ]; then
                _cmd_s_header=$(sed -n '/^#/p; /^[^#]/q' "$_cmd_s_file" 2>/dev/null || true)
                _cmd_s_desc=$(echo "$_cmd_s_header" | sed -n 's/.*@DESC: //p' 2>/dev/null || true)
                printf "  %-15s %s\n" "$(basename "$_cmd_s_file" .sh)" "$_cmd_s_desc"
            fi
        done
    fi

    # print options
    if echo "$_cmd_header" | grep -E -q "@SWITCH:|@OPTION:|@PARAM:"; then
        printf -- "\nOptions:\n"
        echo "$_cmd_header" | grep -E "@SWITCH:|@OPTION:|@PARAM:" | while read -r _cmd_line; do
            case "$_cmd_line" in
                *@PARAM:*)
                    _cmd_clean_line=$(echo "$_cmd_line" | sed 's/.*@PARAM: //')
                    _cmd_cmd_name=$(echo "$_cmd_clean_line" | cut -d, -f1)
                    _cmd_cmd_desc=$(echo "$_cmd_clean_line" | cut -d, -f2)
                    case "$_cmd_line" in *,required*) _cmd_cmd_req="required" ;; *) _cmd_cmd_req="optional" ;; esac
                    _cmd_col1=$(printf -- "<%s>" "$_cmd_cmd_name")
                    if [ "$_cmd_cmd_req" = "required" ]; then
                        printf -- "  %-25s %s (**required)\n" "$_cmd_col1" "$_cmd_cmd_desc"
                    else
                        printf -- "  %-25s %s\n" "$_cmd_col1" "$_cmd_cmd_desc"
                    fi
                    ;;
                *)
                    _cmd_tag_type="SWITCH"
                    case "$_cmd_line" in *@OPTION:*) _cmd_tag_type="OPTION" ;; esac
                    _cmd_clean_line=$(echo "$_cmd_line" | sed "s/.*@\($_cmd_tag_type\): //")
                    _cmd_raw=$(echo "$_cmd_clean_line" | cut -d, -f1)
                    case "$_cmd_line" in *,required*) _cmd_req="required" ;; *) _cmd_req="optional" ;; esac
                    case "$_cmd_clean_line" in
                        *,*,*,*) 
                            _cmd_long=$(echo "$_cmd_clean_line" | cut -d, -f2)
                            _cmd_desc=$(echo "$_cmd_clean_line" | cut -d, -f3)
                            _cmd_col1=$(printf -- "-%s, --%s" "$_cmd_raw" "$_cmd_long")
                            ;;
                        *)
                            _cmd_desc=$(echo "$_cmd_clean_line" | cut -d, -f2)
                            case "$_cmd_raw" in
                                ??*) _cmd_col1=$(printf -- "--%s" "$_cmd_raw") ;;
                                *)   _cmd_col1=$(printf -- "-%s" "$_cmd_raw") ;;
                            esac
                            ;;
                    esac
                    if [ "$_cmd_req" = "required" ]; then
                        printf -- "  %-25s %s (**required)\n" "$_cmd_col1" "$_cmd_desc"
                    else
                        printf -- "  %-25s %s\n" "$_cmd_col1" "$_cmd_desc"
                    fi
                    ;;
            esac
        done
    fi
}


parse_options() {
    _cmd_target_file="$1"
    shift
    _cmd_base_dir=$(dirname "$_cmd_target_file")
    _cmd_wrapper_name=$(basename "$_cmd_target_file")
    _cmd_clean_name="${_cmd_wrapper_name%.sh}"
    _cmd_cmds_dir="$_cmd_base_dir/${_cmd_clean_name}_cmds"
    
    # extract header - all # lines at the top
    _cmd_header=$(sed -n '/^#/p; /^[^#]/q' "$_cmd_target_file" 2>/dev/null || true)
    
    # parse header
    _cmd_meta_desc=$(echo "$_cmd_header" | sed -n 's/.*@DESC: //p' 2>/dev/null || true)
    _cmd_switch_lines=$(echo "$_cmd_header" | grep "@SWITCH:" 2>/dev/null || true)
    _cmd_option_lines=$(echo "$_cmd_header" | grep "@OPTION:" 2>/dev/null || true)
    _cmd_param_lines=$(echo "$_cmd_header" | grep "@PARAM:" 2>/dev/null || true)

    command=""
    _cmd_command_path=""
    _cmd_command_args=""

    # show help if there are subcommands and no arguments
    if [ -d "$_cmd_cmds_dir" ] && [ "$#" -eq 0 ]; then
        _cmd_show_help "$_cmd_target_file" "$_cmd_header"
        if [ -z "$continue_after_showing_help" ]; then
            exit 0
        fi
    fi

    # CLI argument processing loop
    _cmd_param_count=0
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -*)
                # parse switch & option (new metadata format: short,long,description)
                _cmd_clean_arg=$(echo "$1" | sed 's/^-*//')
                _cmd_match_switch=$(echo "$_cmd_header" | grep "@SWITCH: " | grep -E ",$_cmd_clean_arg,|^# @SWITCH: $_cmd_clean_arg,")
                _cmd_match_option=$(echo "$_cmd_header" | grep "@OPTION: " | grep -E ",$_cmd_clean_arg,|^# @OPTION: $_cmd_clean_arg,")
                if [ -n "$_cmd_match_switch" ]; then
                    _cmd_clean_switch=$(echo "$_cmd_match_switch" | sed 's/.*@SWITCH: //')
                    _cmd_switch_short=$(echo "$_cmd_clean_switch" | cut -d, -f1)
                    _cmd_switch_long=$(echo "$_cmd_clean_switch" | cut -d, -f2)
                    if [ -n "$_cmd_switch_long" ]; then
                        _cmd_var_name="$_cmd_switch_long"
                    else
                        _cmd_var_name="$_cmd_switch_short"
                    fi
                    eval "$_cmd_var_name=true"
                elif [ -n "$_cmd_match_option" ]; then
                    _cmd_clean_option=$(echo "$_cmd_match_option" | sed 's/.*@OPTION: //')
                    _cmd_opt_short=$(echo "$_cmd_clean_option" | cut -d, -f1)
                    _cmd_opt_long=$(echo "$_cmd_clean_option" | cut -d, -f2)
                    if [ -n "$_cmd_opt_long" ]; then
                        _cmd_var_name="$_cmd_opt_long"
                    else
                        _cmd_var_name="$_cmd_opt_short"
                    fi
                    if [ -z "$2" ] || case "$2" in -*) true ;; *) false ;; esac; then
                        printf -- "Error: Option --%s requires a matching value.\n" "$_cmd_clean_arg" >&2
                        exit 1
                    fi
                    eval "$_cmd_var_name=\"\$2\""
                    shift
                else
                    # handle -h/--help: show root help only if no command found yet
                    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
                        if [ -z "$_cmd_command_path" ]; then
                            # no command found - show root help
                            _cmd_show_help "$_cmd_target_file" "$_cmd_header"
                            if [ -z "$continue_after_showing_help" ]; then
                                exit 0
                            fi
                        else
                            # command already found - pass -h/--help to subcommand
                            _cmd_command_args="${_cmd_command_args}${_cmd_command_args:+
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
                if [ -d "$_cmd_cmds_dir" ] && [ -z "$_cmd_command_path" ]; then
                    _cmd_candidate="$1"
                    _cmd_candidate_path="$_cmd_cmds_dir/${_cmd_candidate}.sh"
                    if [ -f "$_cmd_candidate_path" ]; then
                        # command found
                        command="$1"
                        _cmd_command_path="$_cmd_candidate_path"
                        shift
                        # collect remaining arguments - swap out spaces for newlines
                        _cmd_command_args=""
                        while [ "$#" -gt 0 ]; do
                            _cmd_command_args="${_cmd_command_args}${_cmd_command_args:+
}$1"
                            shift
                        done
                        break
                    fi
                    # show command error if there are no params
                    if [ -z "$_cmd_param_lines" ]; then
                        printf "Error: '%s' is not a valid %s command.\n" "$1" "$_cmd_clean_name" >&2
                        printf "Run '%s --help' to see available options.\n" "$_cmd_clean_name" >&2
                        exit 1
                    fi
                fi  
                # parse params - if not a command it must be a param
                _cmd_param_count=$((_cmd_param_count + 1))
                _cmd_param_match=$(echo "$_cmd_header" | grep "@PARAM:" | sed -n "${_cmd_param_count}p")
                if [ -n "$_cmd_param_match" ]; then
                    _cmd_param_name=$(echo "$_cmd_param_match" | sed 's/.*@PARAM: //' | cut -d, -f1)
                    eval "$_cmd_param_name=\"\$1\""
                else
                    printf -- "Error: Unexpected argument '%s'.\n" "$1" >&2
                    exit 1
                fi
                ;;
        esac
        shift
    done


    # Validation
    if [ -z "$_cmd_option_lines" ] && [ -z "$_cmd_param_lines" ]; then
        return 0
    fi
    _cmd_validation_failed=false
    # validate required options
    printf "%s\n" "$_cmd_option_lines" | while read -r _cmd_line; do
        case "$_cmd_line" in *,required*) _cmd_requirement="required" ;; *) _cmd_requirement="optional" ;; esac
        if [ "$_cmd_requirement" = "required" ] ; then
            _cmd_clean_line=$(echo "$_cmd_line" | sed 's/.*@OPTION: //')
            _cmd_opt_short=$(echo "$_cmd_clean_line" | cut -d, -f1)
            _cmd_opt_long=$(echo "$_cmd_clean_line" | cut -d, -f2)
            if [ -n "$_cmd_opt_long" ]; then
                _cmd_var_name="$_cmd_opt_long"
            else
                _cmd_var_name="$_cmd_opt_short"
            fi
            eval "_cmd_current_val=\$$_cmd_var_name"
            if [ -z "$_cmd_current_val" ]; then
                printf -- "Error: Mandatory option value mapping for '%s' is missing.\n" "$_cmd_var_name" >&2
                exit 1 
            fi
        fi
    done || _cmd_validation_failed=true
    # validate required parameters
    printf "%s\n" "$_cmd_param_lines" | while read -r _cmd_line; do
        case "$_cmd_line" in *,required*) _cmd_requirement="required" ;; *) _cmd_requirement="optional" ;; esac
        if [ "$_cmd_requirement" = "required" ]; then
            _cmd_clean_line=$(echo "$_cmd_line" | sed 's/.*@PARAM: //')
            _cmd_param_name=$(echo "$_cmd_clean_line" | cut -d, -f1)
            eval "_cmd_current_val=\$$_cmd_param_name"
            if [ -z "$_cmd_current_val" ]; then
                printf -- "Error: Mandatory parameter <%s> is missing.\n" "$_cmd_param_name" >&2
                exit 1
            fi
        fi
    done || _cmd_validation_failed=true
    # exit with error if a validation failed
    if [ "$_cmd_validation_failed" = true ]; then
        exit 1
    fi
}


exec_command() {
    # validate
    if [ -z "$command" ]; then
        return 0
    fi

    # get arguments back into $@ for the command - swap out newlines for spaces
    _cmd_prev_ifs=$IFS
    IFS='
'
    set -f
    set -- $_cmd_command_args
    set +f
    IFS=$_cmd_prev_ifs

    # run the command - include the root command in env
    DOTFILES_CMD="$DOTFILES_CMD" exec sh "$_cmd_command_path" "$@"
}


run_subcommand() {
  shift
  parse_options "$0" "$@"
  exec_command
}
