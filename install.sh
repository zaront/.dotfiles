#! /bin/sh 


# DOWNLOAD DOTFILES

# verify that the dotfiles are not already installed
if [ -d "$HOME/.dotfiles" ]; then
    echo "dotfiles already installed"
    exit 1

# clone the dotfiles if git is installed
elif [ -x "$(command -v git)" ]; then
    git clone https://github.com/zaron/dotfiles.git "$HOME/.dotfiles"

# download the dotfiles with wget if its installed
elif [ -x "$(command -v wget)" ]; then
    mkdir -p "$HOME/.dotfiles" && wget -qO- https://github.com/zaront/.dotfiles/archive/refs/heads/main.tar.gz | tar -xz -C "$HOME/.dotfiles" --strip-components=1
 
# download the dotfiles with curl if its installed
elif [ -x "$(command -v curl)" ]; then
    mkdir -p "$HOME/.dotfiles" && curl -L https://github.com/zaront/.dotfiles/archive/refs/heads/main.tar.gz | tar -xz -C "$HOME/.dotfiles" --strip-components=1

# otherwise, print an error message
else
    echo "Dotfiles could not be installed. Missing git, wget, or curl"
    exit 1
fi


# INSTALL DOTFILES

# if on bash add sourcing startup.sh to .bashrc if it doesn't already exist
if [ -f "$HOME/.bashrc" ]; then
    if ! grep -q "source $HOME/.dotfiles/startup.sh" "$HOME/.bashrc"; then
        printf "\nsource %s/.dotfiles/startup.sh\n" "$HOME" >> "$HOME/.bashrc"
    fi

# if on alpine ash add sourcing startup.sh to .profile if it doesn't already exist
elif [ -f "$HOME/.profile" ]; then
    if ! grep -q ". $HOME/.dotfiles/startup.sh" "$HOME/.profile"; then
        printf "\n. %s/.dotfiles/startup.sh\n" "$HOME" >> "$HOME/.profile"
    fi
fi
# if no .profile exists, create one
if [ ! -f "$HOME/.profile" ]; then
    printf "\n. %s/.dotfiles/startup.sh\n" "$HOME" > "$HOME/.profile"
fi


# COMPLETE
echo "Dotfiles installed"
echo " * start a new shell"
echo " * then type 'dotfiles' to get started"
