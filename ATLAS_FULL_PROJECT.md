# Atlas Warehouse AGV Project

---
## FILE: src/atlas_description/urdf/atlas_agv.urdf.xacro
```
<?xml version="1.0"?>
<robot name="atlas_agv" xmlns:xacro="http://www.ros.org/wiki/xacro">
  <xacro:property name="WR" value="0.05"/>
  <xacro:property name="WT" value="0.04"/>
  <xacro:property name="WS" value="0.30"/>
  <xacro:property name="BX" value="0.30"/>
  <xacro:property name="BY" value="0.25"/>
  <xacro:property name="BZ" value="0.10"/>
  <xacro:property name="BM" value="2.5"/>
  <xacro:property name="WM" value="0.2"/>
  <xacro:property name="CR" value="0.025"/>
  <xacro:property name="PI" value="3.14159265359"/>

  <link name="base_footprint"/>
  <joint name="base_joint" type="fixed">
    <parent link="base_footprint"/>
    <child link="base_link"/>
    <origin xyz="0 0 ${WR}" rpy="0 0 0"/>
  </joint>

  <link name="base_link">
    <visual>
      <origin xyz="0 0 ${BZ/2}"/>
      <geometry><box size="${BX} ${BY} ${BZ}"/></geometry>
      <material name="blue"><color rgba="0.1 0.2 0.6 1"/></material>
    </visual>
    <collision>
      <origin xyz="0 0 ${BZ/2}"/>
      <geometry><box size="${BX} ${BY} ${BZ}"/></geometry>
    </collision>
    <inertial>
      <mass value="${BM}"/>
      <inertia ixx="${BM*(BY*BY+BZ*BZ)/12}" ixy="0" ixz="0"
               iyy="${BM*(BX*BX+BZ*BZ)/12}" iyz="0"
               izz="${BM*(BX*BX+BY*BY)/12}"/>
    </inertial>
  </link>

  <xacro:macro name="wheel" params="name y_sign">
    <link name="${name}_wheel">
      <visual>
        <origin rpy="${PI/2} 0 0"/>
        <geometry><cylinder radius="${WR}" length="${WT}"/></geometry>
        <material name="black"><color rgba="0.1 0.1 0.1 1"/></material>
      </visual>
      <collision>
        <origin rpy="${PI/2} 0 0"/>
        <geometry><cylinder radius="${WR}" length="${WT}"/></geometry>
      </collision>
      <inertial>
        <mass value="${WM}"/>
        <inertia ixx="${WM*(3*WR*WR+WT*WT)/12}" ixy="0" ixz="0"
                 iyy="${WM*(3*WR*WR+WT*WT)/12}" iyz="0"
                 izz="${WM*WR*WR/2}"/>
      </inertial>
    </link>
    <joint name="${name}_wheel_joint" type="continuous">
      <parent link="base_link"/>
      <child link="${name}_wheel"/>
      <origin xyz="0 ${y_sign*WS/2} 0"/>
      <axis xyz="0 1 0"/>
      <dynamics damping="0.5" friction="0.3"/>
    </joint>
    <gazebo reference="${name}_wheel">
      <mu1>1.5</mu1><mu2>1.0</mu2>
      <kp>1e6</kp><kd>10</kd>
      <minDepth>0.001</minDepth>
    </gazebo>
  </xacro:macro>

  <xacro:wheel name="left" y_sign="1"/>
  <xacro:wheel name="right" y_sign="-1"/>

  <link name="caster_wheel">
    <visual><geometry><sphere radius="${CR}"/></geometry></visual>
    <collision><geometry><sphere radius="${CR}"/></geometry></collision>
    <inertial>
      <mass value="0.05"/>
      <inertia ixx="1e-5" ixy="0" ixz="0" iyy="1e-5" iyz="0" izz="1e-5"/>
    </inertial>
  </link>
  <joint name="caster_joint" type="fixed">
    <parent link="base_link"/>
    <child link="caster_wheel"/>
    <origin xyz="0.12 0 ${CR-WR}"/>
  </joint>
  <gazebo reference="caster_wheel">
    <mu1>0.0</mu1><mu2>0.0</mu2>
  </gazebo>

  <!-- IMU -->
  <link name="imu_link"/>
  <joint name="imu_joint" type="fixed">
    <parent link="base_link"/><child link="imu_link"/>
    <origin xyz="0 0 ${BZ/2}"/>
  </joint>
  <gazebo reference="imu_link">
    <sensor name="atlas_imu" type="imu">
      <always_on>true</always_on>
      <update_rate>100</update_rate>
      <plugin name="imu_plugin" filename="libgazebo_ros_imu_sensor.so">
        <ros><namespace>/atlas</namespace>
        <remapping>~/out:=imu</remapping></ros>
        <frame_name>imu_link</frame_name>
      </plugin>
    </sensor>
  </gazebo>

  <!-- Diff drive -->
  <gazebo>
    <plugin name="atlas_drive" filename="libgazebo_ros_diff_drive.so">
      <ros><namespace>/atlas</namespace></ros>
      <update_rate>50</update_rate>
      <left_joint>left_wheel_joint</left_joint>
      <right_joint>right_wheel_joint</right_joint>
      <wheel_separation>${WS}</wheel_separation>
      <wheel_diameter>${2*WR}</wheel_diameter>
      <max_wheel_torque>5.0</max_wheel_torque>
      <max_wheel_acceleration>2.0</max_wheel_acceleration>
      <publish_odom>true</publish_odom>
      <publish_odom_tf>true</publish_odom_tf>
      <publish_wheel_tf>true</publish_wheel_tf>
      <odometry_frame>odom</odometry_frame>
      <robot_base_frame>base_footprint</robot_base_frame>
      <command_topic>cmd_vel</command_topic>
      <odometry_topic>odom</odometry_topic>
    </plugin>
  </gazebo>

  <gazebo reference="base_link">
    <material>Gazebo/Blue</material>
  </gazebo>
</robot>
```

---
## FILE: src/atlas_description/package.xml
```
<?xml version="1.0"?>
<package format="3">
  <name>atlas_description</name>
  <version>1.0.0</version>
  <description>ATLAS AGV robot description</description>
  <maintainer email="atlas@dev.local">atlas</maintainer>
  <license>MIT</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <exec_depend>robot_state_publisher</exec_depend>
  <exec_depend>joint_state_publisher</exec_depend>
  <exec_depend>xacro</exec_depend>
  <exec_depend>gazebo_ros</exec_depend>
  <export><build_type>ament_cmake</build_type></export>
</package>
```

---
## FILE: src/atlas_bringup/launch/atlas_full.launch.py
```
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
```

---
## FILE: src/atlas_bringup/package.xml
```
<?xml version="1.0"?>
<package format="3">
  <name>atlas_bringup</name>
  <version>1.0.0</version>
  <description>ATLAS master launch</description>
  <maintainer email="atlas@dev.local">atlas</maintainer>
  <license>MIT</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <exec_depend>atlas_description</exec_depend>
  <exec_depend>atlas_gazebo</exec_depend>
  <exec_depend>atlas_navigation</exec_depend>
  <exec_depend>atlas_mission_manager</exec_depend>
  <exec_depend>atlas_interfaces</exec_depend>
  <exec_depend>gazebo_ros</exec_depend>
  <exec_depend>robot_state_publisher</exec_depend>
  <exec_depend>xacro</exec_depend>
  <exec_depend>rviz2</exec_depend>
  <export><build_type>ament_cmake</build_type></export>
</package>
```

---
## FILE: src/atlas_interfaces/package.xml
```
<?xml version="1.0"?>
<package format="3">
  <name>atlas_interfaces</name>
  <version>1.0.0</version>
  <description>ATLAS Fleet custom message definitions</description>
  <maintainer email="atlas@dev.local">atlas</maintainer>
  <license>MIT</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <buildtool_depend>rosidl_default_generators</buildtool_depend>
  <depend>std_msgs</depend>
  <depend>geometry_msgs</depend>
  <exec_depend>rosidl_default_runtime</exec_depend>
  <member_of_group>rosidl_interface_packages</member_of_group>
  <export><build_type>ament_cmake</build_type></export>
</package>
```

---
## FILE: src/atlas_gazebo/worlds/warehouse.world
```
<?xml version='1.0'?>
<sdf version='1.6'>
<world name='atlas_warehouse'>
  <gravity>0 0 -9.81</gravity>
  <physics type='ode'>
    <max_step_size>0.001</max_step_size>
    <real_time_factor>1.0</real_time_factor>
    <real_time_update_rate>1000</real_time_update_rate>
    <ode>
      <solver><type>quick</type><iters>50</iters></solver>
    </ode>
  </physics>
  <scene>
    <ambient>0.6 0.6 0.6 1</ambient>
    <background>0.3 0.3 0.35 1</background>
    <shadows>1</shadows>
  </scene>
  <light name='warehouse_sun' type='directional'>
    <cast_shadows>true</cast_shadows>
    <pose>5 6 10 0 0 0</pose>
    <diffuse>0.8 0.8 0.75 1</diffuse>
    <specular>0.2 0.2 0.2 1</specular>
    <direction>-0.3 -0.2 -1</direction>
  </light>
  <light name='fill_light' type='directional'>
    <cast_shadows>false</cast_shadows>
    <pose>0 0 8 0 0 0</pose>
    <diffuse>0.3 0.3 0.35 1</diffuse>
    <specular>0.05 0.05 0.05 1</specular>
    <direction>0.2 0.3 -1</direction>
  </light>
  <include><uri>model://ground_plane</uri></include>

    <model name='floor_main'><static>true</static>
      <pose>4 6 -0.01 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>16 16 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>16 16 0.02</size></box></geometry>
          <material><ambient>0.45 0.43 0.4 1.0</ambient><diffuse>0.45 0.43 0.4 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='floor_load'><static>true</static>
      <pose>0 -0.5 -0.005 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>2 1.5 0.01</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>2 1.5 0.01</size></box></geometry>
          <material><ambient>0.55 0.5 0.3 1.0</ambient><diffuse>0.55 0.5 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='floor_charge'><static>true</static>
      <pose>-1.5 0 -0.005 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>1.0 1.0 0.01</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>1.0 1.0 0.01</size></box></geometry>
          <material><ambient>0.25 0.3 0.45 1.0</ambient><diffuse>0.25 0.3 0.45 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='spine_line'><static>true</static>
      <pose>0 6 0.001 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.05 12 0.002</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.05 12 0.002</size></box></geometry>
          <material><ambient>0.05 0.05 0.05 1.0</ambient><diffuse>0.05 0.05 0.05 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='aisle_line_1'><static>true</static>
      <pose>2.5 2 0.001 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>5 0.05 0.002</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>5 0.05 0.002</size></box></geometry>
          <material><ambient>0.05 0.05 0.05 1.0</ambient><diffuse>0.05 0.05 0.05 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='aisle_line_2'><static>true</static>
      <pose>2.5 4 0.001 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>5 0.05 0.002</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>5 0.05 0.002</size></box></geometry>
          <material><ambient>0.05 0.05 0.05 1.0</ambient><diffuse>0.05 0.05 0.05 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='aisle_line_3'><static>true</static>
      <pose>2.5 6 0.001 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>5 0.05 0.002</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>5 0.05 0.002</size></box></geometry>
          <material><ambient>0.05 0.05 0.05 1.0</ambient><diffuse>0.05 0.05 0.05 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='aisle_line_4'><static>true</static>
      <pose>2.5 8 0.001 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>5 0.05 0.002</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>5 0.05 0.002</size></box></geometry>
          <material><ambient>0.05 0.05 0.05 1.0</ambient><diffuse>0.05 0.05 0.05 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='aisle_line_5'><static>true</static>
      <pose>2.5 10 0.001 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>5 0.05 0.002</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>5 0.05 0.002</size></box></geometry>
          <material><ambient>0.05 0.05 0.05 1.0</ambient><diffuse>0.05 0.05 0.05 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='lane_L'><static>true</static>
      <pose>-0.15 6 0.0008 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.02 12 0.001</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.02 12 0.001</size></box></geometry>
          <material><ambient>0.8 0.7 0.0 1.0</ambient><diffuse>0.8 0.7 0.0 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='lane_R'><static>true</static>
      <pose>0.15 6 0.0008 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.02 12 0.001</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.02 12 0.001</size></box></geometry>
          <material><ambient>0.8 0.7 0.0 1.0</ambient><diffuse>0.8 0.7 0.0 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='alane_U0'><static>true</static>
      <pose>2.5 2.12 0.0008 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>5 0.015 0.001</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>5 0.015 0.001</size></box></geometry>
          <material><ambient>0.8 0.7 0.0 1.0</ambient><diffuse>0.8 0.7 0.0 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='alane_D0'><static>true</static>
      <pose>2.5 1.88 0.0008 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>5 0.015 0.001</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>5 0.015 0.001</size></box></geometry>
          <material><ambient>0.8 0.7 0.0 1.0</ambient><diffuse>0.8 0.7 0.0 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='alane_U1'><static>true</static>
      <pose>2.5 4.12 0.0008 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>5 0.015 0.001</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>5 0.015 0.001</size></box></geometry>
          <material><ambient>0.8 0.7 0.0 1.0</ambient><diffuse>0.8 0.7 0.0 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='alane_D1'><static>true</static>
      <pose>2.5 3.88 0.0008 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>5 0.015 0.001</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>5 0.015 0.001</size></box></geometry>
          <material><ambient>0.8 0.7 0.0 1.0</ambient><diffuse>0.8 0.7 0.0 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='alane_U2'><static>true</static>
      <pose>2.5 6.12 0.0008 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>5 0.015 0.001</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>5 0.015 0.001</size></box></geometry>
          <material><ambient>0.8 0.7 0.0 1.0</ambient><diffuse>0.8 0.7 0.0 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='alane_D2'><static>true</static>
      <pose>2.5 5.88 0.0008 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>5 0.015 0.001</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>5 0.015 0.001</size></box></geometry>
          <material><ambient>0.8 0.7 0.0 1.0</ambient><diffuse>0.8 0.7 0.0 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='alane_U3'><static>true</static>
      <pose>2.5 8.12 0.0008 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>5 0.015 0.001</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>5 0.015 0.001</size></box></geometry>
          <material><ambient>0.8 0.7 0.0 1.0</ambient><diffuse>0.8 0.7 0.0 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='alane_D3'><static>true</static>
      <pose>2.5 7.88 0.0008 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>5 0.015 0.001</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>5 0.015 0.001</size></box></geometry>
          <material><ambient>0.8 0.7 0.0 1.0</ambient><diffuse>0.8 0.7 0.0 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='alane_U4'><static>true</static>
      <pose>2.5 10.12 0.0008 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>5 0.015 0.001</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>5 0.015 0.001</size></box></geometry>
          <material><ambient>0.8 0.7 0.0 1.0</ambient><diffuse>0.8 0.7 0.0 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='alane_D4'><static>true</static>
      <pose>2.5 9.88 0.0008 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>5 0.015 0.001</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>5 0.015 0.001</size></box></geometry>
          <material><ambient>0.8 0.7 0.0 1.0</ambient><diffuse>0.8 0.7 0.0 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='home_pad'><static>true</static>
      <pose>0 0 0.001 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.7 0.7 0.002</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.7 0.7 0.002</size></box></geometry>
          <material><ambient>0.1 0.7 0.2 1.0</ambient><diffuse>0.1 0.7 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='dock_border_n'><static>true</static>
      <pose>0 0.35 0.002 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.7 0.03 0.004</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.7 0.03 0.004</size></box></geometry>
          <material><ambient>0.0 0.9 0.3 1.0</ambient><diffuse>0.0 0.9 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='dock_border_s'><static>true</static>
      <pose>0 -0.35 0.002 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.7 0.03 0.004</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.7 0.03 0.004</size></box></geometry>
          <material><ambient>0.0 0.9 0.3 1.0</ambient><diffuse>0.0 0.9 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='dock_border_e'><static>true</static>
      <pose>0.35 0 0.002 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.03 0.7 0.004</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.03 0.7 0.004</size></box></geometry>
          <material><ambient>0.0 0.9 0.3 1.0</ambient><diffuse>0.0 0.9 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='dock_border_w'><static>true</static>
      <pose>-0.35 0 0.002 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.03 0.7 0.004</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.03 0.7 0.004</size></box></geometry>
          <material><ambient>0.0 0.9 0.3 1.0</ambient><diffuse>0.0 0.9 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='dock_post'><static>true</static>
      <pose>-0.5 0 0.4 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.03</radius><length>0.8</length></cylinder></geometry>
          <material><ambient>0.3 0.3 0.3 1</ambient><diffuse>0.3 0.3 0.3 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='dock_sign'><static>true</static>
      <pose>-0.5 0 0.85 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.3 0.02 0.15</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.3 0.02 0.15</size></box></geometry>
          <material><ambient>0.1 0.5 0.2 1.0</ambient><diffuse>0.1 0.5 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='charger_base'><static>true</static>
      <pose>-1.5 0 0.15 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.4 0.4 0.3</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.4 0.4 0.3</size></box></geometry>
          <material><ambient>0.2 0.2 0.3 1.0</ambient><diffuse>0.2 0.2 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='charger_arm'><static>true</static>
      <pose>-1.5 0 0.4 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.1 0.1 0.2</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.1 0.1 0.2</size></box></geometry>
          <material><ambient>0.4 0.4 0.5 1.0</ambient><diffuse>0.4 0.4 0.5 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='charge_light'><static>true</static>
      <pose>-1.5 0 0.55 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.03</radius><length>0.04</length></cylinder></geometry>
          <material><ambient>0.0 0.9 0.2 1</ambient><diffuse>0.0 0.9 0.2 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rack_1'><static>true</static>
      <pose>1.0 2.45 0.4 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.5 0.35 0.8</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.5 0.35 0.8</size></box></geometry>
          <material><ambient>0.3 0.25 0.2 1.0</ambient><diffuse>0.3 0.25 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b1_1'><static>true</static>
      <pose>1.0 2.45 0.25 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b2_1'><static>true</static>
      <pose>1.0 2.45 0.55 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b3_1'><static>true</static>
      <pose>1.0 2.45 0.8 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box1_1'><static>true</static>
      <pose>0.9 2.45 0.32 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.15 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.15 0.2 0.12</size></box></geometry>
          <material><ambient>0.6 0.5 0.3 1.0</ambient><diffuse>0.6 0.5 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box2_1'><static>true</static>
      <pose>1.1 2.45 0.62 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.18 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.18 0.2 0.12</size></box></geometry>
          <material><ambient>0.4 0.35 0.25 1.0</ambient><diffuse>0.4 0.35 0.25 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='label_1'><static>true</static>
      <pose>1.0 2.63 0.5 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.12 0.01 0.06</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.12 0.01 0.06</size></box></geometry>
          <material><ambient>0.9 0.9 0.9 1.0</ambient><diffuse>0.9 0.9 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rack_2'><static>true</static>
      <pose>2.0 2.45 0.4 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.5 0.35 0.8</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.5 0.35 0.8</size></box></geometry>
          <material><ambient>0.3 0.25 0.2 1.0</ambient><diffuse>0.3 0.25 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b1_2'><static>true</static>
      <pose>2.0 2.45 0.25 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b2_2'><static>true</static>
      <pose>2.0 2.45 0.55 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b3_2'><static>true</static>
      <pose>2.0 2.45 0.8 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box1_2'><static>true</static>
      <pose>1.9 2.45 0.32 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.15 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.15 0.2 0.12</size></box></geometry>
          <material><ambient>0.4 0.35 0.25 1.0</ambient><diffuse>0.4 0.35 0.25 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box2_2'><static>true</static>
      <pose>2.1 2.45 0.62 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.18 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.18 0.2 0.12</size></box></geometry>
          <material><ambient>0.5 0.4 0.2 1.0</ambient><diffuse>0.5 0.4 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='label_2'><static>true</static>
      <pose>2.0 2.63 0.5 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.12 0.01 0.06</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.12 0.01 0.06</size></box></geometry>
          <material><ambient>0.9 0.9 0.9 1.0</ambient><diffuse>0.9 0.9 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rack_3'><static>true</static>
      <pose>3.0 2.45 0.4 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.5 0.35 0.8</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.5 0.35 0.8</size></box></geometry>
          <material><ambient>0.3 0.25 0.2 1.0</ambient><diffuse>0.3 0.25 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b1_3'><static>true</static>
      <pose>3.0 2.45 0.25 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b2_3'><static>true</static>
      <pose>3.0 2.45 0.55 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b3_3'><static>true</static>
      <pose>3.0 2.45 0.8 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box1_3'><static>true</static>
      <pose>2.9 2.45 0.32 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.15 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.15 0.2 0.12</size></box></geometry>
          <material><ambient>0.5 0.4 0.2 1.0</ambient><diffuse>0.5 0.4 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box2_3'><static>true</static>
      <pose>3.1 2.45 0.62 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.18 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.18 0.2 0.12</size></box></geometry>
          <material><ambient>0.7 0.6 0.4 1.0</ambient><diffuse>0.7 0.6 0.4 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='label_3'><static>true</static>
      <pose>3.0 2.63 0.5 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.12 0.01 0.06</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.12 0.01 0.06</size></box></geometry>
          <material><ambient>0.9 0.9 0.9 1.0</ambient><diffuse>0.9 0.9 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rack_4'><static>true</static>
      <pose>4.0 2.45 0.4 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.5 0.35 0.8</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.5 0.35 0.8</size></box></geometry>
          <material><ambient>0.3 0.25 0.2 1.0</ambient><diffuse>0.3 0.25 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b1_4'><static>true</static>
      <pose>4.0 2.45 0.25 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b2_4'><static>true</static>
      <pose>4.0 2.45 0.55 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b3_4'><static>true</static>
      <pose>4.0 2.45 0.8 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box1_4'><static>true</static>
      <pose>3.9 2.45 0.32 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.15 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.15 0.2 0.12</size></box></geometry>
          <material><ambient>0.7 0.6 0.4 1.0</ambient><diffuse>0.7 0.6 0.4 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box2_4'><static>true</static>
      <pose>4.1 2.45 0.62 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.18 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.18 0.2 0.12</size></box></geometry>
          <material><ambient>0.6 0.5 0.3 1.0</ambient><diffuse>0.6 0.5 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='label_4'><static>true</static>
      <pose>4.0 2.63 0.5 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.12 0.01 0.06</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.12 0.01 0.06</size></box></geometry>
          <material><ambient>0.9 0.9 0.9 1.0</ambient><diffuse>0.9 0.9 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rack_5'><static>true</static>
      <pose>1.0 4.45 0.4 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.5 0.35 0.8</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.5 0.35 0.8</size></box></geometry>
          <material><ambient>0.3 0.25 0.2 1.0</ambient><diffuse>0.3 0.25 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b1_5'><static>true</static>
      <pose>1.0 4.45 0.25 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b2_5'><static>true</static>
      <pose>1.0 4.45 0.55 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b3_5'><static>true</static>
      <pose>1.0 4.45 0.8 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box1_5'><static>true</static>
      <pose>0.9 4.45 0.32 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.15 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.15 0.2 0.12</size></box></geometry>
          <material><ambient>0.6 0.5 0.3 1.0</ambient><diffuse>0.6 0.5 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box2_5'><static>true</static>
      <pose>1.1 4.45 0.62 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.18 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.18 0.2 0.12</size></box></geometry>
          <material><ambient>0.4 0.35 0.25 1.0</ambient><diffuse>0.4 0.35 0.25 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='label_5'><static>true</static>
      <pose>1.0 4.63 0.5 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.12 0.01 0.06</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.12 0.01 0.06</size></box></geometry>
          <material><ambient>0.9 0.9 0.9 1.0</ambient><diffuse>0.9 0.9 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rack_6'><static>true</static>
      <pose>2.0 4.45 0.4 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.5 0.35 0.8</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.5 0.35 0.8</size></box></geometry>
          <material><ambient>0.3 0.25 0.2 1.0</ambient><diffuse>0.3 0.25 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b1_6'><static>true</static>
      <pose>2.0 4.45 0.25 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b2_6'><static>true</static>
      <pose>2.0 4.45 0.55 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b3_6'><static>true</static>
      <pose>2.0 4.45 0.8 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box1_6'><static>true</static>
      <pose>1.9 4.45 0.32 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.15 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.15 0.2 0.12</size></box></geometry>
          <material><ambient>0.4 0.35 0.25 1.0</ambient><diffuse>0.4 0.35 0.25 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box2_6'><static>true</static>
      <pose>2.1 4.45 0.62 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.18 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.18 0.2 0.12</size></box></geometry>
          <material><ambient>0.5 0.4 0.2 1.0</ambient><diffuse>0.5 0.4 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='label_6'><static>true</static>
      <pose>2.0 4.63 0.5 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.12 0.01 0.06</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.12 0.01 0.06</size></box></geometry>
          <material><ambient>0.9 0.9 0.9 1.0</ambient><diffuse>0.9 0.9 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rack_7'><static>true</static>
      <pose>3.0 4.45 0.4 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.5 0.35 0.8</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.5 0.35 0.8</size></box></geometry>
          <material><ambient>0.3 0.25 0.2 1.0</ambient><diffuse>0.3 0.25 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b1_7'><static>true</static>
      <pose>3.0 4.45 0.25 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b2_7'><static>true</static>
      <pose>3.0 4.45 0.55 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b3_7'><static>true</static>
      <pose>3.0 4.45 0.8 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box1_7'><static>true</static>
      <pose>2.9 4.45 0.32 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.15 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.15 0.2 0.12</size></box></geometry>
          <material><ambient>0.5 0.4 0.2 1.0</ambient><diffuse>0.5 0.4 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box2_7'><static>true</static>
      <pose>3.1 4.45 0.62 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.18 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.18 0.2 0.12</size></box></geometry>
          <material><ambient>0.7 0.6 0.4 1.0</ambient><diffuse>0.7 0.6 0.4 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='label_7'><static>true</static>
      <pose>3.0 4.63 0.5 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.12 0.01 0.06</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.12 0.01 0.06</size></box></geometry>
          <material><ambient>0.9 0.9 0.9 1.0</ambient><diffuse>0.9 0.9 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rack_8'><static>true</static>
      <pose>4.0 4.45 0.4 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.5 0.35 0.8</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.5 0.35 0.8</size></box></geometry>
          <material><ambient>0.3 0.25 0.2 1.0</ambient><diffuse>0.3 0.25 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b1_8'><static>true</static>
      <pose>4.0 4.45 0.25 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b2_8'><static>true</static>
      <pose>4.0 4.45 0.55 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b3_8'><static>true</static>
      <pose>4.0 4.45 0.8 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box1_8'><static>true</static>
      <pose>3.9 4.45 0.32 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.15 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.15 0.2 0.12</size></box></geometry>
          <material><ambient>0.7 0.6 0.4 1.0</ambient><diffuse>0.7 0.6 0.4 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box2_8'><static>true</static>
      <pose>4.1 4.45 0.62 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.18 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.18 0.2 0.12</size></box></geometry>
          <material><ambient>0.6 0.5 0.3 1.0</ambient><diffuse>0.6 0.5 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='label_8'><static>true</static>
      <pose>4.0 4.63 0.5 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.12 0.01 0.06</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.12 0.01 0.06</size></box></geometry>
          <material><ambient>0.9 0.9 0.9 1.0</ambient><diffuse>0.9 0.9 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rack_9'><static>true</static>
      <pose>1.0 6.45 0.4 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.5 0.35 0.8</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.5 0.35 0.8</size></box></geometry>
          <material><ambient>0.3 0.25 0.2 1.0</ambient><diffuse>0.3 0.25 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b1_9'><static>true</static>
      <pose>1.0 6.45 0.25 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b2_9'><static>true</static>
      <pose>1.0 6.45 0.55 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b3_9'><static>true</static>
      <pose>1.0 6.45 0.8 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box1_9'><static>true</static>
      <pose>0.9 6.45 0.32 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.15 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.15 0.2 0.12</size></box></geometry>
          <material><ambient>0.6 0.5 0.3 1.0</ambient><diffuse>0.6 0.5 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box2_9'><static>true</static>
      <pose>1.1 6.45 0.62 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.18 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.18 0.2 0.12</size></box></geometry>
          <material><ambient>0.4 0.35 0.25 1.0</ambient><diffuse>0.4 0.35 0.25 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='label_9'><static>true</static>
      <pose>1.0 6.63 0.5 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.12 0.01 0.06</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.12 0.01 0.06</size></box></geometry>
          <material><ambient>0.9 0.9 0.9 1.0</ambient><diffuse>0.9 0.9 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rack_10'><static>true</static>
      <pose>2.0 6.45 0.4 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.5 0.35 0.8</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.5 0.35 0.8</size></box></geometry>
          <material><ambient>0.3 0.25 0.2 1.0</ambient><diffuse>0.3 0.25 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b1_10'><static>true</static>
      <pose>2.0 6.45 0.25 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b2_10'><static>true</static>
      <pose>2.0 6.45 0.55 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b3_10'><static>true</static>
      <pose>2.0 6.45 0.8 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box1_10'><static>true</static>
      <pose>1.9 6.45 0.32 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.15 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.15 0.2 0.12</size></box></geometry>
          <material><ambient>0.4 0.35 0.25 1.0</ambient><diffuse>0.4 0.35 0.25 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box2_10'><static>true</static>
      <pose>2.1 6.45 0.62 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.18 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.18 0.2 0.12</size></box></geometry>
          <material><ambient>0.5 0.4 0.2 1.0</ambient><diffuse>0.5 0.4 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='label_10'><static>true</static>
      <pose>2.0 6.63 0.5 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.12 0.01 0.06</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.12 0.01 0.06</size></box></geometry>
          <material><ambient>0.9 0.9 0.9 1.0</ambient><diffuse>0.9 0.9 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rack_11'><static>true</static>
      <pose>3.0 6.45 0.4 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.5 0.35 0.8</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.5 0.35 0.8</size></box></geometry>
          <material><ambient>0.3 0.25 0.2 1.0</ambient><diffuse>0.3 0.25 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b1_11'><static>true</static>
      <pose>3.0 6.45 0.25 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b2_11'><static>true</static>
      <pose>3.0 6.45 0.55 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b3_11'><static>true</static>
      <pose>3.0 6.45 0.8 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box1_11'><static>true</static>
      <pose>2.9 6.45 0.32 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.15 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.15 0.2 0.12</size></box></geometry>
          <material><ambient>0.5 0.4 0.2 1.0</ambient><diffuse>0.5 0.4 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box2_11'><static>true</static>
      <pose>3.1 6.45 0.62 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.18 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.18 0.2 0.12</size></box></geometry>
          <material><ambient>0.7 0.6 0.4 1.0</ambient><diffuse>0.7 0.6 0.4 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='label_11'><static>true</static>
      <pose>3.0 6.63 0.5 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.12 0.01 0.06</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.12 0.01 0.06</size></box></geometry>
          <material><ambient>0.9 0.9 0.9 1.0</ambient><diffuse>0.9 0.9 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rack_12'><static>true</static>
      <pose>4.0 6.45 0.4 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.5 0.35 0.8</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.5 0.35 0.8</size></box></geometry>
          <material><ambient>0.3 0.25 0.2 1.0</ambient><diffuse>0.3 0.25 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b1_12'><static>true</static>
      <pose>4.0 6.45 0.25 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b2_12'><static>true</static>
      <pose>4.0 6.45 0.55 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b3_12'><static>true</static>
      <pose>4.0 6.45 0.8 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box1_12'><static>true</static>
      <pose>3.9 6.45 0.32 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.15 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.15 0.2 0.12</size></box></geometry>
          <material><ambient>0.7 0.6 0.4 1.0</ambient><diffuse>0.7 0.6 0.4 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box2_12'><static>true</static>
      <pose>4.1 6.45 0.62 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.18 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.18 0.2 0.12</size></box></geometry>
          <material><ambient>0.6 0.5 0.3 1.0</ambient><diffuse>0.6 0.5 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='label_12'><static>true</static>
      <pose>4.0 6.63 0.5 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.12 0.01 0.06</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.12 0.01 0.06</size></box></geometry>
          <material><ambient>0.9 0.9 0.9 1.0</ambient><diffuse>0.9 0.9 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rack_13'><static>true</static>
      <pose>1.0 8.45 0.4 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.5 0.35 0.8</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.5 0.35 0.8</size></box></geometry>
          <material><ambient>0.3 0.25 0.2 1.0</ambient><diffuse>0.3 0.25 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b1_13'><static>true</static>
      <pose>1.0 8.45 0.25 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b2_13'><static>true</static>
      <pose>1.0 8.45 0.55 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b3_13'><static>true</static>
      <pose>1.0 8.45 0.8 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box1_13'><static>true</static>
      <pose>0.9 8.45 0.32 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.15 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.15 0.2 0.12</size></box></geometry>
          <material><ambient>0.6 0.5 0.3 1.0</ambient><diffuse>0.6 0.5 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box2_13'><static>true</static>
      <pose>1.1 8.45 0.62 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.18 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.18 0.2 0.12</size></box></geometry>
          <material><ambient>0.4 0.35 0.25 1.0</ambient><diffuse>0.4 0.35 0.25 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='label_13'><static>true</static>
      <pose>1.0 8.63 0.5 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.12 0.01 0.06</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.12 0.01 0.06</size></box></geometry>
          <material><ambient>0.9 0.9 0.9 1.0</ambient><diffuse>0.9 0.9 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rack_14'><static>true</static>
      <pose>2.0 8.45 0.4 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.5 0.35 0.8</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.5 0.35 0.8</size></box></geometry>
          <material><ambient>0.3 0.25 0.2 1.0</ambient><diffuse>0.3 0.25 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b1_14'><static>true</static>
      <pose>2.0 8.45 0.25 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b2_14'><static>true</static>
      <pose>2.0 8.45 0.55 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b3_14'><static>true</static>
      <pose>2.0 8.45 0.8 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box1_14'><static>true</static>
      <pose>1.9 8.45 0.32 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.15 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.15 0.2 0.12</size></box></geometry>
          <material><ambient>0.4 0.35 0.25 1.0</ambient><diffuse>0.4 0.35 0.25 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box2_14'><static>true</static>
      <pose>2.1 8.45 0.62 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.18 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.18 0.2 0.12</size></box></geometry>
          <material><ambient>0.5 0.4 0.2 1.0</ambient><diffuse>0.5 0.4 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='label_14'><static>true</static>
      <pose>2.0 8.63 0.5 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.12 0.01 0.06</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.12 0.01 0.06</size></box></geometry>
          <material><ambient>0.9 0.9 0.9 1.0</ambient><diffuse>0.9 0.9 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rack_15'><static>true</static>
      <pose>3.0 8.45 0.4 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.5 0.35 0.8</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.5 0.35 0.8</size></box></geometry>
          <material><ambient>0.3 0.25 0.2 1.0</ambient><diffuse>0.3 0.25 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b1_15'><static>true</static>
      <pose>3.0 8.45 0.25 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b2_15'><static>true</static>
      <pose>3.0 8.45 0.55 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b3_15'><static>true</static>
      <pose>3.0 8.45 0.8 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box1_15'><static>true</static>
      <pose>2.9 8.45 0.32 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.15 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.15 0.2 0.12</size></box></geometry>
          <material><ambient>0.5 0.4 0.2 1.0</ambient><diffuse>0.5 0.4 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box2_15'><static>true</static>
      <pose>3.1 8.45 0.62 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.18 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.18 0.2 0.12</size></box></geometry>
          <material><ambient>0.7 0.6 0.4 1.0</ambient><diffuse>0.7 0.6 0.4 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='label_15'><static>true</static>
      <pose>3.0 8.63 0.5 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.12 0.01 0.06</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.12 0.01 0.06</size></box></geometry>
          <material><ambient>0.9 0.9 0.9 1.0</ambient><diffuse>0.9 0.9 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rack_16'><static>true</static>
      <pose>4.0 8.45 0.4 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.5 0.35 0.8</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.5 0.35 0.8</size></box></geometry>
          <material><ambient>0.3 0.25 0.2 1.0</ambient><diffuse>0.3 0.25 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b1_16'><static>true</static>
      <pose>4.0 8.45 0.25 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b2_16'><static>true</static>
      <pose>4.0 8.45 0.55 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b3_16'><static>true</static>
      <pose>4.0 8.45 0.8 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box1_16'><static>true</static>
      <pose>3.9 8.45 0.32 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.15 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.15 0.2 0.12</size></box></geometry>
          <material><ambient>0.7 0.6 0.4 1.0</ambient><diffuse>0.7 0.6 0.4 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box2_16'><static>true</static>
      <pose>4.1 8.45 0.62 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.18 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.18 0.2 0.12</size></box></geometry>
          <material><ambient>0.6 0.5 0.3 1.0</ambient><diffuse>0.6 0.5 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='label_16'><static>true</static>
      <pose>4.0 8.63 0.5 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.12 0.01 0.06</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.12 0.01 0.06</size></box></geometry>
          <material><ambient>0.9 0.9 0.9 1.0</ambient><diffuse>0.9 0.9 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rack_17'><static>true</static>
      <pose>1.0 10.45 0.4 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.5 0.35 0.8</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.5 0.35 0.8</size></box></geometry>
          <material><ambient>0.3 0.25 0.2 1.0</ambient><diffuse>0.3 0.25 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b1_17'><static>true</static>
      <pose>1.0 10.45 0.25 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b2_17'><static>true</static>
      <pose>1.0 10.45 0.55 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b3_17'><static>true</static>
      <pose>1.0 10.45 0.8 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box1_17'><static>true</static>
      <pose>0.9 10.45 0.32 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.15 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.15 0.2 0.12</size></box></geometry>
          <material><ambient>0.6 0.5 0.3 1.0</ambient><diffuse>0.6 0.5 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box2_17'><static>true</static>
      <pose>1.1 10.45 0.62 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.18 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.18 0.2 0.12</size></box></geometry>
          <material><ambient>0.4 0.35 0.25 1.0</ambient><diffuse>0.4 0.35 0.25 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='label_17'><static>true</static>
      <pose>1.0 10.63 0.5 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.12 0.01 0.06</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.12 0.01 0.06</size></box></geometry>
          <material><ambient>0.9 0.9 0.9 1.0</ambient><diffuse>0.9 0.9 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rack_18'><static>true</static>
      <pose>2.0 10.45 0.4 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.5 0.35 0.8</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.5 0.35 0.8</size></box></geometry>
          <material><ambient>0.3 0.25 0.2 1.0</ambient><diffuse>0.3 0.25 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b1_18'><static>true</static>
      <pose>2.0 10.45 0.25 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b2_18'><static>true</static>
      <pose>2.0 10.45 0.55 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b3_18'><static>true</static>
      <pose>2.0 10.45 0.8 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box1_18'><static>true</static>
      <pose>1.9 10.45 0.32 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.15 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.15 0.2 0.12</size></box></geometry>
          <material><ambient>0.4 0.35 0.25 1.0</ambient><diffuse>0.4 0.35 0.25 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box2_18'><static>true</static>
      <pose>2.1 10.45 0.62 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.18 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.18 0.2 0.12</size></box></geometry>
          <material><ambient>0.5 0.4 0.2 1.0</ambient><diffuse>0.5 0.4 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='label_18'><static>true</static>
      <pose>2.0 10.63 0.5 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.12 0.01 0.06</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.12 0.01 0.06</size></box></geometry>
          <material><ambient>0.9 0.9 0.9 1.0</ambient><diffuse>0.9 0.9 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rack_19'><static>true</static>
      <pose>3.0 10.45 0.4 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.5 0.35 0.8</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.5 0.35 0.8</size></box></geometry>
          <material><ambient>0.3 0.25 0.2 1.0</ambient><diffuse>0.3 0.25 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b1_19'><static>true</static>
      <pose>3.0 10.45 0.25 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b2_19'><static>true</static>
      <pose>3.0 10.45 0.55 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b3_19'><static>true</static>
      <pose>3.0 10.45 0.8 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box1_19'><static>true</static>
      <pose>2.9 10.45 0.32 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.15 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.15 0.2 0.12</size></box></geometry>
          <material><ambient>0.5 0.4 0.2 1.0</ambient><diffuse>0.5 0.4 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box2_19'><static>true</static>
      <pose>3.1 10.45 0.62 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.18 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.18 0.2 0.12</size></box></geometry>
          <material><ambient>0.7 0.6 0.4 1.0</ambient><diffuse>0.7 0.6 0.4 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='label_19'><static>true</static>
      <pose>3.0 10.63 0.5 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.12 0.01 0.06</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.12 0.01 0.06</size></box></geometry>
          <material><ambient>0.9 0.9 0.9 1.0</ambient><diffuse>0.9 0.9 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rack_20'><static>true</static>
      <pose>4.0 10.45 0.4 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.5 0.35 0.8</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.5 0.35 0.8</size></box></geometry>
          <material><ambient>0.3 0.25 0.2 1.0</ambient><diffuse>0.3 0.25 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b1_20'><static>true</static>
      <pose>4.0 10.45 0.25 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b2_20'><static>true</static>
      <pose>4.0 10.45 0.55 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='shelf_b3_20'><static>true</static>
      <pose>4.0 10.45 0.8 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.48 0.33 0.02</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.48 0.33 0.02</size></box></geometry>
          <material><ambient>0.55 0.45 0.3 1.0</ambient><diffuse>0.55 0.45 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box1_20'><static>true</static>
      <pose>3.9 10.45 0.32 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.15 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.15 0.2 0.12</size></box></geometry>
          <material><ambient>0.7 0.6 0.4 1.0</ambient><diffuse>0.7 0.6 0.4 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='box2_20'><static>true</static>
      <pose>4.1 10.45 0.62 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.18 0.2 0.12</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.18 0.2 0.12</size></box></geometry>
          <material><ambient>0.6 0.5 0.3 1.0</ambient><diffuse>0.6 0.5 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='label_20'><static>true</static>
      <pose>4.0 10.63 0.5 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.12 0.01 0.06</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.12 0.01 0.06</size></box></geometry>
          <material><ambient>0.9 0.9 0.9 1.0</ambient><diffuse>0.9 0.9 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rfid_post_L_0'><static>true</static>
      <pose>-0.15 2 0.3 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.02</radius><length>0.6</length></cylinder></geometry>
          <material><ambient>0.2 0.2 0.7 1</ambient><diffuse>0.2 0.2 0.7 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rfid_post_R_0'><static>true</static>
      <pose>0.15 2 0.3 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.02</radius><length>0.6</length></cylinder></geometry>
          <material><ambient>0.2 0.2 0.7 1</ambient><diffuse>0.2 0.2 0.7 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rfid_bar_0'><static>true</static>
      <pose>0 2 0.62 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.35 0.03 0.03</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.35 0.03 0.03</size></box></geometry>
          <material><ambient>0.2 0.2 0.7 1.0</ambient><diffuse>0.2 0.2 0.7 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rfid_led_0'><static>true</static>
      <pose>0 2 0.66 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.015</radius><length>0.02</length></cylinder></geometry>
          <material><ambient>0.0 0.8 0.0 1</ambient><diffuse>0.0 0.8 0.0 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rfid_post_L_1'><static>true</static>
      <pose>-0.15 4 0.3 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.02</radius><length>0.6</length></cylinder></geometry>
          <material><ambient>0.2 0.2 0.7 1</ambient><diffuse>0.2 0.2 0.7 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rfid_post_R_1'><static>true</static>
      <pose>0.15 4 0.3 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.02</radius><length>0.6</length></cylinder></geometry>
          <material><ambient>0.2 0.2 0.7 1</ambient><diffuse>0.2 0.2 0.7 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rfid_bar_1'><static>true</static>
      <pose>0 4 0.62 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.35 0.03 0.03</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.35 0.03 0.03</size></box></geometry>
          <material><ambient>0.2 0.2 0.7 1.0</ambient><diffuse>0.2 0.2 0.7 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rfid_led_1'><static>true</static>
      <pose>0 4 0.66 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.015</radius><length>0.02</length></cylinder></geometry>
          <material><ambient>0.0 0.8 0.0 1</ambient><diffuse>0.0 0.8 0.0 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rfid_post_L_2'><static>true</static>
      <pose>-0.15 6 0.3 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.02</radius><length>0.6</length></cylinder></geometry>
          <material><ambient>0.2 0.2 0.7 1</ambient><diffuse>0.2 0.2 0.7 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rfid_post_R_2'><static>true</static>
      <pose>0.15 6 0.3 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.02</radius><length>0.6</length></cylinder></geometry>
          <material><ambient>0.2 0.2 0.7 1</ambient><diffuse>0.2 0.2 0.7 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rfid_bar_2'><static>true</static>
      <pose>0 6 0.62 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.35 0.03 0.03</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.35 0.03 0.03</size></box></geometry>
          <material><ambient>0.2 0.2 0.7 1.0</ambient><diffuse>0.2 0.2 0.7 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rfid_led_2'><static>true</static>
      <pose>0 6 0.66 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.015</radius><length>0.02</length></cylinder></geometry>
          <material><ambient>0.0 0.8 0.0 1</ambient><diffuse>0.0 0.8 0.0 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rfid_post_L_3'><static>true</static>
      <pose>-0.15 8 0.3 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.02</radius><length>0.6</length></cylinder></geometry>
          <material><ambient>0.2 0.2 0.7 1</ambient><diffuse>0.2 0.2 0.7 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rfid_post_R_3'><static>true</static>
      <pose>0.15 8 0.3 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.02</radius><length>0.6</length></cylinder></geometry>
          <material><ambient>0.2 0.2 0.7 1</ambient><diffuse>0.2 0.2 0.7 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rfid_bar_3'><static>true</static>
      <pose>0 8 0.62 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.35 0.03 0.03</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.35 0.03 0.03</size></box></geometry>
          <material><ambient>0.2 0.2 0.7 1.0</ambient><diffuse>0.2 0.2 0.7 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rfid_led_3'><static>true</static>
      <pose>0 8 0.66 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.015</radius><length>0.02</length></cylinder></geometry>
          <material><ambient>0.0 0.8 0.0 1</ambient><diffuse>0.0 0.8 0.0 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rfid_post_L_4'><static>true</static>
      <pose>-0.15 10 0.3 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.02</radius><length>0.6</length></cylinder></geometry>
          <material><ambient>0.2 0.2 0.7 1</ambient><diffuse>0.2 0.2 0.7 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rfid_post_R_4'><static>true</static>
      <pose>0.15 10 0.3 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.02</radius><length>0.6</length></cylinder></geometry>
          <material><ambient>0.2 0.2 0.7 1</ambient><diffuse>0.2 0.2 0.7 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rfid_bar_4'><static>true</static>
      <pose>0 10 0.62 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.35 0.03 0.03</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.35 0.03 0.03</size></box></geometry>
          <material><ambient>0.2 0.2 0.7 1.0</ambient><diffuse>0.2 0.2 0.7 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rfid_led_4'><static>true</static>
      <pose>0 10 0.66 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.015</radius><length>0.02</length></cylinder></geometry>
          <material><ambient>0.0 0.8 0.0 1</ambient><diffuse>0.0 0.8 0.0 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='wall_n'><static>true</static>
      <pose>4 13.5 1.5 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>16 0.2 3.0</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>16 0.2 3.0</size></box></geometry>
          <material><ambient>0.5 0.48 0.45 1.0</ambient><diffuse>0.5 0.48 0.45 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='wall_s'><static>true</static>
      <pose>4 -1.5 1.5 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>16 0.2 3.0</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>16 0.2 3.0</size></box></geometry>
          <material><ambient>0.5 0.48 0.45 1.0</ambient><diffuse>0.5 0.48 0.45 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='wall_e'><static>true</static>
      <pose>12.1 6 1.5 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.2 15.2 3.0</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.2 15.2 3.0</size></box></geometry>
          <material><ambient>0.5 0.48 0.45 1.0</ambient><diffuse>0.5 0.48 0.45 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='wall_w'><static>true</static>
      <pose>-2.1 6 1.5 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.2 15.2 3.0</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.2 15.2 3.0</size></box></geometry>
          <material><ambient>0.5 0.48 0.45 1.0</ambient><diffuse>0.5 0.48 0.45 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='base_n'><static>true</static>
      <pose>4 13.4 0.1 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>16 0.05 0.2</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>16 0.05 0.2</size></box></geometry>
          <material><ambient>0.2 0.2 0.2 1.0</ambient><diffuse>0.2 0.2 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='base_s'><static>true</static>
      <pose>4 -1.4 0.1 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>16 0.05 0.2</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>16 0.05 0.2</size></box></geometry>
          <material><ambient>0.2 0.2 0.2 1.0</ambient><diffuse>0.2 0.2 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rail_post_0'><static>true</static>
      <pose>-0.6 1 0.25 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.02</radius><length>0.5</length></cylinder></geometry>
          <material><ambient>0.8 0.7 0.0 1</ambient><diffuse>0.8 0.7 0.0 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rail_post_2'><static>true</static>
      <pose>-0.6 3 0.25 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.02</radius><length>0.5</length></cylinder></geometry>
          <material><ambient>0.8 0.7 0.0 1</ambient><diffuse>0.8 0.7 0.0 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rail_post_4'><static>true</static>
      <pose>-0.6 5 0.25 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.02</radius><length>0.5</length></cylinder></geometry>
          <material><ambient>0.8 0.7 0.0 1</ambient><diffuse>0.8 0.7 0.0 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rail_post_6'><static>true</static>
      <pose>-0.6 7 0.25 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.02</radius><length>0.5</length></cylinder></geometry>
          <material><ambient>0.8 0.7 0.0 1</ambient><diffuse>0.8 0.7 0.0 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rail_post_8'><static>true</static>
      <pose>-0.6 9 0.25 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.02</radius><length>0.5</length></cylinder></geometry>
          <material><ambient>0.8 0.7 0.0 1</ambient><diffuse>0.8 0.7 0.0 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rail_post_10'><static>true</static>
      <pose>-0.6 11 0.25 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.02</radius><length>0.5</length></cylinder></geometry>
          <material><ambient>0.8 0.7 0.0 1</ambient><diffuse>0.8 0.7 0.0 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rail_bar_w'><static>true</static>
      <pose>-0.6 6 0.45 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.03 12 0.03</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.03 12 0.03</size></box></geometry>
          <material><ambient>0.8 0.7 0.0 1.0</ambient><diffuse>0.8 0.7 0.0 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='light_0_1'><static>true</static>
      <pose>0 1 2.9 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.6 0.15 0.03</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.6 0.15 0.03</size></box></geometry>
          <material><ambient>0.95 0.95 0.9 1.0</ambient><diffuse>0.95 0.95 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='light_0_4'><static>true</static>
      <pose>0 4 2.9 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.6 0.15 0.03</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.6 0.15 0.03</size></box></geometry>
          <material><ambient>0.95 0.95 0.9 1.0</ambient><diffuse>0.95 0.95 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='light_0_7'><static>true</static>
      <pose>0 7 2.9 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.6 0.15 0.03</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.6 0.15 0.03</size></box></geometry>
          <material><ambient>0.95 0.95 0.9 1.0</ambient><diffuse>0.95 0.95 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='light_0_10'><static>true</static>
      <pose>0 10 2.9 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.6 0.15 0.03</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.6 0.15 0.03</size></box></geometry>
          <material><ambient>0.95 0.95 0.9 1.0</ambient><diffuse>0.95 0.95 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='light_2.5_1'><static>true</static>
      <pose>2.5 1 2.9 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.6 0.15 0.03</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.6 0.15 0.03</size></box></geometry>
          <material><ambient>0.95 0.95 0.9 1.0</ambient><diffuse>0.95 0.95 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='light_2.5_4'><static>true</static>
      <pose>2.5 4 2.9 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.6 0.15 0.03</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.6 0.15 0.03</size></box></geometry>
          <material><ambient>0.95 0.95 0.9 1.0</ambient><diffuse>0.95 0.95 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='light_2.5_7'><static>true</static>
      <pose>2.5 7 2.9 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.6 0.15 0.03</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.6 0.15 0.03</size></box></geometry>
          <material><ambient>0.95 0.95 0.9 1.0</ambient><diffuse>0.95 0.95 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='light_2.5_10'><static>true</static>
      <pose>2.5 10 2.9 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.6 0.15 0.03</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.6 0.15 0.03</size></box></geometry>
          <material><ambient>0.95 0.95 0.9 1.0</ambient><diffuse>0.95 0.95 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='light_5_1'><static>true</static>
      <pose>5 1 2.9 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.6 0.15 0.03</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.6 0.15 0.03</size></box></geometry>
          <material><ambient>0.95 0.95 0.9 1.0</ambient><diffuse>0.95 0.95 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='light_5_4'><static>true</static>
      <pose>5 4 2.9 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.6 0.15 0.03</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.6 0.15 0.03</size></box></geometry>
          <material><ambient>0.95 0.95 0.9 1.0</ambient><diffuse>0.95 0.95 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='light_5_7'><static>true</static>
      <pose>5 7 2.9 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.6 0.15 0.03</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.6 0.15 0.03</size></box></geometry>
          <material><ambient>0.95 0.95 0.9 1.0</ambient><diffuse>0.95 0.95 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='light_5_10'><static>true</static>
      <pose>5 10 2.9 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.6 0.15 0.03</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.6 0.15 0.03</size></box></geometry>
          <material><ambient>0.95 0.95 0.9 1.0</ambient><diffuse>0.95 0.95 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='light_7.5_1'><static>true</static>
      <pose>7.5 1 2.9 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.6 0.15 0.03</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.6 0.15 0.03</size></box></geometry>
          <material><ambient>0.95 0.95 0.9 1.0</ambient><diffuse>0.95 0.95 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='light_7.5_4'><static>true</static>
      <pose>7.5 4 2.9 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.6 0.15 0.03</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.6 0.15 0.03</size></box></geometry>
          <material><ambient>0.95 0.95 0.9 1.0</ambient><diffuse>0.95 0.95 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='light_7.5_7'><static>true</static>
      <pose>7.5 7 2.9 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.6 0.15 0.03</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.6 0.15 0.03</size></box></geometry>
          <material><ambient>0.95 0.95 0.9 1.0</ambient><diffuse>0.95 0.95 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='light_7.5_10'><static>true</static>
      <pose>7.5 10 2.9 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.6 0.15 0.03</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.6 0.15 0.03</size></box></geometry>
          <material><ambient>0.95 0.95 0.9 1.0</ambient><diffuse>0.95 0.95 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='light_10_1'><static>true</static>
      <pose>10 1 2.9 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.6 0.15 0.03</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.6 0.15 0.03</size></box></geometry>
          <material><ambient>0.95 0.95 0.9 1.0</ambient><diffuse>0.95 0.95 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='light_10_4'><static>true</static>
      <pose>10 4 2.9 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.6 0.15 0.03</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.6 0.15 0.03</size></box></geometry>
          <material><ambient>0.95 0.95 0.9 1.0</ambient><diffuse>0.95 0.95 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='light_10_7'><static>true</static>
      <pose>10 7 2.9 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.6 0.15 0.03</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.6 0.15 0.03</size></box></geometry>
          <material><ambient>0.95 0.95 0.9 1.0</ambient><diffuse>0.95 0.95 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='light_10_10'><static>true</static>
      <pose>10 10 2.9 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.6 0.15 0.03</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.6 0.15 0.03</size></box></geometry>
          <material><ambient>0.95 0.95 0.9 1.0</ambient><diffuse>0.95 0.95 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='bollard_0'><static>true</static>
      <pose>-0.8 -0.8 0.3 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.06</radius><length>0.6</length></cylinder></geometry>
          <material><ambient>0.8 0.7 0.0 1</ambient><diffuse>0.8 0.7 0.0 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='bollard_band_0'><static>true</static>
      <pose>-0.8 -0.8 0.5 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.065</radius><length>0.06</length></cylinder></geometry>
          <material><ambient>0.8 0.1 0.1 1</ambient><diffuse>0.8 0.1 0.1 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='bollard_1'><static>true</static>
      <pose>5.5 -0.8 0.3 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.06</radius><length>0.6</length></cylinder></geometry>
          <material><ambient>0.8 0.7 0.0 1</ambient><diffuse>0.8 0.7 0.0 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='bollard_band_1'><static>true</static>
      <pose>5.5 -0.8 0.5 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.065</radius><length>0.06</length></cylinder></geometry>
          <material><ambient>0.8 0.1 0.1 1</ambient><diffuse>0.8 0.1 0.1 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='bollard_2'><static>true</static>
      <pose>-0.8 12 0.3 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.06</radius><length>0.6</length></cylinder></geometry>
          <material><ambient>0.8 0.7 0.0 1</ambient><diffuse>0.8 0.7 0.0 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='bollard_band_2'><static>true</static>
      <pose>-0.8 12 0.5 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.065</radius><length>0.06</length></cylinder></geometry>
          <material><ambient>0.8 0.1 0.1 1</ambient><diffuse>0.8 0.1 0.1 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='bollard_3'><static>true</static>
      <pose>5.5 12 0.3 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.06</radius><length>0.6</length></cylinder></geometry>
          <material><ambient>0.8 0.7 0.0 1</ambient><diffuse>0.8 0.7 0.0 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='bollard_band_3'><static>true</static>
      <pose>5.5 12 0.5 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.065</radius><length>0.06</length></cylinder></geometry>
          <material><ambient>0.8 0.1 0.1 1</ambient><diffuse>0.8 0.1 0.1 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='dock_platform'><static>true</static>
      <pose>3 -1.2 0.3 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>3 0.6 0.6</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>3 0.6 0.6</size></box></geometry>
          <material><ambient>0.4 0.38 0.35 1.0</ambient><diffuse>0.4 0.38 0.35 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='dock_bumper_l'><static>true</static>
      <pose>1.7 -1.3 0.3 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.15 0.3 0.4</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.15 0.3 0.4</size></box></geometry>
          <material><ambient>0.15 0.15 0.15 1.0</ambient><diffuse>0.15 0.15 0.15 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='dock_bumper_r'><static>true</static>
      <pose>4.3 -1.3 0.3 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.15 0.3 0.4</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.15 0.3 0.4</size></box></geometry>
          <material><ambient>0.15 0.15 0.15 1.0</ambient><diffuse>0.15 0.15 0.15 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='pallet_dock'><static>true</static>
      <pose>3 -1.1 0.65 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.8 0.4 0.1</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.8 0.4 0.1</size></box></geometry>
          <material><ambient>0.6 0.5 0.3 1.0</ambient><diffuse>0.6 0.5 0.3 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='cargo_dock'><static>true</static>
      <pose>3 -1.1 0.85 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.6 0.35 0.3</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.6 0.35 0.3</size></box></geometry>
          <material><ambient>0.5 0.4 0.2 1.0</ambient><diffuse>0.5 0.4 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='info_board_back'><static>true</static>
      <pose>-1.8 6 1.2 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.05 1.5 1.0</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.05 1.5 1.0</size></box></geometry>
          <material><ambient>0.15 0.15 0.2 1.0</ambient><diffuse>0.15 0.15 0.2 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='info_board_face'><static>true</static>
      <pose>-1.75 6 1.2 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.02 1.4 0.9</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.02 1.4 0.9</size></box></geometry>
          <material><ambient>0.1 0.3 0.5 1.0</ambient><diffuse>0.1 0.3 0.5 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='info_frame_t'><static>true</static>
      <pose>-1.75 6 1.7 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.03 1.5 0.03</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.03 1.5 0.03</size></box></geometry>
          <material><ambient>0.4 0.4 0.4 1.0</ambient><diffuse>0.4 0.4 0.4 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='info_frame_b'><static>true</static>
      <pose>-1.75 6 0.72 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.03 1.5 0.03</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.03 1.5 0.03</size></box></geometry>
          <material><ambient>0.4 0.4 0.4 1.0</ambient><diffuse>0.4 0.4 0.4 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='stop_line_home'><static>true</static>
      <pose>0 0.5 0.0009 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.4 0.04 0.001</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.4 0.04 0.001</size></box></geometry>
          <material><ambient>0.9 0.1 0.1 1.0</ambient><diffuse>0.9 0.1 0.1 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='arrow_1.5'><static>true</static>
      <pose>0 1.5 0.0009 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.03 0.2 0.001</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.03 0.2 0.001</size></box></geometry>
          <material><ambient>0.9 0.9 0.9 1.0</ambient><diffuse>0.9 0.9 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='arrow_3.5'><static>true</static>
      <pose>0 3.5 0.0009 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.03 0.2 0.001</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.03 0.2 0.001</size></box></geometry>
          <material><ambient>0.9 0.9 0.9 1.0</ambient><diffuse>0.9 0.9 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='arrow_5.5'><static>true</static>
      <pose>0 5.5 0.0009 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.03 0.2 0.001</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.03 0.2 0.001</size></box></geometry>
          <material><ambient>0.9 0.9 0.9 1.0</ambient><diffuse>0.9 0.9 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='arrow_7.5'><static>true</static>
      <pose>0 7.5 0.0009 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.03 0.2 0.001</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.03 0.2 0.001</size></box></geometry>
          <material><ambient>0.9 0.9 0.9 1.0</ambient><diffuse>0.9 0.9 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='arrow_9.5'><static>true</static>
      <pose>0 9.5 0.0009 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.03 0.2 0.001</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.03 0.2 0.001</size></box></geometry>
          <material><ambient>0.9 0.9 0.9 1.0</ambient><diffuse>0.9 0.9 0.9 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='fire_ext'><static>true</static>
      <pose>-1.9 12 0.4 0 0 0</pose>
      <link name='link'>
        <visual name='v'><geometry><cylinder><radius>0.05</radius><length>0.5</length></cylinder></geometry>
          <material><ambient>0.8 0.1 0.1 1</ambient><diffuse>0.8 0.1 0.1 1</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='fire_ext_sign'><static>true</static>
      <pose>-1.95 12 0.75 0 0 0</pose>
      <link name='link'>
        <collision name='c'><geometry><box><size>0.01 0.2 0.15</size></box></geometry></collision>
        <visual name='v'><geometry><box><size>0.01 0.2 0.15</size></box></geometry>
          <material><ambient>0.9 0.1 0.1 1.0</ambient><diffuse>0.9 0.1 0.1 1.0</diffuse></material>
        </visual>
      </link>
    </model>
    <model name='rfid_S01'><static>true</static><pose>1.0 2.0 0.002 0 0 0</pose><link name='link'><visual name='v'><geometry><box><size>0.15 0.15 0.003</size></box></geometry><material><ambient>0.1 0.3 0.9 1</ambient><diffuse>0.1 0.3 0.9 1</diffuse></material></visual></link></model>
    <model name='rfid_S02'><static>true</static><pose>2.0 2.0 0.002 0 0 0</pose><link name='link'><visual name='v'><geometry><box><size>0.15 0.15 0.003</size></box></geometry><material><ambient>0.1 0.3 0.9 1</ambient><diffuse>0.1 0.3 0.9 1</diffuse></material></visual></link></model>
    <model name='rfid_S03'><static>true</static><pose>3.0 2.0 0.002 0 0 0</pose><link name='link'><visual name='v'><geometry><box><size>0.15 0.15 0.003</size></box></geometry><material><ambient>0.1 0.3 0.9 1</ambient><diffuse>0.1 0.3 0.9 1</diffuse></material></visual></link></model>
    <model name='rfid_S04'><static>true</static><pose>4.0 2.0 0.002 0 0 0</pose><link name='link'><visual name='v'><geometry><box><size>0.15 0.15 0.003</size></box></geometry><material><ambient>0.1 0.3 0.9 1</ambient><diffuse>0.1 0.3 0.9 1</diffuse></material></visual></link></model>
    <model name='rfid_S05'><static>true</static><pose>1.0 4.0 0.002 0 0 0</pose><link name='link'><visual name='v'><geometry><box><size>0.15 0.15 0.003</size></box></geometry><material><ambient>0.1 0.3 0.9 1</ambient><diffuse>0.1 0.3 0.9 1</diffuse></material></visual></link></model>
    <model name='rfid_S06'><static>true</static><pose>2.0 4.0 0.002 0 0 0</pose><link name='link'><visual name='v'><geometry><box><size>0.15 0.15 0.003</size></box></geometry><material><ambient>0.1 0.3 0.9 1</ambient><diffuse>0.1 0.3 0.9 1</diffuse></material></visual></link></model>
    <model name='rfid_S07'><static>true</static><pose>3.0 4.0 0.002 0 0 0</pose><link name='link'><visual name='v'><geometry><box><size>0.15 0.15 0.003</size></box></geometry><material><ambient>0.1 0.3 0.9 1</ambient><diffuse>0.1 0.3 0.9 1</diffuse></material></visual></link></model>
    <model name='rfid_S08'><static>true</static><pose>4.0 4.0 0.002 0 0 0</pose><link name='link'><visual name='v'><geometry><box><size>0.15 0.15 0.003</size></box></geometry><material><ambient>0.1 0.3 0.9 1</ambient><diffuse>0.1 0.3 0.9 1</diffuse></material></visual></link></model>
    <model name='rfid_S09'><static>true</static><pose>1.0 6.0 0.002 0 0 0</pose><link name='link'><visual name='v'><geometry><box><size>0.15 0.15 0.003</size></box></geometry><material><ambient>0.1 0.3 0.9 1</ambient><diffuse>0.1 0.3 0.9 1</diffuse></material></visual></link></model>
    <model name='rfid_S10'><static>true</static><pose>2.0 6.0 0.002 0 0 0</pose><link name='link'><visual name='v'><geometry><box><size>0.15 0.15 0.003</size></box></geometry><material><ambient>0.1 0.3 0.9 1</ambient><diffuse>0.1 0.3 0.9 1</diffuse></material></visual></link></model>
    <model name='rfid_S11'><static>true</static><pose>3.0 6.0 0.002 0 0 0</pose><link name='link'><visual name='v'><geometry><box><size>0.15 0.15 0.003</size></box></geometry><material><ambient>0.1 0.3 0.9 1</ambient><diffuse>0.1 0.3 0.9 1</diffuse></material></visual></link></model>
    <model name='rfid_S12'><static>true</static><pose>4.0 6.0 0.002 0 0 0</pose><link name='link'><visual name='v'><geometry><box><size>0.15 0.15 0.003</size></box></geometry><material><ambient>0.1 0.3 0.9 1</ambient><diffuse>0.1 0.3 0.9 1</diffuse></material></visual></link></model>
    <model name='rfid_S13'><static>true</static><pose>1.0 8.0 0.002 0 0 0</pose><link name='link'><visual name='v'><geometry><box><size>0.15 0.15 0.003</size></box></geometry><material><ambient>0.1 0.3 0.9 1</ambient><diffuse>0.1 0.3 0.9 1</diffuse></material></visual></link></model>
    <model name='rfid_S14'><static>true</static><pose>2.0 8.0 0.002 0 0 0</pose><link name='link'><visual name='v'><geometry><box><size>0.15 0.15 0.003</size></box></geometry><material><ambient>0.1 0.3 0.9 1</ambient><diffuse>0.1 0.3 0.9 1</diffuse></material></visual></link></model>
    <model name='rfid_S15'><static>true</static><pose>3.0 8.0 0.002 0 0 0</pose><link name='link'><visual name='v'><geometry><box><size>0.15 0.15 0.003</size></box></geometry><material><ambient>0.1 0.3 0.9 1</ambient><diffuse>0.1 0.3 0.9 1</diffuse></material></visual></link></model>
    <model name='rfid_S16'><static>true</static><pose>4.0 8.0 0.002 0 0 0</pose><link name='link'><visual name='v'><geometry><box><size>0.15 0.15 0.003</size></box></geometry><material><ambient>0.1 0.3 0.9 1</ambient><diffuse>0.1 0.3 0.9 1</diffuse></material></visual></link></model>
    <model name='rfid_S17'><static>true</static><pose>1.0 10.0 0.002 0 0 0</pose><link name='link'><visual name='v'><geometry><box><size>0.15 0.15 0.003</size></box></geometry><material><ambient>0.1 0.3 0.9 1</ambient><diffuse>0.1 0.3 0.9 1</diffuse></material></visual></link></model>
    <model name='rfid_S18'><static>true</static><pose>2.0 10.0 0.002 0 0 0</pose><link name='link'><visual name='v'><geometry><box><size>0.15 0.15 0.003</size></box></geometry><material><ambient>0.1 0.3 0.9 1</ambient><diffuse>0.1 0.3 0.9 1</diffuse></material></visual></link></model>
    <model name='rfid_S19'><static>true</static><pose>3.0 10.0 0.002 0 0 0</pose><link name='link'><visual name='v'><geometry><box><size>0.15 0.15 0.003</size></box></geometry><material><ambient>0.1 0.3 0.9 1</ambient><diffuse>0.1 0.3 0.9 1</diffuse></material></visual></link></model>
    <model name='rfid_S20'><static>true</static><pose>4.0 10.0 0.002 0 0 0</pose><link name='link'><visual name='v'><geometry><box><size>0.15 0.15 0.003</size></box></geometry><material><ambient>0.1 0.3 0.9 1</ambient><diffuse>0.1 0.3 0.9 1</diffuse></material></visual></link></model>

</world>
</sdf>
```

---
## FILE: src/atlas_gazebo/package.xml
```
<?xml version="1.0"?>
<package format="3">
  <name>atlas_gazebo</name>
  <version>1.0.0</version>
  <description>ATLAS warehouse world</description>
  <maintainer email="atlas@dev.local">atlas</maintainer>
  <license>MIT</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <exec_depend>gazebo_ros</exec_depend>
  <export><build_type>ament_cmake</build_type></export>
</package>
```

---
## FILE: src/atlas_mission_manager/atlas_mission_manager/atlas_gui.py
```
#!/usr/bin/env python3
"""ATLAS Warehouse Fleet Control Center - entry point.

Brand-new replacement GUI for the ATLAS Warehouse AGV.

Registered as the ``atlas_gui`` console script in
``atlas_mission_manager/setup.py`` and launched automatically by
``atlas_bringup/launch/atlas_full.launch.py``.

Design goals
------------
* Never crash on missing topics, missing messages, or restarted nodes.
* All Qt widgets are mutated only on the Qt main thread; the rclpy
  spinner runs in a daemon thread and forwards data via Qt signals.
* Subscriptions are recreated transparently after a node restart -
  rclpy/DDS handles re-discovery, so we only have to keep the GUI
  process alive and wrap every callback in a try/except.
* Zero modifications to navigation, RFID, mission manager or Gazebo
  systems - communication uses the existing ``/atlas/*`` topics only.
"""

import signal
import sys

from PyQt5.QtCore import QTimer
from PyQt5.QtWidgets import QApplication

from atlas_mission_manager.gui.main_window import MainWindow
from atlas_mission_manager.gui.ros_bridge import RosBridge
from atlas_mission_manager.gui.theme import APP_STYLESHEET


def main(argv=None):
    if argv is None:
        argv = sys.argv

    # Allow Ctrl+C in the launching terminal to terminate the process.
    signal.signal(signal.SIGINT, signal.SIG_DFL)

    app = QApplication(argv)
    app.setApplicationName("ATLAS Fleet Control")
    app.setStyleSheet(APP_STYLESHEET)

    bridge = RosBridge()
    window = MainWindow(bridge)
    window.show()

    # Drain the Qt event loop frequently so signals/timers stay responsive
    # and SIGINT is honoured promptly.
    keepalive = QTimer()
    keepalive.timeout.connect(lambda: None)
    keepalive.start(200)

    try:
        rc = app.exec_()
    finally:
        try:
            bridge.shutdown()
        except Exception:
            pass
    sys.exit(rc)


if __name__ == "__main__":
    main()
```


---
## FILE: src/atlas_mission_manager/atlas_mission_manager/__init__.py
```
```

---
## FILE: src/atlas_mission_manager/atlas_mission_manager/send_mission.py
```
"""CLI: ros2 run atlas_mission_manager send_mission S05"""
import sys, uuid, time
import rclpy
from atlas_interfaces.msg import FleetMission

def main():
    rclpy.init()
    node = rclpy.create_node('atlas_send_mission')
    pub = node.create_publisher(FleetMission, '/atlas/mission_cmd', 10)
    shelf = sys.argv[1] if len(sys.argv) > 1 else 'S01'
    time.sleep(0.5)
    m = FleetMission()
    m.mission_id = f'cli-{uuid.uuid4().hex[:6]}'
    m.target_shelf = shelf.upper()
    m.sku = 'SKU-001'
    m.priority = 1
    pub.publish(m)
    print(f'Sent mission {m.mission_id} -> {m.target_shelf}')
    time.sleep(0.5)
    node.destroy_node()
    rclpy.shutdown()
```


---
## FILE: src/atlas_mission_manager/atlas_mission_manager/gui/__init__.py
```
"""ATLAS Fleet Control Center GUI helper sub-package."""
```

---
## FILE: src/atlas_mission_manager/atlas_mission_manager/gui/theme.py
```
"""Visual theme for the ATLAS Fleet Control Center.

Pure constants - no logic, no imports of Qt symbols required at module
import time.  Kept separate so colours and the stylesheet can be tuned
without touching widget code.
"""

# ---- Palette ----------------------------------------------------------
BG_DEEP = "#0b0f1a"
BG_PANEL = "#121a2c"
BG_CARD = "#172238"
BG_INPUT = "#1d2942"
BORDER = "#2c3650"
BORDER_SOFT = "#1f2940"

TEXT_PRIMARY = "#e6f1ff"
TEXT_MUTED = "#8aa0c2"
TEXT_DIM = "#5d6c87"

ACCENT = "#00d4aa"
ACCENT_DARK = "#008f74"
INFO = "#4ea1ff"
WARN = "#ffaa00"
DANGER = "#ff4d4d"
DANGER_DARK = "#a02828"

LOG_BG = "#0a1020"
LOG_TS = "#5d6c87"
LOG_INFO = "#cfd9ea"
LOG_MISSION = "#00d4aa"
LOG_WARN = "#ffaa00"
LOG_ERROR = "#ff6b6b"

# ---- Stylesheet -------------------------------------------------------
APP_STYLESHEET = f"""
* {{
    font-family: "Segoe UI", "Inter", "Roboto", "Cantarell", "Ubuntu", sans-serif;
    color: {TEXT_PRIMARY};
}}

QMainWindow, QWidget {{
    background-color: {BG_DEEP};
}}

QLabel {{
    background: transparent;
}}

QLabel#PageTitle {{
    font-size: 20px;
    font-weight: 700;
    color: {ACCENT};
    letter-spacing: 1px;
}}

QLabel#PageSubtitle {{
    font-size: 11px;
    color: {TEXT_MUTED};
    letter-spacing: 2px;
}}

QLabel#SectionTitle {{
    font-size: 11px;
    font-weight: 700;
    color: {TEXT_MUTED};
    letter-spacing: 2px;
    padding: 0 0 4px 2px;
}}

QLabel#CardTitle {{
    color: {TEXT_MUTED};
    font-size: 10px;
    font-weight: 600;
    letter-spacing: 1px;
}}

QLabel#CardValue {{
    color: {ACCENT};
    font-size: 16px;
    font-weight: 700;
}}

QFrame#Card, QFrame#StatusCard, QFrame#ConnPill {{
    background: {BG_CARD};
    border: 1px solid {BORDER};
    border-radius: 10px;
}}

QFrame#Panel {{
    background: {BG_PANEL};
    border: 1px solid {BORDER_SOFT};
    border-radius: 12px;
}}

QFrame#Divider {{
    background: {BORDER};
    max-height: 1px;
    min-height: 1px;
    border: none;
}}

QPushButton {{
    background-color: {BG_INPUT};
    border: 1px solid {BORDER};
    border-radius: 8px;
    padding: 10px 14px;
    color: {TEXT_PRIMARY};
    font-weight: 600;
    min-height: 24px;
}}

QPushButton:hover {{
    border-color: {ACCENT};
    color: {ACCENT};
}}

QPushButton:pressed {{
    background-color: {ACCENT};
    color: {BG_DEEP};
}}

QPushButton:disabled {{
    color: {TEXT_DIM};
    border-color: {BORDER_SOFT};
}}

QPushButton#PrimaryButton {{
    background-color: {ACCENT_DARK};
    border-color: {ACCENT};
    color: {BG_DEEP};
}}

QPushButton#PrimaryButton:hover {{
    background-color: {ACCENT};
}}

QPushButton#WarnButton {{
    background-color: #5a3a00;
    border-color: {WARN};
    color: {WARN};
}}

QPushButton#WarnButton:hover {{
    background-color: {WARN};
    color: {BG_DEEP};
}}

QPushButton#DangerButton {{
    background-color: {DANGER_DARK};
    border-color: {DANGER};
    color: #ffe6e6;
    font-weight: 700;
    letter-spacing: 1px;
}}

QPushButton#DangerButton:hover {{
    background-color: {DANGER};
    color: {BG_DEEP};
}}

QComboBox, QSpinBox, QLineEdit {{
    background-color: {BG_INPUT};
    border: 1px solid {BORDER};
    border-radius: 6px;
    padding: 6px 8px;
    color: {TEXT_PRIMARY};
    selection-background-color: {ACCENT};
    selection-color: {BG_DEEP};
    min-height: 22px;
}}

QComboBox:focus, QSpinBox:focus, QLineEdit:focus {{
    border-color: {ACCENT};
}}

QComboBox::drop-down {{
    border: none;
    width: 22px;
}}

QComboBox QAbstractItemView {{
    background-color: {BG_PANEL};
    border: 1px solid {BORDER};
    selection-background-color: {ACCENT_DARK};
    color: {TEXT_PRIMARY};
}}

QTableWidget {{
    background-color: {BG_CARD};
    alternate-background-color: {BG_PANEL};
    border: 1px solid {BORDER};
    border-radius: 8px;
    gridline-color: {BORDER_SOFT};
    color: {TEXT_PRIMARY};
    selection-background-color: {ACCENT_DARK};
    selection-color: {BG_DEEP};
}}

QHeaderView::section {{
    background-color: {BG_INPUT};
    color: {TEXT_MUTED};
    border: none;
    border-right: 1px solid {BORDER_SOFT};
    border-bottom: 1px solid {BORDER};
    padding: 6px 8px;
    font-weight: 700;
    letter-spacing: 1px;
}}

QTableWidget::item {{
    padding: 6px 8px;
}}

QTextEdit, QPlainTextEdit {{
    background-color: {LOG_BG};
    border: 1px solid {BORDER};
    border-radius: 8px;
    color: {TEXT_PRIMARY};
    font-family: "JetBrains Mono", "Fira Code", "Consolas", "DejaVu Sans Mono", monospace;
    font-size: 11px;
    padding: 6px;
}}

QScrollBar:vertical {{
    background: {BG_PANEL};
    width: 10px;
    border: none;
    margin: 0;
}}

QScrollBar::handle:vertical {{
    background: {BORDER};
    border-radius: 4px;
    min-height: 24px;
}}

QScrollBar::handle:vertical:hover {{
    background: {ACCENT_DARK};
}}

QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {{
    height: 0;
}}

QScrollBar:horizontal {{
    background: {BG_PANEL};
    height: 10px;
    border: none;
}}

QScrollBar::handle:horizontal {{
    background: {BORDER};
    border-radius: 4px;
    min-width: 24px;
}}

QGroupBox {{
    background: transparent;
    border: 1px solid {BORDER};
    border-radius: 10px;
    margin-top: 14px;
    padding: 14px 10px 10px 10px;
    font-weight: 700;
    color: {TEXT_MUTED};
    letter-spacing: 1px;
}}

QGroupBox::title {{
    subcontrol-origin: margin;
    subcontrol-position: top left;
    left: 12px;
    padding: 0 6px;
    color: {ACCENT};
}}

QToolTip {{
    background-color: {BG_PANEL};
    color: {TEXT_PRIMARY};
    border: 1px solid {ACCENT};
    padding: 4px;
}}

QMessageBox, QDialog {{
    background-color: {BG_PANEL};
}}
"""
```

---
## FILE: src/atlas_mission_manager/atlas_mission_manager/gui/ros_bridge.py
```
"""ROS2 <-> Qt bridge for the ATLAS Fleet Control Center.

Runs the rclpy spin loop in a daemon thread and forwards everything
to the Qt main thread via :class:`PyQt5.QtCore.pyqtSignal`.

All callbacks are wrapped in try/except so a malformed message, a
schema change, or a temporarily missing topic will never crash the
GUI.  Subscriptions and publishers are recreated transparently when
peer nodes restart because rclpy/DDS handles re-discovery for us.
"""

import math
import threading
import time
import uuid

import rclpy
from PyQt5.QtCore import QObject, pyqtSignal


# These imports are wrapped because some message packages may not be
# present on every machine where the GUI is launched (e.g. when only
# parts of the workspace are built).  The GUI must still come up.
try:
    from std_msgs.msg import Empty, String
except Exception:  # pragma: no cover - extremely unlikely
    Empty = None
    String = None

try:
    from nav_msgs.msg import Odometry
except Exception:
    Odometry = None

try:
    from atlas_interfaces.msg import FleetMission, RobotState, ShelfTag
except Exception:
    FleetMission = None
    RobotState = None
    ShelfTag = None


class RosBridge(QObject):
    """Background ROS2 worker that emits Qt signals on each event."""

    # mission_id, target_shelf, sku, current_state, battery, last_tag,
    # carrying, current_sku
    state_signal = pyqtSignal(str, str, str, str, float, str, bool, str)
    odom_signal = pyqtSignal(float, float, float, float, float)  # x, y, yaw, vx, wz
    log_signal = pyqtSignal(str)
    tag_signal = pyqtSignal(str, str, bool)  # tag_id, shelf_id, is_home
    connection_signal = pyqtSignal(bool)
    mission_sent_signal = pyqtSignal(str, str, str, int)  # id, shelf, sku, prio

    def __init__(self):
        super().__init__()
        self._stop = False
        self._spin_thread = None
        self._wd_thread = None
        self.node = None

        self._last_state_t = 0.0
        self._last_odom_t = 0.0
        self._connected = False

        self.pub_mission = None
        self.pub_estop = None
        self.pub_reset = None
        self.pub_reset_dock = None

        self._init_ros()

    # ------------------------------------------------------------------
    # initialisation
    # ------------------------------------------------------------------
    def _init_ros(self):
        try:
            if not rclpy.ok():
                rclpy.init(args=None)
            self.node = rclpy.create_node("atlas_gui")

            if RobotState is not None:
                self.node.create_subscription(
                    RobotState, "/atlas/robot_state", self._on_state, 10
                )
            if Odometry is not None:
                self.node.create_subscription(
                    Odometry, "/atlas/odom", self._on_odom, 50
                )
            if String is not None:
                self.node.create_subscription(
                    String, "/atlas/log", self._on_log, 50
                )
            if ShelfTag is not None:
                self.node.create_subscription(
                    ShelfTag, "/atlas/tag_event", self._on_tag, 10
                )

            if FleetMission is not None:
                self.pub_mission = self.node.create_publisher(
                    FleetMission, "/atlas/mission_cmd", 10
                )
            if Empty is not None:
                self.pub_estop = self.node.create_publisher(
                    Empty, "/atlas/estop", 10
                )
                self.pub_reset = self.node.create_publisher(
                    Empty, "/atlas/reset", 10
                )
                self.pub_reset_dock = self.node.create_publisher(
                    Empty, "/atlas/reset_to_dock", 10
                )

            self._spin_thread = threading.Thread(
                target=self._spin_loop, daemon=True, name="atlas-gui-spin"
            )
            self._spin_thread.start()

            self._wd_thread = threading.Thread(
                target=self._watchdog_loop, daemon=True, name="atlas-gui-wd"
            )
            self._wd_thread.start()

        except Exception as ex:
            print("[atlas_gui] ROS init error: %s" % ex, flush=True)

    # ------------------------------------------------------------------
    # background loops
    # ------------------------------------------------------------------
    def _spin_loop(self):
        while not self._stop:
            try:
                if rclpy.ok() and self.node is not None:
                    rclpy.spin_once(self.node, timeout_sec=0.05)
                else:
                    time.sleep(0.2)
            except Exception as ex:
                # Keep going so the GUI never crashes.
                print("[atlas_gui] spin error: %s" % ex, flush=True)
                time.sleep(0.2)

    def _watchdog_loop(self):
        while not self._stop:
            try:
                now = time.time()
                fresh_state = (now - self._last_state_t) < 3.0
                fresh_odom = (now - self._last_odom_t) < 3.0
                connected = bool(fresh_state or fresh_odom)
                if connected != self._connected:
                    self._connected = connected
                    self.connection_signal.emit(connected)
            except Exception:
                pass
            time.sleep(0.5)

    # ------------------------------------------------------------------
    # subscription callbacks (run in spin thread)
    # ------------------------------------------------------------------
    def _on_state(self, msg):
        try:
            self._last_state_t = time.time()
            state = getattr(msg, "state", "") or ""
            mission_id = getattr(msg, "mission_id", "") or ""
            target_shelf = getattr(msg, "target_shelf", "") or ""
            current_sku = getattr(msg, "current_sku", "") or ""
            last_tag = getattr(msg, "last_tag", "") or ""
            carrying = bool(getattr(msg, "carrying_load", False))
            battery = float(getattr(msg, "battery_percent", 0.0))
            self.state_signal.emit(
                mission_id, target_shelf, current_sku, state,
                battery, last_tag, carrying, current_sku,
            )
        except Exception as ex:
            print("[atlas_gui] state decode error: %s" % ex, flush=True)

    def _on_odom(self, msg):
        try:
            self._last_odom_t = time.time()
            x = float(msg.pose.pose.position.x)
            y = float(msg.pose.pose.position.y)
            q = msg.pose.pose.orientation
            siny = 2.0 * (q.w * q.z + q.x * q.y)
            cosy = 1.0 - 2.0 * (q.y * q.y + q.z * q.z)
            yaw = math.atan2(siny, cosy)
            vx = float(msg.twist.twist.linear.x)
            wz = float(msg.twist.twist.angular.z)
            self.odom_signal.emit(x, y, yaw, vx, wz)
        except Exception as ex:
            print("[atlas_gui] odom decode error: %s" % ex, flush=True)

    def _on_log(self, msg):
        try:
            text = getattr(msg, "data", "") or ""
            if text:
                self.log_signal.emit(text)
        except Exception as ex:
            print("[atlas_gui] log decode error: %s" % ex, flush=True)

    def _on_tag(self, msg):
        try:
            tag_id = getattr(msg, "tag_id", "") or ""
            shelf_id = getattr(msg, "shelf_id", "") or ""
            is_home = bool(getattr(msg, "is_home", False))
            self.tag_signal.emit(tag_id, shelf_id, is_home)
        except Exception as ex:
            print("[atlas_gui] tag decode error: %s" % ex, flush=True)

    # ------------------------------------------------------------------
    # publishers (called from Qt main thread)
    # ------------------------------------------------------------------
    def send_mission(self, shelf, sku, priority):
        if self.pub_mission is None or FleetMission is None:
            return ""
        try:
            m = FleetMission()
            m.mission_id = "gui-" + uuid.uuid4().hex[:6]
            m.target_shelf = str(shelf)
            m.sku = str(sku)
            m.priority = int(priority)
            self.pub_mission.publish(m)
            self.mission_sent_signal.emit(
                m.mission_id, str(shelf), str(sku), int(priority)
            )
            return m.mission_id
        except Exception as ex:
            print("[atlas_gui] publish mission failed: %s" % ex, flush=True)
            return ""

    def _publish_empty(self, pub):
        if pub is None or Empty is None:
            return False
        try:
            pub.publish(Empty())
            return True
        except Exception as ex:
            print("[atlas_gui] publish empty failed: %s" % ex, flush=True)
            return False

    def send_estop(self):
        return self._publish_empty(self.pub_estop)

    def send_reset_estop(self):
        return self._publish_empty(self.pub_reset)

    def send_return_home(self):
        return self._publish_empty(self.pub_reset_dock)

    def send_reset_agv(self):
        return self._publish_empty(self.pub_reset_dock)

    # ------------------------------------------------------------------
    def shutdown(self):
        self._stop = True
        try:
            if self.node is not None:
                self.node.destroy_node()
        except Exception:
            pass
        try:
            if rclpy.ok():
                rclpy.shutdown()
        except Exception:
            pass
```

---
## FILE: src/atlas_mission_manager/atlas_mission_manager/gui/widgets.py
```
"""Custom widgets used by the ATLAS Fleet Control Center."""

from PyQt5.QtCore import Qt
from PyQt5.QtGui import QFont
from PyQt5.QtWidgets import (
    QFrame, QHBoxLayout, QLabel, QProgressBar, QSizePolicy, QVBoxLayout,
    QWidget,
)

from . import theme as T


class Card(QFrame):
    """Generic rounded panel container."""

    def __init__(self, parent=None, object_name="Card"):
        super().__init__(parent)
        self.setObjectName(object_name)
        self.setFrameShape(QFrame.NoFrame)


class StatusCard(QFrame):
    """A single labelled metric card for the centre status panel."""

    LEVELS = {
        "ok": T.ACCENT,
        "info": T.INFO,
        "warn": T.WARN,
        "error": T.DANGER,
        "muted": T.TEXT_DIM,
    }

    def __init__(self, title, default="-", parent=None):
        super().__init__(parent)
        self.setObjectName("StatusCard")
        self.setFrameShape(QFrame.NoFrame)
        layout = QVBoxLayout(self)
        layout.setContentsMargins(14, 10, 14, 10)
        layout.setSpacing(4)
        self._title = QLabel(title.upper())
        self._title.setObjectName("CardTitle")
        self._value = QLabel(default)
        self._value.setObjectName("CardValue")
        self._value.setFont(QFont("Segoe UI", 14, QFont.Bold))
        self._value.setWordWrap(False)
        layout.addWidget(self._title)
        layout.addWidget(self._value)
        self.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Fixed)
        self.set_status("ok")

    def set_value(self, text):
        self._value.setText("" if text is None else str(text))

    def set_status(self, level):
        color = self.LEVELS.get(level, T.TEXT_PRIMARY)
        self._value.setStyleSheet(
            "color: %s; font-weight: 700; font-size: 16px;" % color
        )


class BatteryWidget(QFrame):
    """Battery percent gauge with adaptive colour."""

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setObjectName("StatusCard")
        layout = QVBoxLayout(self)
        layout.setContentsMargins(14, 10, 14, 10)
        layout.setSpacing(6)

        self._title = QLabel("BATTERY")
        self._title.setObjectName("CardTitle")
        self._value = QLabel("100%")
        self._value.setObjectName("CardValue")

        top = QHBoxLayout()
        top.setContentsMargins(0, 0, 0, 0)
        top.addWidget(self._title)
        top.addStretch()
        top.addWidget(self._value)

        self._bar = QProgressBar()
        self._bar.setRange(0, 100)
        self._bar.setValue(100)
        self._bar.setTextVisible(False)
        self._bar.setMinimumHeight(12)
        self._bar.setMaximumHeight(12)

        layout.addLayout(top)
        layout.addWidget(self._bar)
        self.set_percent(100.0)

    def set_percent(self, pct):
        try:
            v = max(0, min(100, int(round(float(pct)))))
        except Exception:
            v = 0
        self._bar.setValue(v)
        self._value.setText("%d%%" % v)
        if v >= 60:
            color = T.ACCENT
        elif v >= 25:
            color = T.WARN
        else:
            color = T.DANGER
        self._value.setStyleSheet("color: %s; font-weight: 700;" % color)
        self._bar.setStyleSheet(
            "QProgressBar { border: 1px solid %s; border-radius: 6px; "
            "background: %s; }"
            "QProgressBar::chunk { background: %s; border-radius: 5px; }"
            % (T.BORDER, T.BG_INPUT, color)
        )


class ConnectionWidget(QFrame):
    """Live / Offline indicator pill."""

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setObjectName("ConnPill")
        layout = QHBoxLayout(self)
        layout.setContentsMargins(12, 6, 12, 6)
        layout.setSpacing(8)

        self._dot = QLabel("\u25CF")
        self._dot.setAlignment(Qt.AlignVCenter | Qt.AlignHCenter)
        self._label = QLabel("CONNECTING")
        self._label.setAlignment(Qt.AlignVCenter)

        layout.addWidget(self._dot)
        layout.addWidget(self._label)
        self.set_connected(False)

    def set_connected(self, connected):
        if connected:
            self._label.setText("LIVE")
            color = T.ACCENT
        else:
            self._label.setText("OFFLINE")
            color = T.DANGER
        self._dot.setStyleSheet("color: %s; font-size: 14px;" % color)
        self._label.setStyleSheet(
            "color: %s; font-weight: 700; letter-spacing: 1px;" % color
        )


class SectionLabel(QLabel):
    """Small uppercase section header."""

    def __init__(self, text, parent=None):
        super().__init__(text.upper(), parent)
        self.setObjectName("SectionTitle")


class Divider(QFrame):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setObjectName("Divider")
        self.setFrameShape(QFrame.NoFrame)
        self.setFixedHeight(1)
```

---
## FILE: src/atlas_mission_manager/atlas_mission_manager/gui/main_window.py
```
"""Main window for the ATLAS Fleet Control Center.

Layout
------
+-------------------------------------------------------------------+
| header  (title + connection pill + clock)                         |
+--------------+----------------------------+-----------------------+
| LEFT         | CENTER                     | RIGHT                 |
|              |                            |                       |
| Create       | AGV Status cards           | Mission queue table   |
| Mission      | + Battery + Connectivity   | Mission history table |
|              |                            | Active task list      |
| Robot        |                            |                       |
| Commands     |                            |                       |
+--------------+----------------------------+-----------------------+
| BOTTOM: scrollable event log                                      |
+-------------------------------------------------------------------+
"""

import math
from datetime import datetime

from PyQt5.QtCore import Qt, QTimer
from PyQt5.QtGui import QFont, QTextCursor
from PyQt5.QtWidgets import (
    QAbstractItemView, QComboBox, QFormLayout, QFrame, QGridLayout,
    QHBoxLayout, QHeaderView, QLabel, QMainWindow, QMessageBox,
    QPushButton, QScrollArea, QSpinBox, QSplitter, QTableWidget,
    QTableWidgetItem, QTextEdit, QVBoxLayout, QWidget,
)

from . import theme as T
from .widgets import (
    BatteryWidget, ConnectionWidget, Divider, SectionLabel, StatusCard,
)


# ---- shelf / SKU catalogue -------------------------------------------
SHELVES = ["S%02d" % i for i in range(1, 21)]
SKUS = ["SKU-001", "SKU-002", "SKU-003", "SKU-004", "SKU-005",
        "SKU-006", "SKU-007", "SKU-008", "SKU-009", "SKU-010"]

PRIORITY_LABELS = {0: "LOW", 1: "NORMAL", 2: "HIGH", 3: "URGENT"}


# ----------------------------------------------------------------------
# helper: panelled column
# ----------------------------------------------------------------------
def _panel(title=None):
    panel = QFrame()
    panel.setObjectName("Panel")
    layout = QVBoxLayout(panel)
    layout.setContentsMargins(14, 14, 14, 14)
    layout.setSpacing(10)
    if title:
        lbl = QLabel(title.upper())
        lbl.setObjectName("SectionTitle")
        layout.addWidget(lbl)
    return panel, layout


# ----------------------------------------------------------------------
# main window
# ----------------------------------------------------------------------
class MainWindow(QMainWindow):

    HISTORY_LIMIT = 50
    LOG_LIMIT = 1000

    def __init__(self, bridge):
        super().__init__()
        self.bridge = bridge

        self.setWindowTitle("ATLAS Fleet Control Center")
        self.setMinimumSize(1280, 760)
        self.resize(1480, 880)

        # mission tracking ------------------------------------------------
        # ordered list of dicts: {id, shelf, sku, priority, status}
        self._missions = []
        # finished missions (most recent first)
        self._history = []
        self._last_active_id = ""
        self._last_state = ""

        self._build_ui()
        self._connect_signals()

        # clock tick
        self._clock = QTimer(self)
        self._clock.timeout.connect(self._update_clock)
        self._clock.start(1000)
        self._update_clock()

        self._append_log("[GUI] ATLAS Fleet Control Center ready", "mission")

    # ------------------------------------------------------------------
    # UI construction
    # ------------------------------------------------------------------
    def _build_ui(self):
        central = QWidget()
        self.setCentralWidget(central)
        root = QVBoxLayout(central)
        root.setContentsMargins(14, 14, 14, 14)
        root.setSpacing(12)

        root.addWidget(self._build_header())

        body_split = QSplitter(Qt.Vertical)
        body_split.setChildrenCollapsible(False)
        body_split.setHandleWidth(6)

        cols = QSplitter(Qt.Horizontal)
        cols.setChildrenCollapsible(False)
        cols.setHandleWidth(6)
        cols.addWidget(self._build_left_panel())
        cols.addWidget(self._build_center_panel())
        cols.addWidget(self._build_right_panel())
        cols.setStretchFactor(0, 0)
        cols.setStretchFactor(1, 2)
        cols.setStretchFactor(2, 1)
        cols.setSizes([300, 720, 420])

        body_split.addWidget(cols)
        body_split.addWidget(self._build_bottom_panel())
        body_split.setStretchFactor(0, 4)
        body_split.setStretchFactor(1, 1)
        body_split.setSizes([600, 220])

        root.addWidget(body_split, 1)

    # ---- header -------------------------------------------------------
    def _build_header(self):
        bar = QFrame()
        bar.setObjectName("Panel")
        h = QHBoxLayout(bar)
        h.setContentsMargins(18, 10, 18, 10)
        h.setSpacing(16)

        title_box = QVBoxLayout()
        title_box.setContentsMargins(0, 0, 0, 0)
        title_box.setSpacing(2)
        title = QLabel("ATLAS  FLEET  CONTROL")
        title.setObjectName("PageTitle")
        sub = QLabel("WAREHOUSE AGV  -  COMMAND CONSOLE")
        sub.setObjectName("PageSubtitle")
        title_box.addWidget(title)
        title_box.addWidget(sub)
        h.addLayout(title_box)
        h.addStretch()

        self.clock_label = QLabel("--:--:--")
        self.clock_label.setStyleSheet(
            "color: %s; font-family: monospace; font-size: 14px;" % T.TEXT_MUTED
        )
        h.addWidget(self.clock_label)

        self.conn_widget = ConnectionWidget()
        h.addWidget(self.conn_widget)
        return bar

    # ---- left panel ---------------------------------------------------
    def _build_left_panel(self):
        outer = QScrollArea()
        outer.setWidgetResizable(True)
        outer.setFrameShape(QFrame.NoFrame)

        container = QWidget()
        col = QVBoxLayout(container)
        col.setContentsMargins(0, 0, 0, 0)
        col.setSpacing(12)

        # ------ Create Mission ----------------------------------------
        cm_panel, cm_layout = _panel("Create Mission")

        form = QFormLayout()
        form.setContentsMargins(0, 0, 0, 0)
        form.setSpacing(8)
        form.setLabelAlignment(Qt.AlignRight)

        self.shelf_combo = QComboBox()
        self.shelf_combo.addItems(SHELVES)
        form.addRow("Target shelf:", self.shelf_combo)

        self.sku_combo = QComboBox()
        self.sku_combo.addItems(SKUS)
        form.addRow("SKU:", self.sku_combo)

        self.prio_spin = QSpinBox()
        self.prio_spin.setRange(0, 3)
        self.prio_spin.setValue(1)
        self.prio_spin.setToolTip("0=LOW  1=NORMAL  2=HIGH  3=URGENT")
        form.addRow("Priority:", self.prio_spin)

        cm_layout.addLayout(form)

        self.btn_start = QPushButton("START MISSION")
        self.btn_start.setObjectName("PrimaryButton")
        self.btn_start.setMinimumHeight(40)
        cm_layout.addWidget(self.btn_start)

        col.addWidget(cm_panel)

        # ------ Robot Commands ----------------------------------------
        rc_panel, rc_layout = _panel("Robot Commands")

        self.btn_return_home = QPushButton("Return Home")
        self.btn_return_home.setMinimumHeight(36)
        rc_layout.addWidget(self.btn_return_home)

        self.btn_reset_agv = QPushButton("RESET AGV")
        self.btn_reset_agv.setObjectName("WarnButton")
        self.btn_reset_agv.setMinimumHeight(40)
        rc_layout.addWidget(self.btn_reset_agv)

        rc_layout.addWidget(Divider())

        self.btn_estop = QPushButton("EMERGENCY  STOP")
        self.btn_estop.setObjectName("DangerButton")
        self.btn_estop.setMinimumHeight(54)
        f = QFont()
        f.setPointSize(12)
        f.setBold(True)
        self.btn_estop.setFont(f)
        rc_layout.addWidget(self.btn_estop)

        self.btn_reset_estop = QPushButton("Reset E-Stop")
        self.btn_reset_estop.setMinimumHeight(34)
        rc_layout.addWidget(self.btn_reset_estop)

        col.addWidget(rc_panel)
        col.addStretch(1)

        outer.setWidget(container)
        outer.setMinimumWidth(280)
        outer.setMaximumWidth(360)
        return outer

    # ---- center panel -------------------------------------------------
    def _build_center_panel(self):
        panel, layout = _panel("AGV Status")

        # status cards in a responsive grid
        grid = QGridLayout()
        grid.setHorizontalSpacing(10)
        grid.setVerticalSpacing(10)

        self.cards = {}
        card_specs = [
            ("State", "IDLE", "ok"),
            ("Mission", "-", "muted"),
            ("Shelf", "-", "muted"),
            ("SKU", "-", "muted"),
            ("RFID", "-", "muted"),
            ("Carrying", "NO", "muted"),
            ("Pos X", "0.00 m", "info"),
            ("Pos Y", "0.00 m", "info"),
            ("Heading", "0.0 deg", "info"),
            ("Lin Vel", "0.00 m/s", "info"),
            ("Ang Vel", "0.00 rad/s", "info"),
            ("Nav", "READY", "ok"),
        ]
        cols = 4
        for i, (name, default, level) in enumerate(card_specs):
            card = StatusCard(name, default)
            card.set_status(level)
            self.cards[name] = card
            grid.addWidget(card, i // cols, i % cols)

        layout.addLayout(grid)

        # battery + connectivity row
        bottom_row = QHBoxLayout()
        bottom_row.setSpacing(10)
        self.battery = BatteryWidget()
        bottom_row.addWidget(self.battery, 2)

        conn_card = QFrame()
        conn_card.setObjectName("StatusCard")
        cl = QHBoxLayout(conn_card)
        cl.setContentsMargins(14, 10, 14, 10)
        cl.setSpacing(10)
        title = QLabel("CONNECTIVITY")
        title.setObjectName("CardTitle")
        cl.addWidget(title)
        cl.addStretch()
        self.conn_inline = ConnectionWidget()
        cl.addWidget(self.conn_inline)
        bottom_row.addWidget(conn_card, 1)

        layout.addLayout(bottom_row)
        layout.addStretch(1)
        return panel

    # ---- right panel --------------------------------------------------
    def _build_right_panel(self):
        outer = QFrame()
        col = QVBoxLayout(outer)
        col.setContentsMargins(0, 0, 0, 0)
        col.setSpacing(12)

        # mission queue --------------------------------------------------
        q_panel, q_layout = _panel("Mission Queue")
        self.queue_table = QTableWidget(0, 5)
        self.queue_table.setHorizontalHeaderLabels(
            ["ID", "Shelf", "SKU", "Prio", "Status"]
        )
        self.queue_table.verticalHeader().setVisible(False)
        self.queue_table.setEditTriggers(QAbstractItemView.NoEditTriggers)
        self.queue_table.setSelectionBehavior(QAbstractItemView.SelectRows)
        self.queue_table.setAlternatingRowColors(True)
        self.queue_table.horizontalHeader().setSectionResizeMode(
            QHeaderView.Stretch
        )
        self.queue_table.setMinimumHeight(140)
        q_layout.addWidget(self.queue_table)
        col.addWidget(q_panel, 2)

        # mission history -----------------------------------------------
        h_panel, h_layout = _panel("Mission History")
        self.history_table = QTableWidget(0, 5)
        self.history_table.setHorizontalHeaderLabels(
            ["Time", "ID", "Shelf", "SKU", "Result"]
        )
        self.history_table.verticalHeader().setVisible(False)
        self.history_table.setEditTriggers(QAbstractItemView.NoEditTriggers)
        self.history_table.setSelectionBehavior(QAbstractItemView.SelectRows)
        self.history_table.setAlternatingRowColors(True)
        self.history_table.horizontalHeader().setSectionResizeMode(
            QHeaderView.Stretch
        )
        self.history_table.setMinimumHeight(140)
        h_layout.addWidget(self.history_table)
        col.addWidget(h_panel, 2)

        # active task list ----------------------------------------------
        a_panel, a_layout = _panel("Active Task")
        self.active_table = QTableWidget(6, 2)
        self.active_table.verticalHeader().setVisible(False)
        self.active_table.horizontalHeader().setVisible(False)
        self.active_table.setEditTriggers(QAbstractItemView.NoEditTriggers)
        self.active_table.setSelectionMode(QAbstractItemView.NoSelection)
        self.active_table.setShowGrid(False)
        self.active_table.horizontalHeader().setSectionResizeMode(
            QHeaderView.Stretch
        )
        self.active_table.setFocusPolicy(Qt.NoFocus)
        self.active_rows = ["State", "Mission", "Target", "SKU", "RFID", "Carrying"]
        for i, name in enumerate(self.active_rows):
            k = QTableWidgetItem(name)
            k.setForeground(self._color_brush(T.TEXT_MUTED))
            v = QTableWidgetItem("-")
            v.setForeground(self._color_brush(T.ACCENT))
            v.setTextAlignment(Qt.AlignRight | Qt.AlignVCenter)
            self.active_table.setItem(i, 0, k)
            self.active_table.setItem(i, 1, v)
        self.active_table.setMinimumHeight(180)
        a_layout.addWidget(self.active_table)
        col.addWidget(a_panel, 1)

        return outer

    @staticmethod
    def _color_brush(hex_color):
        from PyQt5.QtGui import QBrush, QColor
        return QBrush(QColor(hex_color))

    # ---- bottom panel -------------------------------------------------
    def _build_bottom_panel(self):
        panel, layout = _panel("Event Log")

        toolbar = QHBoxLayout()
        toolbar.setContentsMargins(0, 0, 0, 0)
        toolbar.addStretch()
        self.btn_clear_log = QPushButton("Clear")
        self.btn_clear_log.setMaximumWidth(100)
        toolbar.addWidget(self.btn_clear_log)

        self.log_view = QTextEdit()
        self.log_view.setReadOnly(True)
        self.log_view.setLineWrapMode(QTextEdit.NoWrap)
        self.log_view.setMinimumHeight(120)

        layout.addLayout(toolbar)
        layout.addWidget(self.log_view, 1)
        return panel

    # ------------------------------------------------------------------
    # signal wiring
    # ------------------------------------------------------------------
    def _connect_signals(self):
        # buttons
        self.btn_start.clicked.connect(self._on_start_mission)
        self.btn_return_home.clicked.connect(self._on_return_home)
        self.btn_reset_agv.clicked.connect(self._on_reset_agv)
        self.btn_estop.clicked.connect(self._on_estop)
        self.btn_reset_estop.clicked.connect(self._on_reset_estop)
        self.btn_clear_log.clicked.connect(self.log_view.clear)

        # bridge
        self.bridge.state_signal.connect(self._on_state)
        self.bridge.odom_signal.connect(self._on_odom)
        self.bridge.log_signal.connect(self._on_ros_log)
        self.bridge.tag_signal.connect(self._on_tag)
        self.bridge.connection_signal.connect(self._on_connection)
        self.bridge.mission_sent_signal.connect(self._on_mission_sent)

    # ------------------------------------------------------------------
    # button handlers
    # ------------------------------------------------------------------
    def _on_start_mission(self):
        try:
            shelf = self.shelf_combo.currentText()
            sku = self.sku_combo.currentText()
            prio = int(self.prio_spin.value())
            mid = self.bridge.send_mission(shelf, sku, prio)
            if not mid:
                self._append_log(
                    "[GUI] Failed to publish mission - is mission_node running?",
                    "error",
                )
                QMessageBox.warning(
                    self, "Mission Failed",
                    "Could not publish on /atlas/mission_cmd.\n"
                    "Verify the mission_node is running.",
                )
        except Exception as ex:
            self._append_log("[GUI] Start mission error: %s" % ex, "error")

    def _on_return_home(self):
        if self.bridge.send_return_home():
            self._append_log(
                "[GUI] Return Home commanded (-> /atlas/reset_to_dock)",
                "mission",
            )
        else:
            self._append_log("[GUI] Return Home failed", "error")

    def _on_reset_agv(self):
        reply = QMessageBox.question(
            self,
            "Reset AGV",
            "Reset the AGV and return it to the home dock?\n\n"
            "This will:\n"
            "  - Cancel the active mission\n"
            "  - Clear the navigation goal\n"
            "  - Clear the mission queue\n"
            "  - Respawn the AGV at the home dock\n"
            "  - Reset state to IDLE",
            QMessageBox.Yes | QMessageBox.No,
            QMessageBox.No,
        )
        if reply != QMessageBox.Yes:
            return

        if not self.bridge.send_reset_agv():
            self._append_log("[GUI] RESET AGV failed", "error")
            return

        self._append_log("[GUI] RESET AGV commanded", "warn")
        # Mark anything still queued/active as cancelled locally.
        for m in self._missions:
            if m["status"] in ("QUEUED", "ACTIVE"):
                m["status"] = "CANCELLED"
                self._archive_mission(m, "CANCELLED")
        self._missions = [m for m in self._missions if m["status"]
                          in ("DONE", "CANCELLED")]
        self._refresh_queue_table()

    def _on_estop(self):
        if self.bridge.send_estop():
            self._append_log("[GUI] EMERGENCY STOP triggered", "error")
        else:
            self._append_log("[GUI] E-Stop publish failed", "error")

    def _on_reset_estop(self):
        if self.bridge.send_reset_estop():
            self._append_log("[GUI] E-Stop cleared", "mission")
        else:
            self._append_log("[GUI] Reset E-Stop publish failed", "error")

    # ------------------------------------------------------------------
    # ROS-driven slots (Qt main thread)
    # ------------------------------------------------------------------
    def _on_state(self, mission_id, target_shelf, current_sku, state,
                  battery, last_tag, carrying, _sku_dup):
        try:
            self.cards["State"].set_value(state or "IDLE")
            self.cards["State"].set_status(self._level_for_state(state))
            self.cards["Mission"].set_value(mission_id or "-")
            self.cards["Mission"].set_status(
                "ok" if mission_id else "muted"
            )
            self.cards["Shelf"].set_value(target_shelf or "-")
            self.cards["Shelf"].set_status(
                "ok" if target_shelf else "muted"
            )
            self.cards["SKU"].set_value(current_sku or "-")
            self.cards["SKU"].set_status(
                "ok" if current_sku else "muted"
            )
            self.cards["RFID"].set_value(last_tag or "-")
            self.cards["RFID"].set_status(
                "info" if last_tag else "muted"
            )
            self.cards["Carrying"].set_value("YES" if carrying else "NO")
            self.cards["Carrying"].set_status(
                "warn" if carrying else "muted"
            )

            nav_text, nav_level = self._nav_indicator(state)
            self.cards["Nav"].set_value(nav_text)
            self.cards["Nav"].set_status(nav_level)

            self.battery.set_percent(battery)

            # active task panel
            self._set_active_row("State", state or "-")
            self._set_active_row("Mission", mission_id or "-")
            self._set_active_row("Target", target_shelf or "-")
            self._set_active_row("SKU", current_sku or "-")
            self._set_active_row("RFID", last_tag or "-")
            self._set_active_row("Carrying", "YES" if carrying else "NO")

            # mission queue tracking
            self._update_queue_from_state(mission_id, state)

            self._last_active_id = mission_id
            self._last_state = state or ""
        except Exception as ex:
            self._append_log("[GUI] state slot error: %s" % ex, "error")

    def _on_odom(self, x, y, yaw, vx, wz):
        try:
            self.cards["Pos X"].set_value("%.2f m" % x)
            self.cards["Pos Y"].set_value("%.2f m" % y)
            self.cards["Heading"].set_value(
                "%.1f deg" % math.degrees(yaw)
            )
            self.cards["Lin Vel"].set_value("%.2f m/s" % vx)
            self.cards["Ang Vel"].set_value("%.2f rad/s" % wz)
        except Exception as ex:
            self._append_log("[GUI] odom slot error: %s" % ex, "error")

    def _on_ros_log(self, text):
        level = "info"
        low = text.lower()
        if any(k in low for k in ("error", "fail", "rejected", "estop", "e-stop")):
            level = "error"
        elif any(k in low for k in ("warn", "warning")):
            level = "warn"
        elif any(k in low for k in (
            "mission", "queued", "complete", "state ", "reset", "returned"
        )):
            level = "mission"
        self._append_log(text, level)

    def _on_tag(self, tag_id, shelf_id, is_home):
        if is_home:
            text = "[RFID] HOME tag %s" % tag_id
        else:
            text = "[RFID] %s -> %s" % (tag_id, shelf_id or "?")
        self._append_log(text, "info")

    def _on_connection(self, connected):
        self.conn_widget.set_connected(connected)
        self.conn_inline.set_connected(connected)
        if connected:
            self._append_log("[GUI] ROS connection LIVE", "mission")
        else:
            self._append_log("[GUI] ROS connection lost - waiting...", "warn")

    def _on_mission_sent(self, mission_id, shelf, sku, prio):
        entry = {
            "id": mission_id,
            "shelf": shelf,
            "sku": sku,
            "priority": int(prio),
            "status": "QUEUED",
        }
        self._missions.append(entry)
        self._refresh_queue_table()
        self._append_log(
            "[GUI] Mission %s queued -> %s (%s, prio=%s)"
            % (mission_id, shelf, sku, PRIORITY_LABELS.get(prio, str(prio))),
            "mission",
        )

    # ------------------------------------------------------------------
    # mission queue helpers
    # ------------------------------------------------------------------
    def _update_queue_from_state(self, mission_id, state):
        if mission_id:
            for m in self._missions:
                if m["id"] == mission_id and m["status"] != "ACTIVE":
                    m["status"] = "ACTIVE"
            self._refresh_queue_table()
            return

        # No active mission reported.  If we just transitioned away from a
        # previously-active mission, archive it as DONE.
        if self._last_active_id and not mission_id:
            for m in self._missions:
                if m["id"] == self._last_active_id and m["status"] == "ACTIVE":
                    m["status"] = "DONE"
                    self._archive_mission(m, "DONE")
            self._missions = [m for m in self._missions
                              if m["status"] not in ("DONE", "CANCELLED")]
            self._refresh_queue_table()

    def _refresh_queue_table(self):
        active = [m for m in self._missions
                  if m["status"] in ("QUEUED", "ACTIVE")]
        self.queue_table.setRowCount(len(active))
        for r, m in enumerate(active):
            self._set_cell(self.queue_table, r, 0, m["id"])
            self._set_cell(self.queue_table, r, 1, m["shelf"])
            self._set_cell(self.queue_table, r, 2, m["sku"])
            self._set_cell(
                self.queue_table, r, 3,
                PRIORITY_LABELS.get(m["priority"], str(m["priority"])),
            )
            color = T.ACCENT if m["status"] == "ACTIVE" else T.WARN
            self._set_cell(self.queue_table, r, 4, m["status"], color)

    def _archive_mission(self, m, result):
        ts = datetime.now().strftime("%H:%M:%S")
        self._history.insert(0, {
            "time": ts,
            "id": m["id"],
            "shelf": m["shelf"],
            "sku": m["sku"],
            "result": result,
        })
        self._history = self._history[: self.HISTORY_LIMIT]
        self._refresh_history_table()

    def _refresh_history_table(self):
        self.history_table.setRowCount(len(self._history))
        for r, h in enumerate(self._history):
            self._set_cell(self.history_table, r, 0, h["time"])
            self._set_cell(self.history_table, r, 1, h["id"])
            self._set_cell(self.history_table, r, 2, h["shelf"])
            self._set_cell(self.history_table, r, 3, h["sku"])
            color = T.ACCENT if h["result"] == "DONE" else T.DANGER
            self._set_cell(self.history_table, r, 4, h["result"], color)

    @staticmethod
    def _set_cell(table, row, col, text, color=None):
        item = QTableWidgetItem("" if text is None else str(text))
        if color is not None:
            from PyQt5.QtGui import QBrush, QColor
            item.setForeground(QBrush(QColor(color)))
        table.setItem(row, col, item)

    def _set_active_row(self, key, value):
        if key not in self.active_rows:
            return
        r = self.active_rows.index(key)
        item = self.active_table.item(r, 1)
        if item is None:
            item = QTableWidgetItem("")
            self.active_table.setItem(r, 1, item)
        item.setText("" if value is None else str(value))
        item.setTextAlignment(Qt.AlignRight | Qt.AlignVCenter)

    # ------------------------------------------------------------------
    # state helpers
    # ------------------------------------------------------------------
    @staticmethod
    def _level_for_state(state):
        if not state:
            return "muted"
        s = state.upper()
        if s in ("IDLE", "DOCKED"):
            return "ok"
        if s == "ERROR":
            return "error"
        if s in ("AT_SHELF", "PICKUP"):
            return "info"
        return "warn"

    @staticmethod
    def _nav_indicator(state):
        if not state:
            return ("UNKNOWN", "muted")
        s = state.upper()
        if s == "IDLE":
            return ("READY", "ok")
        if s == "ERROR":
            return ("E-STOP", "error")
        if s == "DOCKED":
            return ("DOCKED", "ok")
        return ("ACTIVE", "warn")

    # ------------------------------------------------------------------
    # log helpers
    # ------------------------------------------------------------------
    def _append_log(self, text, level="info"):
        if text is None:
            return
        ts = datetime.now().strftime("%H:%M:%S")
        color_map = {
            "info": T.LOG_INFO,
            "mission": T.LOG_MISSION,
            "warn": T.LOG_WARN,
            "error": T.LOG_ERROR,
        }
        color = color_map.get(level, T.LOG_INFO)

        # Escape minimal HTML so robot log can't inject markup.
        safe = (str(text)
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;"))
        line = (
            '<span style="color:%s;">[%s]</span> '
            '<span style="color:%s;">%s</span>'
            % (T.LOG_TS, ts, color, safe)
        )
        self.log_view.append(line)

        # Cap log length so memory stays bounded.
        if self.log_view.document().blockCount() > self.LOG_LIMIT:
            cursor = self.log_view.textCursor()
            cursor.movePosition(QTextCursor.Start)
            cursor.select(QTextCursor.BlockUnderCursor)
            cursor.removeSelectedText()
            cursor.deleteChar()

        sb = self.log_view.verticalScrollBar()
        sb.setValue(sb.maximum())

    def _update_clock(self):
        self.clock_label.setText(datetime.now().strftime("%H:%M:%S"))

    # ------------------------------------------------------------------
    def closeEvent(self, event):
        try:
            self.bridge.shutdown()
        except Exception:
            pass
        event.accept()
```
---
## FILE: src/atlas_mission_manager/atlas_mission_manager/mission_node.py
```
"""
ATLAS Mission Manager — sole publisher on /atlas/cmd_vel.
NEVER modifies robot pose during normal operation.
RESET TO DOCK only on explicit operator command.
"""
import math
import uuid
import rclpy
from rclpy.node import Node
from std_msgs.msg import Empty, Float32, String
from geometry_msgs.msg import Twist
from nav_msgs.msg import Odometry
from atlas_interfaces.msg import FleetMission, RobotState, ShelfTag
from gazebo_msgs.srv import SetEntityState
from gazebo_msgs.msg import EntityState

AISLE_Y = [2, 4, 6, 8, 10]
SHELF_X = [1.0, 2.0, 3.0, 4.0]
SHELVES = {}
_i = 1
for ay in AISLE_Y:
    for sx in SHELF_X:
        SHELVES['S%02d' % _i] = (sx, float(ay), (AISLE_Y.index(ay) + 1))
        _i += 1

S_IDLE = 'IDLE'
S_NAV_SPINE = 'NAV_SPINE'
S_TURNING = 'TURNING'
S_NAV_AISLE = 'NAV_AISLE'
S_AT_SHELF = 'AT_SHELF'
S_PICKUP = 'PICKUP'
S_PIVOT = 'PIVOT'
S_RET_AISLE = 'RET_AISLE'
S_RET_TURN = 'RET_TURN'
S_RET_SPINE = 'RET_SPINE'
S_DOCKED = 'DOCKED'
S_ERROR = 'ERROR'

class MissionManager(Node):
    def __init__(self):
        super().__init__('atlas_mission_manager')
        self.create_subscription(Twist, '/atlas/nav_vel', self._nav_cb, 10)
        self.create_subscription(Twist, '/atlas/turn_vel', self._turn_cb, 10)
        self.create_subscription(Empty, '/atlas/turn_done', self._turn_done, 10)
        self.create_subscription(Empty, '/atlas/junction', self._junction, 10)
        self.create_subscription(ShelfTag, '/atlas/tag_event', self._tag, 10)
        self.create_subscription(Odometry, '/atlas/odom', self._odom, 10)
        self.create_subscription(FleetMission, '/atlas/mission_cmd', self._mission_in, 10)
        self.create_subscription(Empty, '/atlas/estop', self._estop, 10)
        self.create_subscription(Empty, '/atlas/reset', self._reset_cmd, 10)
        self.create_subscription(Empty, '/atlas/reset_to_dock', self._reset_to_dock, 10)
        self.pub_cmd = self.create_publisher(Twist, '/atlas/cmd_vel', 10)
        self.pub_turn = self.create_publisher(Float32, '/atlas/turn_cmd', 10)
        self.pub_state = self.create_publisher(RobotState, '/atlas/robot_state', 10)
        self.pub_log = self.create_publisher(String, '/atlas/log', 50)
        self.create_timer(1.0 / 50.0, self._tick)
        self.create_timer(1.0 / 10.0, self._pub_status)
        self.gazebo_client = self.create_client(SetEntityState, '/set_entity_state')
        self.state = S_IDLE
        self.queue = []
        self.active = None
        self.nav_tw = Twist()
        self.turn_tw = Twist()
        self.junc_count = 0
        self.x = 0.0
        self.y = 0.0
        self.battery = 100.0
        self.carrying = False
        self.last_tag = ''
        self.estopped = False
        self.state_t = self._now()
        self.get_logger().info('MissionManager ready')

    def _now(self):
        return self.get_clock().now().nanoseconds * 1e-9

    def _log(self, s):
        self.get_logger().info(s)
        m = String()
        m.data = s
        self.pub_log.publish(m)

    def _go(self, ns):
        if ns != self.state:
            self._log('STATE %s -> %s' % (self.state, ns))
            self.state = ns
            self.state_t = self._now()

    def _nav_cb(self, msg):
        self.nav_tw = msg

    def _turn_cb(self, msg):
        self.turn_tw = msg

    def _odom(self, msg):
        self.x = msg.pose.pose.position.x
        self.y = msg.pose.pose.position.y

    def _mission_in(self, msg):
        if msg.target_shelf not in SHELVES:
            self._log('Rejected unknown shelf %s' % msg.target_shelf)
            return
        if not msg.mission_id:
            msg.mission_id = 'm-' + uuid.uuid4().hex[:6]
        self.queue.append(msg)
        self._log('Queued %s -> %s' % (msg.mission_id, msg.target_shelf))

    def _estop(self, _):
        self.estopped = True
        self._go(S_ERROR)

    def _reset_cmd(self, _):
        self.estopped = False
        self.queue = []
        self.active = None
        self.carrying = False
        self._go(S_IDLE)

    def _reset_to_dock(self, _):
        self._log('RESET REQUESTED')
        self._log('MISSION CANCELLED')
        self.estopped = False
        self.queue = []
        self.active = None
        self.carrying = False
        self.nav_tw = Twist()
        self.turn_tw = Twist()
        self.junc_count = 0
        self.pub_cmd.publish(Twist())
        self._relocate_to_dock()
        self._go(S_IDLE)
        self._log('ROBOT RETURNED TO HOME')
        self._log('SYSTEM READY')

    def _relocate_to_dock(self):
        if not self.gazebo_client.wait_for_service(timeout_sec=2.0):
            self._log('WARNING: Gazebo set_entity_state service not available')
            return
        req = SetEntityState.Request()
        req.state = EntityState()
        req.state.name = 'atlas_agv'
        req.state.pose.position.x = 0.0
        req.state.pose.position.y = 0.0
        req.state.pose.position.z = 0.01
        req.state.pose.orientation.x = 0.0
        req.state.pose.orientation.y = 0.0
        req.state.pose.orientation.z = 0.7071
        req.state.pose.orientation.w = 0.7071
        req.state.reference_frame = 'world'
        future = self.gazebo_client.call_async(req)
        rclpy.spin_until_future_complete(self, future, timeout_sec=3.0)

    def _junction(self, _):
        if self.state == S_NAV_SPINE:
            self.junc_count += 1
            target_aisle = SHELVES[self.active.target_shelf][2]
            self._log('Junction #%d/%d' % (self.junc_count, target_aisle))
            if self.junc_count >= target_aisle:
                m = Float32()
                m.data = -math.pi / 2.0
                self.pub_turn.publish(m)
                self._go(S_TURNING)
        elif self.state == S_RET_AISLE:
            m = Float32()
            m.data = math.pi / 2.0
            self.pub_turn.publish(m)
            self._go(S_RET_TURN)

    def _turn_done(self, _):
        if self.state == S_TURNING:
            self._go(S_NAV_AISLE)
        elif self.state == S_RET_TURN:
            self._go(S_RET_SPINE)
        elif self.state == S_PIVOT:
            self._go(S_RET_AISLE)

    def _tag(self, ev):
        self.last_tag = ev.tag_id
        if self.state == S_NAV_AISLE and not ev.is_home:
            if self.active and ev.shelf_id == self.active.target_shelf:
                self._go(S_AT_SHELF)
        elif self.state == S_RET_SPINE and ev.is_home:
            self._go(S_DOCKED)

    def _tick(self):
        now = self._now()
        dt = now - self.state_t
        if self.state == S_IDLE and self.queue and not self.estopped:
            self.active = self.queue.pop(0)
            self.junc_count = 0
            self._go(S_NAV_SPINE)
        elif self.state == S_AT_SHELF and dt > 0.5:
            self._go(S_PICKUP)
        elif self.state == S_PICKUP and dt > 2.0:
            self.carrying = True
            m = Float32()
            m.data = math.pi
            self.pub_turn.publish(m)
            self._go(S_PIVOT)
        elif self.state == S_DOCKED and dt > 1.0:
            self.carrying = False
            self.battery = 100.0
            self.active = None
            self._go(S_IDLE)
            self._log('Mission complete')
        out = Twist()
        if self.state in (S_NAV_SPINE, S_NAV_AISLE, S_RET_AISLE, S_RET_SPINE):
            out = self.nav_tw
        elif self.state in (S_TURNING, S_PIVOT, S_RET_TURN):
            out = self.turn_tw
        if self.estopped:
            out = Twist()
        self.pub_cmd.publish(out)

    def _pub_status(self):
        s = RobotState()
        s.state = self.state
        s.mission_id = self.active.mission_id if self.active else ''
        s.target_shelf = self.active.target_shelf if self.active else ''
        s.current_sku = self.active.sku if self.active else ''
        s.last_tag = self.last_tag
        s.carrying_load = self.carrying
        s.battery_percent = self.battery
        s.pose.x = self.x
        s.pose.y = self.y
        self.pub_state.publish(s)

def main(args=None):
    rclpy.init(args=args)
    node = MissionManager()
    try:
        rclpy.spin(node)
    finally:
        node.destroy_node()
        rclpy.shutdown()

if __name__ == '__main__':
    main()
```

---
## FILE: src/atlas_mission_manager/package.xml
```
<?xml version="1.0"?>
<package format="3">
  <name>atlas_mission_manager</name>
  <version>1.0.0</version>
  <description>ATLAS mission FSM, velocity arbiter, CLI sender, and Fleet Control Center GUI</description>
  <maintainer email="atlas@dev.local">atlas</maintainer>
  <license>MIT</license>
  <buildtool_depend>ament_python</buildtool_depend>
  <depend>rclpy</depend>
  <depend>std_msgs</depend>
  <depend>geometry_msgs</depend>
  <depend>nav_msgs</depend>
  <depend>atlas_interfaces</depend>
  <depend>python3-pyqt5</depend>
  <export><build_type>ament_python</build_type></export>
</package>
```

---
## FILE: src/atlas_mission_manager/setup.py
```
from setuptools import setup

package_name = 'atlas_mission_manager'

setup(
    name=package_name,
    version='1.0.0',
    packages=[
        package_name,
        package_name + '.gui',
    ],
    data_files=[
        ('share/ament_index/resource_index/packages',
         ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='atlas',
    maintainer_email='atlas@dev.local',
    description='ATLAS mission FSM, velocity arbiter, CLI sender, and GUI.',
    license='MIT',
    entry_points={
        'console_scripts': [
            'mission_node = atlas_mission_manager.mission_node:main',
            'send_mission = atlas_mission_manager.send_mission:main',
            'atlas_gui    = atlas_mission_manager.atlas_gui:main',
        ],
    },
)
```

---
## FILE: src/atlas_navigation/package.xml
```
<?xml version="1.0"?>
<package format="3">
  <name>atlas_navigation</name>
  <version>1.0.0</version>
  <description>ATLAS navigation nodes</description>
  <maintainer email="atlas@dev.local">atlas</maintainer>
  <license>MIT</license>
  <buildtool_depend>ament_python</buildtool_depend>
  <depend>rclpy</depend>
  <depend>std_msgs</depend>
  <depend>geometry_msgs</depend>
  <depend>nav_msgs</depend>
  <depend>sensor_msgs</depend>
  <depend>atlas_interfaces</depend>
  <export><build_type>ament_python</build_type></export>
</package>
```

---
## FILE: src/atlas_navigation/atlas_navigation/turn_controller.py
```
"""IMU-based turn controller. Publishes to /atlas/turn_vel."""
import math
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Imu
from std_msgs.msg import Float32, Empty
from geometry_msgs.msg import Twist

SPEED = 0.4
TOL = math.radians(3.0)


def _yaw(q):
    return math.atan2(2*(q.w*q.z+q.x*q.y), 1-2*(q.y*q.y+q.z*q.z))


def _wrap(a):
    return math.atan2(math.sin(a), math.cos(a))


class TurnController(Node):
    def __init__(self):
        super().__init__('atlas_turn_controller')
        self.create_subscription(Imu, '/atlas/imu', self._imu, 10)
        self.create_subscription(Float32, '/atlas/turn_cmd', self._cmd, 10)
        self.pub = self.create_publisher(Twist, '/atlas/turn_vel', 10)
        self.pub_done = self.create_publisher(Empty, '/atlas/turn_done', 10)
        self.create_timer(1/50.0, self._tick)
        self._yaw = 0.0
        self._target = 0.0
        self._dir = 0.0
        self._active = False
        self._have_imu = False

    def _imu(self, msg):
        self._yaw = _yaw(msg.orientation)
        self._have_imu = True

    def _cmd(self, msg):
        if not self._have_imu:
            return
        delta = msg.data
        self._target = _wrap(self._yaw + delta)
        self._dir = 1.0 if delta > 0 else -1.0
        self._active = True

    def _tick(self):
        tw = Twist()
        if self._active and self._have_imu:
            err = _wrap(self._target - self._yaw)
            if abs(err) < TOL:
                self._active = False
                self.pub.publish(Twist())
                self.pub_done.publish(Empty())
                return
            tw.angular.z = self._dir * SPEED
        self.pub.publish(tw)


def main():
    rclpy.init()
    rclpy.spin(TurnController())
    rclpy.shutdown()
```

---
## FILE: src/atlas_navigation/atlas_navigation/__init__.py
```
```

---
## FILE: src/atlas_navigation/atlas_navigation/tag_detector.py
```
"""Simulated RFID tag detector."""
import math
import rclpy
from rclpy.node import Node
from nav_msgs.msg import Odometry
from atlas_interfaces.msg import ShelfTag

DETECT_R = 0.5
REARM_R = 0.8
HOME = {'id': 'TAG-HOME', 'shelf': '', 'x': 0.0, 'y': 0.0, 'home': True}
AISLE_Y = [2, 4, 6, 8, 10]
SHELF_X = [1.0, 2.0, 3.0, 4.0]
TAGS = [HOME]
_i = 1
for ay in AISLE_Y:
    for sx in SHELF_X:
        TAGS.append({'id': f'TAG-S{_i:02d}', 'shelf': f'S{_i:02d}',
                     'x': sx, 'y': float(ay), 'home': False})
        _i += 1


class TagDetector(Node):
    def __init__(self):
        super().__init__('atlas_tag_detector')
        self.create_subscription(Odometry, '/atlas/odom', self._odom, 10)
        self.pub = self.create_publisher(ShelfTag, '/atlas/tag_event', 10)
        self.create_timer(1/50.0, self._tick)
        self._x = self._y = 0.0
        self._armed = {t['id']: True for t in TAGS}
        self._have = False

    def _odom(self, msg):
        self._x = msg.pose.pose.position.x
        self._y = msg.pose.pose.position.y
        self._have = True

    def _tick(self):
        if not self._have:
            return
        for t in TAGS:
            d = math.hypot(self._x - t['x'], self._y - t['y'])
            if self._armed[t['id']] and d <= DETECT_R:
                m = ShelfTag()
                m.tag_id = t['id']
                m.shelf_id = t['shelf']
                m.distance = float(d)
                m.is_home = t['home']
                m.stamp = self.get_clock().now().to_msg()
                self.pub.publish(m)
                self._armed[t['id']] = False
            elif not self._armed[t['id']] and d > REARM_R:
                self._armed[t['id']] = True


def main():
    rclpy.init()
    rclpy.spin(TagDetector())
    rclpy.shutdown()
```

---
## FILE: src/atlas_navigation/atlas_navigation/line_follower.py
```
"""PID line follower. Publishes to /atlas/nav_vel (not cmd_vel directly)."""
import rclpy
from rclpy.node import Node
from std_msgs.msg import Int8MultiArray
from geometry_msgs.msg import Twist

SPEED = 0.4
KP, KI, KD = 0.6, 0.0, 0.2
WEIGHTS = [1.0, 0.71, 0.43, 0.14, -0.14, -0.43, -0.71, -1.0]
GRACE = 60


class LineFollower(Node):
    def __init__(self):
        super().__init__('atlas_line_follower')
        self.create_subscription(Int8MultiArray, '/atlas/line_sensors', self._cb, 10)
        self.pub = self.create_publisher(Twist, '/atlas/nav_vel', 10)
        self.create_timer(1/50.0, self._tick)
        self._err = self._prev = self._intg = 0.0
        self._lost = GRACE + 1
        self._tw = Twist()

    def _cb(self, msg):
        bits = list(msg.data)
        total = sum(bits)
        if total == 0:
            self._lost += 1
            return
        self._err = sum(WEIGHTS[i]*bits[i] for i in range(8)) / total
        d = self._err - self._prev
        self._prev = self._err
        self._intg = max(-1, min(1, self._intg + self._err/50))
        ang = KP*self._err + KI*self._intg + KD*d
        tw = Twist()
        tw.linear.x = SPEED
        tw.angular.z = ang
        self._tw = tw
        self._lost = 0

    def _tick(self):
        if self._lost > GRACE:
            self.pub.publish(Twist())
        else:
            self.pub.publish(self._tw)


def main():
    rclpy.init()
    rclpy.spin(LineFollower())
    rclpy.shutdown()
```

---
## FILE: src/atlas_navigation/atlas_navigation/line_sensor.py
```
"""
Virtual line sensor — 8 IR elements at 50Hz.
Uses odom directly as world coordinates (no transform needed).
The diff_drive plugin odom frame IS the world frame in this project because
the robot spawns at world (0,0,yaw=pi/2) and the plugin initializes odom
at the spawn pose.

KEY DESIGN: odom position IS world position. No odom_to_world conversion.
"""
import math
import rclpy
from rclpy.node import Node
from nav_msgs.msg import Odometry
from std_msgs.msg import Int8MultiArray, Float32MultiArray, Empty

# World geometry — matches atlas_gazebo/worlds/warehouse.world exactly
SPINE = ((0.0, 0.0), (0.0, 12.0))  # x=0, y from 0 to 12
AISLES = [((0.0, y), (5.0, y)) for y in [2, 4, 6, 8, 10]]
ALL_LINES = [SPINE] + AISLES

# Sensor config
LINE_WIDTH = 0.08  # detection width (half=0.04m)
SENSOR_FWD = 0.10  # 10cm ahead of base_footprint
SENSOR_OFFSETS = [0.07, 0.05, 0.03, 0.01, -0.01, -0.03, -0.05, -0.07]
JUNC_THRESH = 5
JUNC_CONFIRM = 3
JUNC_COOLDOWN = 2.0


def _quat_to_yaw(q):
    return math.atan2(2*(q.w*q.z + q.x*q.y), 1 - 2*(q.y*q.y + q.z*q.z))


def _dist_to_seg(px, py, x1, y1, x2, y2):
    dx, dy = x2-x1, y2-y1
    if dx == 0 and dy == 0:
        return math.hypot(px-x1, py-y1)
    t = max(0.0, min(1.0, ((px-x1)*dx+(py-y1)*dy)/(dx*dx+dy*dy)))
    return math.hypot(px-(x1+t*dx), py-(y1+t*dy))


def _min_line_dist(px, py):
    return min(_dist_to_seg(px, py, s[0][0], s[0][1], s[1][0], s[1][1])
               for s in ALL_LINES)


class LineSensor(Node):
    def __init__(self):
        super().__init__('atlas_line_sensor')
        self.create_subscription(Odometry, '/atlas/odom', self._odom_cb, 10)
        self.pub_bin = self.create_publisher(Int8MultiArray, '/atlas/line_sensors', 10)
        self.pub_raw = self.create_publisher(Float32MultiArray, '/atlas/line_raw', 10)
        self.pub_junc = self.create_publisher(Empty, '/atlas/junction', 10)
        self.create_timer(1/50.0, self._tick)
        self._x = self._y = self._yaw = 0.0
        self._have_odom = False
        self._streak = 0
        self._last_junc = 0.0
        self.get_logger().info('LineSensor ready (8ch, 50Hz)')

    def _odom_cb(self, msg):
        # ODOM IS WORLD — no transform needed
        self._x = msg.pose.pose.position.x
        self._y = msg.pose.pose.position.y
        self._yaw = _quat_to_yaw(msg.pose.pose.orientation)
        self._have_odom = True

    def _tick(self):
        if not self._have_odom:
            return
        cs, sn = math.cos(self._yaw), math.sin(self._yaw)
        half = LINE_WIDTH / 2.0
        bits, raws = [], []
        for off in SENSOR_OFFSETS:
            sx = self._x + cs*SENSOR_FWD - sn*off
            sy = self._y + sn*SENSOR_FWD + cs*off
            d = _min_line_dist(sx, sy)
            raws.append(float(d))
            bits.append(1 if d <= half else 0)

        m = Int8MultiArray(); m.data = bits
        self.pub_bin.publish(m)
        r = Float32MultiArray(); r.data = raws
        self.pub_raw.publish(r)

        # Junction detection
        now = self.get_clock().now().nanoseconds * 1e-9
        self._streak = self._streak + 1 if sum(bits) >= JUNC_THRESH else 0
        if self._streak >= JUNC_CONFIRM and (now - self._last_junc) > JUNC_COOLDOWN:
            self._last_junc = now
            self._streak = 0
            self.pub_junc.publish(Empty())
            self.get_logger().info(f'JUNCTION at ({self._x:.2f}, {self._y:.2f})')


def main():
    rclpy.init()
    rclpy.spin(LineSensor())
    rclpy.shutdown()
```

---
## FILE: src/atlas_navigation/setup.py
```
from setuptools import setup
setup(
    name='atlas_navigation',
    version='1.0.0',
    packages=['atlas_navigation'],
    data_files=[
        ('share/ament_index/resource_index/packages', ['resource/atlas_navigation']),
        ('share/atlas_navigation', ['package.xml']),
    ],
    install_requires=['setuptools'],
    entry_points={'console_scripts': [
        'line_sensor    = atlas_navigation.line_sensor:main',
        'line_follower  = atlas_navigation.line_follower:main',
        'turn_controller = atlas_navigation.turn_controller:main',
        'tag_detector   = atlas_navigation.tag_detector:main',
    ]},
)
```
