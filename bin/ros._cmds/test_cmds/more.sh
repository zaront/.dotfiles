# @DESC: My custom configuration script.
# @SWITCH: v,verbose,Enable verbose debugging
# @OPTION: user,The deployment database user account
# @PARAM: target_env,The name of the target server environment
# @PARAM: log_dir,Path to write transaction logs

# desc: more testing
. "$HOME/.dotfiles/common.sh"

parse_options "$0" "$@"

if [ "$v" = true ]; then
    echo "Verbose on more"
fi

if [ -n "$user" ]; then
    echo "User: $user"
fi

if [ -n "$target_env" ]; then
    echo "Target environment: $target_env"
fi

if [ -n "$log_dir" ]; then
    echo "Log directory: $log_dir"
fi

