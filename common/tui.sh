#################
# Text UI Helpers
#################


# source only once
[ -n "$_tui_sourced" ] && return 0
_tui_sourced=1


# set the NO_COLOR & NO_EMOJI flag
# not connected to terminal
if [ ! -t 1 ]; then
    NO_COLOR=1
    NO_EMOJI=1
else
    # no color support
    if [ -z "$NO_COLOR" ]; then
        case "$TERM" in
            *color*|*colors*|*ansi*|xterm*|screen*|tmux*|vt100*|linux)
                ;;
            *)
                export NO_COLOR=1
                ;;
        esac
    fi
    # no emoji support
    if [ -z "$NO_EMOJI" ]; then
        _tui_emoji_ok=0
        # emoji terminals - intercepts and displays emoji even if the os doesn't support emojis
        case "$TERM_PROGRAM" in
            Apple_Terminal|iTerm.app|vscode|WarpTerminal) _tui_emoji_ok=1 ;;
        esac
        # supports UTF-8
        if [ "$(printf '€' | wc -m)" -eq 1 ]; then
            # Windows Terminal
            if [ -n "$WT_SESSION" ]; then
                _tui_emoji_ok=1
            fi
            # Check general terminal types if program signatures didn't match
            if [ "$_tui_emoji_ok" -eq 0 ]; then
                case "$TERM" in
                    xterm-kitty|alacritty|foot|st*) _tui_emoji_ok=1 ;;
                    *256color*|xterm*|screen*|tmux*) _tui_emoji_ok=1 ;;
                esac
            fi
        fi
        if [ "$_tui_emoji_ok" -eq 0 ]; then
            NO_EMOJI=1
        fi
    fi
fi
unset _tui_emoji_ok


update_colors() {
    # setup colors
    if [ -z "$NO_COLOR" ]; then
        TXT_RED='\033[0;31m'
        TXT_GREEN='\033[0;32m'
        TXT_BLUE='\033[0;34m'
        TXT_YELLOW='\033[0;33m'
        TXT_PURPLE='\033[0;35m'
        TXT_GRAY='\033[0;90m'
        TXT_BOLD='\033[1m'
        TXT_DEFAULT='\033[0m'
    fi

    # setup emoji
    if [ -z "$NO_EMOJI" ]; then
        TXT_SUCCESS='✅'
        TXT_WARNING='⚠️'
        TXT_FAILURE='❌'
        TXT_ERROR='❌'
        TXT_INFO='💡'
        TXT_OK='👍'
        TXT_READY='🚀'
        TXT_ATTENTION='🚨'
        TXT_BULLET='🔹'
        TXT_QUESTION='❓'
    else
        TXT_SUCCESS="${TXT_GREEN}${TXT_BOLD}[SUCCESS]${TXT_DEFAULT}"
        TXT_WARNING="${TXT_YELLOW}${TXT_BOLD}[WARNING]${TXT_DEFAULT}"
        TXT_FAILURE="${TXT_RED}${TXT_BOLD}[FAILURE]${TXT_DEFAULT}"
        TXT_ERROR="${TXT_RED}${TXT_BOLD}[ERROR]${TXT_DEFAULT}"
        TXT_INFO="${TXT_BLUE}${TXT_BOLD}[INFO]${TXT_DEFAULT}"
        TXT_OK="${TXT_BOLD}[OK]${TXT_DEFAULT}"
        TXT_READY="${TXT_BOLD}${TXT_YELLOW}[!]${TXT_DEFAULT}"
        TXT_ATTENTION="${TXT_BOLD}${TXT_RED}[!]${TXT_DEFAULT}"
        TXT_BULLET="-"
    fi
}
update_colors


print_error() {
    printf -- "${TXT_ERROR} ${TXT_RED}$1${TXT_DEFAULT}\n" >&2
}
print_success() {
    printf -- "${TXT_SUCCESS} ${TXT_GREEN}$1${TXT_DEFAULT}\n"
}
print_warning() {
    printf -- "${TXT_WARNING}  ${TXT_YELLOW}$1${TXT_DEFAULT}\n"
}
print_info() {
    printf -- "${TXT_BLUE}$1${TXT_DEFAULT}\n"
}


# $1 = title
# $2... = options
# Returns: REPLY = the name of the selected option
prompt_choice() {
    _title="$1"; shift
    printf "${TXT_YELLOW}=== %s ===${TXT_DEFAULT}\n" "$_title"
    
    _idx=1; for _opt in "$@"; do
        printf '%d) %s\n' "$_idx" "$_opt"; _idx=$((_idx + 1))
    done
    printf "${TXT_GRAY}%*s${TXT_DEFAULT}\n" "$((${#_title} + 8))" '' | tr ' ' '-'

    _has_err=0

    # TRAP: If the user presses Ctrl+C, handle cursor alignment and print cancellation message
    trap '
        if [ "$_has_err" -eq 1 ]; then
            # Cursor is on prompt line; drop to error line, clear it, and print notice
            printf "\033[B\r\033[K${TXT_RED}User canceled.${TXT_DEFAULT}\n"
        else
            # No error was visible; cursor is on a fresh new line already, just print notice
            printf "\r\033[K${TXT_RED}User canceled.${TXT_DEFAULT}\n"
        fi
        exit 130
    ' INT

    while true; do
        printf 'Choice [1-%d]: ' "$#"; read -r REPLY

        # Validate input safely
        case "$REPLY" in
            *[!0-9]*|"") _err="Invalid input. Please enter a valid number." ;;
            *) [ "$REPLY" -ge 1 ] && [ "$REPLY" -le "$#" ] && _err="" || \
               _err="Out of range. Please choose between 1 and $#." ;;
        esac

        if [ -n "$_err" ]; then
            [ "$_has_err" -eq 1 ] && printf "\r\033[K"
            printf "${TXT_RED}%s${TXT_DEFAULT}\n\033[2A\r\033[K" "$_err"
            _has_err=1
        else
            # Clear error in-place, move up to clean prompt, then drop down 1 line
            [ "$_has_err" -eq 1 ] && printf "\r\033[K\033[A\r\033[B"
            
            # Reset trap to default behavior before returning so it does not affect the rest of the script
            trap - INT
            printf '%s\n' "$REPLY" && return 0
        fi
    done
}


# Helper to capture single keystrokes in POSIX sh
_tui_get_key() {
    _tui_old_stty=$(stty -g)
    stty -icanon -echo min 1 time 0
    _tui_byte=$(dd bs=1 count=1 2>/dev/null)
    if [ "$_tui_byte" = "$(printf '\033')" ]; then
        _tui_seq=$(dd bs=1 count=2 2>/dev/null)
        case "$_tui_seq" in
            "[A") echo "UP" ;;
            "[B") echo "DOWN" ;;
            *)    echo "ESC" ;;
        esac
    elif [ "$_tui_byte" = "$(printf '\n')" ] || [ -z "$_tui_byte" ]; then
        echo "ENTER"
    fi
    stty "$_tui_old_stty"
}

# $1 = title
# $2... = options
# Returns: REPLY = the name of the selected option
prompt_menu() {
    _tui_title="$1"; shift
    _tui_total_opts=$#
    _tui_current_sel=1

    # TRAP: Restore terminal and print cancellation notice below the menu + separator
    trap '
        stty echo icanon 2>/dev/null
        # Move down past choices and the 1-line dashed separator at the bottom
        _tui_lines_to_jump=$((_tui_total_opts - _tui_current_sel + 2))
        printf "\033[%dB\r${TXT_RED}User canceled.${TXT_DEFAULT}\n" "$_tui_lines_to_jump"
        exit 130
    ' INT

    # Render Menu Title Header
    printf "${TXT_YELLOW}=== %s ===${TXT_DEFAULT}\n" "$_tui_title"

    while true; do
        # 1. Redraw menu options
        _tui_idx=1
        for _tui_opt in "$@"; do
            if [ "$_tui_idx" -eq "$_tui_current_sel" ]; then
                printf " \033[7m> %s\033[0m\n" "$_tui_opt"
            else
                printf "   %s\n" "$_tui_opt"
            fi
            _tui_idx=$((_tui_idx + 1))
        done

        # 2. Draw the dynamic separator line at the bottom of the options stack
        printf "${TXT_GRAY}%*s${TXT_DEFAULT}\n" "$((${#_tui_title} + 8))" '' | tr ' ' '-'

        # 3. Wait for user input
        _tui_key=$(_tui_get_key)

        # 4. Process key actions
        case "$_tui_key" in
            "UP")
                _tui_current_sel=$((_tui_current_sel - 1))
                [ "$_tui_current_sel" -lt 1 ] && _tui_current_sel=$_tui_total_opts
                ;;
            "DOWN")
                _tui_current_sel=$((_tui_current_sel + 1))
                [ "$_tui_current_sel" -gt "$_tui_total_opts" ] && _tui_current_sel=1
                ;;
            "ENTER")
                trap - INT
                
                # Move cursor down past the remaining options and the bottom dashed line
                _tui_lines_to_bottom=$((_tui_total_opts - _tui_current_sel + 2))
                printf "\033[%dB\r" "$_tui_lines_to_bottom"
                
                # Dynamic POSIX way to get the text value at the selected index
                eval "REPLY=\${$_tui_current_sel}"
                return 0
                ;;
        esac

        # 5. Reset cursor position to the top of the option block (+1 for separator line)
        printf "\033[%dA" "$((_tui_total_opts + 1))"
    done
}


# $1 = prompt
# Returns: REPLY ="y" or "n"
prompt_confirm() {
    printf -- "${TXT_QUESTION}${TXT_YELLOW}%s ${TXT_GRAY}[Y/n]${TXT_DEFAULT} " "$1"
    read -r REPLY
    [ -z "$REPLY" ] || [ "$REPLY" = 'y' ] || [ "$REPLY" = 'Y' ] && REPLY="y" || REPLY="n"
}
