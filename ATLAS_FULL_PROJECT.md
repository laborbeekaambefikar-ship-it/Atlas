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
import sys
import math
import threading
import uuid
from datetime import datetime

import rclpy
from rclpy.node import Node
from std_msgs.msg import Empty, String
from geometry_msgs.msg import Twist
from nav_msgs.msg import Odometry
from atlas_interfaces.msg import FleetMission, RobotState, ShelfTag

from PyQt5.QtCore import Qt, pyqtSignal, QObject, QPointF, QRectF
from PyQt5.QtGui import QPainter, QColor, QFont, QPen, QBrush
from PyQt5.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QGridLayout, QLabel, QPushButton, QGroupBox, QTableWidget,
    QTableWidgetItem, QTextEdit, QComboBox, QSpinBox, QDialog,
)

DARK_STYLE = """
QMainWindow { background-color: #1a1a2e; }
QWidget { background-color: #1a1a2e; color: #e0e0e0; font-family: Arial; }
QGroupBox { border: 1px solid #3a3a5c; border-radius: 6px; margin-top: 12px; padding-top: 14px; font-weight: bold; }
QGroupBox::title { subcontrol-origin: margin; left: 10px; padding: 0 6px; color: #00d4aa; }
QPushButton { background-color: #2d2d4a; border: 1px solid #4a4a6a; border-radius: 4px; padding: 8px 16px; min-height: 28px; }
QPushButton:hover { background-color: #3d3d5a; border-color: #00d4aa; }
QPushButton:pressed { background-color: #00d4aa; color: #1a1a2e; }
QTableWidget { background-color: #16213e; border: 1px solid #3a3a5c; }
QHeaderView::section { background-color: #2d2d4a; border: 1px solid #3a3a5c; padding: 6px; }
QTextEdit { background-color: #0f0f23; border: 1px solid #3a3a5c; font-family: monospace; font-size: 10px; }
QProgressBar { border: 1px solid #3a3a5c; border-radius: 3px; text-align: center; background-color: #16213e; }
QProgressBar::chunk { background-color: #00d4aa; border-radius: 2px; }
QComboBox, QSpinBox { background-color: #2d2d4a; border: 1px solid #4a4a6a; border-radius: 4px; padding: 4px; }
"""

class RosBridge(QObject):
    state_sig = pyqtSignal(object)
    odom_sig = pyqtSignal(float, float, float, float, float)
    log_sig = pyqtSignal(str)

    def __init__(self):
        super().__init__()
        rclpy.init()
        self.node = rclpy.create_node("atlas_gui")
        self.node.create_subscription(RobotState, "/atlas/robot_state", self._st, 10)
        self.node.create_subscription(Odometry, "/atlas/odom", self._od, 10)
        self.node.create_subscription(String, "/atlas/log", self._lg, 50)
        self.pub_mission = self.node.create_publisher(FleetMission, "/atlas/mission_cmd", 10)
        self.pub_estop = self.node.create_publisher(Empty, "/atlas/estop", 10)
        self.pub_reset_dock = self.node.create_publisher(Empty, "/atlas/reset_to_dock", 10)
        self.pub_reset = self.node.create_publisher(Empty, "/atlas/reset", 10)
        self._stop = False
        self._thread = threading.Thread(target=self._spin, daemon=True)
        self._thread.start()

    def _spin(self):
        while rclpy.ok() and not self._stop:
            rclpy.spin_once(self.node, timeout_sec=0.05)

    def _st(self, msg):
        self.state_sig.emit(msg)

    def _od(self, msg):
        x = msg.pose.pose.position.x
        y = msg.pose.pose.position.y
        q = msg.pose.pose.orientation
        yaw = math.atan2(2 * (q.w * q.z + q.x * q.y), 1 - 2 * (q.y * q.y + q.z * q.z))
        vx = msg.twist.twist.linear.x
        wz = msg.twist.twist.angular.z
        self.odom_sig.emit(x, y, yaw, vx, wz)

    def _lg(self, msg):
        self.log_sig.emit(msg.data)

    def send_mission(self, shelf, sku, priority):
        m = FleetMission()
        m.mission_id = "gui-" + uuid.uuid4().hex[:6]
        m.target_shelf = shelf
        m.sku = sku
        m.priority = priority
        self.pub_mission.publish(m)
        return m.mission_id

    def send_estop(self):
        self.pub_estop.publish(Empty())

    def send_reset(self):
        self.pub_reset.publish(Empty())

    def send_reset_to_dock(self):
        self.pub_reset_dock.publish(Empty())


    def shutdown(self):
        self._stop = True
        self.node.destroy_node()
        rclpy.shutdown()

class WarehouseMap(QWidget):
    def __init__(self):
        super().__init__()
        self.setMinimumSize(400, 400)
        self.robot_x = 0.0
        self.robot_y = 0.0
        self.robot_yaw = math.pi / 2
        self.trail = []

    def update_robot(self, x, y, yaw):
        self.robot_x = x
        self.robot_y = y
        self.robot_yaw = yaw
        self.trail.append((x, y))
        if len(self.trail) > 500:
            self.trail = self.trail[-500:]
        self.update()

    def _w2s(self, wx, wy):
        margin = 30
        w = self.width() - 2 * margin
        h = self.height() - 2 * margin
        sx = margin + (wx + 2) / 14.0 * w
        sy = margin + (1.0 - (wy + 1) / 14.0) * h
        return sx, sy

    def paintEvent(self, event):
        p = QPainter(self)
        p.setRenderHint(QPainter.Antialiasing)
        p.fillRect(self.rect(), QColor("#0f0f23"))
        x1, y1 = self._w2s(-2, -1)
        x2, y2 = self._w2s(12, 13)
        p.fillRect(QRectF(x1, y2, x2 - x1, y1 - y2), QColor("#1c1c3a"))
        p.setPen(QPen(QColor("#ffaa00"), 3))
        sx1, sy1 = self._w2s(0, 0)
        sx2, sy2 = self._w2s(0, 12)
        p.drawLine(int(sx1), int(sy1), int(sx2), int(sy2))
        p.setPen(QPen(QColor("#ffaa00"), 2))
        for ay in [2, 4, 6, 8, 10]:
            ax1, ay1 = self._w2s(0, ay)
            ax2, ay2 = self._w2s(5, ay)
            p.drawLine(int(ax1), int(ay1), int(ax2), int(ay2))
        hx, hy = self._w2s(0, 0)
        p.setPen(QPen(QColor("#00ff88"), 2))
        p.setBrush(QBrush(QColor("#004422")))
        p.drawEllipse(QPointF(hx, hy), 12, 12)
        p.setPen(QColor("#00ff88"))
        p.setFont(QFont("Arial", 7))
        p.drawText(QRectF(hx - 15, hy - 8, 30, 16), Qt.AlignCenter, "HOME")
        if len(self.trail) > 1:
            p.setPen(QPen(QColor(0, 212, 170, 80), 2))
            for i in range(1, len(self.trail)):
                t1x, t1y = self._w2s(*self.trail[i - 1])
                t2x, t2y = self._w2s(*self.trail[i])
                p.drawLine(int(t1x), int(t1y), int(t2x), int(t2y))
        rx, ry = self._w2s(self.robot_x, self.robot_y)
        p.setPen(QPen(QColor("#00d4aa"), 2))
        p.setBrush(QBrush(QColor("#006655")))
        p.drawEllipse(QPointF(rx, ry), 10, 10)
        arrow_len = 18
        ax = rx + arrow_len * math.cos(-self.robot_yaw + math.pi / 2)
        ay_s = ry + arrow_len * math.sin(-self.robot_yaw + math.pi / 2)
        p.setPen(QPen(QColor("#00ffcc"), 2))
        p.drawLine(int(rx), int(ry), int(ax), int(ay_s))
        p.end()

class MissionDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Create Mission")
        self.setStyleSheet(DARK_STYLE)
        layout = QFormLayout(self)
        self.shelf_combo = QComboBox()
        for i in range(1, 21):
            self.shelf_combo.addItem("S%02d" % i)
        layout.addRow("Target Shelf:", self.shelf_combo)
        self.sku_combo = QComboBox()
        self.sku_combo.addItems(["SKU-001", "SKU-002", "SKU-003", "SKU-004", "SKU-005"])
        layout.addRow("SKU:", self.sku_combo)
        self.prio_spin = QSpinBox()
        self.prio_spin.setRange(0, 3)
        self.prio_spin.setValue(1)
        layout.addRow("Priority:", self.prio_spin)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self.accept)
        bb.rejected.connect(self.reject)
        layout.addRow(bb)

    def get_values(self):
        return (self.shelf_combo.currentText(), self.sku_combo.currentText(), self.prio_spin.value())

class AtlasConsole(QMainWindow):
    def __init__(self, bridge):
        super().__init__()
        self.bridge = bridge
        self.setWindowTitle("ATLAS Fleet Management Console")
        self.setMinimumSize(1280, 720)
        self.setStyleSheet(DARK_STYLE)
        self._build_ui()
        bridge.state_sig.connect(self._on_state)
        bridge.odom_sig.connect(self._on_odom)
        bridge.log_sig.connect(self._on_log)
        self.mission_count = 0
        self.completed_count = 0

    def _build_ui(self):
        central = QWidget()
        self.setCentralWidget(central)
        main_layout = QHBoxLayout(central)
        main_layout.setSpacing(8)
        left = QVBoxLayout()
        left.setSpacing(6)
        header = QLabel("ATLAS FLEET")
        header.setStyleSheet("font-size: 18px; font-weight: bold; color: #00d4aa;")
        header.setAlignment(Qt.AlignCenter)
        left.addWidget(header)
        status_group = QGroupBox("Robot Status")
        sg = QGridLayout(status_group)
        self.labels = {}
        fields = [("State", "IDLE"), ("Mission", "-"), ("Target", "-"),
                  ("Battery", "100%"), ("Velocity", "0.00 m/s"),
                  ("Position", "(0.00, 0.00)"), ("Heading", "90.0"),
                  ("Last RFID", "-"), ("Nav Status", "READY")]
        for i, (name, default) in enumerate(fields):
            lbl = QLabel(name + ":")
            lbl.setStyleSheet("color: #888;")
            val = QLabel(default)
            val.setStyleSheet("color: #00d4aa; font-weight: bold;")
            sg.addWidget(lbl, i, 0)
            sg.addWidget(val, i, 1)
            self.labels[name] = val
        left.addWidget(status_group)
        bat_group = QGroupBox("Battery")
        bl = QVBoxLayout(bat_group)
        self.bat_bar = QProgressBar()
        self.bat_bar.setValue(100)
        self.bat_bar.setFormat("%v%")
        bl.addWidget(self.bat_bar)
        left.addWidget(bat_group)
        left.addStretch()
        center = QVBoxLayout()
        map_group = QGroupBox("Warehouse Map")
        ml = QVBoxLayout(map_group)
        self.map_widget = WarehouseMap()
        ml.addWidget(self.map_widget)
        center.addWidget(map_group)
        log_group = QGroupBox("Event Log")
        ll = QVBoxLayout(log_group)
        self.log_text = QTextEdit()
        self.log_text.setReadOnly(True)
        self.log_text.setMaximumHeight(150)
        ll.addWidget(self.log_text)
        center.addWidget(log_group)
        right = QVBoxLayout()
        right.setSpacing(6)
        ctrl_group = QGroupBox("Mission Control")
        cl = QVBoxLayout(ctrl_group)
        btn_mission = QPushButton("Create Mission")
        btn_mission.clicked.connect(self._create_mission)
        cl.addWidget(btn_mission)
        btn_estop = QPushButton("EMERGENCY STOP")
        btn_estop.setStyleSheet("background-color: #cc2222; border-color: #ff4444; font-weight: bold;")
        btn_estop.clicked.connect(self.bridge.send_estop)
        cl.addWidget(btn_estop)
        btn_reset = QPushButton("Reset E-Stop")
        btn_reset.clicked.connect(self.bridge.send_reset)
        cl.addWidget(btn_reset)
        btn_dock_reset = QPushButton('RESET AGV')
        btn_dock_reset.setStyleSheet('background-color: #884400; border-color: #ff8800; font-weight: bold;')
        btn_dock_reset.clicked.connect(self._reset_agv)
        cl.addWidget(btn_dock_reset)

        right.addWidget(ctrl_group)
        queue_group = QGroupBox("Mission Queue")
        ql = QVBoxLayout(queue_group)
        self.queue_table = QTableWidget(0, 3)
        self.queue_table.setHorizontalHeaderLabels(["ID", "Shelf", "Status"])
        self.queue_table.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)
        self.queue_table.setMaximumHeight(200)
        ql.addWidget(self.queue_table)
        right.addWidget(queue_group)
        right.addStretch()
        main_layout.addLayout(left, 1)
        main_layout.addLayout(center, 3)
        main_layout.addLayout(right, 1)

    def _create_mission(self):
        dlg = MissionDialog(self)
        if dlg.exec_() == QDialog.Accepted:
            shelf, sku, prio = dlg.get_values()
            mid = self.bridge.send_mission(shelf, sku, prio)
            self.mission_count += 1
            row = self.queue_table.rowCount()
            self.queue_table.insertRow(row)
            self.queue_table.setItem(row, 0, QTableWidgetItem(mid))
            self.queue_table.setItem(row, 1, QTableWidgetItem(shelf))
            self.queue_table.setItem(row, 2, QTableWidgetItem("QUEUED"))
            self._on_log("[GUI] Sent mission " + mid + " -> " + shelf)
    def _reset_agv(self):
        from PyQt5.QtWidgets import QMessageBox

        reply = QMessageBox.question(
        self,
        "Reset AGV",
        "Reset AGV and return to Home Dock?\n\nThis will cancel all active missions.",
        QMessageBox.Yes | QMessageBox.No,
        QMessageBox.No
    )

        if reply == QMessageBox.Yes:
         self.bridge.send_reset_to_dock()

    def _on_state(self, msg):
        self.labels["State"].setText(msg.state)
        self.labels["Mission"].setText(msg.mission_id if msg.mission_id else "-")
        self.labels["Target"].setText(msg.target_shelf if msg.target_shelf else "-")
        self.labels["Battery"].setText(str(int(msg.battery_percent)) + "%")
        self.labels["Last RFID"].setText(msg.last_tag if msg.last_tag else "-")
        self.bat_bar.setValue(int(msg.battery_percent))
        if msg.state == "IDLE":
            self.labels["Nav Status"].setText("READY")
            self.labels["Nav Status"].setStyleSheet("color: #00ff88; font-weight: bold;")
        elif msg.state == "ERROR":
            self.labels["Nav Status"].setText("E-STOP")
            self.labels["Nav Status"].setStyleSheet("color: #ff4444; font-weight: bold;")
        else:
            self.labels["Nav Status"].setText("ACTIVE")
            self.labels["Nav Status"].setStyleSheet("color: #ffaa00; font-weight: bold;")

    def _on_odom(self, x, y, yaw, vx, wz):
        self.labels["Position"].setText("(%.2f, %.2f)" % (x, y))
        self.labels["Heading"].setText("%.1f" % math.degrees(yaw))
        self.labels["Velocity"].setText("%.2f m/s" % vx)
        self.map_widget.update_robot(x, y, yaw)

    def _on_log(self, text):
        ts = datetime.now().strftime("%H:%M:%S")
        self.log_text.append("[" + ts + "] " + text)
        if "complete" in text.lower():
            self.completed_count += 1

    def closeEvent(self, event):
        self.bridge.shutdown()
        event.accept()

def main():
    app = QApplication(sys.argv)
    bridge = RosBridge()
    window = AtlasConsole(bridge)
    window.show()
    sys.exit(app.exec_())

if __name__ == "__main__":
    main()
```

---
## FILE: src/atlas_mission_manager/atlas_mission_manager/atlas_control_center.py
```
404: Not Found```

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
  <description>ATLAS mission FSM and velocity arbiter</description>
  <maintainer email="atlas@dev.local">atlas</maintainer>
  <license>MIT</license>
  <buildtool_depend>ament_python</buildtool_depend>
  <depend>rclpy</depend>
  <depend>std_msgs</depend>
  <depend>geometry_msgs</depend>
  <depend>nav_msgs</depend>
  <depend>atlas_interfaces</depend>
  <export><build_type>ament_python</build_type></export>
</package>
```

---
## FILE: src/atlas_mission_manager/setup.py
```
from setuptools import setup
setup(
    name='atlas_mission_manager',
    version='1.0.0',
    packages=['atlas_mission_manager'],
    data_files=[
        ('share/ament_index/resource_index/packages', ['resource/atlas_mission_manager']),
        ('share/atlas_mission_manager', ['package.xml']),
    ],
    install_requires=['setuptools'],
        entry_points={'console_scripts': [
        'mission_node = atlas_mission_manager.mission_node:main',
        'send_mission = atlas_mission_manager.send_mission:main', 'atlas_gui = atlas_mission_manager.atlas_control_center:main', 'atlas_gui = atlas_mission_manager.atlas_control_center:main',
        'atlas_gui = atlas_mission_manager.atlas_gui:main',
    ]},

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
