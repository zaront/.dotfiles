#! /bin/sh 

# path to dotfiles - use parameter, existing path, or default home path
default_path="$HOME/.dotfiles"
export DOTFILES="${1:-${DOTFILES:-$default_path}}"

###################
# DOWNLOAD DOTFILES
###################

# verify that the dotfiles are not already installed
if [ -d "$DOTFILES" ]; then
    echo "dotfiles already installed at '$DOTFILES'"
    exit 1

# clone the dotfiles if git is installed
elif [ -x "$(command -v git)" ]; then
    git clone https://github.com/zaron/dotfiles.git "$DOTFILES"

# download the dotfiles with wget if its installed
elif [ -x "$(command -v wget)" ]; then
    mkdir -p "$DOTFILES" && wget -qO- https://github.com/zaront/.dotfiles/archive/refs/heads/main.tar.gz | tar -xz -C "$DOTFILES" --strip-components=1
 
# download the dotfiles with curl if its installed
elif [ -x "$(command -v curl)" ]; then
    mkdir -p "$DOTFILES" && curl -L https://github.com/zaront/.dotfiles/archive/refs/heads/main.tar.gz | tar -xz -C "$DOTFILES" --strip-components=1

# otherwise, print an error message
else
    echo "Dotfiles could not be installed. Missing git, wget, or curl"
    exit 1
fi


##################
# INSTALL DOTFILES
##################

source_cmd=". \"$DOTFILES/startup.sh\""
if [ "default_path" == "$DOTFILES" ]; then
    source_cmd="$source_cmd \"$DOTFILES\""
fi

# if on bash add sourcing startup.sh to .bashrc if it doesn't already exist
if [ -f "$HOME/.bashrc" ]; then
    if ! grep -q "$source_cmd" "$HOME/.bashrc"; then
        printf "\n$source_cmd\n" >> "$HOME/.bashrc"
    fi

# if on alpine ash add sourcing startup.sh to .profile if it doesn't already exist
elif [ -f "$HOME/.profile" ]; then
    if ! grep -q "$source_cmd" "$HOME/.profile"; then
        printf "\n$source_cmd\n" >> "$HOME/.profile"
    fi
fi
# if no .profile exists, create one
if [ ! -f "$source_cmd" ]; then
    printf "\n$source_cmd\n" > "$HOME/.profile"
    tip=" - [REMINDER] use 'sh -l' to auto source .profile at startup"
fi


# COMPLETE
echo "Dotfiles installed"
echo " - start a new shell"
echo " - then type 'dotfiles' to get started"
if [ -n "$tip" ]; then
    echo "$tip"
fi
