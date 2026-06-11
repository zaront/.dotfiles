# desc: Source ROS2 & workspace

# 1. Dynamically find the first folder inside /opt/ros
default_distro=$(ls -1 /opt/ros 2>/dev/null | head -n 1)

# Fallback to a hardcoded string if /opt/ros is empty or doesn't exist
if [ -z "$default_distro" ]; then
    default_distro="humble"
fi

# 2. Set variables based on parameters or defaults
distro=${1:-$default_distro}
ws_arg=$2

# 3. Source the core ROS 2 installation
if [ -f "/opt/ros/$distro/setup.bash" ]; then
    . "/opt/ros/$distro/setup.bash"
    echo "Sourced ROS 2 $distro"
else
    echo "Error: ROS 2 $distro not found at /opt/ros/$distro"
    # Safely handle exits whether this script is executed or sourced
    (return 0 2>/dev/null) && return 1 || exit 1
fi

# 4. Source workspace based on argument or current directory
if [ -n "$ws_arg" ]; then
    # Explicit path provided by user
    if [ -f "$ws_arg/install/setup.bash" ]; then
        . "$ws_arg/install/setup.bash"
        echo "Sourced workspace: $ws_arg"
    else
        echo "Warning: Workspace not found at $ws_arg/install/setup.bash"
    fi
elif [ -f "install/setup.bash" ]; then
    # Fallback to current working directory
    . "install/setup.bash"
    echo "Sourced local workspace: $(pwd)"
fi
