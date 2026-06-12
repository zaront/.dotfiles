# @DESC: test command
# @SWITCH: v,,Enable verbose debugging
# @PARAM: target_env,The name of the target server environment

. $DOTFILES/common.sh

parse_options "$0" "$@"

if [ "$v" = true ]; then
    echo "Verbose on test (1)"
fi

exec_command

if [ "$v" = true ]; then
    echo "Verbose on test (2)"
fi

BASE_DIR=$DOTFILES/config


VALUE=$(get_ini_value "test" "test" "$BASE_DIR/test.ini")
echo $VALUE
set_ini_value "test" "test" "test" "$BASE_DIR/test.ini"

VALUE=$(get_ini_value "test" "test" "$BASE_DIR/test.ini")
echo $VALUE

set_flag "test"
if get_flag "test"; then
    echo "test flag is set"
fi

# unset_flag "test"
if get_flag "test"; then
    echo "test flag is set"
fi

