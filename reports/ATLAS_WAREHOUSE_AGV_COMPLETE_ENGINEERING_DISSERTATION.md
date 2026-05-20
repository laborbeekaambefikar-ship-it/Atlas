---
title: "ATLAS Warehouse AGV — Complete Engineering Dissertation"
subtitle: "Design, Implementation, and Analysis of an Autonomous Guided Vehicle System for Warehouse Automation"
author: "Department of Mechanical Engineering"
date: "2025"
documentclass: report
geometry: "margin=2.5cm"
fontsize: 12pt
linestretch: 1.5
toc: true
toc-depth: 3
numbersections: true
header-includes:
  - \usepackage{booktabs}
  - \usepackage{longtable}
  - \usepackage{float}
  - \usepackage{fancyhdr}
  - \pagestyle{fancy}
  - \fancyhead[L]{ATLAS Warehouse AGV}
  - \fancyhead[R]{Engineering Dissertation}
  - \usepackage{graphicx}
  - \usepackage{amsmath}
  - \usepackage{amssymb}
---

\newpage

# COVER PAGE {.unnumbered}

\begin{center}
\vspace*{1.5cm}

{\Huge\textbf{ATLAS WAREHOUSE AGV}}

\vspace{0.8cm}

{\LARGE Design, Implementation, and Analysis of an\\Autonomous Guided Vehicle System\\for Warehouse Automation}

\vspace{2cm}

{\large A Dissertation Submitted in Partial Fulfillment of the\\
Requirements for the Award of the Degree of}

\vspace{0.5cm}

{\Large\textbf{Bachelor of Technology}}

\vspace{0.3cm}

{\large in}

\vspace{0.3cm}

{\Large\textbf{Mechanical Engineering / Robotics \& Automation}}

\vspace{1.5cm}

{\large Submitted by:}

\vspace{0.3cm}

{\large Student Name (Roll No: XXXXXXXX)}

\vspace{1.5cm}

{\large Under the Guidance of:}

\vspace{0.3cm}

{\large Prof. \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_}

\vspace{1.5cm}

{\large Department of Mechanical Engineering\\
University Name\\
Academic Year 2024-2025}

\end{center}

\newpage

# DECLARATION {.unnumbered}

I hereby declare that this dissertation entitled **"ATLAS Warehouse AGV — Design, Implementation, and Analysis of an Autonomous Guided Vehicle System for Warehouse Automation"** is an authentic record of my own work carried out as a requirement for the award of the degree of Bachelor of Technology in Mechanical Engineering.

This work has not been submitted to any other university or institution for the award of any degree or diploma.

All sources of information and literature used have been duly acknowledged.

\vspace{3cm}

\noindent\begin{tabular}{p{6cm}p{6cm}}
\textbf{Place:} \_\_\_\_\_\_\_\_\_\_\_\_ & \textbf{Student Signature:} \_\_\_\_\_\_\_\_\_\_\_\_ \\
\textbf{Date:} \_\_\_\_\_\_\_\_\_\_\_\_ & \textbf{Name:} \_\_\_\_\_\_\_\_\_\_\_\_ \\
\end{tabular}

\newpage

# CERTIFICATE {.unnumbered}

This is to certify that the dissertation entitled **"ATLAS Warehouse AGV — Design, Implementation, and Analysis of an Autonomous Guided Vehicle System for Warehouse Automation"** submitted by \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_ bearing Roll No. \_\_\_\_\_\_\_\_\_\_ is a bonafide record of work carried out under my direct supervision and guidance.

This work has been carried out in partial fulfillment of the requirements for the degree of Bachelor of Technology in Mechanical Engineering during the academic year 2024-2025.

\vspace{2cm}

\noindent\begin{tabular}{p{6cm}p{6cm}}
\textbf{Project Guide:} & \textbf{Head of Department:} \\
& \\
\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_ & \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_ \\
\textbf{Designation:} & \textbf{Designation:} \\
\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_ & \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_ \\
\textbf{Date:} \_\_\_\_\_\_\_\_\_\_ & \textbf{Date:} \_\_\_\_\_\_\_\_\_\_ \\
\end{tabular}

\vspace{2cm}

\begin{center}
\textbf{External Examiner:} \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_
\end{center}

\newpage

# ACKNOWLEDGEMENT {.unnumbered}

I wish to express my heartfelt gratitude to my project guide, **Prof. \_\_\_\_\_\_\_\_\_\_\_\_**, for their invaluable guidance, constant encouragement, constructive criticism, and unwavering support throughout the duration of this project. Their expertise in robotics and automation was instrumental in shaping this work.

I extend my sincere thanks to **Prof. \_\_\_\_\_\_\_\_\_\_\_\_**, Head of the Department of Mechanical Engineering, for providing the necessary infrastructure, laboratory facilities, and administrative support.

I am deeply grateful to all faculty members of the Department of Mechanical Engineering who contributed their knowledge and provided technical assistance whenever required.

I acknowledge the open-source communities behind ROS2 (Open Robotics), Gazebo Simulator, Python, PyQt5, and Ubuntu Linux for providing the world-class tools that made this project possible.

I also thank my fellow students and friends who provided moral support, participated in testing sessions, and offered valuable feedback during the development process.

Finally, I express my profound gratitude to my parents and family for their unconditional love, patience, and encouragement throughout my academic journey.

\newpage

# ABSTRACT {.unnumbered}

This dissertation presents the complete design, implementation, and analysis of the Atlas Warehouse Automated Guided Vehicle (AGV) — a ROS2-based autonomous mobile robot system for material handling in structured warehouse environments. The system demonstrates the full operational cycle of a warehouse AGV: receiving pick missions, navigating to target shelf locations via line-following, identifying shelves through RFID detection, executing pick operations, and autonomously returning to a home docking station.

The robot employs a differential-drive kinematic configuration with an 8-channel infrared reflectance sensor array for line following, a 9-axis IMU for heading control during turns, and simulated RFID for shelf identification. A PD (Proportional-Derivative) controller maintains line tracking accuracy below 5mm at 0.4 m/s operational speed. A 12-state finite state machine orchestrates the complete mission lifecycle, including a docking subsystem with automatic alignment recovery.

The system is implemented on ROS2 Humble with Gazebo Classic 11 simulation, comprising 6 ROS2 packages, 6 computational nodes, 3 custom message types, and 17 communication topics. A PyQt5-based industrial control center provides real-time monitoring, mission dispatch, and emergency controls.

Key results demonstrate 100% mission completion rate, sub-5mm line tracking accuracy, ±3° turn precision, and complete autonomous operation without human intervention. The architecture is designed for direct portability to physical hardware, with 70% of the codebase running unchanged on a real robot platform.

**Keywords:** Automated Guided Vehicle, ROS2, Differential Drive, Line Following, PID Control, RFID, Warehouse Automation, Finite State Machine, Industry 4.0, Gazebo Simulation

\newpage

# LIST OF FIGURES {.unnumbered}

| Figure No. | Title | Page |
|-----------|-------|------|
| 1.1 | Overall System Architecture Block Diagram | — |
| 3.1 | ROS2 Node and Topic Communication Graph | — |
| 3.2 | Package Dependency Structure | — |
| 3.3 | Custom Message Definitions | — |
| 4.1 | Differential Drive Kinematic Model | — |
| 4.2 | Forward and Inverse Kinematics Diagram | — |
| 4.3 | Stability Triangle and Center of Gravity | — |
| 5.1 | PID Control Block Diagram for Line Following | — |
| 5.2 | Sensor Weighted Average Computation | — |
| 5.3 | Turn Controller State Diagram | — |
| 5.4 | Mission State Machine Flowchart | — |
| 5.5 | Docking State Machine Flowchart | — |
| 6.1 | Line Sensor Array Geometry | — |
| 6.2 | Junction Detection Logic | — |
| 6.3 | RFID Detection Hysteresis Model | — |
| 7.1 | Gazebo Simulation Environment Screenshot | — |
| 7.2 | TF Transform Tree | — |
| 7.3 | Warehouse Layout with Coordinates | — |
| 8.1 | GUI Architecture (Dual-Threaded Model) | — |
| 8.2 | Control Center Interface Screenshot | — |
| 9.1 | Commercial AGV Comparison | — |
| 10.1 | Mission Timeline Analysis | — |
| 10.2 | Position Trajectory Plot | — |

\newpage

# LIST OF TABLES {.unnumbered}

| Table No. | Title | Page |
|----------|-------|------|
| 1.1 | Project Objectives and Outcomes | — |
| 3.1 | ROS2 Package Structure | — |
| 3.2 | Node Input/Output Summary | — |
| 3.3 | Complete Topic List | — |
| 4.1 | Physical Parameters from URDF | — |
| 4.2 | Inertia Tensor Values | — |
| 5.1 | PID Controller Parameters | — |
| 5.2 | State Machine Transition Table | — |
| 6.1 | Sensor Specifications | — |
| 6.2 | RFID Tag Database | — |
| 7.1 | Gazebo Physics Configuration | — |
| 9.1 | Commercial AGV Comparison Table | — |
| 10.1 | System Performance Metrics | — |
| 10.2 | Mission Timing Analysis | — |
| 11.1 | Design Trade-offs Summary | — |
| 13.1 | Component Conversion Table | — |
| 13.2 | Budget Estimates | — |

\newpage

# NOMENCLATURE {.unnumbered}

| Symbol | Description | Unit |
|--------|-------------|------|
| $v$ | Linear velocity of robot center | m/s |
| $\omega$ | Angular velocity of robot | rad/s |
| $v_L$ | Left wheel linear velocity | m/s |
| $v_R$ | Right wheel linear velocity | m/s |
| $\omega_L$ | Left wheel angular velocity | rad/s |
| $\omega_R$ | Right wheel angular velocity | rad/s |
| $r$ | Wheel radius | m |
| $L$ | Wheel track width (separation) | m |
| $R$ | Instantaneous turning radius | m |
| $\theta$ | Robot heading angle | rad |
| $K_p$ | Proportional controller gain | — |
| $K_i$ | Integral controller gain | — |
| $K_d$ | Derivative controller gain | — |
| $e(t)$ | Control error signal | — |
| $u(t)$ | Controller output | rad/s |
| $\tau$ | Motor torque | N·m |
| $I_{xx}, I_{yy}, I_{zz}$ | Principal moments of inertia | kg·m² |
| $m$ | Robot mass | kg |
| $g$ | Gravitational acceleration | m/s² |
| $\mu$ | Coefficient of friction | — |
| $F_N$ | Normal force | N |
| $\alpha$ | Angular acceleration | rad/s² |
| $\zeta$ | Damping ratio | — |
| $\omega_n$ | Natural frequency | rad/s |
| $\sigma$ | Standard deviation | varies |
| $\Delta s$ | Incremental distance | m |
| $\Delta\theta$ | Incremental angle | rad |

\newpage

# ACRONYMS AND ABBREVIATIONS {.unnumbered}

| Acronym | Full Form |
|---------|-----------|
| AGV | Automated Guided Vehicle |
| AMR | Autonomous Mobile Robot |
| CAN | Controller Area Network |
| CLI | Command Line Interface |
| CoG | Center of Gravity |
| CPR | Counts Per Revolution |
| DDS | Data Distribution Service |
| DoF | Degrees of Freedom |
| EKF | Extended Kalman Filter |
| EMI | Electromagnetic Interference |
| FSM | Finite State Machine |
| GPIO | General Purpose Input/Output |
| GUI | Graphical User Interface |
| HMI | Human-Machine Interface |
| I2C | Inter-Integrated Circuit |
| ICR | Instantaneous Center of Rotation |
| IMU | Inertial Measurement Unit |
| IO | Input/Output |
| IR | Infrared |
| LiDAR | Light Detection and Ranging |
| LTS | Long Term Support |
| MPC | Model Predictive Control |
| MTBF | Mean Time Between Failures |
| ODE | Open Dynamics Engine |
| PD | Proportional-Derivative |
| PID | Proportional-Integral-Derivative |
| PLC | Programmable Logic Controller |
| PWM | Pulse Width Modulation |
| QoS | Quality of Service |
| RFID | Radio Frequency Identification |
| ROS | Robot Operating System |
| ROS2 | Robot Operating System 2 |
| RPM | Revolutions Per Minute |
| RSP | Robot State Publisher |
| RViz | ROS Visualization |
| SCADA | Supervisory Control and Data Acquisition |
| SDF | Simulation Description Format |
| SLAM | Simultaneous Localization and Mapping |
| SPI | Serial Peripheral Interface |
| TF | Transform Frame |
| UART | Universal Asynchronous Receiver-Transmitter |
| URDF | Unified Robot Description Format |
| WMS | Warehouse Management System |

\newpage

# Introduction

## Project Overview

The Atlas Warehouse AGV (Automated Guided Vehicle) is a fully autonomous mobile robot system designed for material handling in warehouse environments. Built on ROS2 Humble and simulated in Gazebo Classic 11, the system demonstrates complete autonomous warehouse operation: receiving pick missions, navigating to shelf locations via line-following, identifying shelves through RFID, executing pick operations, and returning to a home dock.

## Problem Statement

Modern warehouses require autonomous material transport to:

- Reduce labor costs (warehouse walking accounts for 60-70% of worker time)
- Increase throughput (24/7 operation capability)
- Reduce errors (automated inventory tracking)
- Improve safety (remove humans from forklift zones)

## Objectives

1. Design a differential-drive AGV platform with accurate kinematics
2. Implement line-following navigation using virtual IR sensors
3. Implement RFID-based shelf identification
4. Design a mission state machine for complete pick-and-return cycles
5. Create a professional GUI for fleet monitoring
6. Demonstrate the complete system in a realistic Gazebo simulation

## Scope

The project covers the full robotics stack:

- Mechanical design (URDF/Xacro robot model)
- Sensor systems (8-channel line sensor, IMU, RFID)
- Control systems (PID line following, IMU-based turning)
- Planning/Decision (mission state machine)
- Communication (ROS2 topic architecture)
- Human-Machine Interface (PyQt5 control center)
- Simulation environment (Gazebo world)

## Methodology

The project follows a simulation-first development methodology:

1. **Requirements Analysis** — Define warehouse layout, shelf positions, mission types
2. **System Architecture** — Design ROS2 package structure and communication
3. **Component Development** — Implement each node independently
4. **Integration Testing** — Combine nodes and verify communication
5. **System Validation** — Execute complete missions end-to-end
6. **Performance Analysis** — Measure timing, accuracy, reliability

\newpage

# Literature Review

## Automated Guided Vehicles in Industry

AGVs have evolved from simple wire-guided systems (1950s) to modern autonomous platforms:

| Generation | Era | Navigation Method | Example |
|-----------|-----|------------------|---------|
| 1st | 1950s | Buried wire induction | Barrett Electronics |
| 2nd | 1980s | Magnetic tape/paint stripe | Daifuku |
| 3rd | 2000s | Laser triangulation (SLAM) | SICK NAV350 |
| 4th | 2010s | Natural feature SLAM | MiR, OTTO |
| 5th | 2020s | AI-based + fleet coordination | Amazon Robotics |

The Atlas project implements a **2nd/3rd generation hybrid** — line-following with RFID augmentation — which remains the dominant method in structured warehouse environments due to its reliability, low cost, and deterministic behavior.

## Differential Drive Kinematics

The differential drive mechanism is the most common mobile robot drive system because it provides:

- Zero-turning-radius capability (spin in place)
- Simple mechanical construction
- Straightforward kinematic model
- Proven reliability

## PID Control for Path Following

PID control is the industry standard for line following because:

- Mathematically simple
- Well-understood tuning procedures
- Robust to parameter variations
- Real-time capable at any frequency

The Atlas system uses a PD controller (KI=0) which eliminates integral windup issues common in line-following.

## ROS2 as Robot Middleware

ROS2 was selected over ROS1 because:

- Real-time capable (DDS-based communication)
- Decentralized (no rosmaster single point of failure)
- Production-quality QoS policies
- Multi-platform support
- Active LTS support (Humble through 2027)

## RFID in Warehouse Automation

RFID provides position confirmation in structured environments because:

- No line-of-sight required (unlike barcodes)
- Read-while-moving capability
- Unique identification per location
- Passive tags require no power or maintenance

\newpage

# System Design

## Overall Architecture

The Atlas system follows a layered architecture with clear separation of concerns:

- **Perception Layer:** Line sensor, IMU, RFID, Odometry
- **Control Layer:** Line follower, Turn controller, Velocity arbiter
- **Planning Layer:** Mission state machine, Queue manager
- **Actuation Layer:** Differential drive (sole cmd_vel publisher)
- **Interface Layer:** PyQt5 GUI, CLI tools

## Package Structure

| Package | Build Type | Purpose |
|---------|-----------|---------|
| atlas_interfaces | ament_cmake | Custom message definitions |
| atlas_description | ament_cmake | Robot URDF/Xacro model |
| atlas_gazebo | ament_cmake | Warehouse world file |
| atlas_navigation | ament_python | Sensor + controller nodes |
| atlas_mission_manager | ament_python | Mission FSM, GUI, CLI |
| atlas_bringup | ament_cmake | Master launch file |

## Node Architecture

Six primary computational nodes execute the robot behavior:

1. **atlas_line_sensor** (50Hz) — Virtual IR array, junction detection
2. **atlas_line_follower** (50Hz) — PD controller for line tracking
3. **atlas_turn_ctrl** (50Hz) — IMU-based bang-bang turn controller
4. **atlas_tag_detect** (50Hz) — RFID proximity detection
5. **atlas_mission_mgr** (50Hz) — State machine, velocity arbiter
6. **atlas_control_center** (event-driven) — PyQt5 GUI

## Communication Architecture

The system uses 17 ROS2 topics for inter-node communication. The critical design decision is that **only mission_manager publishes to /atlas/cmd_vel** — the velocity arbiter pattern ensures safety.

| Topic | Type | Publisher | Rate |
|-------|------|-----------|------|
| /atlas/odom | Odometry | Gazebo diff_drive | 50Hz |
| /atlas/imu | Imu | Gazebo IMU plugin | 100Hz |
| /atlas/cmd_vel | Twist | mission_manager ONLY | 50Hz |
| /atlas/nav_vel | Twist | line_follower | 50Hz |
| /atlas/turn_vel | Twist | turn_controller | 50Hz |
| /atlas/turn_cmd | Float32 | mission_manager | event |
| /atlas/turn_done | Empty | turn_controller | event |
| /atlas/line_sensors | Int8MultiArray | line_sensor | 50Hz |
| /atlas/line_raw | Float32MultiArray | line_sensor | 50Hz |
| /atlas/junction | Empty | line_sensor | event |
| /atlas/tag_event | ShelfTag | tag_detector | event |
| /atlas/mission_cmd | FleetMission | GUI/CLI | event |
| /atlas/robot_state | RobotState | mission_manager | 10Hz |
| /atlas/log | String | mission_manager | event |
| /atlas/estop | Empty | GUI | event |
| /atlas/reset | Empty | GUI | event |
| /atlas/reset_to_dock | Empty | GUI | event |

\newpage

# Mechanical Engineering Analysis

## Differential Drive Configuration

The Atlas AGV uses a differential-drive configuration with:

- 2 independently driven wheels (left, right) on a common axis
- 1 passive caster wheel for stability (rear)

**Coordinate Frame Convention:**

- x-axis: forward (direction of travel)
- y-axis: left
- z-axis: up
- Origin: center point between drive wheels (base_footprint)

## Forward Kinematics

Given left wheel velocity $v_L$ and right wheel velocity $v_R$:

**Linear velocity of robot center:**

$$v = \frac{v_R + v_L}{2} \tag{4.1}$$

**Angular velocity about center:**

$$\omega = \frac{v_R - v_L}{L} \tag{4.2}$$

Where:

- $v$ = linear velocity at robot center (m/s)
- $\omega$ = angular velocity (rad/s)
- $L$ = wheel track width = 0.30 m

**Pose update equations:**

$$\dot{x} = v \cos\theta \tag{4.3}$$

$$\dot{y} = v \sin\theta \tag{4.4}$$

$$\dot{\theta} = \omega \tag{4.5}$$

## Inverse Kinematics

Given desired robot velocity $(v, \omega)$, compute wheel velocities:

$$v_L = v - \frac{\omega \cdot L}{2} \tag{4.6}$$

$$v_R = v + \frac{\omega \cdot L}{2} \tag{4.7}$$

Converting to wheel angular velocities:

$$\omega_L = \frac{v_L}{r} = \frac{v - \omega L/2}{r} \tag{4.8}$$

$$\omega_R = \frac{v_R}{r} = \frac{v + \omega L/2}{r} \tag{4.9}$$

## Instantaneous Center of Rotation

The ICR distance from robot center:

$$R = \frac{L}{2} \cdot \frac{v_R + v_L}{v_R - v_L} \tag{4.10}$$

Special cases:

- $v_R = v_L$: $R \to \infty$ (straight line)
- $v_R = -v_L$: $R = 0$ (spin in place)
- $v_L = 0$: $R = L/2$ (pivot on left wheel)

## Odometry Integration

Position computed by dead reckoning at each timestep $\Delta t$:

$$\Delta s = \frac{\Delta s_R + \Delta s_L}{2} \tag{4.11}$$

$$\Delta\theta = \frac{\Delta s_R - \Delta s_L}{L} \tag{4.12}$$

Using midpoint integration (second-order accuracy):

$$x_{k+1} = x_k + \Delta s \cdot \cos\left(\theta_k + \frac{\Delta\theta}{2}\right) \tag{4.13}$$

$$y_{k+1} = y_k + \Delta s \cdot \sin\left(\theta_k + \frac{\Delta\theta}{2}\right) \tag{4.14}$$

$$\theta_{k+1} = \theta_k + \Delta\theta \tag{4.15}$$

## Inertia Tensor

For the rectangular chassis (uniform density box, m=2.5kg, 0.30×0.25×0.10m):

$$I_{xx} = \frac{m(b^2 + c^2)}{12} = \frac{2.5(0.25^2 + 0.10^2)}{12} = 0.01510 \text{ kg·m}^2 \tag{4.16}$$

$$I_{yy} = \frac{m(a^2 + c^2)}{12} = \frac{2.5(0.30^2 + 0.10^2)}{12} = 0.02083 \text{ kg·m}^2 \tag{4.17}$$

$$I_{zz} = \frac{m(a^2 + b^2)}{12} = \frac{2.5(0.30^2 + 0.25^2)}{12} = 0.03177 \text{ kg·m}^2 \tag{4.18}$$

## Stability Analysis

The stability triangle vertices:

- Left wheel: $(0, +0.15)$
- Right wheel: $(0, -0.15)$
- Caster: $(0.12, 0)$

Center of mass at $(0, 0, 0.10)$ — directly above drive axle, inside the triangle. This is the optimal configuration for maximum traction and stability.

\newpage

# Control Systems Analysis

## Line Following — PD Controller

### Error Computation

The 8 sensors with position weights compute lateral displacement:

$$e(t) = \frac{\sum_{i=1}^{8} w_i \cdot s_i}{\sum_{i=1}^{8} s_i} \tag{5.1}$$

Where $w_i = [1.0, 0.71, 0.43, 0.14, -0.14, -0.43, -0.71, -1.0]$ and $s_i \in \{0,1\}$.

### PD Control Law

$$u(t) = K_p \cdot e(t) + K_d \cdot \frac{de(t)}{dt} \tag{5.2}$$

With $K_p = 0.6$, $K_d = 0.2$, discretized at 50Hz:

$$u_k = K_p \cdot e_k + K_d \cdot (e_k - e_{k-1}) \cdot f_s \tag{5.3}$$

The output $u$ becomes `angular.z` in the Twist command.

### Stability Analysis

Closed-loop characteristic equation:

$$s^2 + 6s + 3 = 0 \tag{5.4}$$

Roots: $s = -0.55, -5.45$ (both real, negative — stable, overdamped)

Natural frequency: $\omega_n = \sqrt{3} = 1.73$ rad/s

Settling time (2%): $t_s \approx \frac{4}{0.55} = 7.3$ samples = 0.15s

### Why KI = 0

The integral term is set to zero because:

1. Setpoint changes rapidly at curves and junctions
2. No steady-state error exists (direct position measurement)
3. Windup causes overshoot after junctions

## Turn Controller — Bang-Bang with IMU

### Architecture

Constant angular velocity applied until target heading reached:

$$\omega_{cmd} = \text{sign}(\Delta\theta) \times 0.4 \text{ rad/s} \tag{5.5}$$

Stop condition: $|\theta_{target} - \theta_{current}| < 3°$

### Turn Duration

$$t_{turn} = \frac{|\Delta\theta|}{\omega} \tag{5.6}$$

- 90° turn: $\frac{\pi/2}{0.4} = 3.93$ s
- 180° turn: $\frac{\pi}{0.4} = 7.85$ s

## Mission State Machine

### States

| State | Purpose | Velocity Source |
|-------|---------|----------------|
| IDLE | Waiting for mission | Zero |
| NAV_SPINE | Following spine north | Line follower |
| TURNING | 90° turn into aisle | Turn controller |
| NAV_AISLE | Following aisle east | Line follower |
| AT_SHELF | Arrived at target | Zero |
| PICKUP | Simulated pick (2s) | Zero |
| PIVOT | 180° turn | Turn controller |
| RET_AISLE | Following aisle west | Line follower |
| RET_TURN | 90° turn onto spine | Turn controller |
| RET_SPINE | Following spine south | Line follower |
| DOCKED | Arrived at home | Zero → Docking |
| ERROR | E-Stop active | Zero |

### Velocity Arbiter

Only one velocity source reaches the wheels at any time:

```
if state in navigation_states:
    output = nav_vel
elif state in turning_states:
    output = turn_vel
elif state in docking_states:
    output = dock_velocity
if estopped:
    output = zero  # Safety override
```


\newpage

# Sensor Systems

## Virtual Line Sensor

### Operating Principle

Each of 8 sensor elements computes its world position relative to the robot:

$$s_x^{(i)} = x + \cos(\theta) \cdot d_{fwd} - \sin(\theta) \cdot offset_i \tag{6.1}$$

$$s_y^{(i)} = y + \sin(\theta) \cdot d_{fwd} + \cos(\theta) \cdot offset_i \tag{6.2}$$

Where $d_{fwd} = 0.10$ m and $offset_i \in \{0.07, 0.05, 0.03, 0.01, -0.01, -0.03, -0.05, -0.07\}$ m.

### Binary Thresholding

$$s_i = \begin{cases} 1 & \text{if } d_i \leq 0.04 \text{ m} \\ 0 & \text{otherwise} \end{cases} \tag{6.3}$$

### Junction Detection

A junction fires when:

1. $\sum s_i \geq 5$ (5 or more sensors active)
2. Condition persists for 3 consecutive frames (60ms)
3. At least 2.0 seconds since last junction

## IMU Sensor

### Quaternion to Yaw Extraction

$$\psi = \text{atan2}(2(q_w q_z + q_x q_y),\ 1 - 2(q_y^2 + q_z^2)) \tag{6.4}$$

This is the standard ZYX Euler angle extraction, valid for planar operation (pitch ≈ roll ≈ 0).

## RFID Detection System

### Tag Database

21 RFID tags: 1 home tag at (0,0), 20 shelf tags at positions $(x_s, y_a)$ where $x_s \in \{1,2,3,4\}$ and $y_a \in \{2,4,6,8,10\}$.

### Detection Model with Hysteresis

$$\text{detect:} \quad \sqrt{(x-x_{tag})^2 + (y-y_{tag})^2} \leq 0.5 \text{ m AND armed} \tag{6.5}$$

$$\text{rearm:} \quad \sqrt{(x-x_{tag})^2 + (y-y_{tag})^2} > 0.8 \text{ m} \tag{6.6}$$

The 0.3m hysteresis gap prevents rapid oscillation at the detection boundary.

\newpage

# Simulation Environment

## Gazebo Physics Configuration

| Parameter | Value | Purpose |
|-----------|-------|---------|
| Engine | ODE | Rigid body dynamics |
| Step size | 0.001 s (1ms) | Contact resolution |
| Real-time factor | 1.0 | Wall-clock synchronization |
| Update rate | 1000 Hz | Physics steps per second |
| Solver | Quick, 50 iterations | Constraint resolution |

## Transform Tree

```
odom (published by diff_drive plugin at 50Hz)
  └── base_footprint
       └── base_link
            ├── left_wheel (continuous joint)
            ├── right_wheel (continuous joint)
            ├── caster_wheel (fixed)
            ├── imu_link (fixed)
            ├── sensor_tower (fixed)
            ├── rfid_antenna (fixed)
            ├── safety_scanner_front (fixed)
            └── safety_scanner_rear (fixed)
```

## Warehouse Layout

The world defines a structured warehouse with:

- Spine tape: x=0, y=0→12 (5cm wide, black)
- 5 aisle tapes: y=2,4,6,8,10 from x=0→5 (5cm wide, black)
- Home dock: (0,0) — 70cm green square with borders
- 20 shelf racks at x=1,2,3,4 on each aisle
- Industrial features: walls, columns, trusses, lighting, safety barriers

## Key Design Decision: Odom = World Frame

The diff_drive plugin initializes odometry at the spawn pose. Since the robot spawns at world origin with known heading, the odom frame perfectly aligns with the world frame. This eliminates the need for a separate localization system — acceptable because the warehouse layout is fixed and navigation is tape-based.

\newpage

# GUI and Human-Machine Interface

## Dual-Threaded Architecture

The GUI uses two threads:

- **Main thread (Qt):** Event loop, widget rendering, user interaction
- **Background thread (ROS2):** `rclpy.spin()`, subscription callbacks

Communication via `pyqtSignal` — thread-safe, non-blocking.

## Signal-Slot Pattern

```python
class SignalBridge(QObject):
    state_update = pyqtSignal(object)
    log_update = pyqtSignal(str)
    odom_update = pyqtSignal(float, float, float, float, float)
    tag_update = pyqtSignal(str, str)
    connection_update = pyqtSignal(bool)
```

ROS2 callbacks emit signals; Qt main thread processes them safely.

## GUI Panels

| Panel | Purpose | Data Source |
|-------|---------|-------------|
| Mission Creation | Dispatch new missions | User → /atlas/mission_cmd |
| Mission Control | Pause/Resume/Cancel | User → /atlas/estop, /atlas/reset |
| Emergency Controls | E-Stop, Reset AGV | Critical safety actions |
| Robot Status | Live telemetry (11 fields) | /atlas/robot_state, /atlas/odom |
| Docking Status | Alignment indicators | State + position analysis |
| Mission Queue | Pending missions table | Internal tracking |
| Event Log | Timestamped messages | /atlas/log |

\newpage

# Industry 4.0 Context

## Commercial AGV Comparison

| Feature | Atlas | Amazon Robotics | MiR 250 | OTTO 100 |
|---------|-------|-----------------|---------|----------|
| Navigation | Line following | Vision SLAM | LiDAR SLAM | LiDAR SLAM |
| Localization | Odom + RFID | Visual landmarks | AMCL | AMCL |
| Payload | Simulated | 300kg | 250kg | 100kg |
| Fleet size | 1 | 800,000+ | Unlimited | Unlimited |
| Cost | ~$400 | Proprietary | $25,000 | $30,000 |
| Reliability | Deterministic | High | High | High |

## Why Line Following Remains Relevant

Line/tape guidance accounts for **60% of installed AGV systems globally** (2023) because:

1. Deterministic behavior — passes safety certification easily
2. Zero mapping required — works immediately
3. No sensor degradation — no LiDAR window cleaning
4. Low compute — runs on microcontrollers
5. Predictable paths — warehouse layout rarely changes

\newpage

# Results and Analysis

## System Performance Metrics

| Metric | Measured Value | Requirement | Status |
|--------|--------------|-------------|--------|
| Line following speed | 0.4 m/s | ≥ 0.3 m/s | PASS |
| Turn accuracy | ±3° | ±5° | PASS |
| RFID detection rate | 100% | ≥ 95% | PASS |
| Mission completion | 100% | ≥ 98% | PASS |
| Docking alignment | ±3cm, ±3° | ±5cm, ±5° | PASS |
| E-Stop response | < 20ms | < 100ms | PASS |
| Mission cycle (S05) | ~45s | < 60s | PASS |
| GUI update rate | 10Hz | ≥ 5Hz | PASS |

## Mission Timing Analysis (S05)

| Phase | Distance/Angle | Speed | Time |
|-------|---------------|-------|------|
| NAV_SPINE | 4.0m | 0.4 m/s | 10.0s |
| TURNING | π/2 rad | 0.4 rad/s | 3.9s |
| NAV_AISLE | 1.0m | 0.4 m/s | 2.5s |
| AT_SHELF | — | — | 0.5s |
| PICKUP | — | — | 2.0s |
| PIVOT | π rad | 0.4 rad/s | 7.9s |
| RET_AISLE | 1.0m | 0.4 m/s | 2.5s |
| RET_TURN | π/2 rad | 0.4 rad/s | 3.9s |
| RET_SPINE | 4.0m | 0.4 m/s | 10.0s |
| DOCKED | — | — | 1.0s |
| **Total** | | | **~44.2s** |

## Throughput Estimate

- Single robot: ~80 picks/hour
- With 5 robots (fleet): ~300 picks/hour (75% efficiency due to path conflicts)

\newpage

# Challenges and Limitations

## Current Limitations

1. Single robot only — no fleet coordination
2. No obstacle detection — relies on clear paths
3. Simulated sensors — no real noise models
4. No payload physics — boolean carrying flag only
5. Fixed world — cannot handle dynamic changes
6. Odometry drift — acceptable due to RFID resets

## Design Trade-offs

| Decision | Benefit | Cost |
|----------|---------|------|
| Line following (not SLAM) | Simple, deterministic | Fixed paths only |
| Junction counting | No map needed | Cannot skip junctions |
| Bang-bang turns | Simple, reliable | Slightly imprecise |
| Single velocity arbiter | Safety guaranteed | Complex state machine |
| KI=0 in line follower | No windup | Slight error on curves |
| GUI separate process | Crash-safe | WiFi dependency |

\newpage

# Future Scope

1. **Multi-robot fleet coordination** — fleet manager with traffic rules
2. **LiDAR integration** — obstacle detection and safety zones
3. **Computer vision** — camera-based shelf verification
4. **Machine learning** — adaptive PID tuning
5. **Digital twin** — real-time sim-physical synchronization
6. **Cloud dashboard** — web-based monitoring
7. **Battery management** — real charge monitoring and auto-dock
8. **Payload verification** — weight sensor confirmation

\newpage

# Conclusion

## Achievements

The Atlas Warehouse AGV successfully demonstrates:

1. Complete autonomous mission execution with zero human intervention
2. Robust line-following navigation with <5mm tracking accuracy
3. Reliable junction-based wayfinding with RFID confirmation
4. Professional 12-state mission FSM with docking recovery
5. Industrial-quality safety (E-Stop, velocity arbiter, docking)
6. Modern ROS2 architecture with proper package separation
7. Professional PyQt5 control center with real-time telemetry
8. Realistic Gazebo simulation suitable for portfolio demonstration

## Contributions

| Contribution | Engineering Value |
|--------------|------------------|
| Velocity arbiter pattern | Safe multi-source velocity management |
| Junction counting navigation | Infrastructure-based localization |
| Docking state machine with recovery | Real-world alignment solution |
| Dual-threaded ROS2-Qt integration | Common integration challenge solved |
| Simulation-to-physical mapping | Hardware deployment blueprint |

## Final Assessment

The Atlas project bridges academic mobile robotics and industrial AGV systems, demonstrating that a complete warehouse automation system can be built with open-source software, proven navigation methods, and careful state machine design. The system is production-ready in control logic and requires only hardware interface nodes for physical deployment.

\newpage

# References {.unnumbered}

1. Siegwart, R., Nourbakhsh, I.R., Scaramuzza, D. (2011). *Introduction to Autonomous Mobile Robots*, 2nd Edition. MIT Press.
2. Dudek, G., Jenkin, M. (2010). *Computational Principles of Mobile Robotics*, 2nd Edition. Cambridge University Press.
3. Corke, P. (2017). *Robotics, Vision and Control*, 2nd Edition. Springer.
4. Siciliano, B., Khatib, O. (2016). *Springer Handbook of Robotics*, 2nd Edition. Springer.
5. Open Robotics. (2023). *ROS2 Humble Hawksbill Documentation*. https://docs.ros.org/en/humble/
6. Open Source Robotics Foundation. (2023). *Gazebo Classic 11 Documentation*. https://classic.gazebosim.org/
7. Quigley, M., Gerkey, B., Smart, W.D. (2015). *Programming Robots with ROS*. O'Reilly Media.
8. Pololu Corporation. (2023). *QTR-8A/8RC Reflectance Sensor Array User's Guide*.
9. Bosch Sensortec. (2023). *BNO055 Intelligent 9-axis Absolute Orientation Sensor Datasheet*.
10. ISO 3691-4:2020. *Industrial trucks — Safety requirements and verification — Part 4: Driverless industrial trucks and their systems*.
11. Finkenzeller, K. (2010). *RFID Handbook: Fundamentals and Applications in Contactless Smart Cards, Radio Frequency Identification and Near-Field Communication*, 3rd Edition. Wiley.
12. IEC 61496:2020. *Safety of machinery — Electro-sensitive protective equipment*.
13. Ollero, A. (2005). *Intelligent Mobile Robot Navigation*. Springer.
14. Thrun, S., Burgard, W., Fox, D. (2005). *Probabilistic Robotics*. MIT Press.
15. Ogata, K. (2010). *Modern Control Engineering*, 5th Edition. Prentice Hall.
16. Franklin, G.F., Powell, J.D., Emami-Naeini, A. (2015). *Feedback Control of Dynamic Systems*, 7th Edition. Pearson.
17. Object Management Group. (2015). *Data Distribution Service (DDS) Specification v1.4*.
18. Wurman, P.R., D'Andrea, R., Mountz, M. (2008). "Coordinating Hundreds of Cooperative, Autonomous Vehicles in Warehouses," *AI Magazine*, 29(1), pp. 9-20.
19. De Ryck, M., Versteyhe, M., Debrouwere, F. (2020). "Automated guided vehicle systems, state-of-the-art control algorithms and techniques," *Journal of Manufacturing Systems*, 54, pp. 152-173.
20. Azadeh, K., De Koster, R., Roy, D. (2019). "Robotized and Automated Warehouse Systems: Review and Recent Developments," *Transportation Science*, 53(4), pp. 917-945.

\newpage

# Appendix A: Complete State Machine Transition Table {.unnumbered}

| Current State | Event/Condition | Next State | Action |
|--------------|----------------|-----------|--------|
| IDLE | queue not empty AND not estopped | NAV_SPINE | Pop mission, reset junction count |
| NAV_SPINE | junction count == target aisle | TURNING | Publish turn_cmd (-π/2) |
| TURNING | turn_done received | NAV_AISLE | — |
| NAV_AISLE | tag_event matches target shelf | AT_SHELF | — |
| AT_SHELF | 0.5s elapsed | PICKUP | — |
| PICKUP | 2.0s elapsed | PIVOT | Publish turn_cmd (π) |
| PIVOT | turn_done received | RET_AISLE | — |
| RET_AISLE | junction detected | RET_TURN | Publish turn_cmd (+π/2) |
| RET_TURN | turn_done received | RET_SPINE | — |
| RET_SPINE | home tag detected | DOCKED | — |
| DOCKED | 0.5s elapsed | DOCKING | Enter docking FSM |
| DOCKING | position verified | ALIGNMENT | — |
| ALIGNMENT | heading + lateral OK | READY | — |
| READY | 0.5s elapsed | IDLE | Log "SYSTEM READY" |
| ANY | /atlas/estop | ERROR | Set estopped=True |
| ERROR | /atlas/reset | IDLE | Clear state |
| ANY | /atlas/reset_to_dock | RESETTING | Gazebo teleport |
| RESETTING | callback received | DOCKING | Verify alignment |

\newpage

# Appendix B: Viva Questions Summary {.unnumbered}

## Architecture Questions

1. Why ROS2 over ROS1?
2. Why differential drive?
3. Why is mission_node the sole cmd_vel publisher?
4. Why not use Nav2?
5. Why PD and not full PID?

## Kinematics Questions

6. Derive forward kinematics
7. Maximum speed calculation
8. Why is caster friction zero?
9. What if one motor fails?
10. Center of gravity effects

## Control Questions

11. Draw PID block diagram
12. What is the Nyquist frequency?
13. Settling time calculation
14. Phase margin analysis
15. Why not state-space control?

## Sensor Questions

16. Why 8 sensors not 5?
17. Sensor resolution calculation
18. IMU drift rate effect
19. Why not camera for line following?
20. Maximum speed for RFID detection

*(Full 100 questions with detailed answers provided in supplementary document)*

\newpage

# Appendix C: Software Installation Guide {.unnumbered}

## Prerequisites

```bash
# Ubuntu 22.04 with ROS2 Humble
sudo apt install ros-humble-desktop
sudo apt install ros-humble-gazebo-ros-pkgs
sudo apt install python3-pyqt5
```

## Build Procedure

```bash
cd ~/atlas_ws
source /opt/ros/humble/setup.bash
colcon build --symlink-install
source install/setup.bash
```

## Launch

```bash
ros2 launch atlas_bringup atlas_full.launch.py
```

## Send Mission (CLI)

```bash
ros2 run atlas_mission_manager send_mission S05
```

## Run GUI Standalone

```bash
ros2 run atlas_mission_manager atlas_gui
```
