# desc: Toggle automaticly sourcing ros in each terminal

flag_file="$HOME/.ros_autosource_enabled"

if [ -f "$flag_file" ]; then
    rm "$flag_file"
    echo "ROS Autosource DISABLED. Restart your terminal or type 'rossource' to source manually."
else
    touch "$flag_file"
    echo "ROS Autosource ENABLED. ROS 2 will automatically source in every new terminal."
    # Call it immediately for convenience
    rossource
fi