# @DESC: Toggle a server on or off

. $DOTFILES/common.sh
parse_options "$0" "$@"

# validate ssh installed
if ! command -v sshd > /dev/null 2>&1; then
    echo "sshd command not found"
    echo "please install openssh"
    exit 1
fi

if ps -A -o comm= | grep -x "sshd" > /dev/null 2>&1; then
    # sshd is running
    echo "shutdown ssh server"
    pkill sshd
    [ command -v termux-wake-unlock > /dev/null 2>&1 ] && termux-wake-unlock
else
    # sshd is not running
    echo "server on - run again to turn off."
    echo "Note: this will run in the background even when the app is quit."
    echo user: $(whoami)
    echo pass: <to do>
    sshd
    [ command -v termux-wake-lock > /dev/null 2>&1 ] && termux-wake-lock
fi
