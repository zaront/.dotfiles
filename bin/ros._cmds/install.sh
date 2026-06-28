# @DESC: Install ROS 2 distro

. $DOTFILES/common.sh
parse_options "$0" "$@"


# select ROS 2 distro
prompt_choice "ROS 2 Distro" "humble"
case "$REPLY" in
    1) distro="humble";;
esac
# verify its not already installed
if [ -d "/opt/ros/$distro" ]; then
    echo "ROS 2 $distro is already installed at /opt/ros/$distro"
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
    if [ "$ENVIORMENT" = "termux" ]; then
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
            echo "  In a new shell type 'ubuntu' to login"
            echo "  Then reinstall .dotfiles and rerun 'ros. install'"
        fi
    fi
    exit 1
fi
if [ "$VERSION" != "$required_version" ]; then
    echo "Your version of Ubuntu is $VERSION"
    echo "ROS 2 $distro is only supported on Ubuntu:${required_version}"
    exit 1
fi


install_humble() {

}



# start install
case "$distro" in
    humble) install_humble;;
esac
