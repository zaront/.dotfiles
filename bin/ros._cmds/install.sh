# show a posix compliant menu to configure ROS 2 Humble install options, including:
# - ROS 2 distribution (default to humble)
# - # OPTIONALY INCLUDE A DEFAULT workspace

# Usage: ros._cmds/install.sh
# Example: ros._cmds/install.sh

. $DOTFILES/common.sh

parse_options "$0" "$@"



#allow the user to choose a ROS 2 distro
prompt_choice "ROS 2 Distro" "humble" "foxy" "rolling" "galactic" "humble"
case "$REPLY" in
    1) distro="humble";;
    2) distro="foxy";;
    3) distro="rolling";;
    4) distro="galactic";;
    5) distro="humble";;
esac
echo your choice is $distro