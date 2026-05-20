#!/bin/bash
###############################################################################
# ATLAS GUI Installer — Replaces broken GUI with working PyQt5 Control Center
# Run from any directory. All paths are absolute.
# NO git commands. NO GitHub. Purely local workspace operations.
###############################################################################
set -e

echo "=============================================="
echo " ATLAS Control Center GUI Installer"
echo "=============================================="
echo ""

# ─── Configuration ───────────────────────────────────────
WS="$HOME/atlas_ws"
PKG_DIR="$WS/src/atlas_mission_manager"
PY_DIR="$PKG_DIR/atlas_mission_manager"
GUI_SOURCE="/projects/sandbox/Atlas/atlas_control_center.py"

# Verify workspace exists
if [ ! -d "$WS/src" ]; then
    echo "ERROR: Workspace not found at $WS"
    echo "Trying extracted zip location..."
    WS="/projects/sandbox/Atlas/extracted/atlas_ws"
    PKG_DIR="$WS/src/atlas_mission_manager"
    PY_DIR="$PKG_DIR/atlas_mission_manager"
    if [ ! -d "$WS/src" ]; then
        echo "ERROR: No workspace found. Exiting."
        exit 1
    fi
fi

echo "[1/7] Workspace found: $WS"

# ─── Step 1: Backup old GUI files ────────────────────────
echo "[2/7] Backing up old GUI files..."
BACKUP_DIR="$PKG_DIR/gui_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"


for f in atlas_gui.py atlas_control_center.py; do
    if [ -f "$PY_DIR/$f" ]; then
        cp "$PY_DIR/$f" "$BACKUP_DIR/"
        rm -f "$PY_DIR/$f"
        echo "  Backed up and removed: $f"
    fi
done
echo "  Backup location: $BACKUP_DIR"

# ─── Step 2: Install new GUI file ────────────────────────
echo "[3/7] Installing new GUI..."
cp "$GUI_SOURCE" "$PY_DIR/atlas_control_center.py"
chmod 644 "$PY_DIR/atlas_control_center.py"
echo "  Installed: $PY_DIR/atlas_control_center.py"

# ─── Step 3: Update setup.py ─────────────────────────────
echo "[4/7] Updating setup.py entry points..."
SETUP_FILE="$PKG_DIR/setup.py"

cat > "$SETUP_FILE" << 'SETUP_EOF'
from setuptools import setup

setup(
    name='atlas_mission_manager',
    version='1.0.0',
    packages=['atlas_mission_manager'],
    data_files=[
        ('share/ament_index/resource_index/packages',
         ['resource/atlas_mission_manager']),
        ('share/atlas_mission_manager', ['package.xml']),
    ],
    install_requires=['setuptools'],
    entry_points={'console_scripts': [
        'mission_node = atlas_mission_manager.mission_node:main',
        'send_mission = atlas_mission_manager.send_mission:main',
        'atlas_gui = atlas_mission_manager.atlas_control_center:main',
    ]},
)
SETUP_EOF
echo "  Updated: $SETUP_FILE"

# ─── Step 4: Update package.xml (add PyQt5 dep) ──────────
echo "[5/7] Updating package.xml..."
PKGXML="$PKG_DIR/package.xml"
# Only add if not already present
if ! grep -q "python3-pyqt5" "$PKGXML" 2>/dev/null; then
cat > "$PKGXML" << 'PKGXML_EOF'
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
  <depend>gazebo_msgs</depend>
  <exec_depend>python3-pyqt5</exec_depend>
  <export><build_type>ament_python</build_type></export>
</package>
PKGXML_EOF
echo "  Updated: $PKGXML"
else
    echo "  package.xml already has PyQt5 dependency"
fi


# ─── Step 5: Update launch file to include GUI ────────────
echo "[6/7] Updating launch file..."
LAUNCH_DIR="$WS/src/atlas_bringup/launch"
LAUNCH_FILE="$LAUNCH_DIR/atlas_full.launch.py"

cat > "$LAUNCH_FILE" << 'LAUNCH_EOF'
"""ATLAS_FLEET full system launch — ONE command starts everything."""
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

    # Pre-process xacro to temp file for spawn_entity -file
    urdf_tmp = '/tmp/atlas_agv.urdf'
    subprocess.run(['xacro', xacro_file, '-o', urdf_tmp], check=True)

    # t=0: Gazebo
    gazebo = ExecuteProcess(
        cmd=['gazebo', '--verbose', world,
             '-s', 'libgazebo_ros_init.so',
             '-s', 'libgazebo_ros_factory.so'],
        output='screen',
    )

    # t=4: Spawn robot
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

    # t=6: Robot State Publisher
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

    # t=10: Navigation + Mission nodes
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

    # t=12: RViz
    rviz = Node(
        package='rviz2', executable='rviz2', name='atlas_rviz',
        output='log', parameters=[{'use_sim_time': True}],
    )
    rviz_t = TimerAction(period=12.0, actions=[rviz])

    # t=14: GUI (crash-safe — won't kill robot)
    gui = Node(
        package='atlas_mission_manager',
        executable='atlas_gui',
        name='atlas_control_center',
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
LAUNCH_EOF
echo "  Updated: $LAUNCH_FILE"


# ─── Step 6: Validate and rebuild ────────────────────────
echo "[7/7] Validating and rebuilding..."

# Syntax check
python3 -c "
import ast
with open('$PY_DIR/atlas_control_center.py') as f:
    ast.parse(f.read())
print('  Syntax validation: PASSED')
"

# Import check (non-ROS imports only — PyQt5 needs display so we check differently)
python3 -c "
import sys, math, uuid, threading
from datetime import datetime
print('  Standard lib imports: PASSED')
" || true

python3 -c "
import importlib.util
deps = ['PyQt5', 'PyQt5.QtCore', 'PyQt5.QtWidgets']
missing = [d for d in deps if importlib.util.find_spec(d) is None]
if missing:
    print(f'  WARNING: Missing PyQt5 modules: {missing}')
    print('  Install with: sudo apt install python3-pyqt5')
else:
    print('  PyQt5 module check: PASSED')
" || true

# Rebuild workspace
echo "  Building workspace..."
cd "$WS"
source /opt/ros/humble/setup.bash 2>/dev/null || true
colcon build --symlink-install --packages-select atlas_mission_manager 2>&1 | tail -5

echo ""
echo "=============================================="
echo " INSTALLATION COMPLETE"
echo "=============================================="
echo ""
echo " New GUI: atlas_control_center.py"
echo " Entry point: atlas_gui"
echo " Package: atlas_mission_manager"
echo ""
echo " To launch the full system:"
echo "   cd ~/atlas_ws"
echo "   source install/setup.bash"
echo "   ros2 launch atlas_bringup atlas_full.launch.py"
echo ""
echo " To run GUI standalone:"
echo "   ros2 run atlas_mission_manager atlas_gui"
echo ""
echo " GUI Features:"
echo "   - Mission dispatch (shelf/SKU/priority)"
echo "   - Pause/Resume/Cancel mission"
echo "   - Emergency Stop / Reset E-Stop"
echo "   - RESET AGV (full respawn at home dock)"
echo "   - Live robot status panel"
echo "   - Mission queue table"
echo "   - Scrollable event log"
echo "   - Dark industrial theme"
echo "=============================================="
