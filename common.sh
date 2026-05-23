# common helper functions for dotfiles


run_subcommand() {
    SCRIPT_PATH="${1:-${BASH_SOURCE:-$0}}"
    shift
    
    BASE_DIR=$(dirname "$SCRIPT_PATH")
    WRAPPER_NAME=$(basename "$SCRIPT_PATH")
    CMDS_DIR="$BASE_DIR/${WRAPPER_NAME}_cmds"

    show_generic_help() {
        MAIN_DESC=$(sed -n "s/^# *desc: *//p" "$SCRIPT_PATH" 2>/dev/null)
        
        if [ -n "$MAIN_DESC" ]; then
            printf "%s\n\n" "$MAIN_DESC"
        fi
        
        printf "Usage: %s [command] [arguments...]\n\n" "$WRAPPER_NAME"
        printf "Available commands:\n"
        
        if [ -d "$CMDS_DIR" ]; then
            for file in "$CMDS_DIR"/*.sh; do
                if [ -f "$file" ]; then
                    FULL_NAME="${file##*/}"
                    CMD_NAME="${FULL_NAME%.sh}"
                    
                    DESC=$(sed -n "s/^# *desc: *//p" "$file" 2>/dev/null)
                    if [ -z "$DESC" ]; then
                        DESC="No description available."
                    fi
                    
                    printf "  %-15s %s\n" "$CMD_NAME" "$DESC"
                fi
            done
        else
            printf "  (No commands found. Directory %s_cmds does not exist)\n" "$WRAPPER_NAME"
        fi
    }

    if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_generic_help
        return 0
    fi

    SUB_CMD="$1"
    shift
    
    CMD_PATH="$CMDS_DIR/${SUB_CMD}.sh"

    # Validate that the targeted .sh file actually exists
    if [ -f "$CMD_PATH" ]; then
        # Dynamically select the interpreter based on the host shell environment
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
