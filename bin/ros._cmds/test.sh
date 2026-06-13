# @DESC: test command
# @SWITCH: v,,Enable verbose debugging
# @PARAM: target_env,The name of the target server environment

. $DOTFILES/common.sh
set_flag "tesfFlag"

parse_options "$0" "$@"

if [ "$v" = true ]; then
    echo "Verbose on test (1)"
fi

exec_command

if [ "$v" = true ]; then
    echo "Verbose on test (2)"
fi

if [ -n "$target_env" ]; then
    echo "Target environment: $target_env"
fi




key="test/test2/test3"



#set_flag "test"
if get_flag "test"; then
    echo "set flag"
fi


if ! get_flag "test"; then
    echo "removed flag"
fi



VALUE=$(get_value "$key")
echo prev: $VALUE

set_value "$key" ""
VALUE=$(get_value "$key")
echo new: $VALUE

# set_startup "echo startup test"
# set_startup "echo startup test"
# set_startup "echo startup test"
# set_startup "echo startup test"
if get_startup "echo startup test"; then
    echo "Startup command is set"
fi
#unset_startup "echo startup test"


script='
echo "Starting my system setup..."
if [ -d "$HOME/bin" ]; then
    echo "Bin path exists."
fi
'

# set_startup "$script"
# set_startup "$script"
# set_startup "$script"
# unset_startup "$script"


read_template "test"