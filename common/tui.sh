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
else
    TXT_SUCCESS="${TXT_GREEN}${TXT_BOLD}[SUCCESS]${TXT_DEFAULT}"
    TXT_WARNING="${TXT_YELLOW}${TXT_BOLD}[WARNING]${TXT_DEFAULT}"
    TXT_FAILURE="${TXT_RED}${TXT_BOLD}[FAILURE]${TXT_DEFAULT}"
    TXT_ERROR="${TXT_RED}${TXT_BOLD}[ERROR]${TXT_DEFAULT}"
    TXT_INFO="${TXT_BLUE}${TXT_BOLD}[INFO]${TXT_DEFAULT}"
    TXT_OK="${TXT_BOLD}[OK]${TXT_DEFAULT}"
    TXT_READY="${TXT_BOLD}${TXT_YELLOW}[!]${TXT_DEFAULT}"
    TXT_ATTENTION="${TXT_BOLD}${TXT_RED}[!]${TXT_DEFAULT}"
    TXT_BULLET="*"
fi

print_error() {
    printf -- "${TXT_ERROR} ${TXT_RED}$1${TXT_DEFAULT}\n" >&2
}
print_success() {
    printf -- "${TXT_SUCCESS} ${TXT_GREEN}$1${TXT_DEFAULT}\n"
}
print_warning() {
    printf -- "${TXT_WARNING} ${TXT_YELLOW}$1${TXT_DEFAULT}\n"
}
print_info() {
    printf -- "${TXT_BLUE}$1${TXT_DEFAULT}\n"
}


prompt_choice() {
    # Isolate the first argument as a custom title header
    _tui_title="$1"
    shift # Remove the title from the argument stack so only options remain
    
    while true; do 
        # Display the custom title safely
        printf '%s\n' "" "=== $_title ===" 
        
        # 1. Dynamically loop through arguments to print the menu numbers 
        _tui_index=1 
        for _tui_opt in "$@"; do 
            printf '%d) %s\n' "$_tui_index" "$_tui_opt" 
            _tui_index=$((_index + 1)) 
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
