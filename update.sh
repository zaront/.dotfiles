#! /bin/sh 

#if installed with git, pull the latest changes
if [ -d "$DOTFILES/.git" ]; then
    cd "$DOTFILES" && git pull

# or, download with git
elif [ -x "$(command -v wget)" ]; then
    wget -qO- https://github.com/zaront/.dotfiles/archive/refs/heads/main.tar.gz | tar -xz -C "$DOTFILES" --strip-components=1

# or, download with curl
elif [ -x "$(command -v curl)" ]; then
    curl -L https://github.com/zaront/.dotfiles/archive/refs/heads/main.tar.gz | tar -xz -C "$DOTFILES" --strip-components=1

# otherwise, print an error message
else
    echo "${TXT_ERROR}${TXT_RED} Dotfiles could not be updated. Missing git, wget, or curl${TXT_DEFAULT}"
    exit 1
fi

# complete
if [ $? -ne 0 ]; then
    echo "${TXT_ERROR}${TXT_RED} Dotfiles failed to update.${TXT_DEFAULT}"
else
    echo "${TXT_SUCCESS}${TXT_GREEN} Dotfiles have been updated${TXT_DEFAULT}"
fi