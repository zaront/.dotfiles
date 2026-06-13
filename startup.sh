# run at the start of a new shell

# add bin to path
export DOTFILES="$HOME/.dotfiles"
export PATH="$DOTFILES/bin:$PATH"


# add support for bash completion
if [ -n "$BASH_VERSION" ]; then
    . "$DOTFILES/bash_completion.sh"
fi


# source config startup - if it exists
if [ -f "$DOTFILES/config/startup.sh" ]; then
    . "$DOTFILES/config/startup.sh"
fi