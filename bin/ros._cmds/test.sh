
. $DOTFILES/common.sh

run_subcommand "$0" "$@"

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

