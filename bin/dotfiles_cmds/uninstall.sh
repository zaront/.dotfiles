# @DESC: Uninstall .dotfiles

. "$DOTFILES/common.sh"

#confirm unistall
prompt_confirm "Are you sure you want to uninstall .dotfiles?"
if [ "$REPLY" = "y" ]; then
    # run uninstall script
    . "$DOTFILES/uninstall.sh"
fi