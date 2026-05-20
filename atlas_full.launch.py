"""
ATLAS_FLEET full system launch — ONE command starts everything.
"""
import os, subprocess
from launch import LaunchDescription
from launch.actions import ExecuteProcess, TimerAction
from launch.substitutions import Command
from launch_ros.actions import Node
from launch_ros.parameter_descriptions import ParameterValue
from ament_index_python.packages import get_package_share_directory

def generate_launch_description():
    desc_pkg = get_package_share_directory('atlas_description')
    gz_pkg = get_package_share_directory('atlas_gazebo')

    world = os.path.join(gz_pkg, 'worlds', 'warehouse.world')
    xacro_file = os.path.join(desc_pkg, 'urdf', 'atlas_agv.urdf.xacro')
    rviz_cfg = os.path.join(desc_pkg, 'rviz', 'atlas.rviz')

    # Pre-process xacro to temp file for spawn_entity -file
    urdf_tmp = '/tmp/atlas_agv.urdf'
    subprocess.run(['xacro', xacro_file, '-o', urdf_tmp], check=True)

    # ── t=0: Gazebo ──
    gazebo = ExecuteProcess(
        cmd=['gazebo', '--verbose', world,
             '-s', 'libgazebo_ros_init.so',
             '-s', 'libgazebo_ros_factory.so'],
        output='screen',
    )

    # ── t=4: Spawn robot from file (no double-spawn) ──
    spawn = Node(
        package='gazebo_ros',
        executable='spawn_entity.py',
        output='screen',
        arguments=[
            '-entity', 'atlas_agv',
            '-file', urdf_tmp,
            '-x', '0.0', '-y', '0.0', '-z', '0.01',
            '-Y', '1.5708',
        ],
    )
    spawn_t = TimerAction(period=4.0, actions=[spawn])

    # ── t=6: Robot State Publisher ──
    robot_desc = Command(['xacro ', xacro_file])
    rsp = Node(
        package='robot_state_publisher',
        executable='robot_state_publisher',
        namespace='atlas',
        output='screen',
        parameters=[{
            'use_sim_time': True,
            'robot_description': ParameterValue(robot_desc, value_type=str),
        }],
    )
    rsp_t = TimerAction(period=6.0, actions=[rsp])

    # ── t=10: Navigation + Mission nodes ──
    nav_nodes = [
        Node(package='atlas_navigation', executable='line_sensor',
             name='atlas_line_sensor', output='screen'),
        Node(package='atlas_navigation', executable='line_follower',
             name='atlas_line_follower', output='screen'),
        Node(package='atlas_navigation', executable='turn_controller',
             name='atlas_turn_ctrl', output='screen'),
        Node(package='atlas_navigation', executable='tag_detector',
             name='atlas_tag_detect', output='screen'),
        Node(package='atlas_mission_manager', executable='mission_node',
             name='atlas_mission_mgr', output='screen'),
    ]
    nav_t = TimerAction(period=10.0, actions=nav_nodes)

    # ── t=12: RViz ──
    rviz = Node(
        package='rviz2',
        executable='rviz2',
        name='atlas_rviz',
        arguments=['-d', rviz_cfg],
        output='log',
        parameters=[{'use_sim_time': True}],
    )
    rviz_t = TimerAction(period=12.0, actions=[rviz])

    # ── t=14: GUI (runs independently — crash won't kill robot) ──
    gui = Node(
        package='atlas_mission_manager',
        executable='atlas_gui',
        name='atlas_gui',
        output='log',
    )
    gui_t = TimerAction(period=14.0, actions=[gui])

    return LaunchDescription([
        gazebo,
        spawn_t,
        rsp_t,
        nav_t,
        rviz_t,
        gui_t,
    ])
