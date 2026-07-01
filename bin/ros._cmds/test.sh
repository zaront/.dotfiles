# @DESC: Order parts from supplier
# @SWITCH: v,,Verify the order before sending
# @SWITCH: ,free,Request free shipping
# @SWITCH: P,PO,Submit as a purchase order
# @OPTION: p,,Requested price
# @OPTION: ,user,User name,required
# @OPTION: i,id,The item id,required
# @PARAM: item_name,The name of the item to order,required
# @PARAM: backup,Path to backup the order to

. $DOTFILES/common.sh

run_subcommand "$0" "$@"

get_system_info
print_error "System info: $ENVIRONMENT, $CONTAINER, $ARCH, $OS, $VERSION"
echo $TXT_OK this is OK
printf "  ${TXT_BULLET} This is a test\n"