
. $HOME/.dotfiles/common.sh

BASE_DIR=$HOME/.dotfiles/bin/rosh_cmds
echo $BASE_DIR

VALUE=$(get_ini_value "test" "test" "$BASE_DIR/test.ini")
echo $VALUE
set_ini_value "test" "test" "test" "$BASE_DIR/test.ini"

VALUE=$(get_ini_value "test" "test" "$BASE_DIR/test.ini")
echo $VALUE
