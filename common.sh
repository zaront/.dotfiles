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




##############
# INI Helpers
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
