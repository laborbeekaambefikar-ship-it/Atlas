"""
ATLAS Mission Manager — sole publisher on /atlas/cmd_vel.
Includes docking state machine for proper home alignment.
NEVER modifies robot pose directly. Movement ONLY through cmd_vel.
Uses Gazebo set_entity_state ONLY for hard reset (RESET AGV button).
"""
import math
import uuid
import rclpy
from rclpy.node import Node
from std_msgs.msg import Empty, Float32, String, Int8MultiArray
from geometry_msgs.msg import Twist
from nav_msgs.msg import Odometry
from sensor_msgs.msg import Imu
from atlas_interfaces.msg import FleetMission, RobotState, ShelfTag
from gazebo_msgs.srv import SetEntityState

# Shelf catalog
AISLE_Y = [2, 4, 6, 8, 10]
SHELF_X = [1.0, 2.0, 3.0, 4.0]
SHELVES = {}
_i = 1
for ay in AISLE_Y:
    for sx in SHELF_X:
        SHELVES[f'S{_i:02d}'] = (sx, float(ay), (AISLE_Y.index(ay) + 1))
        _i += 1

# === Mission States ===
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

# === Docking States ===
S_RETURNING_HOME = 'RETURNING_HOME'
S_DOCKING = 'DOCKING'
S_ALIGNMENT = 'ALIGNMENT'
S_READY = 'READY'
S_RECOVERY_DOCKING = 'RECOVERY_DOCKING'
S_RESETTING = 'RESETTING'

# === Docking Parameters ===
HOME_X = 0.0
HOME_Y = 0.0
HOME_YAW = math.pi / 2.0  # 90 degrees (spawn orientation)
DOCK_SPEED = 0.15  # Slow approach speed
DOCK_POSITION_TOL = 0.05  # 5cm position tolerance
DOCK_YAW_TOL = math.radians(3.0)  # 3 degree heading tolerance
DOCK_LATERAL_TOL = 0.03  # 3cm lateral tolerance
ALIGNMENT_KP = 2.0  # Proportional gain for alignment correction
RECOVERY_ROTATE_SPEED = 0.3  # rad/s for tape search rotation
LINE_CENTER_WEIGHTS = [0.07, 0.05, 0.03, 0.01, -0.01, -0.03, -0.05, -0.07]


def _quat_to_yaw(q):
    return math.atan2(2.0 * (q.w * q.z + q.x * q.y),
                      1.0 - 2.0 * (q.y * q.y + q.z * q.z))


def _wrap_angle(a):
    return math.atan2(math.sin(a), math.cos(a))


class MissionManager(Node):
    def __init__(self):
        super().__init__('atlas_mission_manager')
        # === Subscriptions ===
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
        self.create_subscription(Int8MultiArray, '/atlas/line_sensors', self._line_cb, 10)
        self.create_subscription(Imu, '/atlas/imu', self._imu_cb, 10)

        # === Publishers ===
        self.pub_cmd = self.create_publisher(Twist, '/atlas/cmd_vel', 10)
        self.pub_turn = self.create_publisher(Float32, '/atlas/turn_cmd', 10)
        self.pub_state = self.create_publisher(RobotState, '/atlas/robot_state', 10)
        self.pub_log = self.create_publisher(String, '/atlas/log', 50)

        # === Gazebo service client ===
        self.set_entity_client = self.create_client(
            SetEntityState, '/set_entity_state')

        # === Timers ===
        self.create_timer(1.0 / 50.0, self._tick)
        self.create_timer(1.0 / 10.0, self._pub_status)

        # === State variables ===
        self.state = S_IDLE
        self.queue = []
        self.active = None
        self.nav_tw = Twist()
        self.turn_tw = Twist()
        self.junc_count = 0
        self.x = 0.0
        self.y = 0.0
        self.yaw = 0.0
        self.battery = 100.0
        self.carrying = False
        self.last_tag = ''
        self.estopped = False
        self.state_t = self._now()

        # === Line sensor state ===
        self.line_bits = [0] * 8
        self.line_detected = False
        self.line_error = 0.0  # lateral offset from center

        # === Docking state ===
        self.dock_state = ''
        self.dock_attempt = 0
        self.recovery_rotate_dir = 1.0

        self.get_logger().info('MissionManager ready (with docking FSM)')

    def _now(self):
        return self.get_clock().now().nanoseconds * 1e-9

    def _log(self, s):
        self.get_logger().info(s)
        m = String()
        m.data = s
        self.pub_log.publish(m)

    def _go(self, ns):
        if ns != self.state:
            self._log(f'STATE {self.state} -> {ns}')
            self.state = ns
            self.state_t = self._now()

    # === Callbacks ===

    def _nav_cb(self, msg):
        self.nav_tw = msg

    def _turn_cb(self, msg):
        self.turn_tw = msg

    def _odom(self, msg):
        self.x = msg.pose.pose.position.x
        self.y = msg.pose.pose.position.y
        self.yaw = _quat_to_yaw(msg.pose.pose.orientation)

    def _imu_cb(self, msg):
        self.yaw = _quat_to_yaw(msg.orientation)

    def _line_cb(self, msg):
        self.line_bits = list(msg.data)
        total = sum(self.line_bits)
        self.line_detected = total > 0
        if total > 0:
            self.line_error = sum(
                LINE_CENTER_WEIGHTS[i] * self.line_bits[i]
                for i in range(8)) / total
        else:
            self.line_error = 0.0

    def _mission_in(self, msg):
        if msg.target_shelf not in SHELVES:
            self._log(f'Rejected unknown shelf {msg.target_shelf}')
            return
        if not msg.mission_id:
            msg.mission_id = f'm-{uuid.uuid4().hex[:6]}'
        self.queue.append(msg)
        self._log(f'Queued {msg.mission_id} -> {msg.target_shelf}')

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
        """Hard reset: physically respawn robot at home dock via Gazebo."""
        self._log('RESET AGV REQUESTED — performing physical reset')
        # Stop everything
        self.estopped = False
        self.queue = []
        self.active = None
        self.carrying = False
        self.pub_cmd.publish(Twist())
        # Enter resetting state
        self._go(S_RESETTING)
        # Call Gazebo to physically move robot
        self._gazebo_reset_entity()

    def _gazebo_reset_entity(self):
        """Reset robot position in Gazebo via set_entity_state service."""
        if not self.set_entity_client.service_is_ready():
            self._log('WARNING: Gazebo set_entity_state not available, entering docking')
            self._go(S_RETURNING_HOME)
            return

        from gazebo_msgs.msg import EntityState
        req = SetEntityState.Request()
        state = EntityState()
        state.name = 'atlas_agv'
        state.pose.position.x = HOME_X
        state.pose.position.y = HOME_Y
        state.pose.position.z = 0.01
        # yaw = pi/2 quaternion: z=sin(pi/4), w=cos(pi/4)
        state.pose.orientation.x = 0.0
        state.pose.orientation.y = 0.0
        state.pose.orientation.z = 0.7071068
        state.pose.orientation.w = 0.7071068
        state.twist = Twist()
        state.reference_frame = 'world'
        req.state = state

        future = self.set_entity_client.call_async(req)
        future.add_done_callback(self._reset_done_callback)

    def _reset_done_callback(self, future):
        """Called when Gazebo reset completes."""
        try:
            future.result()
            self._log('Gazebo reset successful — entering DOCKING verification')
        except Exception as e:
            self._log(f'Gazebo reset failed: {e}')
        # After physical reset, enter docking to verify alignment
        self._go(S_DOCKING)
        self.dock_state = 'verifying'
        self.dock_attempt = 0

    def _junction(self, _):
        if self.state == S_NAV_SPINE:
            self.junc_count += 1
            target_aisle = SHELVES[self.active.target_shelf][2]
            self._log(f'Junction #{self.junc_count}/{target_aisle}')
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
        elif self.state == S_RETURNING_HOME and ev.is_home:
            self._go(S_DOCKING)
            self.dock_state = 'approaching'

    # === Main tick ===

    def _tick(self):
        now = self._now()
        dt = now - self.state_t

        # --- Normal mission states ---
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

        elif self.state == S_DOCKED and dt > 0.5:
            # Instead of going straight to IDLE, enter docking verification
            self.carrying = False
            self.battery = 100.0
            self.active = None
            self._go(S_DOCKING)
            self.dock_state = 'verifying'
            self.dock_attempt = 0

        # --- Docking state machine ---
        elif self.state == S_RESETTING:
            # Waiting for Gazebo callback — publish zero velocity
            pass

        elif self.state == S_RETURNING_HOME:
            # Use line follower to navigate back to home tag
            pass  # nav_vel drives this, home tag triggers S_DOCKING

        elif self.state == S_DOCKING:
            self._tick_docking(dt)

        elif self.state == S_ALIGNMENT:
            self._tick_alignment(dt)

        elif self.state == S_RECOVERY_DOCKING:
            self._tick_recovery(dt)

        elif self.state == S_READY:
            # Robot is perfectly docked — transition to IDLE after brief pause
            if dt > 0.5:
                self._log('SYSTEM READY — accepting missions')
                self._go(S_IDLE)

        # --- Velocity output ---
        out = Twist()
        if self.state in (S_NAV_SPINE, S_NAV_AISLE, S_RET_AISLE, S_RET_SPINE,
                          S_RETURNING_HOME):
            out = self.nav_tw
        elif self.state in (S_TURNING, S_PIVOT, S_RET_TURN):
            out = self.turn_tw
        elif self.state in (S_DOCKING, S_ALIGNMENT, S_RECOVERY_DOCKING):
            out = self._get_dock_velocity()
        # E-stop overrides everything
        if self.estopped:
            out = Twist()
        self.pub_cmd.publish(out)

    def _tick_docking(self, dt):
        """Docking state: verify position and heading at home."""
        dist_to_home = math.hypot(self.x - HOME_X, self.y - HOME_Y)
        yaw_err = abs(_wrap_angle(self.yaw - HOME_YAW))
        lateral_err = abs(self.x - HOME_X)  # x offset from spine

        if self.dock_state == 'verifying':
            # Check if already well-positioned (e.g., after Gazebo reset)
            if (dist_to_home < DOCK_POSITION_TOL and
                    yaw_err < DOCK_YAW_TOL and
                    lateral_err < DOCK_LATERAL_TOL):
                self._log('Dock verified — position OK')
                self._go(S_ALIGNMENT)
                self.dock_state = 'final_check'
            elif dt > 1.0:
                # Not well-positioned, need alignment
                self._log(f'Dock check: dist={dist_to_home:.3f} yaw_err={math.degrees(yaw_err):.1f} lat={lateral_err:.3f}')
                if self.line_detected:
                    self._go(S_ALIGNMENT)
                    self.dock_state = 'centering'
                else:
                    self._go(S_RECOVERY_DOCKING)
                    self.dock_state = 'searching'

        elif self.dock_state == 'approaching':
            # Approaching home at dock speed using line data
            if dist_to_home < DOCK_POSITION_TOL:
                self._go(S_ALIGNMENT)
                self.dock_state = 'centering'

    def _tick_alignment(self, dt):
        """Fine-tune centering on tape and heading correction."""
        yaw_err = abs(_wrap_angle(self.yaw - HOME_YAW))
        lateral_err = abs(self.x - HOME_X)

        if self.dock_state == 'final_check':
            # Quick verification after Gazebo reset
            if dt > 0.3:
                if (yaw_err < DOCK_YAW_TOL and
                        lateral_err < DOCK_LATERAL_TOL and
                        self.line_detected):
                    self._log('ALIGNMENT VERIFIED — docking complete')
                    self._go(S_READY)
                elif self.line_detected:
                    self.dock_state = 'centering'
                else:
                    self._go(S_RECOVERY_DOCKING)
                    self.dock_state = 'searching'

        elif self.dock_state == 'centering':
            # Use line sensor to center
            if (yaw_err < DOCK_YAW_TOL and
                    lateral_err < DOCK_LATERAL_TOL and
                    abs(self.line_error) < 0.1):
                self._log('ALIGNMENT COMPLETE')
                self._go(S_READY)
            elif dt > 5.0:
                # Timeout — accept if close enough
                self.dock_attempt += 1
                if self.dock_attempt >= 3:
                    self._log('Alignment timeout — accepting position')
                    self._go(S_READY)
                else:
                    self._log(f'Alignment retry #{self.dock_attempt}')
                    self.dock_state = 'centering'
                    self.state_t = self._now()

    def _tick_recovery(self, dt):
        """Recovery: rotate to find tape, then re-center."""
        if self.dock_state == 'searching':
            if self.line_detected:
                self._log('TAPE REACQUIRED — entering alignment')
                self._go(S_ALIGNMENT)
                self.dock_state = 'centering'
            elif dt > 6.0:
                # Searched too long — switch direction
                self.recovery_rotate_dir *= -1.0
                self.dock_attempt += 1
                if self.dock_attempt >= 4:
                    self._log('Recovery failed — forcing READY state')
                    self._go(S_READY)
                else:
                    self.state_t = self._now()

    def _get_dock_velocity(self):
        """Compute velocity command for docking/alignment states."""
        tw = Twist()

        if self.state == S_DOCKING and self.dock_state == 'approaching':
            # Slow forward approach with line centering
            tw.linear.x = DOCK_SPEED
            if self.line_detected:
                tw.angular.z = -ALIGNMENT_KP * self.line_error
            return tw

        elif self.state == S_ALIGNMENT and self.dock_state == 'centering':
            # Pure rotation/lateral correction
            yaw_err = _wrap_angle(self.yaw - HOME_YAW)
            if abs(yaw_err) > DOCK_YAW_TOL:
                # Correct heading first
                tw.angular.z = -1.5 * yaw_err
                tw.angular.z = max(-0.3, min(0.3, tw.angular.z))
            elif self.line_detected and abs(self.line_error) > 0.05:
                # Correct lateral offset
                tw.angular.z = -ALIGNMENT_KP * self.line_error * 0.5
                tw.linear.x = 0.05  # Creep forward
            return tw

        elif self.state == S_RECOVERY_DOCKING and self.dock_state == 'searching':
            # Rotate slowly to find tape
            tw.angular.z = self.recovery_rotate_dir * RECOVERY_ROTATE_SPEED
            return tw

        return tw

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
