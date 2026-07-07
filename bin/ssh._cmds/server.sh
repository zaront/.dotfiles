# @DESC: Toggle a server on or off (termux only)

. $DOTFILES/common.sh
parse_args "$0" "$@"

get_system_info

if [ "$ENVIRONMENT" = "termux" ]; then

    # insure sshd installed
    if ! command -v sshd > /dev/null 2>&1; then
        echo "sshd command required, but not found"
        prompt_confirm "install openssh"
        if [ "$REPLY" != "n" ]; then
            exit 1
        fi
        pkg install openssh
    fi

    # insure termux-wifi-connectioninfo installed
    if ! command -v termux-wifi-connectioninfo > /dev/null 2>&1; then
        echo "termux-wifi-connectioninfo command required, but not found"
        prompt_confirm "install termux-wifi-connectioninfo"
        if [ "$REPLY" != "n" ]; then
            exit 1
        fi
        pkg install termux-api
    fi

    if ps -A -o comm= | grep -x "sshd" > /dev/null 2>&1; then
        # shodown ssh server
        print_warning "shutdown ssh server"
        pkill sshd
        termux-wake-unlock
    else
        # start ssh server
        ip=$(termux-wifi-connectioninfo | grep -oP '"ip":\s*"\K[^"]+')
        user=$(whoami)
        print_success "server on - run again to turn off."
        print_info "Note: this will run in the background even when the app is quit."
        echo "user: $user"
        echo "host: $ip"
        echo "port: 8022"
        print_info "to connect run 'ssh $user@$ip -p 8022' from another client"
        sshd
        termux-wake-lock
    fi
    exit 0
fi

print_error "this only runs on termux"
exit 1
