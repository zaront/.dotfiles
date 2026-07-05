###################################
# a sh posix argument parser
# fast: no subshells or processes
# uses metatags to define arguments
# supports: subcommands
#           colors
#           auto help (-h/--help)
#           stop options (--)
#           grouped switches (-abc)
###################################

# source only once
[ -n "$_cmd_sourced" ] && return 0
_cmd_sourced=1

. $DOTFILES/common/tui.sh

# EXAMPLE METADATA: - should be added to the top of the script
#   - parameter can be in any order
#   - descriptive text can be multiple lines

# @DESC:    Order parts from supplier
#           - all orders are sent the next day
# @VERSION: 0.4.2-alpha (26.07)
# @SWITCH:  -v, Verify the order before sending
# @SWITCH:  --free, Request free shipping
# @SWITCH:  -P, --PO, Submit as a purchase order
# @OPTION:  -p, Requested price
# @OPTION:  --user, <user name>, REQUIRED
# @OPTION:  -i, --id, <id>, REQUIRED, The items id
# @PARAM:   <item_name>, The name of the item to order, REQUIRED
# @STDIN:   REQUIRED, <header>, A header to put on the order
# @PARAM:   <backup>, Path to backup the order to

# @EXAMPLE: 
#   place_order --user John -i 123 paper "my header"
#   place_order --user John -i 123 paper < header.txt
#
#  You can pipe the output to a file:
#  place_order "USB cable" --user "John Doe" -i "123456" < /tmp/order_header.txt > /tmp/order.txt



# will always be the root command
DOTFILES_CMD="${DOTFILES_CMD:-$0}"

# if not connected to terminal
if [ ! -t 1 ]; then
    NO_TIP=1
fi

_cmd_nl='
'


# will parse args, then run a subcommand
# $1 = $0
# $2 = $@
run_args() {
  shift
  parse_args "$0" "$@"
  run_subcommand
}


# will run a subcommand 
# must call 'parse_args' first
run_subcommand() {
    # validate
    if [ -z "$command" ]; then
        return 0
    fi

    # get arguments back into $@ for the command - swap out newlines for spaces
    _cmd_prev_ifs=$IFS
    IFS="$_cmd_nl"
    set -f
    set -- $_cmd_command_args
    set +f
    IFS=$_cmd_prev_ifs

    # run the command - include the root command in env
    DOTFILES_CMD="$DOTFILES_CMD" exec sh "$_cmd_command_path" "$@"
}


# $1 = $0
# $2 = $@
# returns: command - the parsed command name
#          arguments - for SWITCH & OPTION, short name is pefered over long name, for PARAM, it the value name
#          printed_help - if help was printed
# pesets:  continue_after_showing_help - to not exit after showing help
parse_args() {
    # process first argument
    _cmd_current_name=${1##*/} # get filename
    _cmd_current_name=${_cmd_current_name%".sh"} # remove extension
    _cmd_commands_dir="${1%/*}/${_cmd_current_name}_cmds" # get commands directory
    shift
    
    # extract metatags from header
    _cmd_metatag_header "$0"
    _cmd_metatags="$_cmd_header"

    command=""
    _cmd_command_path=""
    _cmd_command_args=""

    # show help if there are subcommands and no arguments
    if [ -d "$_cmd_commands_dir" ] && [ "$#" -eq 0 ]; then
        _cmd_print_help "$_cmd_metatags" "$_cmd_current_name" "$_cmd_commands_dir"
        printed_help=1
        if [ -z "$continue_after_showing_help" ]; then
            exit 0
        fi
    fi

    # parse arguments - loop
    _cmd_param_order_count=0
    _cmd_stop_options=""
    _cmd_grouped_switches=""
    while [ "$#" -gt 0 ]; do

        # get next argument
        if [ -z "$_cmd_grouped_switches" ]; then
            # extract next argument
            _cmd_arg="$1"
            shift
            # categorize argument type
            if [ "$_cmd_arg" = "--" ]; then
                _cmd_stop_options=1
                continue
            fi
            _cmd_arg_type=""
            _cmd_long_dash="" # used for easy printing of -- or -
            if [ -z "$_cmd_stop_options" ]; then # no stop options
                if [ "${_cmd_arg%${_cmd_arg#??}}" = "--" ]; then # has two dashes
                    _cmd_arg_type="long"
                    _cmd_long_dash="-"
                elif [ "${_cmd_arg%${_cmd_arg#?}}" = "-" ]; then # has one dash
                    _cmd_arg_type="short"
                    if [ "${#_cmd_arg}" -gt 2 ]; then # is a grouped switch
                        _cmd_grouped_switches="${_cmd_arg#?}" # remove first dash
                        _cmd_arg="${_cmd_grouped_switches%${_cmd_grouped_switches#?}}" # get first switch
                        _cmd_grouped_switches="${_cmd_grouped_switches#?}" # remove switch from group
                    fi
                fi
            fi
        else
            # extract from grouped switches
            _cmd_arg="${_cmd_grouped_switches%${_cmd_grouped_switches#?}}" # get next switch
            _cmd_grouped_switches="${_cmd_grouped_switches#?}" # remove switch from group
        fi

        # switch & option
        if [ -n "$_cmd_arg_type" ]; then
            # strip dashes
            _cmd_arg="${_cmd_arg#-}"
            _cmd_arg="${_cmd_arg#-}"
            # match switch & option
            _cmd_arg_found=""
            _cmd_parse_metatag "$_cmd_metatags"
            while _cmd_parse_metatag; do
                case "$_cmd_tag" in
                    "@SWITCH")
                        if [ $_cmd_arg_type = "short" -a "$_cmd_arg" = "$_cmd_short" ] || [ $_cmd_arg_type = "long" -a "$_cmd_arg" = "$_cmd_long" ]; then
                            eval "${_cmd_short:-$_cmd_long}=1" # set variable
                            _cmd_arg_found=1
                            break # completed processing this argument
                        fi
                    ;;
                    "@OPTION")
                        if [ $_cmd_arg_type = "short" -a "$_cmd_arg" = "$_cmd_short" ] || [ $_cmd_arg_type = "long" -a "$_cmd_arg" = "$_cmd_long" ]; then
                            # validate has value
                            if [ -z "$1" ] || case "$1" in -*) true ;; *) false ;; esac; then
                                print_error "Option '-${_cmd_long_dash}${_cmd_arg}' is missing the value <$_cmd_value>."
                                [ -z "$NO_TIP" ] && print_info "use --help for usage"
                                exit 1
                            fi
                            eval "${_cmd_short:-$_cmd_long}=$1" # set variable
                            shift # remove value
                            _cmd_arg_found=1
                            break # completed processing this argument
                        fi
                    ;;
                esac
            done
            # argument not found
            if [ -z "$_cmd_arg_found" ]; then
                # show version (--version)
                if [ "$_cmd_arg" = "version" ] && _cmd_arg_type="long"; then
                     _cmd_parse_metatag "$_cmd_metatags" "@VERSION"
                    if _cmd_parse_metatag; then
                        printf -- "$_cmd_desc\n"
                        exit 0
                    fi
                fi
                # show help (-h, --help)
                if [ "$_cmd_arg" = "h" ] || [ "$_cmd_arg" = "help" ]; then
                    if [ -z "$_cmd_command_path" ]; then
                        # no command found yet - show help for this command
                        _cmd_print_help "$_cmd_metatags" "$_cmd_current_name" "$_cmd_commands_dir"
                        printed_help=1
                        if [ -z "$continue_after_showing_help" ]; then
                            exit 0
                        fi
                    else
                        # command already found - pass --help to subcommand
                        _cmd_command_args="${_cmd_command_args}${_cmd_command_args:+$_cmd_nl}--help"
                    fi
                # unknown argument
                else
                    print_error "Unknown option '-${_cmd_long_dash}${_cmd_arg}'."
                    [ -z "$NO_TIP" ] && print_info "use --help for usage"
                    exit 1
                fi
            fi

        # command & param & stdin
        else
            # match command
            if [ -d "$_cmd_commands_dir" ] && [ -z "$_cmd_command_path" ]; then
                _cmd_candidate_path="$_cmd_commands_dir/${_cmd_arg}.sh"
                if [ -f "$_cmd_candidate_path" ]; then
                    # command found
                    command="$_cmd_arg"
                    _cmd_command_path="$_cmd_candidate_path"
                    # collect remaining arguments - swap out spaces for newlines
                    _cmd_command_args=""
                    while [ "$#" -gt 0 ]; do
                        _cmd_command_args="${_cmd_command_args}${_cmd_command_args:+$_cmd_nl}$1"
                        shift
                    done
                    break # completed processing this argument
                fi
                # unknown command - only if it has no params or stdin
                _cmd_parse_metatag "$_cmd_metatags" "@PARAM"
                if ! _cmd_parse_metatag; then # has no params
                    _cmd_parse_metatag "$_cmd_metatags" "@STDIN"
                    if ! _cmd_parse_metatag || [ -z "$_cmd_value" ]; then # has no stdin with value
                        print_error "'$_cmd_arg' is not a valid $_cmd_current_name command."
                        [ -z "$NO_TIP" ] && print_info "use --help for usage"
                        exit 1
                    fi
                fi
            fi  
            # match param - if not a command it must be a param or stdin
            _cmd_param_order_index=0
            _cmd_param_order_count=$((_cmd_param_order_count + 1))
            _cmd_parse_metatag "$_cmd_metatags"
            # get the next param or stdin in order
            while [ "$_cmd_param_order_index" -lt "$_cmd_param_order_count" ]; do
                _cmd_parse_metatag || break
                case "$_cmd_tag" in
                    "@PARAM"|"@STDIN")
                        [ -n "$_cmd_value" ] && _cmd_param_order_index=$((_cmd_param_order_index + 1))
                    ;;
                esac
            done
            if [ -n "$_cmd_value" ]; then
                eval "$_cmd_value=\"\$_cmd_arg\"" # set variable
            else
                print_error "Unexpected argument '$_cmd_arg'."
                [ -z "$NO_TIP" ] && print_info "use --help for usage"
                exit 1
            fi
        fi
    done

    # required options & params & stdin
    _cmd_parse_metatag "$_cmd_metatags"
    while _cmd_parse_metatag; do
        [ -n "$_cmd_req" ] || continue # not required
        case "$_cmd_tag" in
            "@OPTION")
                _cmd_long_dash2=""
                [ -z "$_cmd_short" ] && _cmd_long_dash2="-"
                eval "_cmd_current_val=\"\$${_cmd_short:-$_cmd_long}\"" # get variable from string
                if [ -z "$_cmd_current_val" ]; then
                    print_error "Option '-${_cmd_long_dash2}${_cmd_short:-$_cmd_long}' is required."
                    [ -z "$NO_TIP" ] && print_info "use --help for usage"
                    exit 1
                fi
            ;;
            "@PARAM")
                eval "_cmd_current_val=\"\$${_cmd_value}\"" # get variable from string
                if [ -z "$_cmd_current_val" ]; then
                    print_error "Parameter '$_cmd_value' is required."
                    [ -z "$NO_TIP" ] && print_info "use --help for usage"
                    exit 1
                fi
            ;;
            "@STDIN")
                if [ -z "$_cmd_stdin" ]; then
                    if [ -t 0 ]; then # no stdin
                        if [ -z "_cmd_value" ]; then
                            print_error "Standard input (< stdin) is required."
                            [ -z "$NO_TIP" ] && print_info "use --help for usage"
                            exit 1
                        else
                            eval "_cmd_current_val=\"\$${_cmd_value}\"" # get variable from string
                            if [ -z "$_cmd_current_val" ]; then
                                print_error "Parameter '$_cmd_value' or standard input (< stdin) is required."
                                [ -z "$NO_TIP" ] && print_info "use --help for usage"
                                exit 1
                            fi
                        fi
                    fi
                fi
            ;;
        esac
    done
}


# $1 = metatag header
# $2 = current command name
# $3 = sub commands directory
_cmd_print_help() {
    _cmd_metatags="$1"
    _cmd_current_name="$2"
    _cmd_commands_dir="$3"

    # print usage
    printf -- "${TXT_GRAY}Usage:${TXT_DEFAULT}  ${_cmd_current_name}"
    # switches
    _cmd_parse_metatag "$_cmd_metatags" "@SWITCH"
    while _cmd_parse_metatag; do
        printf -- " ${TXT_GRAY}[%s]${TXT_DEFAULT}" "-${_cmd_short:-"-$_cmd_long"}"
    done
    # options
    _cmd_parse_metatag "$_cmd_metatags" "@OPTION"
    while _cmd_parse_metatag; do
        if [ -n "$_cmd_req" ]; then
            printf -- " ${TXT_RED}%s <%s>${TXT_DEFAULT}" "-${_cmd_short:-"-$_cmd_long"}" "$_cmd_value"
        else
            printf -- " ${TXT_GRAY}[%s <%s>]${TXT_DEFAULT}" "-${_cmd_short:-"-$_cmd_long"}" "$_cmd_value"
        fi
    done
    # command
    if [ -d "$_cmd_commands_dir" ]; then
        _cmd_parse_metatag "$_cmd_metatags" "@PARAM"
        if _cmd_parse_metatag; then
            printf -- " ${TXT_GRAY}[COMMAND]${TXT_DEFAULT}"
        else
            printf -- " COMMAND"
        fi
    fi
    # parameters & stdin
    _cmd_parse_metatag "$_cmd_metatags"
    while _cmd_parse_metatag; do
        case "$_cmd_tag" in
            "@PARAM"|"@STDIN")
                if [ -n "$_cmd_req" ]; then
                    printf -- " %s" "$_cmd_value"
                else
                    printf -- " ${TXT_GRAY}[%s]${TXT_DEFAULT}" "$_cmd_value"
                fi
            ;;
        esac
    done
    # stdin
    _cmd_parse_metatag "$_cmd_metatags" "@STDIN"
    if _cmd_parse_metatag; then
        if [ -n "$_cmd_req" ]; then
            printf -- " %s" "< stdin"
        else
            printf -- " ${TXT_GRAY}[%s]${TXT_DEFAULT}" "< stdin"
        fi
    fi
    printf -- "${TXT_DEFAULT}\n"

    # print description
    _cmd_parse_metatag "$_cmd_metatags" "@DESC"
    while _cmd_parse_metatag; do
        printf -- "\n${TXT_BOLD}${TXT_BLUE}$_cmd_desc${TXT_DEFAULT}\n"
    done

    # print commands
    if [ -d "$_cmd_commands_dir" ]; then
        printf -- "\n${TXT_BOLD}Commands:${TXT_DEFAULT}\n"
        for _cmd_cmds_file in "$_cmd_commands_dir"/*.sh; do
            _cmd_metatag_header "$_cmd_cmds_file"
            _cmd_parse_metatag "$_cmd_header" "@DESC"
            _cmd_parse_metatag
            _cmd_cmds_file=${_cmd_cmds_file##*/} # get filename
            _cmd_cmds_file=${_cmd_cmds_file%".sh"} # remove extension
            printf -- "  ${TXT_YELLOW}%-23s${TXT_DEFAULT} ${TXT_GRAY}%s${TXT_DEFAULT}\n" "$_cmd_cmds_file" "${_cmd_desc%%"\n"*}"
        done
    fi

    # print options
    _cmd_printed=""
    _cmd_parse_metatag "$_cmd_metatags"
    while _cmd_parse_metatag; do
        case "$_cmd_tag" in
            "@SWITCH"|"@OPTION"|"@PARAM"|"@STDIN"|"@VERSION")
                if [ "$_cmd_printed" != "options" ]; then
                    printf -- "\n${TXT_BOLD}Options:${TXT_DEFAULT}\n"
                    _cmd_printed="options"
                fi
                _cmd_fmt_value=""
                _cmd_fmt_color=""
                _cmd_fmt_color_end=""
                [ "$_cmd_tag" = "@VERSION" ] && _cmd_long="version" # include version as an option
                [ "$_cmd_tag" = "@VERSION" ] && _cmd_desc="Display the version" # include version destription
                [ "$_cmd_short" ] && _cmd_fmt_value="-${_cmd_short}" # short
                [ "$_cmd_long" ] && [ "$_cmd_fmt_value" ] && _cmd_fmt_value="${_cmd_fmt_value}, " # comma
                [ "$_cmd_long" ] && _cmd_fmt_value="${_cmd_fmt_value}--${_cmd_long}" # long
                [ "$_cmd_value" ] && [ "$_cmd_fmt_value" ] && _cmd_fmt_value="${_cmd_fmt_value} <${_cmd_value}>" # option value
                [ "$_cmd_value" ] && [ ! "$_cmd_fmt_value" ] && _cmd_fmt_value="${_cmd_fmt_value}${_cmd_value}" # param value
                [ "$_cmd_value" ] && [ "$_cmd_tag" = "@STDIN" ] && _cmd_fmt_value="${_cmd_fmt_value}, < stdin" # stdin value + pipe
                [ ! "$_cmd_value" ] && [ "$_cmd_tag" = "@STDIN" ] && _cmd_fmt_value="${_cmd_fmt_value}< stdin" # stdin pipe only
                [ "$_cmd_tag" = "@PARAM" ] && _cmd_fmt_color="${TXT_YELLOW}" && _cmd_fmt_color_end="${TXT_DEFAULT} " # param yellow
                [ "$_cmd_tag" = "@STDIN" ] && _cmd_fmt_color="${TXT_BLUE}" && _cmd_fmt_color_end="${TXT_DEFAULT} " # stdin blue
                _cmd_fmt_value="  $_cmd_fmt_value" # indent
                _cmd_desc="${TXT_GRAY}$_cmd_desc${TXT_DEFAULT}" # gray
                [ "$_cmd_req" ] && _cmd_desc="$_cmd_desc ${TXT_RED}(REQUIRED)${TXT_DEFAULT}" # required
                _cmd_print_columns "$_cmd_fmt_value" "$_cmd_desc" 25 "$_cmd_fmt_color" "$_cmd_fmt_color_end" # print
            ;;
        esac
    done

    # print examples
    _cmd_parse_metatag "$_cmd_metatags" "@EXAMPLE"
    while _cmd_parse_metatag; do
        if [ "$_cmd_printed" != "example" ]; then
            printf -- "\n${TXT_BOLD}${TXT_BOLD}Examples:${TXT_DEFAULT}\n"
            _cmd_printed="example"
        fi
        _cmd_print_columns "" "${TXT_PURPLE}$_cmd_desc${TXT_DEFAULT}" 1
    done
}


# $1 = Column 1 text (Single line)
# $2 = Column 2 text (Multi-line)
# $3 = padding (e.g., 20)
# $4 = frame start
# $5 = frame center
# $6 = frame end
_cmd_print_columns() {
    _cmd_col1="$1"
    _cmd_col2="$2"
    _cmd_frame_start="$4"
    _cmd_frame_center="${5:-" "}"
    _cmd_frame_end="$6"
    _cmd_fmt_columns="%b%-${3:-25}b%b%b%b\n"
    
    while [ -n "$_cmd_col2" ]; do
        # get line
        _cmd_line="${_cmd_col2%%"\n"*}"
        if [ "$_cmd_col2" = "$_cmd_line" ]; then
            _cmd_col2=""
        else
            _cmd_col2="${_cmd_col2#*"\n"}"
        fi
        # print
        printf -- "$_cmd_fmt_columns" "$_cmd_frame_start" "$_cmd_col1" "$_cmd_frame_center" "$_cmd_line" "$_cmd_frame_end"
        _cmd_col1=""
    done
}


# Parse a list of metatags into variables
# $1 = set metatags
# $2 = filter by tag (optional)
# Results: _cmd_tag, _cmd_desc, _cmd_short, _cmd_long, _cmd_value, _cmd_req
_cmd_parse_metatag() {
    # set the list
    if [ -n "$1" ]; then
        _cmd_lines="$1"
        _cmd_filter="$2"
        _cmd_param_count=0
        _cmd_option_count=0
        return 0
    fi

    while true; do
        # reset variables
        _cmd_tag=""
        _cmd_desc=""
        _cmd_short=""
        _cmd_long=""
        _cmd_value=""
        _cmd_req=""

        # no more lines
        [ -z "$_cmd_lines" ] && return 1

        # get line
        _cmd_line="${_cmd_lines%%"\n"*}"
        if [ "$_cmd_lines" = "$_cmd_line" ]; then
            _cmd_lines=""
        else
            _cmd_lines="${_cmd_lines#*"\n"}"
        fi

        # parse tag
        _cmd_tag="${_cmd_line%%":"*}" # extract to :
        _cmd_line="${_cmd_line#*":"}" # strip :

        # parse parameters
        case "$_cmd_tag" in
            "@DESC"|"@EXAMPLE"|"@VERSION")
                # remander is description
                _cmd_line="${_cmd_line#"${_cmd_line%%[![:space:]]*}"}" # left trim
                _cmd_desc="${_cmd_line}" 
            ;;
            *)
                # parse parameters
                _cmd_line="${_cmd_line}," # add comma
                while [ -n "$_cmd_line" ]; do
                    _cmd_parm="${_cmd_line%%","*}" # extract to comma
                    _cmd_line="${_cmd_line#*","}" # strip comma
                    _cmd_parm="${_cmd_parm#"${_cmd_parm%%[![:space:]]*}"}" # left trim
                    _cmd_parm="${_cmd_parm%"${_cmd_parm##*[![:space:]]}"}" # right trim
                    # assingn parameter
                    case "$_cmd_parm" in
                        "REQUIRED") _cmd_req=1 ;;   
                        "--"*) _cmd_long="${_cmd_parm#"--"}" ;;
                        "-"*) _cmd_short="${_cmd_parm#"-"}" ;;
                        "<"*) 
                            _cmd_value="${_cmd_parm#"<"}" 
                            _cmd_value="${_cmd_value%">"}"
                        ;;
                        *)
                            if [ -n "$_cmd_desc" ]; then
                                _cmd_desc="$_cmd_desc, $_cmd_parm"
                            else
                                _cmd_desc="$_cmd_parm"
                            fi
                        ;;
                    esac
                done
            ;;
        esac

        # parse multi-line description
        while [ -n "$_cmd_lines" ] && [ "${_cmd_lines#"@"}" = "$_cmd_lines" ]; do
            # get line
            _cmd_line="${_cmd_lines%%"\n"*}"
            if [ "$_cmd_lines" = "$_cmd_line" ]; then
                _cmd_lines=""
            else
                _cmd_lines="${_cmd_lines#*"\n"}"
            fi
            # add to description
            if [ -n "$_cmd_desc" ]; then
                _cmd_desc="$_cmd_desc\n$_cmd_line"
            else
                _cmd_desc="$_cmd_line"
            fi
        done

        # add defaults
        case "$_cmd_tag" in
            "@SWITCH")
                _cmd_value=""
                _cmd_req=""
            ;;
            "@OPTION")
                if [ -z "$_cmd_value" ]; then
                    _cmd_option_count=$((_cmd_option_count + 1))
                    _cmd_value="value_$_cmd_option_count"
                fi
            ;;
            "@PARAM")
                if [ -z "$_cmd_value" ]; then
                    _cmd_param_count=$((_cmd_param_count + 1))
                    _cmd_value="param_$_cmd_param_count"
                fi
                _cmd_short=""
                _cmd_long=""
            ;;
            "@STDIN")
                _cmd_short=""
                _cmd_long=""
            ;;
        esac

        # skip invalid tags
        case "$_cmd_tag" in
            "@SWITCH"|"@OPTION") 
                [ -z "$_cmd_short" ] && [ -z "$_cmd_long" ] && continue # missing short or long
                [ "${_cmd_short#* }" != "$_cmd_short" ] && continue # short has spaces
                [ "${_cmd_long#* }" != "$_cmd_long" ] && continue # long has spaces
                [ -n "$_cmd_short" ] && [ ! "${#_cmd_short}" -eq 1 ] && continue # short must be 1 char
                [ -n "$_cmd_long" ] && [ ! "${#_cmd_long}" -gt 1 ] && continue # long must be more than 1 char
            ;;
            "@PARAM"|"@STDIN")
                [ "${_cmd_value#* }" != "$_cmd_value" ] && continue # value has spaces
            ;;
            "@DESC"|"@EXAMPLE")
                [ -z "$_cmd_desc" ] && continue # missing description
            ;;
        esac

        # return if matching filter
        if [ -z "$_cmd_filter" ] || [ "$_cmd_tag" = "$_cmd_filter" ]; then
            break
        fi
    done
}


# Extract metatags from the header
# $1 = Path to the script file
# Results: _cmd_header
_cmd_metatag_header() {
    _cmd_header=""
    _cmd_is_tag=""
    while read -r _cmd_line; do
        _cmd_line="${_cmd_line#"${_cmd_line%%[![:space:]]*}"}" # left trim
        _cmd_line="${_cmd_line%"${_cmd_line##*[![:space:]]}"}" # right trim
        # keep metatag lines
        case "$_cmd_line" in
            "#"*) 
                _cmd_line="${_cmd_line#'#'}" # strip #
                _cmd_line="${_cmd_line#"${_cmd_line%%[![:space:]]*}"}" # left trim
                # check if this is a metatag line
                case "$_cmd_line" in
                    @*) 
                        # add line
                        if [ -z "$_cmd_header" ]; then
                            _cmd_header="$_cmd_line"
                        else
                            _cmd_header="$_cmd_header\n$_cmd_line"
                        fi
                        _cmd_is_tag=1
                    ;;
                    *)
                        if [ -n "$_cmd_is_tag" ]; then
                             # add line
                            _cmd_header="$_cmd_header\n$_cmd_line"
                        fi
                    ;;
                esac
            ;;
            "") 
                _cmd_is_tag=""
                continue
            ;;
            *) break ;;
        esac
    done < "$1"
}