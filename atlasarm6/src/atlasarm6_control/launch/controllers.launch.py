"""Launch ros2_controllers for AtlasArm-6."""
from launch import LaunchDescription
from launch.actions import ExecuteProcess, TimerAction
from launch_ros.actions import Node


def generate_launch_description():
    # Spawn joint_state_broadcaster
    jsb_spawner = Node(
        package='controller_manager',
        executable='spawner',
        arguments=['joint_state_broadcaster', '--controller-manager', '/controller_manager'],
        output='screen',
    )

    # Spawn arm_controller (with delay to let JSB load first)
    arm_spawner = Node(
        package='controller_manager',
        executable='spawner',
        arguments=['arm_controller', '--controller-manager', '/controller_manager'],
        output='screen',
    )
    arm_spawner_delayed = TimerAction(period=3.0, actions=[arm_spawner])

    return LaunchDescription([
        jsb_spawner,
        arm_spawner_delayed,
    ])
