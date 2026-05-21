#!/bin/bash
###############################################################################
# AtlasArm-6 Launch File Fix
# Patches display.launch.py and atlasarm6_gazebo.launch.py to use
# ParameterValue wrapper required by ROS2 Humble.
#
# Usage:
#   wget https://raw.githubusercontent.com/laborbeekaambefikar-ship-it/Atlas/atlasarm6/atlasarm6_install/fix_launch_files.sh
#   bash fix_launch_files.sh
###############################################################################
set -e

WS="${1:-$HOME/atlasarm6_ws}"
SRC="$WS/src"

echo "Patching launch files in $SRC..."

# Fix 1: display.launch.py
cat > "$SRC/atlasarm_description/launch/display.launch.py" << 'EOF'
"""Display AtlasArm-6 in RViz with joint sliders."""
from launch import LaunchDescription
from launch_ros.actions import Node
from launch.substitutions import Command, PathJoinSubstitution
from launch_ros.substitutions import FindPackageShare
from launch_ros.parameter_descriptions import ParameterValue


def generate_launch_description():
    pkg = FindPackageShare('atlasarm_description')
    xacro_file = PathJoinSubstitution([pkg, 'urdf', 'atlasarm6.urdf.xacro'])
    rviz_cfg = PathJoinSubstitution([pkg, 'rviz', 'atlasarm6.rviz'])
    robot_desc = ParameterValue(Command(['xacro ', xacro_file]), value_type=str)

    return LaunchDescription([
        Node(
            package='robot_state_publisher',
            executable='robot_state_publisher',
            parameters=[{'robot_description': robot_desc}],
        ),
        Node(
            package='joint_state_publisher_gui',
            executable='joint_state_publisher_gui',
        ),
        Node(
            package='rviz2',
            executable='rviz2',
            arguments=['-d', rviz_cfg],
        ),
    ])
EOF
echo "  Fixed: atlasarm_description/launch/display.launch.py"

# Fix 2: atlasarm6_gazebo.launch.py
cat > "$SRC/atlasarm_bringup/launch/atlasarm6_gazebo.launch.py" << 'EOF'
"""Launch Gazebo + AtlasArm-6 + ros2_control."""
import os
from launch import LaunchDescription
from launch.actions import ExecuteProcess, RegisterEventHandler, TimerAction
from launch.event_handlers import OnProcessExit
from launch_ros.actions import Node
from launch.substitutions import Command
from launch_ros.parameter_descriptions import ParameterValue
from ament_index_python.packages import get_package_share_directory


def generate_launch_description():
    desc_pkg = get_package_share_directory('atlasarm_description')
    gz_pkg = get_package_share_directory('atlasarm_gazebo')

    xacro_file = os.path.join(desc_pkg, 'urdf', 'atlasarm6.urdf.xacro')
    world_file = os.path.join(gz_pkg, 'worlds', 'atlasarm6_workspace.world')
    robot_desc = ParameterValue(Command(['xacro ', xacro_file]), value_type=str)

    rsp = Node(
        package='robot_state_publisher',
        executable='robot_state_publisher',
        output='screen',
        parameters=[{'robot_description': robot_desc, 'use_sim_time': True}],
    )

    gazebo = ExecuteProcess(
        cmd=['gazebo', '--verbose', world_file,
             '-s', 'libgazebo_ros_init.so',
             '-s', 'libgazebo_ros_factory.so'],
        output='screen',
    )

    spawn = Node(
        package='gazebo_ros',
        executable='spawn_entity.py',
        arguments=['-topic', 'robot_description',
                   '-entity', 'atlasarm6',
                   '-x', '0', '-y', '0', '-z', '0'],
        output='screen',
    )

    load_jsb = ExecuteProcess(
        cmd=['ros2', 'control', 'load_controller', '--set-state', 'active',
             'joint_state_broadcaster'],
        output='screen',
    )

    load_arm = ExecuteProcess(
        cmd=['ros2', 'control', 'load_controller', '--set-state', 'active',
             'atlasarm6_arm_controller'],
        output='screen',
    )

    return LaunchDescription([
        rsp,
        gazebo,
        TimerAction(period=3.0, actions=[spawn]),
        RegisterEventHandler(OnProcessExit(target_action=spawn,
                                            on_exit=[load_jsb])),
        RegisterEventHandler(OnProcessExit(target_action=load_jsb,
                                            on_exit=[load_arm])),
    ])
EOF
echo "  Fixed: atlasarm_bringup/launch/atlasarm6_gazebo.launch.py"

# Validate Python syntax
python3 -c "import ast; ast.parse(open('$SRC/atlasarm_description/launch/display.launch.py').read())" && echo "  display.launch.py: SYNTAX OK"
python3 -c "import ast; ast.parse(open('$SRC/atlasarm_bringup/launch/atlasarm6_gazebo.launch.py').read())" && echo "  atlasarm6_gazebo.launch.py: SYNTAX OK"

# Rebuild affected packages
echo ""
echo "Rebuilding workspace..."
cd "$WS"
source /opt/ros/humble/setup.bash
colcon build --symlink-install --packages-select atlasarm_description atlasarm_bringup 2>&1 | tail -5

echo ""
echo "═══════════════════════════════════════════════════"
echo " Fix applied. Re-source the workspace and try again:"
echo ""
echo "   source ~/atlasarm6_ws/install/setup.bash"
echo "   ~/atlasarm6_ws/run_display.sh"
echo "═══════════════════════════════════════════════════"
