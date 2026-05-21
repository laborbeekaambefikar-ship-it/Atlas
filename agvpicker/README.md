# AGVPicker — 6-DOF Robotic Arm (ROS2 Humble)

Fully automated, reproducible ROS2 project for a 6-DOF robotic manipulator with Gazebo simulation, ros2_control, and MoveIt2 motion planning.

---

## Quickstart (3 Commands)

```bash
# 1. Clone and enter
git clone https://github.com/laborbeekaambefikar-ship-it/Atlas.git && cd Atlas/agvpicker

# 2. Install everything (ROS2 + deps + build workspace)
chmod +x setup_agvpicker.sh && ./setup_agvpicker.sh

# 3. Launch the full system
source ~/.bashrc && ./run_agvpicker.sh
```

---

## What Gets Installed

| Component | Version |
|-----------|---------|
| Ubuntu | 22.04 LTS |
| ROS2 | Humble Hawksbill |
| Gazebo | Classic 11 |
| MoveIt2 | Humble release |
| ros2_control | Humble release |

---

## Package Structure

```
agvpicker/
├── setup_agvpicker.sh          # ONE script installs everything
├── run_agvpicker.sh            # ONE script runs the full system
├── README.md
└── src/
    ├── agvpicker_description/  # URDF/Xacro, RViz config
    │   ├── urdf/agvpicker.urdf.xacro
    │   ├── launch/display.launch.py
    │   └── rviz/display.rviz
    ├── agvpicker_control/      # ros2_control configuration
    │   ├── config/ros2_controllers.yaml
    │   └── launch/controllers.launch.py
    ├── agvpicker_gazebo/       # Gazebo world + spawn
    │   ├── worlds/arm_table.world
    │   └── launch/gazebo.launch.py
    ├── agvpicker_moveit_config/ # MoveIt2 planning
    │   ├── srdf/agvpicker.srdf
    │   ├── config/kinematics.yaml
    │   ├── config/ompl_planning.yaml
    │   ├── config/moveit_controllers.yaml
    │   ├── config/joint_limits.yaml
    │   └── launch/moveit.launch.py
    └── agvpicker_bringup/      # Master launch
        └── launch/agvpicker_full.launch.py
```

---

## Robot Specifications

| Parameter | Value |
|-----------|-------|
| DOF | 6 (revolute joints) |
| Joint 1 | Base rotation (yaw) ±180° |
| Joint 2 | Shoulder (pitch) ±90° |
| Joint 3 | Elbow (pitch) ±135° |
| Joint 4 | Wrist pitch ±120° |
| Joint 5 | Wrist roll ±180° |
| Joint 6 | End-effector ±90° |
| Reach | ~0.76m (base to TCP) |
| Total mass | ~6.5 kg |
| Control | Position-based JointTrajectoryController |

---

## Individual Launch Commands

```bash
# View URDF in RViz (no Gazebo, with joint sliders)
ros2 launch agvpicker_description display.launch.py

# Gazebo only (with controllers)
ros2 launch agvpicker_gazebo gazebo.launch.py

# MoveIt2 planning (after Gazebo is running)
ros2 launch agvpicker_moveit_config moveit.launch.py

# Full system (Gazebo + Controllers + MoveIt2 + RViz)
ros2 launch agvpicker_bringup agvpicker_full.launch.py
```

---

## Send a Joint Command (test)

```bash
# Move to ready position
ros2 action send_goal /arm_controller/follow_joint_trajectory \
  control_msgs/action/FollowJointTrajectory \
  "{trajectory: {joint_names: [joint1, joint2, joint3, joint4, joint5, joint6], \
  points: [{positions: [0.0, -0.5, 1.0, -0.5, 0.0, 0.0], time_from_start: {sec: 3}}]}}"
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `gazebo: command not found` | `source /opt/ros/humble/setup.bash` |
| Controller not loading | Wait 10s after Gazebo starts, controllers auto-spawn |
| MoveIt planning fails | Ensure `arm_controller` is active: `ros2 control list_controllers` |
| No RViz display | Check `robot_description` topic: `ros2 topic echo /robot_description` |

---

## License

MIT
