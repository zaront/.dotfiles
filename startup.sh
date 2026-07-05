# run at the start of a new shell

# set dotfiles directory - using existing path, first parmeter, or default home path
export DOTFILES="${1:-${DOTFILES:-$HOME/.dotfiles}}"
# add bin to path
export PATH="$PATH:$DOTFILES/bin"


# add support for bash completion
if [ -n "$BASH_VERSION" ]; then
    . "$DOTFILES/bash_completion.bash"
fi


# source all config startup.d files
if [ -d "$DOTFILES/config/startup.d" ]; then
    eval "$(find "$DOTFILES/config/startup.d" -type f -name "*.sh" -exec printf '. "%s"\n' {} +)" # executs all startup scripts
fi