"""MoveIt2 move_group launch for AtlasArm-6."""
import os
from launch import LaunchDescription
from launch.substitutions import Command
from launch_ros.actions import Node
from launch_ros.parameter_descriptions import ParameterValue
from ament_index_python.packages import get_package_share_directory


def generate_launch_description():
    desc_pkg = get_package_share_directory('atlasarm6_description')
    moveit_pkg = get_package_share_directory('atlasarm6_moveit_config')

    xacro_file = os.path.join(desc_pkg, 'urdf', 'atlasarm6.urdf.xacro')
    srdf_file = os.path.join(moveit_pkg, 'srdf', 'atlasarm6.srdf')
    kinematics_file = os.path.join(moveit_pkg, 'config', 'kinematics.yaml')
    ompl_file = os.path.join(moveit_pkg, 'config', 'ompl_planning.yaml')
    controllers_file = os.path.join(moveit_pkg, 'config', 'moveit_controllers.yaml')
    joint_limits_file = os.path.join(moveit_pkg, 'config', 'joint_limits.yaml')

    robot_description = ParameterValue(
        Command(['xacro ', xacro_file]), value_type=str)

    with open(srdf_file, 'r') as f:
        srdf_content = f.read()

    move_group_node = Node(
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
            {'planning_scene_monitor_options': {
                'robot_description': 'robot_description',
                'joint_state_topic': '/joint_states',
            }},
        ],
    )

    rviz_cfg = os.path.join(moveit_pkg, 'config', 'moveit_rviz.rviz')

    rviz = Node(
        package='rviz2',
        executable='rviz2',
        arguments=['-d', rviz_cfg] if os.path.exists(rviz_cfg) else [],
        parameters=[
            {'robot_description': robot_description},
            {'robot_description_semantic': srdf_content},
            kinematics_file,
        ],
    )

    return LaunchDescription([
        move_group_node,
        rviz,
    ])
