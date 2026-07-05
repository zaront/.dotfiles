# @DESC: Toggle auto-sourcing ROS2 & workspaces
#
# run it once to enable auto-sourcing in each new shell
# run it again to disable auto-sourcing
# @SWITCH: -r, Remove rossource auto-source from your shell

. $DOTFILES/common.sh

parse_args "$0" "$@"

if [ -n "$r" ]; then
    unset_startup "auto-source"
    unset_flag "auto-source"
    print_success "Removed rossource & auto-source from your shell"
    exit 0
fi

# setup auto-source for the first time
if ! get_startup "auto-source"; then
    get_template "auto-source"
    set_startup "auto-source" "$TEMPLATE"
fi

# toggle auto-source
if get_flag "auto-source"; then
    unset_flag "auto-source"
    print_warning "auto-source DISABLED."
else
    set_flag "auto-source"
    print_success "auto-source ENABLED. ROS 2 will automatically source in every new shell."
fi
print_info "  ${TXT_BULLET} Type 'rossource' to source manually \n     will source a workspace if within its folder"
