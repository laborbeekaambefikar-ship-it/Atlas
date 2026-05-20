#!/bin/bash
###############################################################################
# AtlasArm-6 — One-Shot Setup Script
# Installs ROS2 Humble + Gazebo + MoveIt2 + builds the full workspace
# Target: Ubuntu 22.04 (fresh install)
# Usage:  chmod +x setup_atlasarm6.sh && ./setup_atlasarm6.sh
###############################################################################
set -e

YELLOW='\033[1;33m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
RED='\033[1;31m'
NC='\033[0m'

WS_DIR="$HOME/atlasarm6_ws"
ROS_DISTRO="humble"

echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║       AtlasArm-6 — Automated Setup (ROS2 Humble)       ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

###############################################################################
# STEP 1: System prerequisites
###############################################################################
echo -e "${YELLOW}[1/7] Installing system prerequisites...${NC}"
sudo apt-get update -qq
sudo apt-get install -y -qq \
  software-properties-common curl gnupg lsb-release wget git \
  python3-pip python3-colcon-common-extensions python3-rosdep \
  python3-vcstool build-essential cmake

###############################################################################
# STEP 2: ROS2 Humble installation
###############################################################################
if [ ! -f /opt/ros/${ROS_DISTRO}/setup.bash ]; then
  echo -e "${YELLOW}[2/7] Installing ROS2 Humble...${NC}"
  sudo add-apt-repository universe -y
  sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
    -o /usr/share/keyrings/ros-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
    http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" \
    | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
  sudo apt-get update -qq
  sudo apt-get install -y -qq ros-${ROS_DISTRO}-desktop
else
  echo -e "${GREEN}[2/7] ROS2 Humble already installed — skipping.${NC}"
fi

source /opt/ros/${ROS_DISTRO}/setup.bash

###############################################################################
# STEP 3: ROS2 packages (Gazebo, MoveIt2, controllers, ros2_control)
###############################################################################
echo -e "${YELLOW}[3/7] Installing ROS2 packages (MoveIt2, Gazebo, ros2_control)...${NC}"
sudo apt-get install -y -qq \
  ros-${ROS_DISTRO}-gazebo-ros-pkgs \
  ros-${ROS_DISTRO}-gazebo-ros2-control \
  ros-${ROS_DISTRO}-ros2-control \
  ros-${ROS_DISTRO}-ros2-controllers \
  ros-${ROS_DISTRO}-moveit \
  ros-${ROS_DISTRO}-moveit-ros-planning-interface \
  ros-${ROS_DISTRO}-moveit-visual-tools \
  ros-${ROS_DISTRO}-joint-state-publisher \
  ros-${ROS_DISTRO}-joint-state-publisher-gui \
  ros-${ROS_DISTRO}-robot-state-publisher \
  ros-${ROS_DISTRO}-xacro \
  ros-${ROS_DISTRO}-controller-manager \
  ros-${ROS_DISTRO}-joint-trajectory-controller \
  ros-${ROS_DISTRO}-joint-state-broadcaster \
  ros-${ROS_DISTRO}-gripper-controllers \
  ros-${ROS_DISTRO}-rviz2 \
  ros-${ROS_DISTRO}-tf2-tools \
  ros-${ROS_DISTRO}-rqt-joint-trajectory-controller

###############################################################################
# STEP 4: Initialize rosdep
###############################################################################
echo -e "${YELLOW}[4/7] Initializing rosdep...${NC}"
if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then
  sudo rosdep init 2>/dev/null || true
fi
rosdep update --rosdistro=${ROS_DISTRO} 2>/dev/null || true

###############################################################################
# STEP 5: Create workspace and generate packages
###############################################################################
echo -e "${YELLOW}[5/7] Creating workspace at ${WS_DIR}...${NC}"
mkdir -p ${WS_DIR}/src
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy source packages into workspace
cp -r ${SCRIPT_DIR}/src/* ${WS_DIR}/src/

###############################################################################
# STEP 6: Install workspace dependencies via rosdep
###############################################################################
echo -e "${YELLOW}[6/7] Resolving workspace dependencies...${NC}"
cd ${WS_DIR}
rosdep install --from-paths src --ignore-src -r -y 2>/dev/null || true

###############################################################################
# STEP 7: Build workspace
###############################################################################
echo -e "${YELLOW}[7/7] Building workspace (colcon build)...${NC}"
cd ${WS_DIR}
source /opt/ros/${ROS_DISTRO}/setup.bash
colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release 2>&1 | tail -5

###############################################################################
# STEP 8: Setup shell auto-source
###############################################################################
echo -e "${YELLOW}Configuring shell environment...${NC}"
BASHRC_LINE="source ${WS_DIR}/install/setup.bash"
if ! grep -qF "${BASHRC_LINE}" ~/.bashrc 2>/dev/null; then
  echo "" >> ~/.bashrc
  echo "# AtlasArm-6 ROS2 workspace" >> ~/.bashrc
  echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc
  echo "${BASHRC_LINE}" >> ~/.bashrc
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          AtlasArm-6 Setup Complete!                     ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  Workspace: ${WS_DIR}                    ║${NC}"
echo -e "${GREEN}║                                                          ║${NC}"
echo -e "${GREEN}║  To launch the full system:                              ║${NC}"
echo -e "${GREEN}║    source ~/.bashrc                                      ║${NC}"
echo -e "${GREEN}║    ./run_atlasarm6.sh                                    ║${NC}"
echo -e "${GREEN}║                                                          ║${NC}"
echo -e "${GREEN}║  Or manually:                                            ║${NC}"
echo -e "${GREEN}║    ros2 launch atlasarm6_bringup atlasarm6_full.launch.py║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
