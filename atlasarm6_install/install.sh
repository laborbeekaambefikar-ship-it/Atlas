#!/bin/bash
###############################################################################
#  ATLASARM-6 — One-Command Installer
#  
#  Usage (on fresh Ubuntu 22.04):
#    bash <(curl -fsSL https://raw.githubusercontent.com/laborbeekaambefikar-ship-it/Atlas/atlasarm6/atlasarm6_install/install.sh)
#
#  Or download and run:
#    wget https://raw.githubusercontent.com/laborbeekaambefikar-ship-it/Atlas/atlasarm6/atlasarm6_install/install.sh
#    chmod +x install.sh
#    ./install.sh
###############################################################################
set -e

# Color output
R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; B='\033[0;34m'; N='\033[0m'

print_h() { echo -e "\n${B}═══════════════════════════════════════════════════════════════${N}"; echo -e "${B} $1${N}"; echo -e "${B}═══════════════════════════════════════════════════════════════${N}"; }
print_s() { echo -e "${G}[OK]${N} $1"; }
print_w() { echo -e "${Y}[..]${N} $1"; }
print_e() { echo -e "${R}[!!]${N} $1"; }

REPO_BASE="https://raw.githubusercontent.com/laborbeekaambefikar-ship-it/Atlas/atlasarm6/atlasarm6_install"
WS="$HOME/atlasarm6_ws"

clear
cat << 'BANNER'
   _  _   _              _                  __  
  /_\| |_| | __ _ ___ /_\  _ _ _ __    / /  
 / _ \  _| |/ _` (_-< / _ \| '_| '  \  / _ \ 
/_/ \_\__|_|\__,_/__//_/ \_\_| |_|_|_| \___/ 
                                            
       6-DOF Robotic Arm — Auto Installer
BANNER
echo ""
echo "This will install:"
echo "  - System dependencies (sudo required)"
echo "  - ROS2 Humble + MoveIt2 + Gazebo Classic 11"
echo "  - AtlasArm-6 workspace at: $WS"
echo "  - All packages, controllers, launch files"
echo ""
echo "Estimated time: 15-30 minutes (depending on internet speed)"
echo ""
read -p "Continue? [y/N]: " confirm
[[ "$confirm" != "y" && "$confirm" != "Y" ]] && exit 0

# ───────────────────────────────────────────────────────────
# Phase 1: Verify Ubuntu 22.04
# ───────────────────────────────────────────────────────────
print_h "PHASE 1/6 — System Verification"

if ! grep -q "Ubuntu 22.04" /etc/os-release 2>/dev/null; then
    print_e "This installer requires Ubuntu 22.04 (Jammy)"
    print_e "Detected: $(lsb_release -d 2>/dev/null | cut -f2)"
    exit 1
fi
print_s "Ubuntu 22.04 detected"

# ───────────────────────────────────────────────────────────
# Phase 2: System Dependencies
# ───────────────────────────────────────────────────────────
print_h "PHASE 2/6 — Installing System Dependencies"

print_w "Updating apt cache..."
sudo apt update -qq

print_w "Installing base tools..."
sudo apt install -y -qq \
    curl wget gnupg lsb-release software-properties-common \
    build-essential cmake git python3-pip python3-dev python3-venv \
    locales

# Locale setup (required by ROS2)
sudo locale-gen en_US en_US.UTF-8 >/dev/null 2>&1
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 >/dev/null 2>&1
print_s "Base tools installed"

# ───────────────────────────────────────────────────────────
# Phase 3: ROS2 Humble
# ───────────────────────────────────────────────────────────
print_h "PHASE 3/6 — Installing ROS2 Humble"

if ! dpkg -l | grep -q "ros-humble-desktop"; then
    print_w "Adding ROS2 apt repository..."
    sudo add-apt-repository universe -y >/dev/null 2>&1
    sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
        -o /usr/share/keyrings/ros-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" \
        | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

    sudo apt update -qq
    print_w "Installing ros-humble-desktop (this takes 5-10 min)..."
    sudo apt install -y -qq ros-humble-desktop python3-rosdep \
        python3-colcon-common-extensions python3-vcstool
    print_s "ROS2 Humble installed"
else
    print_s "ROS2 Humble already present"
fi

# rosdep init
if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then
    print_w "Initializing rosdep..."
    sudo rosdep init >/dev/null 2>&1 || true
    rosdep update -q >/dev/null 2>&1
fi

# ───────────────────────────────────────────────────────────
# Phase 4: MoveIt2 + Gazebo + ros2_control
# ───────────────────────────────────────────────────────────
print_h "PHASE 4/6 — Installing MoveIt2, Gazebo, ros2_control"

print_w "Installing MoveIt2 binaries..."
sudo apt install -y -qq \
    ros-humble-moveit \
    ros-humble-moveit-ros-planning-interface \
    ros-humble-moveit-visual-tools \
    ros-humble-moveit-py 2>/dev/null || true

print_w "Installing Gazebo Classic 11..."
sudo apt install -y -qq \
    ros-humble-gazebo-ros-pkgs \
    ros-humble-gazebo-ros2-control

print_w "Installing ros2_control + controllers..."
sudo apt install -y -qq \
    ros-humble-ros2-control \
    ros-humble-ros2-controllers \
    ros-humble-joint-state-broadcaster \
    ros-humble-joint-state-publisher-gui \
    ros-humble-joint-trajectory-controller \
    ros-humble-position-controllers \
    ros-humble-robot-state-publisher \
    ros-humble-xacro

# TRAC-IK is optional (KDL is the default kinematics solver)
sudo apt install -y -qq ros-humble-trac-ik-kinematics-plugin 2>/dev/null || \
    print_w "TRAC-IK not available — using KDL solver (default, works fine)"

print_s "All ROS2 packages installed"

# ───────────────────────────────────────────────────────────
# Phase 5: Create AtlasArm-6 Workspace
# ───────────────────────────────────────────────────────────
print_h "PHASE 5/6 — Generating AtlasArm-6 Workspace"

if [ -d "$WS" ]; then
    print_w "Workspace exists at $WS"
    read -p "Backup and recreate? [y/N]: " bak
    if [[ "$bak" == "y" || "$bak" == "Y" ]]; then
        BACKUP="$WS.backup.$(date +%s)"
        mv "$WS" "$BACKUP"
        print_s "Old workspace backed up to: $BACKUP"
    else
        print_e "Aborted — workspace already exists"
        exit 1
    fi
fi

mkdir -p "$WS/src"
cd "$WS/src"

print_w "Downloading workspace generator..."
wget -q "$REPO_BASE/create_workspace.sh" -O /tmp/atlasarm6_create.sh
chmod +x /tmp/atlasarm6_create.sh
bash /tmp/atlasarm6_create.sh "$WS/src"
print_s "Workspace files generated at $WS"

# ───────────────────────────────────────────────────────────
# Phase 6: Build
# ───────────────────────────────────────────────────────────
print_h "PHASE 6/6 — Building Workspace"

cd "$WS"
source /opt/ros/humble/setup.bash

print_w "Resolving dependencies..."
rosdep install --from-paths src --ignore-src -r -y 2>/dev/null || true

print_w "Building (this takes 3-8 min)..."
colcon build --symlink-install 2>&1 | tail -10 || {
    print_e "Build failed. Check $WS/log/latest_build/ for details"
    exit 1
}
print_s "Build complete"

# Add source to .bashrc if not present
if ! grep -q "atlasarm6_ws/install/setup.bash" "$HOME/.bashrc"; then
    echo "" >> "$HOME/.bashrc"
    echo "# AtlasArm-6 workspace" >> "$HOME/.bashrc"
    echo "source $WS/install/setup.bash" >> "$HOME/.bashrc"
    print_s "Added AtlasArm-6 to .bashrc"
fi

# ───────────────────────────────────────────────────────────
# Done
# ───────────────────────────────────────────────────────────
print_h "INSTALLATION COMPLETE"

cat << EOF

  ${G}AtlasArm-6 is installed and ready to use!${N}

  ${Y}Quick Start:${N}

  1. Open a new terminal (so .bashrc loads), then:

     ${B}# View the robot in RViz${N}
     ros2 launch atlasarm_description display.launch.py

     ${B}# Run full simulation (Gazebo + MoveIt2 + RViz)${N}
     ros2 launch atlasarm_bringup atlasarm6_full.launch.py

     ${B}# Run pick-and-place demo${N}
     ros2 run atlasarm_examples pick_and_place_demo

     ${B}# Send a manipulation task${N}
     ros2 run atlasarm_examples send_task --pick 0.4 0.0 0.15 --place 0.4 0.3 0.15

  ${Y}Workspace location:${N} $WS

  ${Y}Helper scripts:${N}
     $WS/run_display.sh   — Quick RViz view
     $WS/run_full.sh      — Full simulation
     $WS/run_demo.sh      — Pick-and-place demo

EOF
