# desc: Kill ros2 processes & reset service

pkill -f webots_ros2_driver
killall -9 _ros2_daemon python3 spawner robot_state_publisher
ros2 daemon stop
ros2 daemon start