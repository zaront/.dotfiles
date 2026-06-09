#! /bin/sh
# desc: Update your .dotfiles to the latest version from github

#if installed with git, pull the latest changes
if [ -d "$HOME/.dotfiles/.git" ]; then
    cd "$HOME/.dotfiles" && git pull

#otherwize us wget or curl to download the latest version and overwrite the existing files
else

    # download the dotfiles with wget if its installed
    if [ -x "$(command -v wget)" ]; then
        wget -qO- https://github.com/zaront/.dotfiles/archive/refs/heads/main.tar.gz | tar -xz -C "$HOME/.dotfiles" --strip-components=1

# download the dotfiles with curl if its installed
    elif [ -x "$(command -v curl)" ]; then
        curl -L https://github.com/zaront/.dotfiles/archive/refs/heads/main.tar.gz | tar -xz -C "$HOME/.dotfiles" --strip-components=1

    # otherwise, print an error message
    else
        echo "Dotfiles could not be updated. Missing git, wget, or curl"
        exit 1
    fi
fi

# complete
echo "Dotfiles have been updated"
