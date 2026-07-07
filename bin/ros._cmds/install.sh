# @DESC: Install ROS 2 distro

. $DOTFILES/common.sh
parse_args "$0" "$@"


# select ROS 2 distro
prompt_menu "Select a ROS Distro" "humble"
distro="$REPLY"

# verify its not already installed
if [ -d "/opt/ros/$distro" ]; then
    print_error "$distro is already installed at /opt/ros/$distro"
    exit 1
fi

# required version
case "$distro" in
    humble) required_version="22.04";;
esac

# verify ubuntu version
get_system_info
if [ "$OS" != "ubuntu" ]; then
    echo "ROS 2 $distro is only supported on Ubuntu:${required_version}"
    if [ "$ENVIRONMENT" = "termux" ]; then
        echo "Your on termux"
        echo "You can install Ubuntu on Termux with proot-distro"
        echo "  pkg install proot-distro"
        echo "  proot-distro install ubuntu:${required_version}"
        echo ""
        prompt_confirm "Install Ubuntu on Termux?"
        if [ "$REPLY" = "y" ]; then
            pkg install proot-distro
            proot-distro install ubuntu:${required_version}
            # add an alias to .bashrc
            echo "alias ubuntu='proot-distro login ubuntu'" >> $HOME/.bashrc
            echo "proot and ubuntu are installed"
            print_info "  In a new shell type 'ubuntu' to login"
            print_info "  Then reinstall .dotfiles and rerun 'ros. install'"
        fi
    fi
    exit 1
fi
if [ "$VERSION" != "$required_version" ]; then
    print_info "Your version of Ubuntu is $VERSION"
    print_error "ROS 2 $distro is only supported on Ubuntu:${required_version}"
    exit 1
fi


install_humble() {
    exit
}



# start install
print_info "Installing ROS $distro..."
case "$distro" in
    humble) install_humble;;
esac
