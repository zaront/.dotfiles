
. $DOTFILES/common.sh

BASE_DIR=$DOTFILES/config


VALUE=$(get_ini_value "test" "test" "$BASE_DIR/test.ini")
echo $VALUE
set_ini_value "test" "test" "test" "$BASE_DIR/test.ini"

VALUE=$(get_ini_value "test" "test" "$BASE_DIR/test.ini")
echo $VALUE

run_subcommand "$0" "$@"