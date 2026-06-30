
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
