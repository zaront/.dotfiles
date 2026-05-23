#! /bin/sh


# UNINSTALL DOTFILES

# if on bash remove sourcing shstart.sh from .bashrc if it exists
if [ -f "$HOME/.bashrc" ]; then
    sed -i '/\. "$HOME\/.dotfiles\/shstart.sh"/d' "$HOME/.bashrc"

# if on alpine ash remove sourcing shstart.sh to .profile if it exists
elif [ -f "$HOME/.profile" ]; then
    sed -i '/\. "export ENV='$HOME\/.dotfiles\/shstart.sh'"/d' "$HOME/.profile"
fi 


# REMOVE DOTFILES
rm -rf "$HOME/.dotfiles"


# COMPLETE
echo "Dotfiles have been uninstalled"
