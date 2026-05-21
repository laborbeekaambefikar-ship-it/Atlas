"""ROS2 <-> Qt bridge for the ATLAS Fleet Control Center.

Runs the rclpy spin loop in a daemon thread and forwards everything
to the Qt main thread via :class:`PyQt5.QtCore.pyqtSignal`.

All callbacks are wrapped in try/except so a malformed message, a
schema change, or a temporarily missing topic will never crash the
GUI.  Subscriptions and publishers are recreated transparently when
peer nodes restart because rclpy/DDS handles re-discovery for us.
"""

import math
import threading
import time
import uuid

import rclpy
from PyQt5.QtCore import QObject, pyqtSignal


# These imports are wrapped because some message packages may not be
# present on every machine where the GUI is launched (e.g. when only
# parts of the workspace are built).  The GUI must still come up.
try:
    from std_msgs.msg import Empty, String
except Exception:  # pragma: no cover - extremely unlikely
    Empty = None
    String = None

try:
    from nav_msgs.msg import Odometry
except Exception:
    Odometry = None

try:
    from atlas_interfaces.msg import FleetMission, RobotState, ShelfTag
except Exception:
    FleetMission = None
    RobotState = None
    ShelfTag = None


class RosBridge(QObject):
    """Background ROS2 worker that emits Qt signals on each event."""

    # mission_id, target_shelf, sku, current_state, battery, last_tag,
    # carrying, current_sku
    state_signal = pyqtSignal(str, str, str, str, float, str, bool, str)
    odom_signal = pyqtSignal(float, float, float, float, float)  # x, y, yaw, vx, wz
    log_signal = pyqtSignal(str)
    tag_signal = pyqtSignal(str, str, bool)  # tag_id, shelf_id, is_home
    connection_signal = pyqtSignal(bool)
    mission_sent_signal = pyqtSignal(str, str, str, int)  # id, shelf, sku, prio

    def __init__(self):
        super().__init__()
        self._stop = False
        self._spin_thread = None
        self._wd_thread = None
        self.node = None

        self._last_state_t = 0.0
        self._last_odom_t = 0.0
        self._connected = False

        self.pub_mission = None
        self.pub_estop = None
        self.pub_reset = None
        self.pub_reset_dock = None

        self._init_ros()

    # ------------------------------------------------------------------
    # initialisation
    # ------------------------------------------------------------------
    def _init_ros(self):
        try:
            if not rclpy.ok():
                rclpy.init(args=None)
            self.node = rclpy.create_node("atlas_gui")

            if RobotState is not None:
                self.node.create_subscription(
                    RobotState, "/atlas/robot_state", self._on_state, 10
                )
            if Odometry is not None:
                self.node.create_subscription(
                    Odometry, "/atlas/odom", self._on_odom, 50
                )
            if String is not None:
                self.node.create_subscription(
                    String, "/atlas/log", self._on_log, 50
                )
            if ShelfTag is not None:
                self.node.create_subscription(
                    ShelfTag, "/atlas/tag_event", self._on_tag, 10
                )

            if FleetMission is not None:
                self.pub_mission = self.node.create_publisher(
                    FleetMission, "/atlas/mission_cmd", 10
                )
            if Empty is not None:
                self.pub_estop = self.node.create_publisher(
                    Empty, "/atlas/estop", 10
                )
                self.pub_reset = self.node.create_publisher(
                    Empty, "/atlas/reset", 10
                )
                self.pub_reset_dock = self.node.create_publisher(
                    Empty, "/atlas/reset_to_dock", 10
                )

            self._spin_thread = threading.Thread(
                target=self._spin_loop, daemon=True, name="atlas-gui-spin"
            )
            self._spin_thread.start()

            self._wd_thread = threading.Thread(
                target=self._watchdog_loop, daemon=True, name="atlas-gui-wd"
            )
            self._wd_thread.start()

        except Exception as ex:
            print("[atlas_gui] ROS init error: %s" % ex, flush=True)

    # ------------------------------------------------------------------
    # background loops
    # ------------------------------------------------------------------
    def _spin_loop(self):
        while not self._stop:
            try:
                if rclpy.ok() and self.node is not None:
                    rclpy.spin_once(self.node, timeout_sec=0.05)
                else:
                    time.sleep(0.2)
            except Exception as ex:
                # Keep going so the GUI never crashes.
                print("[atlas_gui] spin error: %s" % ex, flush=True)
                time.sleep(0.2)

    def _watchdog_loop(self):
        while not self._stop:
            try:
                now = time.time()
                fresh_state = (now - self._last_state_t) < 3.0
                fresh_odom = (now - self._last_odom_t) < 3.0
                connected = bool(fresh_state or fresh_odom)
                if connected != self._connected:
                    self._connected = connected
                    self.connection_signal.emit(connected)
            except Exception:
                pass
            time.sleep(0.5)

    # ------------------------------------------------------------------
    # subscription callbacks (run in spin thread)
    # ------------------------------------------------------------------
    def _on_state(self, msg):
        try:
            self._last_state_t = time.time()
            state = getattr(msg, "state", "") or ""
            mission_id = getattr(msg, "mission_id", "") or ""
            target_shelf = getattr(msg, "target_shelf", "") or ""
            current_sku = getattr(msg, "current_sku", "") or ""
            last_tag = getattr(msg, "last_tag", "") or ""
            carrying = bool(getattr(msg, "carrying_load", False))
            battery = float(getattr(msg, "battery_percent", 0.0))
            self.state_signal.emit(
                mission_id, target_shelf, current_sku, state,
                battery, last_tag, carrying, current_sku,
            )
        except Exception as ex:
            print("[atlas_gui] state decode error: %s" % ex, flush=True)

    def _on_odom(self, msg):
        try:
            self._last_odom_t = time.time()
            x = float(msg.pose.pose.position.x)
            y = float(msg.pose.pose.position.y)
            q = msg.pose.pose.orientation
            siny = 2.0 * (q.w * q.z + q.x * q.y)
            cosy = 1.0 - 2.0 * (q.y * q.y + q.z * q.z)
            yaw = math.atan2(siny, cosy)
            vx = float(msg.twist.twist.linear.x)
            wz = float(msg.twist.twist.angular.z)
            self.odom_signal.emit(x, y, yaw, vx, wz)
        except Exception as ex:
            print("[atlas_gui] odom decode error: %s" % ex, flush=True)

    def _on_log(self, msg):
        try:
            text = getattr(msg, "data", "") or ""
            if text:
                self.log_signal.emit(text)
        except Exception as ex:
            print("[atlas_gui] log decode error: %s" % ex, flush=True)

    def _on_tag(self, msg):
        try:
            tag_id = getattr(msg, "tag_id", "") or ""
            shelf_id = getattr(msg, "shelf_id", "") or ""
            is_home = bool(getattr(msg, "is_home", False))
            self.tag_signal.emit(tag_id, shelf_id, is_home)
        except Exception as ex:
            print("[atlas_gui] tag decode error: %s" % ex, flush=True)

    # ------------------------------------------------------------------
    # publishers (called from Qt main thread)
    # ------------------------------------------------------------------
    def send_mission(self, shelf, sku, priority):
        if self.pub_mission is None or FleetMission is None:
            return ""
        try:
            m = FleetMission()
            m.mission_id = "gui-" + uuid.uuid4().hex[:6]
            m.target_shelf = str(shelf)
            m.sku = str(sku)
            m.priority = int(priority)
            self.pub_mission.publish(m)
            self.mission_sent_signal.emit(
                m.mission_id, str(shelf), str(sku), int(priority)
            )
            return m.mission_id
        except Exception as ex:
            print("[atlas_gui] publish mission failed: %s" % ex, flush=True)
            return ""

    def _publish_empty(self, pub):
        if pub is None or Empty is None:
            return False
        try:
            pub.publish(Empty())
            return True
        except Exception as ex:
            print("[atlas_gui] publish empty failed: %s" % ex, flush=True)
            return False

    def send_estop(self):
        return self._publish_empty(self.pub_estop)

    def send_reset_estop(self):
        return self._publish_empty(self.pub_reset)

    def send_return_home(self):
        return self._publish_empty(self.pub_reset_dock)

    def send_reset_agv(self):
        return self._publish_empty(self.pub_reset_dock)

    # ------------------------------------------------------------------
    def shutdown(self):
        self._stop = True
        try:
            if self.node is not None:
                self.node.destroy_node()
        except Exception:
            pass
        try:
            if rclpy.ok():
                rclpy.shutdown()
        except Exception:
            pass
