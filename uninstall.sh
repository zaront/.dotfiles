#! /bin/sh

#verify $DOTFILES is set
if [ -z "$DOTFILES" ]; then
    echo "[ERROR] DOTFILES environment variable is not set"
    exit 1
fi

####################
# UNINSTALL DOTFILES
####################

# if on bash remove sourcing startup.sh from .bashrc if it exists
if [ -f "$HOME/.bashrc" ]; then
    sed -i "\|\. \"$DOTFILES/startup\.sh\"|d" "$HOME/.bashrc"

# if on alpine ash remove sourcing startup.sh to .profile if it exists
elif [ -f "$HOME/.profile" ]; then
    sed -i "\|\. \"$DOTFILES/startup\.sh\"|d" "$HOME/.profile"
fi 


# REMOVE DOTFILES
#rm -rf "$DOTFILES"


# COMPLETE
echo "Dotfiles have been uninstalled"
