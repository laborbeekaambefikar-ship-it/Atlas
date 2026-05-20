# AtlasArm-6 — Auto Installer

A complete one-command installation system for the AtlasArm-6 6-DOF robotic arm.

## What This Installs

- ROS2 Humble (full desktop)
- MoveIt2 (motion planning)
- Gazebo Classic 11 (simulation)
- ros2_control + controllers
- Complete AtlasArm-6 workspace at `~/atlasarm6_ws/`
- 7 ROS2 packages with all source code generated automatically
- Helper scripts for one-command launch

## Requirements

- **Ubuntu 22.04 LTS (Jammy)** — required
- Internet connection
- ~5GB disk space
- sudo access
- 15-30 minutes installation time

## One-Command Installation

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/laborbeekaambefikar-ship-it/Atlas/atlasarm6/atlasarm6_install/install.sh)
```

Or download first:

```bash
wget https://raw.githubusercontent.com/laborbeekaambefikar-ship-it/Atlas/atlasarm6/atlasarm6_install/install.sh
chmod +x install.sh
./install.sh
```

## After Installation — Quick Start

The installer creates several helper scripts at `~/atlasarm6_ws/`:

| Script | Purpose |
|--------|---------|
| `run_display.sh` | View robot in RViz with joint sliders |
| `run_gazebo.sh` | Launch arm in Gazebo (controllers only) |
| `run_full.sh` | Full system: Gazebo + MoveIt2 + RViz |
| `run_joint_test.sh` | Test all 6 joints with sinusoidal motion |
| `run_demo.sh` | Pick-and-place demonstration |
| `rebuild.sh` | Clean rebuild of workspace |

### Recommended First Run

```bash
# Terminal 1 — Launch the simulation
~/atlasarm6_ws/run_gazebo.sh

# Wait for Gazebo to fully load (about 8 seconds)

# Terminal 2 — Run joint test to verify everything works
~/atlasarm6_ws/run_joint_test.sh
```

If you see the arm moving in Gazebo, the system is working.

### Pick-and-Place Demo

```bash
# Terminal 1
~/atlasarm6_ws/run_gazebo.sh

# Terminal 2 (after Gazebo loads)
~/atlasarm6_ws/run_demo.sh
```

### Full System with MoveIt2 (advanced)

```bash
~/atlasarm6_ws/run_full.sh
```

This launches Gazebo, ros2_control, MoveIt2 move_group, and RViz with the MoveIt motion planning panel. You can drag the interactive marker to plan and execute Cartesian motions.

## Manual Commands

If you prefer ROS2 commands:

```bash
# View only (no simulation)
ros2 launch atlasarm_description display.launch.py

# Gazebo simulation
ros2 launch atlasarm_bringup atlasarm6_gazebo.launch.py

# Full system
ros2 launch atlasarm_bringup atlasarm6_full.launch.py

# Run demos
ros2 run atlasarm_examples joint_test
ros2 run atlasarm_examples pick_and_place_demo

# Send a task
ros2 run atlasarm_examples send_task --pick 0.4 0.0 0.45 --place 0.4 0.3 0.45
```

## Workspace Structure

```
~/atlasarm6_ws/
├── src/
│   ├── atlasarm_interfaces/      # Custom messages
│   ├── atlasarm_description/     # URDF/Xacro robot model
│   ├── atlasarm_control/         # ros2_control config
│   ├── atlasarm_moveit_config/   # MoveIt2 configuration
│   ├── atlasarm_gazebo/          # Gazebo world
│   ├── atlasarm_bringup/         # Launch files
│   └── atlasarm_examples/        # Python demos
├── build/                         # Build artifacts (auto-generated)
├── install/                       # Installation (auto-generated)
├── log/                           # Build/run logs (auto-generated)
├── run_display.sh                 # Helper scripts
├── run_gazebo.sh
├── run_full.sh
├── run_demo.sh
├── run_joint_test.sh
└── rebuild.sh
```

## Troubleshooting

### "Command not found: ros2"

Open a new terminal — the installer adds ROS2 sourcing to your `~/.bashrc`. Or manually:

```bash
source /opt/ros/humble/setup.bash
source ~/atlasarm6_ws/install/setup.bash
```

### Gazebo opens but arm doesn't appear

Wait 5-10 seconds — the spawn command runs after a delay. Check the terminal for errors.

### Controllers fail to load

```bash
# Check what's loaded
ros2 control list_controllers

# Manual load
ros2 control load_controller --set-state active joint_state_broadcaster
ros2 control load_controller --set-state active atlasarm6_arm_controller
```

### Build fails

```bash
cd ~/atlasarm6_ws
rm -rf build install log
colcon build --symlink-install
```

### Want to start completely fresh

```bash
mv ~/atlasarm6_ws ~/atlasarm6_ws.old
./install.sh    # re-run installer
```

## What's NOT Included

- Physical hardware drivers (this is simulation-only)
- Grippers (URDF reserved for future addition)
- Real UR5e meshes (uses simple geometric primitives instead)
- Camera sensors (can be added to URDF if needed)

## Project Identity

AtlasArm-6 uses Universal Robots UR5e as its **kinematic reference** (link dimensions, joint limits, mass distribution) but is an **independent project** with:

- Own namespace: `atlasarm_*` packages
- Own joint names: `aa6_j1` through `aa6_j6`
- Own link names: `aa6_base_link` through `aa6_tool0`
- Own DH parameters (compact 750mm reach variant)
- Own custom messages and interfaces

## License

MIT License — Free to use, modify, and distribute.
