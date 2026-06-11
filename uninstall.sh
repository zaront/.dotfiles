#! /bin/sh


# UNINSTALL DOTFILES

# if on bash remove sourcing startup.sh from .bashrc if it exists
if [ -f "$HOME/.bashrc" ]; then
    sed -i "\|source $HOME/\.dotfiles/startup\.sh|d" "$HOME/.bashrc"

# if on alpine ash remove sourcing startup.sh to .profile if it exists
elif [ -f "$HOME/.profile" ]; then
    sed -i "\|\. $HOME/\.dotfiles/startup\.sh|d" "$HOME/.profile"
fi 


# REMOVE DOTFILES
rm -rf "$HOME/.dotfiles"


# COMPLETE
echo "Dotfiles have been uninstalled"
