# @DESC: Toggle auto-sourcing ROS2 & workspaces
# @SWITCH: r,,Remove rossource auto-source from your shell

. $DOTFILES/common.sh

parse_options "$0" "$@"

if [ "$r" = true ]; then
    unset_startup "auto-source"
    unset_flag "auto-source"
    echo "Removed rossource & auto-source from your shell"
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
    echo "ROS2 auto-source DISABLED."
else
    set_flag "auto-source"
    echo "ROS2 auto-source ENABLED. ROS 2 will automatically source in every new shell."
fi
echo "  *Type 'rossource' to source manually & at the root of a workspace to source it"
