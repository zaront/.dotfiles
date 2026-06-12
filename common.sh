# common helper functions for dotfiles


##############
# Sub Commands
##############

run_subcommand() {
  SCRIPT_PATH="${1:-${BASH_SOURCE:-$0}}"
  shift
  BASE_DIR=$(dirname "$SCRIPT_PATH")
  WRAPPER_NAME=$(basename "$SCRIPT_PATH")
  
  # Strip trailing .sh extension from wrapper name to construct clean folder path
  CLEAN_NAME="${WRAPPER_NAME%.sh}"
  CMDS_DIR="$BASE_DIR/${CLEAN_NAME}_cmds"

  show_generic_help() {
    MAIN_DESC=$(sed -n "s/^# *desc: *//p" "$SCRIPT_PATH" 2>/dev/null)
    [ -n "$MAIN_DESC" ] && printf "%s\n\n" "$MAIN_DESC"
    printf "Usage: %s [command] [arguments...]\n\n" "$WRAPPER_NAME"
    printf "Available commands:\n"
    
    # Scan directory and extract names/descriptions from individual subcommand scripts
    if [ -d "$CMDS_DIR" ]; then
      for file in "$CMDS_DIR"/*.sh; do
        if [ -f "$file" ]; then
          FULL_NAME="${file##*/}"
          CMD_NAME="${FULL_NAME%.sh}"
          DESC=$(sed -n "s/^# *desc: *//p" "$file" 2>/dev/null)
          [ -z "$DESC" ] && DESC="No description available."
          printf " %-15s %s\n" "$CMD_NAME" "$DESC"
        fi
      done
    else
      printf " (No commands found. Directory %s_cmds does not exist)\n" "$CLEAN_NAME"
    fi
  }

  # Trigger help text if no subcommand is provided or help flags are passed
  if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_generic_help
    return 0
  fi

  SUB_CMD="$1"
  shift
  CMD_PATH="$CMDS_DIR/${SUB_CMD}.sh"

  # Validate subcommand existence and execute using the proper host shell interpreter
  if [ -f "$CMD_PATH" ]; then
    if [ -n "$BASH_VERSION" ]; then
      exec bash "$CMD_PATH" "$@"
    else
      exec sh "$CMD_PATH" "$@"
    fi
  else
    printf "Error: '%s' is not a valid %s command.\n" "$SUB_CMD" "$WRAPPER_NAME" >&2
    printf "Run '%s --help' to see available options.\n" "$WRAPPER_NAME" >&2
    return 1
  fi
}

# Pure POSIX compliant meta-tag options parser.
# Works in any standard 'sh' shell environment.

parse_meta_tags() {
    _pmt_target_file="$1"
    shift 
    
    _pmt_header=$(sed -n '/^#/p; /^[^#]/q' "$_pmt_target_file")
    echo "$_pmt_header" | grep "@META" >/dev/null 2>&1 || return 0

    # Help menu generator
    for _pmt_arg in "$@"; do
        if [ "$_pmt_arg" = "-h" ] || [ "$_pmt_arg" = "--help" ]; then
            _pmt_base_name=$(basename "$_pmt_target_file" .sh)
            printf -- "Usage: %s" "$_pmt_base_name"

            echo "$_pmt_header" | grep "@SWITCH:" | while read -r _pmt_line; do
                _pmt_raw=$(echo "$_pmt_line" | sed 's/.*@SWITCH: //' | cut -d, -f1)
                case "$_pmt_raw" in
                    ??*) printf -- " [--%s]" "$_pmt_raw" ;;
                    *)   printf -- " [-%s]" "$_pmt_raw" ;;
                esac
            done
            
            echo "$_pmt_header" | grep "@OPTION:" | while read -r _pmt_line; do
                _pmt_clean=$(echo "$_pmt_line" | sed 's/.*@OPTION: //')
                _pmt_raw=$(echo "$_pmt_clean" | cut -d, -f1)
                
                # Dynamic field resolution for usage block mapping
                case "$_pmt_clean" in
                    *,*,*,*) _pmt_var_name=$(echo "$_pmt_clean" | cut -d, -f2) ;;
                    *)       _pmt_var_name="value" ;; # Fallback name placeholder for short-only configuration lines
                esac
                
                case "$_pmt_line" in
                    *,required*) _pmt_req="required" ;;
                    *)           _pmt_req="optional" ;;
                esac

                case "$_pmt_raw" in
                    ??*) _pmt_flag="--$_pmt_raw" ;;
                    *)   _pmt_flag="-$_pmt_raw" ;;
                esac

                if [ "$_pmt_req" = "required" ]; then
                    printf -- " %s <%s>" "$_pmt_flag" "$_pmt_var_name"
                else
                    printf -- " [%s <%s>]" "$_pmt_flag" "$_pmt_var_name"
                fi
            done

            echo "$_pmt_header" | grep "@PARAM:" | while read -r _pmt_line; do
                _pmt_clean=$(echo "$_pmt_line" | sed 's/.*@PARAM: //')
                _pmt_param_name=$(echo "$_pmt_clean" | cut -d, -f1)
                
                case "$_pmt_line" in
                    *,required*) _pmt_req="required" ;;
                    *)           _pmt_req="optional" ;;
                esac
                
                if [ "$_pmt_req" = "required" ]; then
                    printf -- " <%s>" "$_pmt_param_name"
                else
                    printf -- " [<%s>]" "$_pmt_param_name"
                fi
            done

            printf -- "\n\nDescription:\n"
            echo "$_pmt_header" | grep "@META_DESC" | sed 's/.*@META_DESC: /  /'
            printf -- "\nOptions & Parameters:\n"
            
            echo "$_pmt_header" | grep -E "@SWITCH:|@OPTION:|@PARAM:" | while read -r _pmt_line; do
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
            exit 0
        fi
    done

    # CLI argument parsing evaluation
    _pmt_param_count=0
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -*)
                _pmt_clean_arg=$(echo "$1" | sed 's/^-*//')
                _pmt_match_switch=$(echo "$_pmt_header" | grep "@SWITCH: " | grep -E ",$_pmt_clean_arg,|^# @SWITCH: $_pmt_clean_arg,")
                _pmt_match_option=$(echo "$_pmt_header" | grep "@OPTION: " | grep -E ",$_pmt_clean_arg,|^# @OPTION: $_pmt_clean_arg,")
                
                if [ -n "$_pmt_match_switch" ]; then
                    case "$_pmt_match_switch" in
                        *,*,*,*) _pmt_var_name=$(echo "$_pmt_match_switch" | sed 's/.*@SWITCH: //' | cut -d, -f2) ;;
                        *)       _pmt_var_name=$(echo "$_pmt_match_switch" | sed 's/.*@SWITCH: //' | cut -d, -f1) ;;
                    esac
                    eval "$_pmt_var_name=true"
                elif [ -n "$_pmt_match_option" ]; then
                    case "$_pmt_match_option" in
                        *,*,*,*) _pmt_var_name=$(echo "$_pmt_match_option" | sed 's/.*@OPTION: //' | cut -d, -f2) ;;
                        *)       _pmt_var_name=$(echo "$_pmt_match_option" | sed 's/.*@OPTION: //' | cut -d, -f1) ;;
                    esac
                    
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

    # Structural constraint validation
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



##############
# Flag files
##############

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