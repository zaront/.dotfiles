# run at the start of a new shell

# set dotfiles directory - using existing path, first parmeter, or default home path
export DOTFILES="${1:-${DOTFILES:-$HOME/.dotfiles}}"
# add bin to path
export PATH="$PATH:$DOTFILES/bin"


# add support for bash completion
if [ -n "$BASH_VERSION" ]; then
    . "$DOTFILES/bash_completion.bash"
fi


# source config startup - if it exists
if [ -f "$DOTFILES/config/startup.sh" ]; then
    . "$DOTFILES/config/startup.sh"
fi