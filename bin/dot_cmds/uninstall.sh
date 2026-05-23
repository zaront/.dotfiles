#! /bin/sh
# desc: Uninstall .dotfiles

#confirm unistall
echo "Are you sure you want to uninstall .dotfiles? (y/n)"
read -r response
if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
    # run uninstall script
    . "$HOME/.dotfiles/uninstall.sh"
fi