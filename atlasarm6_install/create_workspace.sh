#!/bin/bash
###############################################################################
# AtlasArm-6 Workspace File Generator
# Creates all package files using heredocs (no external file dependencies)
# 
# Usage: bash create_workspace.sh /path/to/atlasarm6_ws/src
###############################################################################
set -e

SRC="${1:-$HOME/atlasarm6_ws/src}"
mkdir -p "$SRC"
cd "$SRC"

echo "Generating AtlasArm-6 packages in: $SRC"

# Source ROS2 for ros2 pkg create
source /opt/ros/humble/setup.bash

# ──────────────────────────────────────────────────────────────
# Package 1: atlasarm_interfaces
# ──────────────────────────────────────────────────────────────
echo "[1/7] atlasarm_interfaces"
mkdir -p atlasarm_interfaces/{msg,srv,action}
cd atlasarm_interfaces

cat > package.xml << 'EOF'
<?xml version="1.0"?>
<package format="3">
  <name>atlasarm_interfaces</name>
  <version>1.0.0</version>
  <description>AtlasArm-6 custom message definitions</description>
  <maintainer email="atlasarm@dev.local">atlasarm</maintainer>
  <license>MIT</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <buildtool_depend>rosidl_default_generators</buildtool_depend>
  <depend>std_msgs</depend>
  <depend>geometry_msgs</depend>
  <depend>builtin_interfaces</depend>
  <depend>action_msgs</depend>
  <exec_depend>rosidl_default_runtime</exec_depend>
  <member_of_group>rosidl_interface_packages</member_of_group>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF

cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.8)
project(atlasarm_interfaces)
find_package(ament_cmake REQUIRED)
find_package(rosidl_default_generators REQUIRED)
find_package(std_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(builtin_interfaces REQUIRED)
find_package(action_msgs REQUIRED)

rosidl_generate_interfaces(${PROJECT_NAME}
  "msg/ArmCommand.msg"
  "msg/ArmState.msg"
  "msg/ManipulationTask.msg"
  DEPENDENCIES std_msgs geometry_msgs builtin_interfaces
)

ament_export_dependencies(rosidl_default_runtime)
ament_package()
EOF

cat > msg/ArmCommand.msg << 'EOF'
string command_id
string command_type
geometry_msgs/PoseStamped target_pose
string gripper_state
float32 speed_scaling
uint8 priority
EOF

cat > msg/ArmState.msg << 'EOF'
string state
string active_command_id
float64[] joint_positions
float64[] joint_velocities
geometry_msgs/PoseStamped tool_pose
bool gripper_closed
float32 payload_estimate_kg
bool is_collision_detected
builtin_interfaces/Time stamp
EOF

cat > msg/ManipulationTask.msg << 'EOF'
string task_id
string task_type
geometry_msgs/PoseStamped pick_pose
geometry_msgs/PoseStamped place_pose
string object_id
float32 object_height_mm
float32 object_width_mm
uint8 priority
EOF

cd ..
echo "  ✓ atlasarm_interfaces"

# ──────────────────────────────────────────────────────────────
# Package 2: atlasarm_description
# ──────────────────────────────────────────────────────────────
echo "[2/7] atlasarm_description"
mkdir -p atlasarm_description/{urdf,rviz,launch}
cd atlasarm_description

cat > package.xml << 'EOF'
<?xml version="1.0"?>
<package format="3">
  <name>atlasarm_description</name>
  <version>1.0.0</version>
  <description>AtlasArm-6 URDF/Xacro robot description</description>
  <maintainer email="atlasarm@dev.local">atlasarm</maintainer>
  <license>MIT</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <exec_depend>robot_state_publisher</exec_depend>
  <exec_depend>joint_state_publisher_gui</exec_depend>
  <exec_depend>xacro</exec_depend>
  <exec_depend>rviz2</exec_depend>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF

cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.8)
project(atlasarm_description)
find_package(ament_cmake REQUIRED)
install(DIRECTORY urdf rviz launch DESTINATION share/${PROJECT_NAME})
ament_package()
EOF



# ── URDF/Xacro: pure-geometry 6-DOF arm (no mesh files needed) ──
cat > urdf/atlasarm6.urdf.xacro << 'XACRO_EOF'
<?xml version="1.0"?>
<robot name="atlasarm6" xmlns:xacro="http://www.ros.org/wiki/xacro">

  <!-- ═══ AtlasArm-6 Parameters (UR5e-derived, compact variant) ═══ -->
  <xacro:property name="PI" value="3.14159265359"/>
  <xacro:property name="d1" value="0.150"/>
  <xacro:property name="a2" value="0.390"/>
  <xacro:property name="a3" value="0.360"/>
  <xacro:property name="d4" value="0.120"/>
  <xacro:property name="d5" value="0.090"/>
  <xacro:property name="d6" value="0.090"/>

  <!-- Link masses (kg) -->
  <xacro:property name="m_base"      value="3.5"/>
  <xacro:property name="m_shoulder"  value="3.0"/>
  <xacro:property name="m_uarm"      value="6.5"/>
  <xacro:property name="m_forearm"   value="1.8"/>
  <xacro:property name="m_w1"        value="1.6"/>
  <xacro:property name="m_w2"        value="1.6"/>
  <xacro:property name="m_w3"        value="0.18"/>

  <!-- Joint limits -->
  <xacro:property name="lim_j1" value="${270*PI/180}"/>
  <xacro:property name="lim_j2_lo" value="${-180*PI/180}"/>
  <xacro:property name="lim_j2_hi" value="${90*PI/180}"/>
  <xacro:property name="lim_j3" value="${170*PI/180}"/>
  <xacro:property name="lim_j456" value="${360*PI/180}"/>
  <xacro:property name="vel_low" value="1.047"/>
  <xacro:property name="vel_high" value="2.094"/>

  <!-- Materials -->
  <material name="atlas_dark"><color rgba="0.18 0.18 0.22 1"/></material>
  <material name="atlas_silver"><color rgba="0.55 0.57 0.60 1"/></material>
  <material name="atlas_orange"><color rgba="0.92 0.55 0.10 1"/></material>
  <material name="atlas_blue"><color rgba="0.10 0.30 0.70 1"/></material>

  <!-- Cylinder inertia macro -->
  <xacro:macro name="cyl_inertia" params="m r h">
    <inertial>
      <mass value="${m}"/>
      <inertia ixx="${m*(3*r*r+h*h)/12}" ixy="0" ixz="0"
               iyy="${m*(3*r*r+h*h)/12}" iyz="0"
               izz="${m*r*r/2}"/>
    </inertial>
  </xacro:macro>

  <!-- ═══ World fixed base ═══ -->
  <link name="world"/>

  <!-- ═══ Base ═══ -->
  <link name="aa6_base_link">
    <visual>
      <origin xyz="0 0 0.04"/>
      <geometry><cylinder radius="0.075" length="0.08"/></geometry>
      <material name="atlas_dark"/>
    </visual>
    <collision>
      <origin xyz="0 0 0.04"/>
      <geometry><cylinder radius="0.075" length="0.08"/></geometry>
    </collision>
    <xacro:cyl_inertia m="${m_base}" r="0.075" h="0.08"/>
  </link>

  <joint name="aa6_world_to_base" type="fixed">
    <parent link="world"/>
    <child link="aa6_base_link"/>
    <origin xyz="0 0 0" rpy="0 0 0"/>
  </joint>

  <!-- ═══ J1: Base rotation ═══ -->
  <link name="aa6_shoulder_link">
    <visual>
      <origin xyz="0 0 0.045"/>
      <geometry><cylinder radius="0.06" length="0.09"/></geometry>
      <material name="atlas_blue"/>
    </visual>
    <collision>
      <origin xyz="0 0 0.045"/>
      <geometry><cylinder radius="0.06" length="0.09"/></geometry>
    </collision>
    <xacro:cyl_inertia m="${m_shoulder}" r="0.06" h="0.09"/>
  </link>
  <joint name="aa6_j1" type="revolute">
    <parent link="aa6_base_link"/>
    <child link="aa6_shoulder_link"/>
    <origin xyz="0 0 0.08" rpy="0 0 0"/>
    <axis xyz="0 0 1"/>
    <limit lower="${-lim_j1}" upper="${lim_j1}" effort="150" velocity="${vel_low}"/>
    <dynamics damping="0.5"/>
  </joint>

  <!-- ═══ J2: Shoulder pitch ═══ -->
  <link name="aa6_upper_arm_link">
    <visual>
      <origin xyz="0 0 ${a2/2}"/>
      <geometry><cylinder radius="0.045" length="${a2}"/></geometry>
      <material name="atlas_silver"/>
    </visual>
    <collision>
      <origin xyz="0 0 ${a2/2}"/>
      <geometry><cylinder radius="0.045" length="${a2}"/></geometry>
    </collision>
    <xacro:cyl_inertia m="${m_uarm}" r="0.045" h="${a2}"/>
  </link>
  <joint name="aa6_j2" type="revolute">
    <parent link="aa6_shoulder_link"/>
    <child link="aa6_upper_arm_link"/>
    <origin xyz="0 0.08 0.09" rpy="0 0 0"/>
    <axis xyz="0 1 0"/>
    <limit lower="${lim_j2_lo}" upper="${lim_j2_hi}" effort="150" velocity="${vel_low}"/>
    <dynamics damping="0.5"/>
  </joint>

  <!-- ═══ J3: Elbow ═══ -->
  <link name="aa6_forearm_link">
    <visual>
      <origin xyz="0 0 ${a3/2}"/>
      <geometry><cylinder radius="0.035" length="${a3}"/></geometry>
      <material name="atlas_silver"/>
    </visual>
    <collision>
      <origin xyz="0 0 ${a3/2}"/>
      <geometry><cylinder radius="0.035" length="${a3}"/></geometry>
    </collision>
    <xacro:cyl_inertia m="${m_forearm}" r="0.035" h="${a3}"/>
  </link>
  <joint name="aa6_j3" type="revolute">
    <parent link="aa6_upper_arm_link"/>
    <child link="aa6_forearm_link"/>
    <origin xyz="0 -0.05 ${a2}" rpy="0 0 0"/>
    <axis xyz="0 1 0"/>
    <limit lower="${-lim_j3}" upper="${lim_j3}" effort="150" velocity="${vel_low}"/>
    <dynamics damping="0.5"/>
  </joint>

  <!-- ═══ J4: Wrist 1 ═══ -->
  <link name="aa6_wrist_1_link">
    <visual>
      <origin xyz="0 0 ${d4/2}"/>
      <geometry><cylinder radius="0.030" length="${d4}"/></geometry>
      <material name="atlas_orange"/>
    </visual>
    <collision>
      <origin xyz="0 0 ${d4/2}"/>
      <geometry><cylinder radius="0.030" length="${d4}"/></geometry>
    </collision>
    <xacro:cyl_inertia m="${m_w1}" r="0.030" h="${d4}"/>
  </link>
  <joint name="aa6_j4" type="revolute">
    <parent link="aa6_forearm_link"/>
    <child link="aa6_wrist_1_link"/>
    <origin xyz="0 0 ${a3}" rpy="0 0 0"/>
    <axis xyz="0 1 0"/>
    <limit lower="${-lim_j456}" upper="${lim_j456}" effort="28" velocity="${vel_high}"/>
    <dynamics damping="0.3"/>
  </joint>

  <!-- ═══ J5: Wrist 2 ═══ -->
  <link name="aa6_wrist_2_link">
    <visual>
      <origin xyz="0 0 ${d5/2}"/>
      <geometry><cylinder radius="0.028" length="${d5}"/></geometry>
      <material name="atlas_orange"/>
    </visual>
    <collision>
      <origin xyz="0 0 ${d5/2}"/>
      <geometry><cylinder radius="0.028" length="${d5}"/></geometry>
    </collision>
    <xacro:cyl_inertia m="${m_w2}" r="0.028" h="${d5}"/>
  </link>
  <joint name="aa6_j5" type="revolute">
    <parent link="aa6_wrist_1_link"/>
    <child link="aa6_wrist_2_link"/>
    <origin xyz="0 0.06 ${d4}" rpy="0 0 0"/>
    <axis xyz="0 0 1"/>
    <limit lower="${-lim_j456}" upper="${lim_j456}" effort="28" velocity="${vel_high}"/>
    <dynamics damping="0.3"/>
  </joint>

  <!-- ═══ J6: Wrist 3 (tool flange) ═══ -->
  <link name="aa6_wrist_3_link">
    <visual>
      <origin xyz="0 0 ${d6/2}"/>
      <geometry><cylinder radius="0.025" length="${d6}"/></geometry>
      <material name="atlas_orange"/>
    </visual>
    <collision>
      <origin xyz="0 0 ${d6/2}"/>
      <geometry><cylinder radius="0.025" length="${d6}"/></geometry>
    </collision>
    <xacro:cyl_inertia m="${m_w3}" r="0.025" h="${d6}"/>
  </link>
  <joint name="aa6_j6" type="revolute">
    <parent link="aa6_wrist_2_link"/>
    <child link="aa6_wrist_3_link"/>
    <origin xyz="0 -0.04 ${d5}" rpy="0 0 0"/>
    <axis xyz="0 1 0"/>
    <limit lower="${-lim_j456}" upper="${lim_j456}" effort="28" velocity="${vel_high}"/>
    <dynamics damping="0.3"/>
  </joint>

  <!-- ═══ Tool0 frame ═══ -->
  <link name="aa6_tool0"/>
  <joint name="aa6_tool0_joint" type="fixed">
    <parent link="aa6_wrist_3_link"/>
    <child link="aa6_tool0"/>
    <origin xyz="0 0 ${d6}" rpy="0 0 0"/>
  </joint>

  <!-- ═══ ros2_control hardware interface ═══ -->
  <ros2_control name="atlasarm6_hw" type="system">
    <hardware>
      <plugin>gazebo_ros2_control/GazeboSystem</plugin>
    </hardware>
    <joint name="aa6_j1">
      <command_interface name="position"/>
      <state_interface name="position"/>
      <state_interface name="velocity"/>
    </joint>
    <joint name="aa6_j2">
      <command_interface name="position"/>
      <state_interface name="position"/>
      <state_interface name="velocity"/>
    </joint>
    <joint name="aa6_j3">
      <command_interface name="position"/>
      <state_interface name="position"/>
      <state_interface name="velocity"/>
    </joint>
    <joint name="aa6_j4">
      <command_interface name="position"/>
      <state_interface name="position"/>
      <state_interface name="velocity"/>
    </joint>
    <joint name="aa6_j5">
      <command_interface name="position"/>
      <state_interface name="position"/>
      <state_interface name="velocity"/>
    </joint>
    <joint name="aa6_j6">
      <command_interface name="position"/>
      <state_interface name="position"/>
      <state_interface name="velocity"/>
    </joint>
  </ros2_control>

  <!-- Gazebo plugin -->
  <gazebo>
    <plugin filename="libgazebo_ros2_control.so" name="gazebo_ros2_control">
      <parameters>$(find atlasarm_control)/config/atlasarm6_controllers.yaml</parameters>
    </plugin>
  </gazebo>

  <!-- Gazebo materials -->
  <gazebo reference="aa6_base_link"><material>Gazebo/DarkGrey</material></gazebo>
  <gazebo reference="aa6_shoulder_link"><material>Gazebo/Blue</material></gazebo>
  <gazebo reference="aa6_upper_arm_link"><material>Gazebo/Grey</material></gazebo>
  <gazebo reference="aa6_forearm_link"><material>Gazebo/Grey</material></gazebo>
  <gazebo reference="aa6_wrist_1_link"><material>Gazebo/Orange</material></gazebo>
  <gazebo reference="aa6_wrist_2_link"><material>Gazebo/Orange</material></gazebo>
  <gazebo reference="aa6_wrist_3_link"><material>Gazebo/Orange</material></gazebo>

</robot>
XACRO_EOF



# ── RViz config ──
cat > rviz/atlasarm6.rviz << 'RVIZ_EOF'
Panels:
  - Class: rviz_common/Displays
    Name: Displays
Visualization Manager:
  Class: ""
  Displays:
    - Class: rviz_default_plugins/Grid
      Name: Grid
      Enabled: true
      Cell Size: 0.5
      Plane Cell Count: 20
    - Class: rviz_default_plugins/RobotModel
      Description Topic:
        Value: /robot_description
      Name: RobotModel
      Enabled: true
    - Class: rviz_default_plugins/TF
      Name: TF
      Enabled: true
  Global Options:
    Background Color: 48; 48; 48
    Fixed Frame: world
  Tools:
    - Class: rviz_default_plugins/Interact
    - Class: rviz_default_plugins/MoveCamera
    - Class: rviz_default_plugins/Select
  Views:
    Current:
      Class: rviz_default_plugins/Orbit
      Distance: 2.5
      Focal Point: { X: 0, Y: 0, Z: 0.4 }
      Pitch: 0.5
      Yaw: 0.7
RVIZ_EOF

# ── Display launch ──
cat > launch/display.launch.py << 'PYEOF'
"""Display AtlasArm-6 in RViz with joint sliders."""
from launch import LaunchDescription
from launch_ros.actions import Node
from launch.substitutions import Command, PathJoinSubstitution
from launch_ros.substitutions import FindPackageShare


def generate_launch_description():
    pkg = FindPackageShare('atlasarm_description')
    xacro_file = PathJoinSubstitution([pkg, 'urdf', 'atlasarm6.urdf.xacro'])
    rviz_cfg = PathJoinSubstitution([pkg, 'rviz', 'atlasarm6.rviz'])
    robot_desc = Command(['xacro ', xacro_file])

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
PYEOF

cd ..
echo "  ✓ atlasarm_description"

# ──────────────────────────────────────────────────────────────
# Package 3: atlasarm_control
# ──────────────────────────────────────────────────────────────
echo "[3/7] atlasarm_control"
mkdir -p atlasarm_control/config
cd atlasarm_control

cat > package.xml << 'EOF'
<?xml version="1.0"?>
<package format="3">
  <name>atlasarm_control</name>
  <version>1.0.0</version>
  <description>AtlasArm-6 ros2_control configuration</description>
  <maintainer email="atlasarm@dev.local">atlasarm</maintainer>
  <license>MIT</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <exec_depend>ros2_control</exec_depend>
  <exec_depend>ros2_controllers</exec_depend>
  <exec_depend>joint_state_broadcaster</exec_depend>
  <exec_depend>joint_trajectory_controller</exec_depend>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF

cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.8)
project(atlasarm_control)
find_package(ament_cmake REQUIRED)
install(DIRECTORY config DESTINATION share/${PROJECT_NAME})
ament_package()
EOF

cat > config/atlasarm6_controllers.yaml << 'YAML_EOF'
controller_manager:
  ros__parameters:
    update_rate: 100

    joint_state_broadcaster:
      type: joint_state_broadcaster/JointStateBroadcaster

    atlasarm6_arm_controller:
      type: joint_trajectory_controller/JointTrajectoryController

atlasarm6_arm_controller:
  ros__parameters:
    joints:
      - aa6_j1
      - aa6_j2
      - aa6_j3
      - aa6_j4
      - aa6_j5
      - aa6_j6
    command_interfaces:
      - position
    state_interfaces:
      - position
      - velocity
    state_publish_rate: 100.0
    action_monitor_rate: 20.0
    allow_partial_joints_goal: false
    constraints:
      stopped_velocity_tolerance: 0.05
      goal_time: 0.0
YAML_EOF

cd ..
echo "  ✓ atlasarm_control"

# ──────────────────────────────────────────────────────────────
# Package 4: atlasarm_moveit_config
# ──────────────────────────────────────────────────────────────
echo "[4/7] atlasarm_moveit_config"
mkdir -p atlasarm_moveit_config/{config,launch}
cd atlasarm_moveit_config

cat > package.xml << 'EOF'
<?xml version="1.0"?>
<package format="3">
  <name>atlasarm_moveit_config</name>
  <version>1.0.0</version>
  <description>AtlasArm-6 MoveIt2 configuration</description>
  <maintainer email="atlasarm@dev.local">atlasarm</maintainer>
  <license>MIT</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <exec_depend>moveit_ros_move_group</exec_depend>
  <exec_depend>moveit_kinematics</exec_depend>
  <exec_depend>moveit_planners_ompl</exec_depend>
  <exec_depend>moveit_ros_visualization</exec_depend>
  <exec_depend>moveit_simple_controller_manager</exec_depend>
  <exec_depend>atlasarm_description</exec_depend>
  <exec_depend>atlasarm_control</exec_depend>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF

cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.8)
project(atlasarm_moveit_config)
find_package(ament_cmake REQUIRED)
install(DIRECTORY config launch DESTINATION share/${PROJECT_NAME})
ament_package()
EOF

cat > config/atlasarm6.srdf << 'SRDF_EOF'
<?xml version="1.0"?>
<robot name="atlasarm6">

  <group name="atlasarm6_arm">
    <chain base_link="aa6_base_link" tip_link="aa6_tool0"/>
  </group>

  <group_state name="home" group="atlasarm6_arm">
    <joint name="aa6_j1" value="0"/>
    <joint name="aa6_j2" value="-1.5708"/>
    <joint name="aa6_j3" value="1.5708"/>
    <joint name="aa6_j4" value="-1.5708"/>
    <joint name="aa6_j5" value="-1.5708"/>
    <joint name="aa6_j6" value="0"/>
  </group_state>

  <group_state name="ready" group="atlasarm6_arm">
    <joint name="aa6_j1" value="0"/>
    <joint name="aa6_j2" value="-1.0472"/>
    <joint name="aa6_j3" value="1.0472"/>
    <joint name="aa6_j4" value="-1.5708"/>
    <joint name="aa6_j5" value="-1.5708"/>
    <joint name="aa6_j6" value="0"/>
  </group_state>

  <group_state name="vertical" group="atlasarm6_arm">
    <joint name="aa6_j1" value="0"/>
    <joint name="aa6_j2" value="0"/>
    <joint name="aa6_j3" value="0"/>
    <joint name="aa6_j4" value="0"/>
    <joint name="aa6_j5" value="0"/>
    <joint name="aa6_j6" value="0"/>
  </group_state>

  <virtual_joint name="virtual_joint" type="fixed" parent_frame="world" child_link="aa6_base_link"/>

  <disable_collisions link1="aa6_base_link" link2="aa6_shoulder_link" reason="Adjacent"/>
  <disable_collisions link1="aa6_shoulder_link" link2="aa6_upper_arm_link" reason="Adjacent"/>
  <disable_collisions link1="aa6_upper_arm_link" link2="aa6_forearm_link" reason="Adjacent"/>
  <disable_collisions link1="aa6_forearm_link" link2="aa6_wrist_1_link" reason="Adjacent"/>
  <disable_collisions link1="aa6_wrist_1_link" link2="aa6_wrist_2_link" reason="Adjacent"/>
  <disable_collisions link1="aa6_wrist_2_link" link2="aa6_wrist_3_link" reason="Adjacent"/>

</robot>
SRDF_EOF

cat > config/kinematics.yaml << 'EOF'
atlasarm6_arm:
  kinematics_solver: kdl_kinematics_plugin/KDLKinematicsPlugin
  kinematics_solver_search_resolution: 0.005
  kinematics_solver_timeout: 0.05
EOF

cat > config/joint_limits.yaml << 'EOF'
default_velocity_scaling_factor: 0.5
default_acceleration_scaling_factor: 0.5
joint_limits:
  aa6_j1: { has_velocity_limits: true, max_velocity: 1.047, has_acceleration_limits: true, max_acceleration: 2.0 }
  aa6_j2: { has_velocity_limits: true, max_velocity: 1.047, has_acceleration_limits: true, max_acceleration: 2.0 }
  aa6_j3: { has_velocity_limits: true, max_velocity: 1.047, has_acceleration_limits: true, max_acceleration: 2.0 }
  aa6_j4: { has_velocity_limits: true, max_velocity: 2.094, has_acceleration_limits: true, max_acceleration: 4.0 }
  aa6_j5: { has_velocity_limits: true, max_velocity: 2.094, has_acceleration_limits: true, max_acceleration: 4.0 }
  aa6_j6: { has_velocity_limits: true, max_velocity: 2.094, has_acceleration_limits: true, max_acceleration: 4.0 }
EOF

cat > config/moveit_controllers.yaml << 'EOF'
moveit_controller_manager: moveit_simple_controller_manager/MoveItSimpleControllerManager

moveit_simple_controller_manager:
  controller_names:
    - atlasarm6_arm_controller

  atlasarm6_arm_controller:
    type: FollowJointTrajectory
    action_ns: follow_joint_trajectory
    default: true
    joints:
      - aa6_j1
      - aa6_j2
      - aa6_j3
      - aa6_j4
      - aa6_j5
      - aa6_j6
EOF

cat > config/ompl_planning.yaml << 'EOF'
planning_plugin: ompl_interface/OMPLPlanner

planner_configs:
  RRTConnect:
    type: geometric::RRTConnect
    range: 0.0
  RRTstar:
    type: geometric::RRTstar
    range: 0.0
    goal_bias: 0.05

atlasarm6_arm:
  planner_configs:
    - RRTConnect
    - RRTstar
  default_planner_config: RRTConnect
EOF



# ── MoveIt2 launch ──
cat > launch/move_group.launch.py << 'PYEOF'
"""Launch MoveIt2 move_group node for AtlasArm-6."""
import os
import yaml
from launch import LaunchDescription
from launch_ros.actions import Node
from ament_index_python.packages import get_package_share_directory


def load_yaml(pkg, file_path):
    full = os.path.join(get_package_share_directory(pkg), file_path)
    try:
        with open(full) as f:
            return yaml.safe_load(f)
    except Exception:
        return {}


def load_file(pkg, file_path):
    full = os.path.join(get_package_share_directory(pkg), file_path)
    try:
        with open(full) as f:
            return f.read()
    except Exception:
        return ''


def generate_launch_description():
    desc_pkg = get_package_share_directory('atlasarm_description')
    moveit_pkg = get_package_share_directory('atlasarm_moveit_config')

    xacro_file = os.path.join(desc_pkg, 'urdf', 'atlasarm6.urdf.xacro')
    import subprocess
    robot_desc_str = subprocess.check_output(['xacro', xacro_file]).decode()

    robot_description = {'robot_description': robot_desc_str}
    robot_description_semantic = {
        'robot_description_semantic': load_file('atlasarm_moveit_config', 'config/atlasarm6.srdf')
    }

    kinematics = load_yaml('atlasarm_moveit_config', 'config/kinematics.yaml')
    ompl_yaml = load_yaml('atlasarm_moveit_config', 'config/ompl_planning.yaml')
    moveit_controllers = load_yaml('atlasarm_moveit_config', 'config/moveit_controllers.yaml')
    joint_limits = load_yaml('atlasarm_moveit_config', 'config/joint_limits.yaml')

    move_group_node = Node(
        package='moveit_ros_move_group',
        executable='move_group',
        output='screen',
        parameters=[
            robot_description,
            robot_description_semantic,
            {'robot_description_kinematics': kinematics},
            {'robot_description_planning': joint_limits},
            ompl_yaml,
            moveit_controllers,
            {'use_sim_time': True},
            {'publish_robot_description_semantic': True},
        ],
    )

    return LaunchDescription([move_group_node])
PYEOF

cat > launch/moveit_rviz.launch.py << 'PYEOF'
"""Launch RViz with MoveIt2 plugin."""
import os
import subprocess
from launch import LaunchDescription
from launch_ros.actions import Node
from ament_index_python.packages import get_package_share_directory


def load_file(pkg, file_path):
    full = os.path.join(get_package_share_directory(pkg), file_path)
    try:
        with open(full) as f:
            return f.read()
    except Exception:
        return ''


def generate_launch_description():
    desc_pkg = get_package_share_directory('atlasarm_description')
    moveit_pkg = get_package_share_directory('atlasarm_moveit_config')

    xacro_file = os.path.join(desc_pkg, 'urdf', 'atlasarm6.urdf.xacro')
    robot_desc_str = subprocess.check_output(['xacro', xacro_file]).decode()

    robot_description = {'robot_description': robot_desc_str}
    robot_description_semantic = {
        'robot_description_semantic': load_file('atlasarm_moveit_config', 'config/atlasarm6.srdf')
    }

    rviz_cfg = os.path.join(desc_pkg, 'rviz', 'atlasarm6.rviz')

    rviz = Node(
        package='rviz2',
        executable='rviz2',
        arguments=['-d', rviz_cfg],
        parameters=[robot_description, robot_description_semantic, {'use_sim_time': True}],
        output='log',
    )

    return LaunchDescription([rviz])
PYEOF

cd ..
echo "  ✓ atlasarm_moveit_config"

# ──────────────────────────────────────────────────────────────
# Package 5: atlasarm_gazebo
# ──────────────────────────────────────────────────────────────
echo "[5/7] atlasarm_gazebo"
mkdir -p atlasarm_gazebo/{worlds,launch}
cd atlasarm_gazebo

cat > package.xml << 'EOF'
<?xml version="1.0"?>
<package format="3">
  <name>atlasarm_gazebo</name>
  <version>1.0.0</version>
  <description>AtlasArm-6 Gazebo world files</description>
  <maintainer email="atlasarm@dev.local">atlasarm</maintainer>
  <license>MIT</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <exec_depend>gazebo_ros_pkgs</exec_depend>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF

cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.8)
project(atlasarm_gazebo)
find_package(ament_cmake REQUIRED)
install(DIRECTORY worlds launch DESTINATION share/${PROJECT_NAME})
ament_package()
EOF

cat > worlds/atlasarm6_workspace.world << 'WORLD_EOF'
<?xml version="1.0"?>
<sdf version="1.6">
<world name="atlasarm6_workspace">
  <gravity>0 0 -9.81</gravity>
  <physics type="ode">
    <max_step_size>0.001</max_step_size>
    <real_time_factor>1.0</real_time_factor>
    <real_time_update_rate>1000</real_time_update_rate>
  </physics>
  <scene>
    <ambient>0.5 0.5 0.55 1</ambient>
    <background>0.2 0.2 0.25 1</background>
    <shadows>1</shadows>
  </scene>

  <include><uri>model://sun</uri></include>
  <include><uri>model://ground_plane</uri></include>

  <!-- Work table -->
  <model name="work_table"><static>true</static>
    <pose>0.5 0 0.4 0 0 0</pose>
    <link name="link">
      <collision name="c"><geometry><box><size>0.8 1.2 0.04</size></box></geometry></collision>
      <visual name="v"><geometry><box><size>0.8 1.2 0.04</size></box></geometry>
        <material><ambient>0.5 0.4 0.3 1</ambient><diffuse>0.55 0.45 0.32 1</diffuse></material>
      </visual>
    </link>
  </model>
  <model name="table_legs_a"><static>true</static>
    <pose>0.85 0.55 0.2 0 0 0</pose>
    <link name="link"><visual name="v"><geometry><box><size>0.04 0.04 0.4</size></box></geometry>
      <material><ambient>0.3 0.3 0.3 1</ambient></material></visual></link>
  </model>
  <model name="table_legs_b"><static>true</static>
    <pose>0.85 -0.55 0.2 0 0 0</pose>
    <link name="link"><visual name="v"><geometry><box><size>0.04 0.04 0.4</size></box></geometry>
      <material><ambient>0.3 0.3 0.3 1</ambient></material></visual></link>
  </model>
  <model name="table_legs_c"><static>true</static>
    <pose>0.15 0.55 0.2 0 0 0</pose>
    <link name="link"><visual name="v"><geometry><box><size>0.04 0.04 0.4</size></box></geometry>
      <material><ambient>0.3 0.3 0.3 1</ambient></material></visual></link>
  </model>
  <model name="table_legs_d"><static>true</static>
    <pose>0.15 -0.55 0.2 0 0 0</pose>
    <link name="link"><visual name="v"><geometry><box><size>0.04 0.04 0.4</size></box></geometry>
      <material><ambient>0.3 0.3 0.3 1</ambient></material></visual></link>
  </model>

  <!-- Pick object (red cube) -->
  <model name="pick_cube">
    <pose>0.4 0 0.45 0 0 0</pose>
    <link name="link">
      <inertial>
        <mass>0.1</mass>
        <inertia ixx="0.0001" iyy="0.0001" izz="0.0001" ixy="0" ixz="0" iyz="0"/>
      </inertial>
      <collision name="c"><geometry><box><size>0.04 0.04 0.04</size></box></geometry></collision>
      <visual name="v"><geometry><box><size>0.04 0.04 0.04</size></box></geometry>
        <material><ambient>0.8 0.1 0.1 1</ambient><diffuse>0.9 0.15 0.15 1</diffuse></material>
      </visual>
    </link>
  </model>

  <!-- Target zone (green pad) -->
  <model name="place_target"><static>true</static>
    <pose>0.4 0.3 0.42 0 0 0</pose>
    <link name="link">
      <visual name="v"><geometry><box><size>0.1 0.1 0.001</size></box></geometry>
        <material><ambient>0.1 0.7 0.2 1</ambient><diffuse>0.1 0.8 0.25 1</diffuse></material>
      </visual>
    </link>
  </model>

</world>
</sdf>
WORLD_EOF

cd ..
echo "  ✓ atlasarm_gazebo"

# ──────────────────────────────────────────────────────────────
# Package 6: atlasarm_bringup
# ──────────────────────────────────────────────────────────────
echo "[6/7] atlasarm_bringup"
mkdir -p atlasarm_bringup/launch
cd atlasarm_bringup

cat > package.xml << 'EOF'
<?xml version="1.0"?>
<package format="3">
  <name>atlasarm_bringup</name>
  <version>1.0.0</version>
  <description>AtlasArm-6 system launch files</description>
  <maintainer email="atlasarm@dev.local">atlasarm</maintainer>
  <license>MIT</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <exec_depend>atlasarm_description</exec_depend>
  <exec_depend>atlasarm_control</exec_depend>
  <exec_depend>atlasarm_moveit_config</exec_depend>
  <exec_depend>atlasarm_gazebo</exec_depend>
  <exec_depend>gazebo_ros_pkgs</exec_depend>
  <exec_depend>gazebo_ros2_control</exec_depend>
  <exec_depend>controller_manager</exec_depend>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF

cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.8)
project(atlasarm_bringup)
find_package(ament_cmake REQUIRED)
install(DIRECTORY launch DESTINATION share/${PROJECT_NAME})
ament_package()
EOF

cat > launch/atlasarm6_gazebo.launch.py << 'PYEOF'
"""Launch Gazebo + AtlasArm-6 + ros2_control."""
import os
from launch import LaunchDescription
from launch.actions import ExecuteProcess, RegisterEventHandler, TimerAction
from launch.event_handlers import OnProcessExit
from launch_ros.actions import Node
from launch.substitutions import Command
from ament_index_python.packages import get_package_share_directory


def generate_launch_description():
    desc_pkg = get_package_share_directory('atlasarm_description')
    gz_pkg = get_package_share_directory('atlasarm_gazebo')

    xacro_file = os.path.join(desc_pkg, 'urdf', 'atlasarm6.urdf.xacro')
    world_file = os.path.join(gz_pkg, 'worlds', 'atlasarm6_workspace.world')
    robot_desc = Command(['xacro ', xacro_file])

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
PYEOF

cat > launch/atlasarm6_full.launch.py << 'PYEOF'
"""Full system: Gazebo + ros2_control + MoveIt2 + RViz."""
import os
from launch import LaunchDescription
from launch.actions import IncludeLaunchDescription, TimerAction
from launch.launch_description_sources import PythonLaunchDescriptionSource
from ament_index_python.packages import get_package_share_directory


def generate_launch_description():
    bringup = get_package_share_directory('atlasarm_bringup')
    moveit = get_package_share_directory('atlasarm_moveit_config')

    gazebo = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(bringup, 'launch', 'atlasarm6_gazebo.launch.py'))
    )

    move_group = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(moveit, 'launch', 'move_group.launch.py'))
    )

    rviz = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(moveit, 'launch', 'moveit_rviz.launch.py'))
    )

    return LaunchDescription([
        gazebo,
        TimerAction(period=8.0, actions=[move_group]),
        TimerAction(period=10.0, actions=[rviz]),
    ])
PYEOF

cd ..
echo "  ✓ atlasarm_bringup"



# ──────────────────────────────────────────────────────────────
# Package 7: atlasarm_examples (Python)
# ──────────────────────────────────────────────────────────────
echo "[7/7] atlasarm_examples"
mkdir -p atlasarm_examples/{atlasarm_examples,resource,test}
cd atlasarm_examples

cat > package.xml << 'EOF'
<?xml version="1.0"?>
<package format="3">
  <name>atlasarm_examples</name>
  <version>1.0.0</version>
  <description>AtlasArm-6 demo scripts and Python API examples</description>
  <maintainer email="atlasarm@dev.local">atlasarm</maintainer>
  <license>MIT</license>
  <buildtool_depend>ament_python</buildtool_depend>
  <depend>rclpy</depend>
  <depend>std_msgs</depend>
  <depend>geometry_msgs</depend>
  <depend>trajectory_msgs</depend>
  <depend>atlasarm_interfaces</depend>
  <export><build_type>ament_python</build_type></export>
</package>
EOF

cat > setup.py << 'EOF'
from setuptools import setup

setup(
    name='atlasarm_examples',
    version='1.0.0',
    packages=['atlasarm_examples'],
    data_files=[
        ('share/ament_index/resource_index/packages',
         ['resource/atlasarm_examples']),
        ('share/atlasarm_examples', ['package.xml']),
    ],
    install_requires=['setuptools'],
    entry_points={'console_scripts': [
        'pick_and_place_demo = atlasarm_examples.pick_and_place_demo:main',
        'send_task = atlasarm_examples.send_task:main',
        'joint_test = atlasarm_examples.joint_test:main',
    ]},
)
EOF

cat > setup.cfg << 'EOF'
[develop]
script_dir=$base/lib/atlasarm_examples
[install]
install_scripts=$base/lib/atlasarm_examples
EOF

touch resource/atlasarm_examples
touch atlasarm_examples/__init__.py

# ─── joint_test.py — simple controller test ───
cat > atlasarm_examples/joint_test.py << 'PYEOF'
"""Simple joint controller test — sends a sinusoidal trajectory.
Verifies that the arm can be commanded without MoveIt2."""
import math
import time
import rclpy
from rclpy.node import Node
from trajectory_msgs.msg import JointTrajectory, JointTrajectoryPoint
from builtin_interfaces.msg import Duration


class JointTester(Node):
    def __init__(self):
        super().__init__('atlasarm6_joint_test')
        self.pub = self.create_publisher(
            JointTrajectory,
            '/atlasarm6_arm_controller/joint_trajectory',
            10)
        self.joints = ['aa6_j1', 'aa6_j2', 'aa6_j3',
                       'aa6_j4', 'aa6_j5', 'aa6_j6']
        self.get_logger().info('AtlasArm-6 Joint Tester ready')
        time.sleep(1.0)
        self.run_test()

    def send_pose(self, positions, duration_s=2.0):
        msg = JointTrajectory()
        msg.joint_names = self.joints
        pt = JointTrajectoryPoint()
        pt.positions = positions
        pt.time_from_start = Duration(sec=int(duration_s),
                                       nanosec=int((duration_s % 1) * 1e9))
        msg.points = [pt]
        self.pub.publish(msg)
        time.sleep(duration_s + 0.5)

    def run_test(self):
        self.get_logger().info('Step 1: Move to vertical (zeros)')
        self.send_pose([0.0, 0.0, 0.0, 0.0, 0.0, 0.0], 3.0)

        self.get_logger().info('Step 2: Move to home pose')
        self.send_pose([0.0, -1.5708, 1.5708, -1.5708, -1.5708, 0.0], 3.0)

        self.get_logger().info('Step 3: Move to ready pose')
        self.send_pose([0.0, -1.0472, 1.0472, -1.5708, -1.5708, 0.0], 3.0)

        self.get_logger().info('Step 4: Wave J1 left/right')
        self.send_pose([1.0, -1.0472, 1.0472, -1.5708, -1.5708, 0.0], 2.0)
        self.send_pose([-1.0, -1.0472, 1.0472, -1.5708, -1.5708, 0.0], 2.0)
        self.send_pose([0.0, -1.0472, 1.0472, -1.5708, -1.5708, 0.0], 2.0)

        self.get_logger().info('Step 5: Spin wrist J6')
        for ang in [1.5, 3.0, 1.5, 0.0]:
            self.send_pose([0.0, -1.0472, 1.0472, -1.5708, -1.5708, ang], 1.5)

        self.get_logger().info('Step 6: Return to home')
        self.send_pose([0.0, -1.5708, 1.5708, -1.5708, -1.5708, 0.0], 3.0)

        self.get_logger().info('Joint test complete')


def main(args=None):
    rclpy.init(args=args)
    JointTester()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
PYEOF

# ─── pick_and_place_demo.py — uses trajectory commands directly ───
cat > atlasarm_examples/pick_and_place_demo.py << 'PYEOF'
"""Pick-and-place demonstration using direct joint trajectory commands.
This works WITHOUT MoveIt2 — for systems where moveit_py isn't available."""
import time
import math
import rclpy
from rclpy.node import Node
from trajectory_msgs.msg import JointTrajectory, JointTrajectoryPoint
from builtin_interfaces.msg import Duration

# Pre-computed joint configurations for demo
POSES = {
    'home':       [0.0, -1.5708,  1.5708, -1.5708, -1.5708, 0.0],
    'ready':      [0.0, -1.0472,  1.0472, -1.5708, -1.5708, 0.0],
    'pre_pick':   [0.0, -0.7854,  1.2217, -2.0071, -1.5708, 0.0],
    'pick':       [0.0, -0.5236,  1.4137, -2.4609, -1.5708, 0.0],
    'lift':       [0.0, -0.7854,  1.2217, -2.0071, -1.5708, 0.0],
    'pre_place':  [0.7854, -0.7854,  1.2217, -2.0071, -1.5708, 0.0],
    'place':      [0.7854, -0.5236,  1.4137, -2.4609, -1.5708, 0.0],
    'retract':    [0.7854, -0.7854,  1.2217, -2.0071, -1.5708, 0.0],
}


class PickPlaceDemo(Node):
    def __init__(self):
        super().__init__('atlasarm6_pick_place_demo')
        self.pub = self.create_publisher(
            JointTrajectory,
            '/atlasarm6_arm_controller/joint_trajectory',
            10)
        self.joints = ['aa6_j1', 'aa6_j2', 'aa6_j3',
                       'aa6_j4', 'aa6_j5', 'aa6_j6']
        self.get_logger().info('=== AtlasArm-6 Pick-and-Place Demo ===')
        time.sleep(1.0)
        self.run_demo()

    def goto(self, name, duration=2.5):
        if name not in POSES:
            self.get_logger().error(f'Unknown pose: {name}')
            return
        self.get_logger().info(f'→ {name}')
        msg = JointTrajectory()
        msg.joint_names = self.joints
        pt = JointTrajectoryPoint()
        pt.positions = POSES[name]
        pt.time_from_start = Duration(sec=int(duration),
                                       nanosec=int((duration % 1) * 1e9))
        msg.points = [pt]
        self.pub.publish(msg)
        time.sleep(duration + 0.5)

    def run_demo(self):
        # Phase 1: Initialize
        self.goto('ready', 3.0)
        time.sleep(0.5)

        # Phase 2: Approach pick
        self.get_logger().info('--- PICK SEQUENCE ---')
        self.goto('pre_pick', 2.5)
        self.goto('pick', 2.0)
        self.get_logger().info('[Gripper would close here]')
        time.sleep(1.0)
        self.goto('lift', 2.0)

        # Phase 3: Move to place
        self.get_logger().info('--- PLACE SEQUENCE ---')
        self.goto('pre_place', 3.0)
        self.goto('place', 2.0)
        self.get_logger().info('[Gripper would open here]')
        time.sleep(1.0)
        self.goto('retract', 2.0)

        # Phase 4: Return home
        self.get_logger().info('--- RETURN HOME ---')
        self.goto('ready', 3.0)
        self.goto('home', 3.0)

        self.get_logger().info('=== DEMO COMPLETE ===')


def main(args=None):
    rclpy.init(args=args)
    PickPlaceDemo()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
PYEOF

# ─── send_task.py — CLI for sending tasks ───
cat > atlasarm_examples/send_task.py << 'PYEOF'
"""CLI: Send a manipulation task to AtlasArm-6.
Usage: ros2 run atlasarm_examples send_task --pick X Y Z --place X Y Z"""
import sys
import uuid
import time
import argparse
import rclpy
from atlasarm_interfaces.msg import ManipulationTask
from geometry_msgs.msg import PoseStamped


def make_pose(x, y, z) -> PoseStamped:
    p = PoseStamped()
    p.header.frame_id = 'world'
    p.pose.position.x = float(x)
    p.pose.position.y = float(y)
    p.pose.position.z = float(z)
    p.pose.orientation.x = 0.0
    p.pose.orientation.y = 1.0
    p.pose.orientation.z = 0.0
    p.pose.orientation.w = 0.0
    return p


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--pick', nargs=3, type=float,
                        default=[0.4, 0.0, 0.45])
    parser.add_argument('--place', nargs=3, type=float,
                        default=[0.4, 0.3, 0.45])
    parser.add_argument('--type', default='pick_and_place')
    args, ros_args = parser.parse_known_args()

    rclpy.init(args=ros_args)
    node = rclpy.create_node('atlasarm6_send_task')
    pub = node.create_publisher(ManipulationTask, '/atlasarm6/task_cmd', 10)
    time.sleep(0.5)

    task = ManipulationTask()
    task.task_id = f'cli-{uuid.uuid4().hex[:6]}'
    task.task_type = args.type
    task.pick_pose = make_pose(*args.pick)
    task.place_pose = make_pose(*args.place)
    task.priority = 1

    pub.publish(task)
    print(f'Sent task: {task.task_id}')
    print(f'  Pick:  {args.pick}')
    print(f'  Place: {args.place}')

    time.sleep(0.5)
    node.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
PYEOF

cd ..
echo "  ✓ atlasarm_examples"

# ──────────────────────────────────────────────────────────────
# Helper run scripts at workspace root
# ──────────────────────────────────────────────────────────────
WS_ROOT="$(dirname $SRC)"
echo ""
echo "Creating helper scripts in $WS_ROOT..."

cat > "$WS_ROOT/run_display.sh" << 'EOF'
#!/bin/bash
# View AtlasArm-6 in RViz with joint sliders
source /opt/ros/humble/setup.bash
source "$(dirname $0)/install/setup.bash"
ros2 launch atlasarm_description display.launch.py
EOF
chmod +x "$WS_ROOT/run_display.sh"

cat > "$WS_ROOT/run_gazebo.sh" << 'EOF'
#!/bin/bash
# Launch AtlasArm-6 in Gazebo (no MoveIt2)
source /opt/ros/humble/setup.bash
source "$(dirname $0)/install/setup.bash"
ros2 launch atlasarm_bringup atlasarm6_gazebo.launch.py
EOF
chmod +x "$WS_ROOT/run_gazebo.sh"

cat > "$WS_ROOT/run_full.sh" << 'EOF'
#!/bin/bash
# Launch AtlasArm-6 full system: Gazebo + MoveIt2 + RViz
source /opt/ros/humble/setup.bash
source "$(dirname $0)/install/setup.bash"
ros2 launch atlasarm_bringup atlasarm6_full.launch.py
EOF
chmod +x "$WS_ROOT/run_full.sh"

cat > "$WS_ROOT/run_demo.sh" << 'EOF'
#!/bin/bash
# Run the pick-and-place demonstration
# (Requires Gazebo to be already running — use run_gazebo.sh first)
source /opt/ros/humble/setup.bash
source "$(dirname $0)/install/setup.bash"
ros2 run atlasarm_examples pick_and_place_demo
EOF
chmod +x "$WS_ROOT/run_demo.sh"

cat > "$WS_ROOT/run_joint_test.sh" << 'EOF'
#!/bin/bash
# Quick test that the arm responds to commands
source /opt/ros/humble/setup.bash
source "$(dirname $0)/install/setup.bash"
ros2 run atlasarm_examples joint_test
EOF
chmod +x "$WS_ROOT/run_joint_test.sh"

cat > "$WS_ROOT/rebuild.sh" << 'EOF'
#!/bin/bash
# Clean rebuild of the workspace
cd "$(dirname $0)"
source /opt/ros/humble/setup.bash
rm -rf build install log
colcon build --symlink-install
echo ""
echo "Build complete. Source the workspace with:"
echo "  source $(pwd)/install/setup.bash"
EOF
chmod +x "$WS_ROOT/rebuild.sh"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " AtlasArm-6 workspace generated successfully"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Packages created in $SRC:"
ls -1 "$SRC"
echo ""
echo "Helper scripts in $WS_ROOT:"
ls -1 "$WS_ROOT"/*.sh 2>/dev/null
echo ""
