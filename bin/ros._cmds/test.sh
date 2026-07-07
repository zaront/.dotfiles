

. $DOTFILES/common.sh

run_args "$0" "$@"

get_system_info
print_error "System info: $ENVIRONMENT, $CONTAINER, $ARCH, $OS, $VERSION"
echo $TXT_OK this is OK
printf "  ${TXT_BULLET} This is a test\n"

prompt_select "Test" "Aaaa" "Bbbbbbb" "C"