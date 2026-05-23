# common helper functions for dotfiles


run_subcommand() {
    SCRIPT_PATH="${1:-${BASH_SOURCE:-$0}}"
    shift
    
    BASE_DIR=$(dirname "$SCRIPT_PATH")
    WRAPPER_NAME=$(basename "$SCRIPT_PATH")
    CMDS_DIR="$BASE_DIR/${WRAPPER_NAME}_cmds"

    show_generic_help() {
        # 1. Read the description of the main wrapper script itself
        MAIN_DESC=$(sed -n "s/^# *desc: *//p" "$SCRIPT_PATH" 2>/dev/null)
        
        # 2. Print the global script description first if it exists
        if [ -n "$MAIN_DESC" ]; then
            printf "%s\n\n" "$MAIN_DESC"
        fi
        
        # 3. Print the usage line
        printf "Usage: %s [command] [arguments...]\n\n" "$WRAPPER_NAME"
        printf "Available commands:\n"
        
        # 4. List the subcommands
        if [ -d "$CMDS_DIR" ]; then
            for file in "$CMDS_DIR"/*; do
                if [ -x "$file" ] && [ -f "$file" ]; then
                    CMD_NAME="${file##*/}"
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
    CMD_PATH="$CMDS_DIR/$SUB_CMD"

    if [ -x "$CMD_PATH" ] && [ -f "$CMD_PATH" ]; then
        exec "$CMD_PATH" "$@"
    else
        printf "Error: '%s' is not a valid %s command.\n" "$SUB_CMD" "$WRAPPER_NAME" >&2
        printf "Run '%s --help' to see available options.\n" "$WRAPPER_NAME" >&2
        return 1
    fi
}
