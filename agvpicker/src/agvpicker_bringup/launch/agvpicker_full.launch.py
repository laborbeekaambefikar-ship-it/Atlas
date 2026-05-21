"""
AGVPicker Full System Launch
────────────────────────────────────────────────
ONE command starts: Gazebo + Robot + Controllers + MoveIt2 + RViz
Usage: ros2 launch agvpicker_bringup agvpicker_full.launch.py
"""
import os
from launch import LaunchDescription
from launch.actions import ExecuteProcess, IncludeLaunchDescription, TimerAction
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import Command
from launch_ros.actions import Node
from launch_ros.parameter_descriptions import ParameterValue
from ament_index_python.packages import get_package_share_directory


def generate_launch_description():
    desc_pkg = get_package_share_directory('agvpicker_description')
    gz_pkg = get_package_share_directory('agvpicker_gazebo')
    ctrl_pkg = get_package_share_directory('agvpicker_control')
    moveit_pkg = get_package_share_directory('agvpicker_moveit_config')

    xacro_file = os.path.join(desc_pkg, 'urdf', 'agvpicker.urdf.xacro')
    world_file = os.path.join(gz_pkg, 'worlds', 'arm_table.world')
    rviz_cfg = os.path.join(desc_pkg, 'rviz', 'display.rviz')
    srdf_file = os.path.join(moveit_pkg, 'srdf', 'agvpicker.srdf')
    kinematics_file = os.path.join(moveit_pkg, 'config', 'kinematics.yaml')
    ompl_file = os.path.join(moveit_pkg, 'config', 'ompl_planning.yaml')
    controllers_file = os.path.join(moveit_pkg, 'config', 'moveit_controllers.yaml')
    joint_limits_file = os.path.join(moveit_pkg, 'config', 'joint_limits.yaml')

    robot_description = ParameterValue(
        Command(['xacro ', xacro_file]), value_type=str)

    with open(srdf_file, 'r') as f:
        srdf_content = f.read()

    # ═══════ t=0: Gazebo ═══════
    gazebo = ExecuteProcess(
        cmd=['gazebo', '--verbose', world_file,
             '-s', 'libgazebo_ros_init.so',
             '-s', 'libgazebo_ros_factory.so'],
        output='screen',
    )

    # ═══════ t=0: Robot State Publisher ═══════
    rsp = Node(
        package='robot_state_publisher',
        executable='robot_state_publisher',
        output='screen',
        parameters=[{
            'robot_description': robot_description,
            'use_sim_time': True,
        }],
    )

    # ═══════ t=4: Spawn robot ═══════
    spawn = Node(
        package='gazebo_ros',
        executable='spawn_entity.py',
        arguments=[
            '-topic', 'robot_description',
            '-entity', 'agvpicker',
            '-x', '0', '-y', '0', '-z', '0',
        ],
        output='screen',
    )
    spawn_delayed = TimerAction(period=4.0, actions=[spawn])

    # ═══════ t=7: Controllers ═══════
    jsb = Node(
        package='controller_manager',
        executable='spawner',
        arguments=['joint_state_broadcaster', '--controller-manager', '/controller_manager'],
        output='screen',
    )
    jsb_delayed = TimerAction(period=7.0, actions=[jsb])

    arm_ctrl = Node(
        package='controller_manager',
        executable='spawner',
        arguments=['arm_controller', '--controller-manager', '/controller_manager'],
        output='screen',
    )
    arm_ctrl_delayed = TimerAction(period=9.0, actions=[arm_ctrl])

    # ═══════ t=12: MoveIt2 move_group ═══════
    move_group = Node(
        package='moveit_ros_move_group',
        executable='move_group',
        output='screen',
        parameters=[
            {'robot_description': robot_description},
            {'robot_description_semantic': srdf_content},
            kinematics_file,
            ompl_file,
            controllers_file,
            joint_limits_file,
            {'use_sim_time': True},
        ],
    )
    move_group_delayed = TimerAction(period=12.0, actions=[move_group])

    # ═══════ t=14: RViz2 ═══════
    rviz = Node(
        package='rviz2',
        executable='rviz2',
        arguments=['-d', rviz_cfg],
        parameters=[{'use_sim_time': True}],
        output='log',
    )
    rviz_delayed = TimerAction(period=14.0, actions=[rviz])

    return LaunchDescription([
        gazebo,
        rsp,
        spawn_delayed,
        jsb_delayed,
        arm_ctrl_delayed,
        move_group_delayed,
        rviz_delayed,
    ])
