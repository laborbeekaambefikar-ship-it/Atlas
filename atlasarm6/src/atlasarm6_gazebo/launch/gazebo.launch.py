"""Launch Gazebo with AtlasArm-6 + ros2_control."""
import os
from launch import LaunchDescription
from launch.actions import ExecuteProcess, TimerAction
from launch.substitutions import Command
from launch_ros.actions import Node
from launch_ros.parameter_descriptions import ParameterValue
from ament_index_python.packages import get_package_share_directory


def generate_launch_description():
    desc_pkg = get_package_share_directory('atlasarm6_description')
    gz_pkg = get_package_share_directory('atlasarm6_gazebo')
    ctrl_pkg = get_package_share_directory('atlasarm6_control')

    xacro_file = os.path.join(desc_pkg, 'urdf', 'atlasarm6.urdf.xacro')
    world_file = os.path.join(gz_pkg, 'worlds', 'arm_table.world')

    robot_description = ParameterValue(
        Command(['xacro ', xacro_file]), value_type=str)

    # Gazebo server + client
    gazebo = ExecuteProcess(
        cmd=['gazebo', '--verbose', world_file,
             '-s', 'libgazebo_ros_init.so',
             '-s', 'libgazebo_ros_factory.so'],
        output='screen',
    )

    # Robot State Publisher
    rsp = Node(
        package='robot_state_publisher',
        executable='robot_state_publisher',
        output='screen',
        parameters=[{
            'robot_description': robot_description,
            'use_sim_time': True,
        }],
    )

    # Spawn robot
    spawn = Node(
        package='gazebo_ros',
        executable='spawn_entity.py',
        arguments=[
            '-topic', 'robot_description',
            '-entity', 'atlasarm6',
            '-x', '0', '-y', '0', '-z', '0',
        ],
        output='screen',
    )
    spawn_delayed = TimerAction(period=4.0, actions=[spawn])

    # Joint State Broadcaster
    jsb = Node(
        package='controller_manager',
        executable='spawner',
        arguments=['joint_state_broadcaster', '--controller-manager', '/controller_manager'],
        output='screen',
    )
    jsb_delayed = TimerAction(period=7.0, actions=[jsb])

    # Arm Controller
    arm_ctrl = Node(
        package='controller_manager',
        executable='spawner',
        arguments=['arm_controller', '--controller-manager', '/controller_manager'],
        output='screen',
    )
    arm_ctrl_delayed = TimerAction(period=9.0, actions=[arm_ctrl])

    return LaunchDescription([
        gazebo,
        rsp,
        spawn_delayed,
        jsb_delayed,
        arm_ctrl_delayed,
    ])
