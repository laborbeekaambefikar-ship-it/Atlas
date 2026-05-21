#!/bin/bash
###############################################################################
# AGVPicker — Run Script
# Launches the full system: Gazebo + Robot + Controllers + MoveIt2 + RViz
###############################################################################
set -e

WS_DIR="$HOME/agvpicker_ws"
ROS_DISTRO="humble"

# Source ROS2 and workspace
source /opt/ros/${ROS_DISTRO}/setup.bash
source ${WS_DIR}/install/setup.bash

echo "╔══════════════════════════════════════════════════════════╗"
echo "║         AGVPicker — Launching Full System              ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  Gazebo + 6-DOF Arm + ros2_control + MoveIt2 + RViz    ║"
echo "║  Press Ctrl+C to stop all nodes                         ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

ros2 launch agvpicker_bringup agvpicker_full.launch.py
