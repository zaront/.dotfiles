#!/bin/sh

      # these comments don't count either


# DESC: This description will become overridden by the later one
# @DESC: 
#
# Order parts from supplier
# these parts are important
#
# this space is preserved

# these comments don't count
# @EXAMPLE: 
# this is some ways to use this
# you can do this, or that
#     here are some quote "like this" or 'like this'.
#       can we use variables here: [${i}]

#these comments don't count

# @SWITCH: -v, --verify
#          Verify the order before sending
#          it takes time to get this right
# @OPTION: -u, --user, <user name>, REQUIRED, This is the description with, cammas
# @PARAM: <item_name>, REQUIRED, The name of the item to order
# @PARAM: Path to backup the order to
# @PARAM: 22,Path to backup the order to
# @OPTION:  this si some text  , REQUIRED, -t
# the item is very important and theirfor required.
# @DESC:
# @EXAMPLE:
# @OPTION:
# @SWITCH:
# @PARAM:

# these are comments not included
# they don't count
i="my variable"
# @EXAMPLE: 
# this will not be parsed,  its not in the header


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
            "@DESC"|"@EXAMPLE")
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
            "@PARAM")
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


# $1 = command path
# $2 = metatag header
# $2 = sub commands directory
_cmd_print_help() {
    _cmd_command=${1##*/} # get filename
    _cmd_command=${_cmd_command%".sh"} # remove extension
    _cmd_metatags="$2"
    _cmd_cmds_dir="$3"

    # print usage
    printf -- "${TXT_GRAY}Usage:${TXT_DEFAULT}  ${_cmd_command}"
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
    if [ -d "$_cmd_has_sub_cmds" ]; then
        _cmd_parse_metatag "$_cmd_metatags" "@PARAM"
        if _cmd_parse_metatag; then
            printf -- " ${TXT_GRAY}[COMMAND]${TXT_DEFAULT}"
        else
            printf -- " COMMAND"
        fi
    fi
    # parameters
    _cmd_parse_metatag "$_cmd_metatags" "@PARAM"
    while _cmd_parse_metatag; do
        if [ -n "$_cmd_req" ]; then
            printf -- " <%s>" "$_cmd_value"
        else
            printf -- " ${TXT_GRAY}[<%s>]${TXT_DEFAULT}" "$_cmd_value"
        fi
    done
    printf -- "${TXT_DEFAULT}\n"

    # print description
    _cmd_parse_metatag "$_cmd_metatags" "@DESC"
    while _cmd_parse_metatag; do
        printf -- "\n${TXT_BOLD}${TXT_BLUE}$_cmd_desc${TXT_DEFAULT}\n"
    done

    # print commands
    if [ -d "$_cmd_cmds_dir" ]; then
        printf -- "\n${TXT_BOLD}Commands:${TXT_DEFAULT}\n"
        for _cmd_s_file in "$_cmd_cmds_dir"/*.sh; do
            _cmd_metatag_header "$_cmd_s_file"
            _cmd_parse_metatag "$_cmd_header" "@DESC"
            _cmd_parse_metatag
            _cmd_s_file=${_cmd_s_file##*/} # get filename
            _cmd_s_file=${_cmd_s_file%".sh"} # remove extension
            printf -- "  ${TXT_YELLOW}%-23s${TXT_DEFAULT} ${TXT_GRAY}%s${TXT_DEFAULT}\n" "$_cmd_s_file" "${_cmd_desc%%"\n"*}"
        done
    fi

    # print options
    _cmd_printed=""
    _cmd_parse_metatag "$_cmd_metatags"
    while _cmd_parse_metatag; do
        case "$_cmd_tag" in
            "@SWITCH"|"@OPTION"|"@PARAM")
            if [ "$_cmd_printed" != "options" ]; then
                printf -- "\n${TXT_BOLD}Options:${TXT_DEFAULT}\n"
                _cmd_printed="options"
            fi
            _cmd_fmt_value=""
            _cmd_fmt_color=""
            _cmd_fmt_color_end=""
            [ "$_cmd_short" ] && _cmd_fmt_value="-${_cmd_short}" # short
            [ "$_cmd_long" ] && [ "$_cmd_fmt_value" ] && _cmd_fmt_value="${_cmd_fmt_value}, " # comma
            [ "$_cmd_long" ] && _cmd_fmt_value="${_cmd_fmt_value}--${_cmd_long}" # long
            [ "$_cmd_value" ] && [ "$_cmd_fmt_value" ] && _cmd_fmt_value="${_cmd_fmt_value} " # space
            [ "$_cmd_value" ] && _cmd_fmt_value="${_cmd_fmt_value}<${_cmd_value}>" # value
            [ "$_cmd_tag" = "@PARAM" ] && _cmd_fmt_color="${TXT_YELLOW}" && _cmd_fmt_color_end="${TXT_DEFAULT} " # yellow
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


parse_args() {
    
}


debug() {
    _cmd_metatag_header "$0"
    _cmd_parse_metatag "$_cmd_header"
    while _cmd_parse_metatag; do
        echo "[$_cmd_tag]"
        echo "  short: [$_cmd_short]"
        echo "  long:  [$_cmd_long]"
        echo "  value: [$_cmd_value]"
        echo "  req:   [$_cmd_req]"
        echo "  desc:  [$_cmd_desc]"
        echo ""
    done
}


debug2() {
    _cmd_metatag_header "$0"
    _cmd_metatags="$_cmd_header"
    _cmd_print_help "$0" "$_cmd_metatags" "$DOTFILES/bin/ros._cmds"
}

. $DOTFILES/common/tui.sh
debug2
echo "$_cmd_metatags"

exit 0

















lines="
# @DESC,    Order parts from supplier
# @SWITCH: v,,Verify the order before sending
# @SWITCH: ,free,Request free shipping
# @SWITCH: P,PO,Submit as a purchase order
# @OPTION: p,,Requested price
# @OPTION: ,user,User name,required
# @OPTION: i,id,The item id,required
# @PARAM: item_name,The name of the item to order,required
# @PARAM: backup,Path to backup the order to

"


old_ifs="$IFS"

IFS='
'

# 2. Loop natively through the lines (automatically skips if empty/unset)
for _line in $lines; do
    # Restore standard IFS briefly if needed inside, or use parameter expansions:
    _short_opt="${_line%%,*}"                  # Extracts everything before the first comma
    _rem="${_line#*,}"                          # Trims off everything before the first comma
    _long_opt="${_rem%%,*}"                    # Extracts everything before the second comma
    _description="${_rem#*,}"                  # Extracts everything after the second comma

    # Use your data natively
    echo "Short: $_short_opt | Long: $_long_opt | Info: $_description"
done


IFS="$old_ifs"