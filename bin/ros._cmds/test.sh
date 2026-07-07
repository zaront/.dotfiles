

. $DOTFILES/common.sh

run_args "$0" "$@"



prompt_choice "Test" "Aaaa" "Bbbbbbb" "C"
echo "You selected $REPLY"