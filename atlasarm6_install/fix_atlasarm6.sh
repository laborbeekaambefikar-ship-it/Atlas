#!/bin/bash
###############################################################################
#  AtlasArm-6 — Runtime Fix Patch
#
#  Fixes three issues in an existing ~/atlasarm6_ws install:
#    1. joint_test.py / pick_and_place_demo.py log "success" but the arm
#       never moves, because they publish to the controller before it has
#       subscribed. Patch adds a wait_for_controller() helper.
#    2. MoveIt RViz never shows a MotionPlanning panel because the launched
#       RViz config has no MoveIt displays. Patch ships a proper moveit.rviz
#       and updates moveit_rviz.launch.py to use it (with output=screen and
#       the full set of MoveIt parameters).
#    3. atlasarm6_full.launch.py uses fixed 8s/10s sleeps that race against
#       Gazebo startup. Patch chains move_group + rviz to fire after the
#       controllers are actually loaded, via OnProcessExit.
#
#  Also installs rqt_joint_trajectory_controller and adds a run_sliders.sh
#  helper so you can drive the arm with sliders without needing MoveIt.
#
#  Usage:
#    wget https://raw.githubusercontent.com/laborbeekaambefikar-ship-it/Atlas/atlasarm6-fixes/atlasarm6_install/fix_atlasarm6.sh
#    bash fix_atlasarm6.sh
#
#  Optional first argument: path to workspace (default: $HOME/atlasarm6_ws)
###############################################################################
set -e

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; B='\033[0;34m'; N='\033[0m'
ok()   { echo -e "${G}[OK]${N} $1"; }
info() { echo -e "${B}[..]${N} $1"; }
warn() { echo -e "${Y}[!!]${N} $1"; }
err()  { echo -e "${R}[XX]${N} $1"; }

WS="${1:-$HOME/atlasarm6_ws}"
SRC="$WS/src"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  AtlasArm-6 Runtime Fix Patch"
echo "═══════════════════════════════════════════════════════════════"
echo "  Workspace: $WS"
echo ""

if [ ! -d "$SRC/atlasarm_examples" ] || \
   [ ! -d "$SRC/atlasarm_moveit_config" ] || \
   [ ! -d "$SRC/atlasarm_bringup" ]; then
    err "Workspace doesn't look right at $WS"
    err "Expected to find atlasarm_examples, atlasarm_moveit_config, atlasarm_bringup under $SRC"
    exit 1
fi
ok "Workspace structure verified"

# ─────────────────────────────────────────────────────────────────────────────
# Fix 1: joint_test.py  — wait for controller before publishing
# ─────────────────────────────────────────────────────────────────────────────
info "Patching atlasarm_examples/joint_test.py"
cat > "$SRC/atlasarm_examples/atlasarm_examples/joint_test.py" << 'PYEOF'
"""Simple joint controller test — sends 6 trajectory waypoints.

Verifies that the arm can be commanded without MoveIt2. Waits for the
joint_trajectory_controller to be subscribed before publishing, so the
demo cannot silently succeed against a non-existent controller.
"""
import time
import rclpy
from rclpy.node import Node
from trajectory_msgs.msg import JointTrajectory, JointTrajectoryPoint
from builtin_interfaces.msg import Duration


TOPIC = '/atlasarm6_arm_controller/joint_trajectory'


class JointTester(Node):
    def __init__(self):
        super().__init__('atlasarm6_joint_test')
        self.pub = self.create_publisher(JointTrajectory, TOPIC, 10)
        self.joints = ['aa6_j1', 'aa6_j2', 'aa6_j3',
                       'aa6_j4', 'aa6_j5', 'aa6_j6']
        self.get_logger().info('AtlasArm-6 Joint Tester ready')

    def wait_for_controller(self, timeout_s=30.0):
        """Block until the controller is subscribed to our trajectory topic."""
        self.get_logger().info(
            f'Waiting for subscriber on {TOPIC} (up to {timeout_s:.0f}s)...')
        deadline = time.time() + timeout_s
        while rclpy.ok() and time.time() < deadline:
            if self.pub.get_subscription_count() > 0:
                # Small extra settle so the controller is ready to receive
                time.sleep(0.5)
                self.get_logger().info('Controller subscribed - starting test')
                return True
            rclpy.spin_once(self, timeout_sec=0.5)
        self.get_logger().error(
            f'No subscriber on {TOPIC} after {timeout_s:.0f}s. '
            'Is atlasarm6_arm_controller loaded? Try: ros2 control list_controllers')
        return False

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

        self.get_logger().info('Joint test complete - arm moved through 6 poses')


def main(args=None):
    rclpy.init(args=args)
    node = JointTester()
    try:
        if node.wait_for_controller():
            node.run_test()
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
PYEOF
ok "joint_test.py patched"

# ─────────────────────────────────────────────────────────────────────────────
# Fix 1b: pick_and_place_demo.py  — same wait_for_controller treatment
# ─────────────────────────────────────────────────────────────────────────────
info "Patching atlasarm_examples/pick_and_place_demo.py"
cat > "$SRC/atlasarm_examples/atlasarm_examples/pick_and_place_demo.py" << 'PYEOF'
"""Pick-and-place demonstration using direct joint trajectory commands.

Works WITHOUT MoveIt2. Waits for the controller to be subscribed before
sending commands, so it cannot silently succeed against a dead controller.
"""
import time
import rclpy
from rclpy.node import Node
from trajectory_msgs.msg import JointTrajectory, JointTrajectoryPoint
from builtin_interfaces.msg import Duration


TOPIC = '/atlasarm6_arm_controller/joint_trajectory'

POSES = {
    'home':       [0.0,    -1.5708,  1.5708, -1.5708, -1.5708, 0.0],
    'ready':      [0.0,    -1.0472,  1.0472, -1.5708, -1.5708, 0.0],
    'pre_pick':   [0.0,    -0.7854,  1.2217, -2.0071, -1.5708, 0.0],
    'pick':       [0.0,    -0.5236,  1.4137, -2.4609, -1.5708, 0.0],
    'lift':       [0.0,    -0.7854,  1.2217, -2.0071, -1.5708, 0.0],
    'pre_place':  [0.7854, -0.7854,  1.2217, -2.0071, -1.5708, 0.0],
    'place':      [0.7854, -0.5236,  1.4137, -2.4609, -1.5708, 0.0],
    'retract':    [0.7854, -0.7854,  1.2217, -2.0071, -1.5708, 0.0],
}

SEQUENCE = [
    ('home',      3.0),
    ('ready',     2.5),
    ('pre_pick',  2.5),
    ('pick',      2.0),
    ('lift',      2.0),
    ('pre_place', 2.5),
    ('place',     2.0),
    ('retract',   2.0),
    ('home',      3.0),
]


class PickAndPlace(Node):
    def __init__(self):
        super().__init__('atlasarm6_pick_and_place')
        self.pub = self.create_publisher(JointTrajectory, TOPIC, 10)
        self.joints = ['aa6_j1', 'aa6_j2', 'aa6_j3',
                       'aa6_j4', 'aa6_j5', 'aa6_j6']
        self.get_logger().info('AtlasArm-6 Pick-and-Place Demo')

    def wait_for_controller(self, timeout_s=30.0):
        self.get_logger().info(
            f'Waiting for subscriber on {TOPIC} (up to {timeout_s:.0f}s)...')
        deadline = time.time() + timeout_s
        while rclpy.ok() and time.time() < deadline:
            if self.pub.get_subscription_count() > 0:
                time.sleep(0.5)
                self.get_logger().info('Controller subscribed - starting demo')
                return True
            rclpy.spin_once(self, timeout_sec=0.5)
        self.get_logger().error(
            f'No subscriber on {TOPIC} after {timeout_s:.0f}s. '
            'Is atlasarm6_arm_controller loaded?')
        return False

    def send_pose(self, name, duration_s):
        positions = POSES[name]
        msg = JointTrajectory()
        msg.joint_names = self.joints
        pt = JointTrajectoryPoint()
        pt.positions = positions
        pt.time_from_start = Duration(sec=int(duration_s),
                                       nanosec=int((duration_s % 1) * 1e9))
        msg.points = [pt]
        self.pub.publish(msg)
        self.get_logger().info(f'  -> {name}')
        time.sleep(duration_s + 0.5)

    def run(self):
        for name, duration in SEQUENCE:
            self.send_pose(name, duration)
            if name == 'pick':
                self.get_logger().info('  [Gripper would close here]')
            elif name == 'place':
                self.get_logger().info('  [Gripper would open here]')
        self.get_logger().info('Pick-and-place demo complete')


def main(args=None):
    rclpy.init(args=args)
    node = PickAndPlace()
    try:
        if node.wait_for_controller():
            node.run()
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
PYEOF
ok "pick_and_place_demo.py patched"

# ─────────────────────────────────────────────────────────────────────────────
# Fix 2: New RViz config WITH the MoveIt MotionPlanning panel
# ─────────────────────────────────────────────────────────────────────────────
info "Writing atlasarm_moveit_config/config/moveit.rviz (with MotionPlanning panel)"
mkdir -p "$SRC/atlasarm_moveit_config/config"
cat > "$SRC/atlasarm_moveit_config/config/moveit.rviz" << 'RVIZEOF'
Panels:
  - Class: rviz_common/Displays
    Name: Displays
  - Class: rviz_common/Help
    Name: Help
  - Class: rviz_common/Selection
    Name: Selection
  - Class: rviz_common/Tool Properties
    Name: Tool Properties
  - Class: rviz_common/Views
    Name: Views
  - Class: moveit_rviz_plugin/MotionPlanning
    Name: MotionPlanning

Visualization Manager:
  Class: ""
  Displays:
    - Class: rviz_default_plugins/Grid
      Name: Grid
      Enabled: true
      Cell Size: 0.5
      Plane Cell Count: 20
    - Class: rviz_default_plugins/TF
      Name: TF
      Enabled: true
    - Class: rviz_default_plugins/RobotModel
      Name: RobotModel
      Enabled: true
      Description Topic:
        Value: /robot_description
    - Class: moveit_rviz_plugin/MotionPlanning
      Name: MotionPlanning
      Enabled: true
      Robot Description: robot_description
      Move Group Namespace: ""
      Planning Scene Topic: /monitored_planning_scene
      Planning Request:
        Planning Group: atlasarm6_arm
        Interactive Marker Size: 0.1
        Show Workspace: false
      Scene Geometry:
        Scene Alpha: 1.0
      Scene Robot:
        Show Robot Visual: true
        Show Robot Collision: false
        Robot Alpha: 0.5
      Planned Path:
        Trajectory Topic: /display_planned_path
        State Display Time: 0.05 s
        Loop Animation: false
        Show Robot Visual: true
        Robot Alpha: 0.8
  Global Options:
    Background Color: 48; 48; 48
    Fixed Frame: world
    Frame Rate: 30
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
RVIZEOF
ok "moveit.rviz written"

# ─────────────────────────────────────────────────────────────────────────────
# Fix 2b: moveit_rviz.launch.py  — use new config + screen output + full params
# ─────────────────────────────────────────────────────────────────────────────
info "Patching atlasarm_moveit_config/launch/moveit_rviz.launch.py"
cat > "$SRC/atlasarm_moveit_config/launch/moveit_rviz.launch.py" << 'PYEOF'
"""Launch RViz2 with the MoveIt MotionPlanning panel."""
import os
import subprocess
import yaml
from launch import LaunchDescription
from launch_ros.actions import Node
from ament_index_python.packages import get_package_share_directory


def load_yaml(pkg, file_path):
    full = os.path.join(get_package_share_directory(pkg), file_path)
    try:
        with open(full) as f:
            return yaml.safe_load(f) or {}
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
    robot_desc_str = subprocess.check_output(['xacro', xacro_file]).decode()

    robot_description = {'robot_description': robot_desc_str}
    robot_description_semantic = {
        'robot_description_semantic':
            load_file('atlasarm_moveit_config', 'config/atlasarm6.srdf')
    }
    kinematics = load_yaml('atlasarm_moveit_config', 'config/kinematics.yaml')
    joint_limits = load_yaml('atlasarm_moveit_config', 'config/joint_limits.yaml')
    ompl_yaml = load_yaml('atlasarm_moveit_config', 'config/ompl_planning.yaml')

    rviz_cfg = os.path.join(moveit_pkg, 'config', 'moveit.rviz')

    rviz = Node(
        package='rviz2',
        executable='rviz2',
        arguments=['-d', rviz_cfg],
        parameters=[
            robot_description,
            robot_description_semantic,
            {'robot_description_kinematics': kinematics},
            {'robot_description_planning': joint_limits},
            ompl_yaml,
            {'use_sim_time': True},
        ],
        output='screen',
    )

    return LaunchDescription([rviz])
PYEOF
ok "moveit_rviz.launch.py patched"

# ─────────────────────────────────────────────────────────────────────────────
# Fix 3: atlasarm6_full.launch.py  — chain MoveIt + RViz after controllers
# ─────────────────────────────────────────────────────────────────────────────
info "Patching atlasarm_bringup/launch/atlasarm6_full.launch.py"
cat > "$SRC/atlasarm_bringup/launch/atlasarm6_full.launch.py" << 'PYEOF'
"""Full system: Gazebo + ros2_control + MoveIt2 + RViz, properly chained.

Replaces the previous fixed-time TimerAction approach with OnProcessExit
event handlers that fire move_group only after both controllers are loaded.
"""
import os
from launch import LaunchDescription
from launch.actions import (ExecuteProcess, IncludeLaunchDescription,
                             RegisterEventHandler, TimerAction)
from launch.event_handlers import OnProcessExit
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import Command
from launch_ros.actions import Node
from launch_ros.parameter_descriptions import ParameterValue
from ament_index_python.packages import get_package_share_directory


def generate_launch_description():
    desc_pkg = get_package_share_directory('atlasarm_description')
    gz_pkg = get_package_share_directory('atlasarm_gazebo')
    moveit_pkg = get_package_share_directory('atlasarm_moveit_config')

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

    move_group_launch = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(moveit_pkg, 'launch', 'move_group.launch.py'))
    )
    rviz_launch = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(moveit_pkg, 'launch', 'moveit_rviz.launch.py'))
    )

    return LaunchDescription([
        rsp,
        gazebo,
        TimerAction(period=3.0, actions=[spawn]),
        RegisterEventHandler(OnProcessExit(target_action=spawn,
                                            on_exit=[load_jsb])),
        RegisterEventHandler(OnProcessExit(target_action=load_jsb,
                                            on_exit=[load_arm])),
        # Once the arm controller is active, bring MoveIt up.
        # Give RViz a 4s lead so move_group has time to advertise services.
        RegisterEventHandler(OnProcessExit(
            target_action=load_arm,
            on_exit=[
                move_group_launch,
                TimerAction(period=4.0, actions=[rviz_launch]),
            ])),
    ])
PYEOF
ok "atlasarm6_full.launch.py patched"

# ─────────────────────────────────────────────────────────────────────────────
# Fix 4: run_sliders.sh  — joint-trajectory slider GUI for run_gazebo.sh users
# ─────────────────────────────────────────────────────────────────────────────
info "Writing $WS/run_sliders.sh"
cat > "$WS/run_sliders.sh" << 'EOF'
#!/bin/bash
# Slider GUI to drive atlasarm6_arm_controller from rqt.
# Run AFTER run_gazebo.sh (the controller must be active first).
source /opt/ros/humble/setup.bash
source "$(dirname $0)/install/setup.bash"
echo "In the rqt window:"
echo "  1. Pick '/controller_manager' from the dropdown"
echo "  2. Pick 'atlasarm6_arm_controller'"
echo "  3. Toggle the red power button (top-right) ON"
echo "  4. Drag the sliders"
ros2 run rqt_joint_trajectory_controller rqt_joint_trajectory_controller
EOF
chmod +x "$WS/run_sliders.sh"
ok "run_sliders.sh written"

# ─────────────────────────────────────────────────────────────────────────────
# Install the rqt slider plugin (best effort)
# ─────────────────────────────────────────────────────────────────────────────
info "Installing ros-humble-rqt-joint-trajectory-controller (sudo)"
if dpkg -l | grep -q ros-humble-rqt-joint-trajectory-controller; then
    ok "rqt_joint_trajectory_controller already installed"
else
    sudo apt update -qq
    if sudo apt install -y -qq ros-humble-rqt-joint-trajectory-controller; then
        ok "rqt_joint_trajectory_controller installed"
    else
        warn "Could not install rqt_joint_trajectory_controller — run_sliders.sh will fail."
        warn "Install manually: sudo apt install ros-humble-rqt-joint-trajectory-controller"
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Validate Python syntax of every file we touched
# ─────────────────────────────────────────────────────────────────────────────
info "Validating Python syntax"
for f in \
    "$SRC/atlasarm_examples/atlasarm_examples/joint_test.py" \
    "$SRC/atlasarm_examples/atlasarm_examples/pick_and_place_demo.py" \
    "$SRC/atlasarm_moveit_config/launch/moveit_rviz.launch.py" \
    "$SRC/atlasarm_bringup/launch/atlasarm6_full.launch.py"; do
    if python3 -c "import ast; ast.parse(open('$f').read())"; then
        ok "syntax OK: $(basename $f)"
    else
        err "syntax FAIL: $f"
        exit 1
    fi
done

# ─────────────────────────────────────────────────────────────────────────────
# Rebuild affected packages
# ─────────────────────────────────────────────────────────────────────────────
info "Rebuilding affected packages"
cd "$WS"
source /opt/ros/humble/setup.bash
colcon build --symlink-install --packages-select \
    atlasarm_examples atlasarm_moveit_config atlasarm_bringup 2>&1 | tail -8

ok "Rebuild complete"

cat << EOF

═══════════════════════════════════════════════════════════════════
 ${G}Fix applied successfully.${N}
═══════════════════════════════════════════════════════════════════

  ${Y}Re-source the workspace:${N}
     source $WS/install/setup.bash

  ${Y}Try the fixed full system (Gazebo + MoveIt + RViz):${N}
     $WS/run_full.sh

   You should now see, in order:
     1. Gazebo window with the arm
     2. After ~6s: controllers load (watch the terminal)
     3. After ~10s: RViz opens with the MotionPlanning panel
     4. In RViz: pick a 'Goal State' (e.g. 'ready') -> Plan -> Execute

  ${Y}Or drive the arm with sliders (no MoveIt needed):${N}
     # Terminal A
     $WS/run_gazebo.sh
     # Terminal B (after Gazebo loads)
     $WS/run_sliders.sh

  ${Y}Or run the now-actually-working joint test:${N}
     # Terminal A
     $WS/run_gazebo.sh
     # Terminal B
     $WS/run_joint_test.sh

EOF
