"""
ATLAS Fleet Control Center — PyQt5 Industrial Dashboard
ROS2 Humble compatible GUI for Atlas Warehouse AGV system.
Includes docking state indicators and proper RESET AGV with physical recovery.
"""
import sys
import math
import uuid
import threading
from datetime import datetime

from PyQt5.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QGridLayout, QGroupBox, QLabel, QPushButton, QComboBox,
    QTableWidget, QTableWidgetItem, QPlainTextEdit, QSplitter,
    QMessageBox, QHeaderView, QFrame, QSpinBox
)
from PyQt5.QtCore import Qt, QTimer, pyqtSignal, QObject
from PyQt5.QtGui import QFont, QColor

import rclpy
from rclpy.node import Node
from std_msgs.msg import Empty, String
from geometry_msgs.msg import Twist
from nav_msgs.msg import Odometry
from atlas_interfaces.msg import FleetMission, RobotState, ShelfTag
from gazebo_msgs.srv import SetEntityState


DARK_STYLE = """
QMainWindow { background-color: #1a1a2e; }
QWidget { background-color: #1a1a2e; color: #e0e0e0; font-size: 11px; }
QGroupBox {
    border: 1px solid #3a3a5c;
    border-radius: 4px;
    margin-top: 8px;
    padding-top: 12px;
    font-weight: bold;
    color: #00d4aa;
}
QGroupBox::title { subcontrol-origin: margin; left: 10px; padding: 0 4px; }
QPushButton {
    background-color: #2d2d4e;
    border: 1px solid #4a4a7a;
    border-radius: 4px;
    padding: 6px 12px;
    color: #e0e0e0;
    font-weight: bold;
    min-height: 28px;
}
QPushButton:hover { background-color: #3d3d6e; border-color: #00d4aa; }
QPushButton:pressed { background-color: #4d4d8e; }
QPushButton#estop {
    background-color: #8b0000;
    border-color: #ff0000;
    color: #ffffff;
    font-size: 14px;
    min-height: 40px;
}
QPushButton#estop:hover { background-color: #aa0000; }
QPushButton#reset_agv {
    background-color: #8b4500;
    border-color: #ff8c00;
    color: #ffffff;
    font-size: 12px;
    min-height: 36px;
}
QPushButton#reset_agv:hover { background-color: #aa5500; }
QPushButton#dispatch {
    background-color: #004d00;
    border-color: #00aa00;
    color: #ffffff;
}
QPushButton#dispatch:hover { background-color: #006600; }
QComboBox {
    background-color: #2d2d4e;
    border: 1px solid #4a4a7a;
    border-radius: 3px;
    padding: 4px;
    color: #e0e0e0;
}
QComboBox::drop-down { border: none; background: #3d3d6e; width: 20px; }
QComboBox QAbstractItemView { background-color: #2d2d4e; color: #e0e0e0; }
QSpinBox {
    background-color: #2d2d4e;
    border: 1px solid #4a4a7a;
    border-radius: 3px;
    padding: 4px;
    color: #e0e0e0;
}
QTableWidget {
    background-color: #12122a;
    gridline-color: #3a3a5c;
    border: 1px solid #3a3a5c;
    color: #e0e0e0;
}
QTableWidget::item { padding: 4px; }
QHeaderView::section {
    background-color: #2d2d4e;
    color: #00d4aa;
    border: 1px solid #3a3a5c;
    padding: 4px;
    font-weight: bold;
}
QPlainTextEdit {
    background-color: #0a0a1a;
    border: 1px solid #3a3a5c;
    color: #b0ffb0;
    font-family: 'Courier New', monospace;
    font-size: 10px;
}
QLabel#status_value { color: #00d4aa; font-weight: bold; }
QLabel#header {
    color: #00d4aa;
    font-size: 16px;
    font-weight: bold;
    padding: 4px;
}
QFrame#separator { background-color: #3a3a5c; }
"""

# Shelf catalog matching mission_node.py exactly
AISLE_Y = [2, 4, 6, 8, 10]
SHELF_X = [1.0, 2.0, 3.0, 4.0]
SHELF_LIST = []
_i = 1
for _ay in AISLE_Y:
    for _sx in SHELF_X:
        SHELF_LIST.append(f'S{_i:02d}')
        _i += 1

SKU_LIST = [
    'SKU-001', 'SKU-002', 'SKU-003', 'SKU-004', 'SKU-005',
    'SKU-010', 'SKU-020', 'SKU-050', 'SKU-100', 'SKU-200',
]

# State color mapping
STATE_COLORS = {
    'IDLE': '#88ff88',
    'READY': '#00ff00',
    'NAV_SPINE': '#44aaff',
    'NAV_AISLE': '#44aaff',
    'TURNING': '#44aaff',
    'RET_AISLE': '#44aaff',
    'RET_TURN': '#44aaff',
    'RET_SPINE': '#44aaff',
    'RETURNING_HOME': '#4488ff',
    'DOCKING': '#ffcc00',
    'ALIGNMENT': '#ffcc00',
    'RECOVERY_DOCKING': '#ff8800',
    'RESETTING': '#ff8800',
    'AT_SHELF': '#00d4aa',
    'PICKUP': '#00d4aa',
    'PIVOT': '#00d4aa',
    'DOCKED': '#00d4aa',
    'ERROR': '#ff4444',
}


class SignalBridge(QObject):
    """Thread-safe signal bridge for ROS callbacks to Qt updates."""
    state_update = pyqtSignal(object)
    log_update = pyqtSignal(str)
    odom_update = pyqtSignal(float, float, float, float, float)
    tag_update = pyqtSignal(str, str)
    connection_update = pyqtSignal(bool)


class AtlasRosNode(Node):
    """ROS2 node for GUI communication."""

    def __init__(self, signals):
        super().__init__('atlas_control_center')
        self.signals = signals
        self._last_state_time = 0.0

        # Subscribers
        self.create_subscription(RobotState, '/atlas/robot_state', self._state_cb, 10)
        self.create_subscription(String, '/atlas/log', self._log_cb, 50)
        self.create_subscription(Odometry, '/atlas/odom', self._odom_cb, 10)
        self.create_subscription(ShelfTag, '/atlas/tag_event', self._tag_cb, 10)

        # Publishers
        self.pub_mission = self.create_publisher(FleetMission, '/atlas/mission_cmd', 10)
        self.pub_estop = self.create_publisher(Empty, '/atlas/estop', 10)
        self.pub_reset = self.create_publisher(Empty, '/atlas/reset', 10)
        self.pub_reset_dock = self.create_publisher(Empty, '/atlas/reset_to_dock', 10)
        self.pub_cmd_vel = self.create_publisher(Twist, '/atlas/cmd_vel', 10)

        # Connection watchdog
        self.create_timer(2.0, self._check_connection)
        self.get_logger().info('Atlas Control Center node started')

    def _state_cb(self, msg):
        self._last_state_time = self.get_clock().now().nanoseconds * 1e-9
        try:
            self.signals.state_update.emit(msg)
        except Exception:
            pass

    def _log_cb(self, msg):
        try:
            self.signals.log_update.emit(msg.data)
        except Exception:
            pass

    def _odom_cb(self, msg):
        try:
            x = msg.pose.pose.position.x
            y = msg.pose.pose.position.y
            q = msg.pose.pose.orientation
            yaw = math.atan2(2.0*(q.w*q.z + q.x*q.y), 1.0 - 2.0*(q.y*q.y + q.z*q.z))
            vx = msg.twist.twist.linear.x
            wz = msg.twist.twist.angular.z
            self.signals.odom_update.emit(x, y, yaw, vx, wz)
        except Exception:
            pass

    def _tag_cb(self, msg):
        try:
            self.signals.tag_update.emit(msg.tag_id, msg.shelf_id)
        except Exception:
            pass

    def _check_connection(self):
        now = self.get_clock().now().nanoseconds * 1e-9
        connected = (now - self._last_state_time) < 3.0
        try:
            self.signals.connection_update.emit(connected)
        except Exception:
            pass

    def send_mission(self, shelf, sku, priority):
        msg = FleetMission()
        msg.mission_id = f'gui-{uuid.uuid4().hex[:6]}'
        msg.target_shelf = shelf
        msg.sku = sku
        msg.priority = priority
        self.pub_mission.publish(msg)
        self.get_logger().info(f'Dispatched {msg.mission_id} -> {shelf}')
        return msg.mission_id

    def send_estop(self):
        self.pub_estop.publish(Empty())
        self.get_logger().warn('E-STOP ACTIVATED')

    def send_reset_estop(self):
        self.pub_reset.publish(Empty())
        self.get_logger().info('E-Stop reset')

    def send_reset_to_dock(self):
        """Full AGV reset: publishes to /atlas/reset_to_dock.
        The mission_node handles the actual Gazebo reset + docking sequence."""
        # Stop robot immediately from GUI side
        self.pub_cmd_vel.publish(Twist())
        # Publish reset_to_dock — mission_node does the physical reset
        self.pub_reset_dock.publish(Empty())
        self.get_logger().warn('RESET AGV: Physical reset requested')

    def send_return_home(self):
        self.pub_reset.publish(Empty())
        self.get_logger().info('Return Home requested')


class AtlasControlCenter(QMainWindow):
    """Main GUI window."""

    def __init__(self, ros_node, signals):
        super().__init__()
        self.node = ros_node
        self.signals = signals
        self.setWindowTitle('ATLAS Fleet Control Center')
        self.setMinimumSize(1200, 800)
        self.resize(1400, 900)

        self._state = 'IDLE'
        self._x = 0.0
        self._y = 0.0
        self._yaw = 0.0
        self._vx = 0.0
        self._wz = 0.0
        self._connected = False

        self._build_ui()
        self._connect_signals()

    def _build_ui(self):
        central = QWidget()
        self.setCentralWidget(central)
        main_layout = QVBoxLayout(central)
        main_layout.setContentsMargins(8, 8, 8, 8)
        main_layout.setSpacing(6)

        header = QLabel('ATLAS FLEET CONTROL CENTER')
        header.setObjectName('header')
        header.setAlignment(Qt.AlignCenter)
        main_layout.addWidget(header)

        splitter = QSplitter(Qt.Horizontal)
        main_layout.addWidget(splitter)

        # Left panel
        left = QWidget()
        left_layout = QVBoxLayout(left)
        left_layout.setContentsMargins(4, 4, 4, 4)
        left_layout.setSpacing(6)
        left_layout.addWidget(self._build_mission_panel())
        left_layout.addWidget(self._build_control_panel())
        left_layout.addWidget(self._build_emergency_panel())
        left_layout.addStretch()
        splitter.addWidget(left)

        # Center panel
        center = QWidget()
        center_layout = QVBoxLayout(center)
        center_layout.setContentsMargins(4, 4, 4, 4)
        center_layout.setSpacing(6)
        center_layout.addWidget(self._build_status_panel())
        center_layout.addWidget(self._build_docking_panel())
        center_layout.addWidget(self._build_queue_panel())
        splitter.addWidget(center)

        # Right panel
        right = QWidget()
        right_layout = QVBoxLayout(right)
        right_layout.setContentsMargins(4, 4, 4, 4)
        right_layout.setSpacing(6)
        right_layout.addWidget(self._build_log_panel())
        splitter.addWidget(right)

        splitter.setSizes([320, 500, 400])

    def _build_mission_panel(self):
        group = QGroupBox('Mission Creation')
        layout = QGridLayout(group)
        layout.addWidget(QLabel('Target Shelf:'), 0, 0)
        self.combo_shelf = QComboBox()
        self.combo_shelf.addItems(SHELF_LIST)
        layout.addWidget(self.combo_shelf, 0, 1)
        layout.addWidget(QLabel('SKU:'), 1, 0)
        self.combo_sku = QComboBox()
        self.combo_sku.addItems(SKU_LIST)
        self.combo_sku.setEditable(True)
        layout.addWidget(self.combo_sku, 1, 1)
        layout.addWidget(QLabel('Priority:'), 2, 0)
        self.spin_priority = QSpinBox()
        self.spin_priority.setRange(1, 10)
        self.spin_priority.setValue(1)
        layout.addWidget(self.spin_priority, 2, 1)
        btn_dispatch = QPushButton('DISPATCH MISSION')
        btn_dispatch.setObjectName('dispatch')
        btn_dispatch.clicked.connect(self._on_dispatch)
        layout.addWidget(btn_dispatch, 3, 0, 1, 2)
        return group

    def _build_control_panel(self):
        group = QGroupBox('Mission Control')
        layout = QVBoxLayout(group)
        for text, handler in [('Pause Mission', self._on_pause),
                              ('Resume Mission', self._on_resume),
                              ('Cancel Mission', self._on_cancel),
                              ('Return Home', self._on_return_home)]:
            btn = QPushButton(text)
            btn.clicked.connect(handler)
            layout.addWidget(btn)
        return group

    def _build_emergency_panel(self):
        group = QGroupBox('Emergency Controls')
        layout = QVBoxLayout(group)
        btn_estop = QPushButton('EMERGENCY STOP')
        btn_estop.setObjectName('estop')
        btn_estop.clicked.connect(self._on_estop)
        layout.addWidget(btn_estop)
        btn_reset_estop = QPushButton('Reset E-Stop')
        btn_reset_estop.clicked.connect(self._on_reset_estop)
        layout.addWidget(btn_reset_estop)
        sep = QFrame()
        sep.setFrameShape(QFrame.HLine)
        sep.setObjectName('separator')
        layout.addWidget(sep)
        btn_reset_agv = QPushButton('RESET AGV TO DOCK')
        btn_reset_agv.setObjectName('reset_agv')
        btn_reset_agv.clicked.connect(self._on_reset_agv)
        layout.addWidget(btn_reset_agv)
        return group

    def _build_status_panel(self):
        group = QGroupBox('Robot Status')
        layout = QGridLayout(group)
        self.status_labels = {}
        fields = [
            ('State', 'state'), ('Mission', 'mission'),
            ('Target Shelf', 'shelf'), ('SKU', 'sku'),
            ('Position', 'position'), ('Heading', 'heading'),
            ('Velocity', 'velocity'), ('Last RFID', 'rfid'),
            ('Battery', 'battery'), ('Carrying', 'carrying'),
            ('Connection', 'connection'),
        ]
        for row, (label_text, key) in enumerate(fields):
            lbl = QLabel(f'{label_text}:')
            lbl.setStyleSheet('color: #888;')
            layout.addWidget(lbl, row, 0)
            val = QLabel('---')
            val.setObjectName('status_value')
            layout.addWidget(val, row, 1)
            self.status_labels[key] = val
        return group

    def _build_docking_panel(self):
        """Docking state indicators."""
        group = QGroupBox('Docking Status')
        layout = QGridLayout(group)
        self.dock_labels = {}
        fields = [
            ('Dock State', 'dock_state'),
            ('Line Detected', 'line_detected'),
            ('Alignment', 'alignment'),
            ('Home Reached', 'home_reached'),
            ('Ready', 'ready_status'),
        ]
        for row, (label_text, key) in enumerate(fields):
            lbl = QLabel(f'{label_text}:')
            lbl.setStyleSheet('color: #888;')
            layout.addWidget(lbl, row, 0)
            val = QLabel('---')
            val.setStyleSheet('font-weight: bold;')
            layout.addWidget(val, row, 1)
            self.dock_labels[key] = val
        return group

    def _build_queue_panel(self):
        group = QGroupBox('Mission Queue')
        layout = QVBoxLayout(group)
        self.queue_table = QTableWidget(0, 4)
        self.queue_table.setHorizontalHeaderLabels(
            ['Mission ID', 'Shelf', 'SKU', 'Priority'])
        self.queue_table.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)
        self.queue_table.setSelectionBehavior(QTableWidget.SelectRows)
        layout.addWidget(self.queue_table)
        return group

    def _build_log_panel(self):
        group = QGroupBox('Event Log')
        layout = QVBoxLayout(group)
        self.log_text = QPlainTextEdit()
        self.log_text.setReadOnly(True)
        self.log_text.setMaximumBlockCount(500)
        layout.addWidget(self.log_text)
        btn_clear = QPushButton('Clear Log')
        btn_clear.clicked.connect(self.log_text.clear)
        layout.addWidget(btn_clear)
        return group

    def _connect_signals(self):
        self.signals.state_update.connect(self._on_state_update)
        self.signals.log_update.connect(self._on_log_update)
        self.signals.odom_update.connect(self._on_odom_update)
        self.signals.tag_update.connect(self._on_tag_update)
        self.signals.connection_update.connect(self._on_connection_update)

    # === Signal handlers ===

    def _on_state_update(self, msg):
        try:
            self._state = msg.state
            self.status_labels['state'].setText(msg.state)
            self.status_labels['mission'].setText(msg.mission_id or 'None')
            self.status_labels['shelf'].setText(msg.target_shelf or '---')
            self.status_labels['sku'].setText(msg.current_sku or '---')
            self.status_labels['rfid'].setText(msg.last_tag or '---')
            self.status_labels['battery'].setText(f'{msg.battery_percent:.0f}%')
            self.status_labels['carrying'].setText('YES' if msg.carrying_load else 'No')

            # State color
            color = STATE_COLORS.get(msg.state, '#00d4aa')
            self.status_labels['state'].setStyleSheet(
                f'color: {color}; font-weight: bold;')

            # Update docking indicators
            self._update_docking_indicators(msg.state)
        except Exception:
            pass

    def _update_docking_indicators(self, state):
        """Update the docking panel based on current state."""
        try:
            # Dock state
            dock_states = ['RETURNING_HOME', 'DOCKING', 'ALIGNMENT',
                           'RECOVERY_DOCKING', 'RESETTING', 'READY']
            if state in dock_states:
                self.dock_labels['dock_state'].setText(state)
                color = STATE_COLORS.get(state, '#ffcc00')
                self.dock_labels['dock_state'].setStyleSheet(
                    f'color: {color}; font-weight: bold;')
            elif state == 'IDLE':
                self.dock_labels['dock_state'].setText('IDLE')
                self.dock_labels['dock_state'].setStyleSheet(
                    'color: #88ff88; font-weight: bold;')
            else:
                self.dock_labels['dock_state'].setText('IN MISSION')
                self.dock_labels['dock_state'].setStyleSheet(
                    'color: #44aaff; font-weight: bold;')

            # Ready status
            if state in ('IDLE', 'READY'):
                self.dock_labels['ready_status'].setText('READY')
                self.dock_labels['ready_status'].setStyleSheet(
                    'color: #00ff00; font-weight: bold;')
            elif state == 'ERROR':
                self.dock_labels['ready_status'].setText('ERROR')
                self.dock_labels['ready_status'].setStyleSheet(
                    'color: #ff4444; font-weight: bold;')
            else:
                self.dock_labels['ready_status'].setText('BUSY')
                self.dock_labels['ready_status'].setStyleSheet(
                    'color: #ffcc00; font-weight: bold;')

            # Home reached
            dist = math.hypot(self._x, self._y)
            if dist < 0.1:
                self.dock_labels['home_reached'].setText('YES')
                self.dock_labels['home_reached'].setStyleSheet(
                    'color: #00ff00; font-weight: bold;')
            else:
                self.dock_labels['home_reached'].setText(f'No ({dist:.2f}m)')
                self.dock_labels['home_reached'].setStyleSheet(
                    'color: #ff8800; font-weight: bold;')

            # Alignment (yaw error from 90 degrees)
            yaw_err = abs(math.degrees(self._yaw) - 90.0)
            if yaw_err > 180:
                yaw_err = 360 - yaw_err
            if yaw_err < 3.0:
                self.dock_labels['alignment'].setText(f'OK ({yaw_err:.1f} deg)')
                self.dock_labels['alignment'].setStyleSheet(
                    'color: #00ff00; font-weight: bold;')
            else:
                self.dock_labels['alignment'].setText(f'{yaw_err:.1f} deg error')
                self.dock_labels['alignment'].setStyleSheet(
                    'color: #ff8800; font-weight: bold;')

            # Line detected (based on position near spine x=0)
            if abs(self._x) < 0.05:
                self.dock_labels['line_detected'].setText('ON LINE')
                self.dock_labels['line_detected'].setStyleSheet(
                    'color: #00ff00; font-weight: bold;')
            else:
                self.dock_labels['line_detected'].setText(f'OFF ({abs(self._x):.3f}m)')
                self.dock_labels['line_detected'].setStyleSheet(
                    'color: #ff4444; font-weight: bold;')
        except Exception:
            pass

    def _on_log_update(self, text):
        try:
            ts = datetime.now().strftime('%H:%M:%S')
            self.log_text.appendPlainText(f'[{ts}] {text}')
        except Exception:
            pass

    def _on_odom_update(self, x, y, yaw, vx, wz):
        try:
            self._x = x
            self._y = y
            self._yaw = yaw
            self._vx = vx
            self._wz = wz
            self.status_labels['position'].setText(f'({x:.2f}, {y:.2f})')
            self.status_labels['heading'].setText(f'{math.degrees(yaw):.1f} deg')
            self.status_labels['velocity'].setText(f'lin={vx:.2f} ang={wz:.2f}')
        except Exception:
            pass

    def _on_tag_update(self, tag_id, shelf_id):
        try:
            self.status_labels['rfid'].setText(tag_id)
        except Exception:
            pass

    def _on_connection_update(self, connected):
        try:
            self._connected = connected
            if connected:
                self.status_labels['connection'].setText('CONNECTED')
                self.status_labels['connection'].setStyleSheet(
                    'color: #00ff00; font-weight: bold;')
            else:
                self.status_labels['connection'].setText('DISCONNECTED')
                self.status_labels['connection'].setStyleSheet(
                    'color: #ff4444; font-weight: bold;')
        except Exception:
            pass

    # === Button handlers ===

    def _on_dispatch(self):
        shelf = self.combo_shelf.currentText()
        sku = self.combo_sku.currentText()
        priority = self.spin_priority.value()
        mid = self.node.send_mission(shelf, sku, priority)
        row = self.queue_table.rowCount()
        self.queue_table.insertRow(row)
        self.queue_table.setItem(row, 0, QTableWidgetItem(mid))
        self.queue_table.setItem(row, 1, QTableWidgetItem(shelf))
        self.queue_table.setItem(row, 2, QTableWidgetItem(sku))
        self.queue_table.setItem(row, 3, QTableWidgetItem(str(priority)))
        self._on_log_update(f'Dispatched {mid} -> {shelf} [{sku}]')

    def _on_pause(self):
        self.node.send_estop()
        self._on_log_update('Mission PAUSED (E-Stop)')

    def _on_resume(self):
        self.node.send_reset_estop()
        self._on_log_update('Mission RESUMED')

    def _on_cancel(self):
        self.node.send_reset_estop()
        self._on_log_update('Mission CANCELLED')

    def _on_return_home(self):
        self.node.send_return_home()
        self._on_log_update('Return Home requested')

    def _on_estop(self):
        self.node.send_estop()
        self._on_log_update('*** EMERGENCY STOP ACTIVATED ***')

    def _on_reset_estop(self):
        self.node.send_reset_estop()
        self._on_log_update('E-Stop reset, system ready')

    def _on_reset_agv(self):
        reply = QMessageBox.question(
            self, 'Confirm RESET AGV',
            'This will:\n'
            '- Cancel active mission\n'
            '- Stop robot immediately\n'
            '- Clear all state\n'
            '- Physically respawn at home dock\n'
            '- Perform docking alignment verification\n'
            '- Re-center on navigation tape\n'
            '- Restore mission-ready state\n\n'
            'Continue?',
            QMessageBox.Yes | QMessageBox.No, QMessageBox.No)
        if reply == QMessageBox.Yes:
            self.node.send_reset_to_dock()
            self.queue_table.setRowCount(0)
            self._on_log_update('*** RESET AGV: Physical reset + docking initiated ***')


def main(args=None):
    rclpy.init(args=args)
    signals = SignalBridge()
    ros_node = AtlasRosNode(signals)

    spin_thread = threading.Thread(target=rclpy.spin, args=(ros_node,), daemon=True)
    spin_thread.start()

    app = QApplication(sys.argv)
    app.setStyleSheet(DARK_STYLE)
    window = AtlasControlCenter(ros_node, signals)
    window.show()
    exit_code = app.exec_()

    ros_node.destroy_node()
    rclpy.shutdown()
    sys.exit(exit_code)


if __name__ == '__main__':
    main()
