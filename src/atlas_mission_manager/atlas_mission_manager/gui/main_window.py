"""Main window for the ATLAS Fleet Control Center.

Layout
------
+-------------------------------------------------------------------+
| header  (title + connection pill + clock)                         |
+--------------+----------------------------+-----------------------+
| LEFT         | CENTER                     | RIGHT                 |
|              |                            |                       |
| Create       | AGV Status cards           | Mission queue table   |
| Mission      | + Battery + Connectivity   | Mission history table |
|              |                            | Active task list      |
| Robot        |                            |                       |
| Commands     |                            |                       |
+--------------+----------------------------+-----------------------+
| BOTTOM: scrollable event log                                      |
+-------------------------------------------------------------------+
"""

import math
from datetime import datetime

from PyQt5.QtCore import Qt, QTimer
from PyQt5.QtGui import QFont, QTextCursor
from PyQt5.QtWidgets import (
    QAbstractItemView, QComboBox, QFormLayout, QFrame, QGridLayout,
    QHBoxLayout, QHeaderView, QLabel, QMainWindow, QMessageBox,
    QPushButton, QScrollArea, QSpinBox, QSplitter, QTableWidget,
    QTableWidgetItem, QTextEdit, QVBoxLayout, QWidget,
)

from . import theme as T
from .widgets import (
    BatteryWidget, ConnectionWidget, Divider, SectionLabel, StatusCard,
)


# ---- shelf / SKU catalogue -------------------------------------------
SHELVES = ["S%02d" % i for i in range(1, 21)]
SKUS = ["SKU-001", "SKU-002", "SKU-003", "SKU-004", "SKU-005",
        "SKU-006", "SKU-007", "SKU-008", "SKU-009", "SKU-010"]

PRIORITY_LABELS = {0: "LOW", 1: "NORMAL", 2: "HIGH", 3: "URGENT"}


# ----------------------------------------------------------------------
# helper: panelled column
# ----------------------------------------------------------------------
def _panel(title=None):
    panel = QFrame()
    panel.setObjectName("Panel")
    layout = QVBoxLayout(panel)
    layout.setContentsMargins(14, 14, 14, 14)
    layout.setSpacing(10)
    if title:
        lbl = QLabel(title.upper())
        lbl.setObjectName("SectionTitle")
        layout.addWidget(lbl)
    return panel, layout


# ----------------------------------------------------------------------
# main window
# ----------------------------------------------------------------------
class MainWindow(QMainWindow):

    HISTORY_LIMIT = 50
    LOG_LIMIT = 1000

    def __init__(self, bridge):
        super().__init__()
        self.bridge = bridge

        self.setWindowTitle("ATLAS Fleet Control Center")
        self.setMinimumSize(1280, 760)
        self.resize(1480, 880)

        # mission tracking ------------------------------------------------
        # ordered list of dicts: {id, shelf, sku, priority, status}
        self._missions = []
        # finished missions (most recent first)
        self._history = []
        self._last_active_id = ""
        self._last_state = ""

        self._build_ui()
        self._connect_signals()

        # clock tick
        self._clock = QTimer(self)
        self._clock.timeout.connect(self._update_clock)
        self._clock.start(1000)
        self._update_clock()

        self._append_log("[GUI] ATLAS Fleet Control Center ready", "mission")

    # ------------------------------------------------------------------
    # UI construction
    # ------------------------------------------------------------------
    def _build_ui(self):
        central = QWidget()
        self.setCentralWidget(central)
        root = QVBoxLayout(central)
        root.setContentsMargins(14, 14, 14, 14)
        root.setSpacing(12)

        root.addWidget(self._build_header())

        body_split = QSplitter(Qt.Vertical)
        body_split.setChildrenCollapsible(False)
        body_split.setHandleWidth(6)

        cols = QSplitter(Qt.Horizontal)
        cols.setChildrenCollapsible(False)
        cols.setHandleWidth(6)
        cols.addWidget(self._build_left_panel())
        cols.addWidget(self._build_center_panel())
        cols.addWidget(self._build_right_panel())
        cols.setStretchFactor(0, 0)
        cols.setStretchFactor(1, 2)
        cols.setStretchFactor(2, 1)
        cols.setSizes([300, 720, 420])

        body_split.addWidget(cols)
        body_split.addWidget(self._build_bottom_panel())
        body_split.setStretchFactor(0, 4)
        body_split.setStretchFactor(1, 1)
        body_split.setSizes([600, 220])

        root.addWidget(body_split, 1)

    # ---- header -------------------------------------------------------
    def _build_header(self):
        bar = QFrame()
        bar.setObjectName("Panel")
        h = QHBoxLayout(bar)
        h.setContentsMargins(18, 10, 18, 10)
        h.setSpacing(16)

        title_box = QVBoxLayout()
        title_box.setContentsMargins(0, 0, 0, 0)
        title_box.setSpacing(2)
        title = QLabel("ATLAS  FLEET  CONTROL")
        title.setObjectName("PageTitle")
        sub = QLabel("WAREHOUSE AGV  -  COMMAND CONSOLE")
        sub.setObjectName("PageSubtitle")
        title_box.addWidget(title)
        title_box.addWidget(sub)
        h.addLayout(title_box)
        h.addStretch()

        self.clock_label = QLabel("--:--:--")
        self.clock_label.setStyleSheet(
            "color: %s; font-family: monospace; font-size: 14px;" % T.TEXT_MUTED
        )
        h.addWidget(self.clock_label)

        self.conn_widget = ConnectionWidget()
        h.addWidget(self.conn_widget)
        return bar

    # ---- left panel ---------------------------------------------------
    def _build_left_panel(self):
        outer = QScrollArea()
        outer.setWidgetResizable(True)
        outer.setFrameShape(QFrame.NoFrame)

        container = QWidget()
        col = QVBoxLayout(container)
        col.setContentsMargins(0, 0, 0, 0)
        col.setSpacing(12)

        # ------ Create Mission ----------------------------------------
        cm_panel, cm_layout = _panel("Create Mission")

        form = QFormLayout()
        form.setContentsMargins(0, 0, 0, 0)
        form.setSpacing(8)
        form.setLabelAlignment(Qt.AlignRight)

        self.shelf_combo = QComboBox()
        self.shelf_combo.addItems(SHELVES)
        form.addRow("Target shelf:", self.shelf_combo)

        self.sku_combo = QComboBox()
        self.sku_combo.addItems(SKUS)
        form.addRow("SKU:", self.sku_combo)

        self.prio_spin = QSpinBox()
        self.prio_spin.setRange(0, 3)
        self.prio_spin.setValue(1)
        self.prio_spin.setToolTip("0=LOW  1=NORMAL  2=HIGH  3=URGENT")
        form.addRow("Priority:", self.prio_spin)

        cm_layout.addLayout(form)

        self.btn_start = QPushButton("START MISSION")
        self.btn_start.setObjectName("PrimaryButton")
        self.btn_start.setMinimumHeight(40)
        cm_layout.addWidget(self.btn_start)

        col.addWidget(cm_panel)

        # ------ Robot Commands ----------------------------------------
        rc_panel, rc_layout = _panel("Robot Commands")

        self.btn_return_home = QPushButton("Return Home")
        self.btn_return_home.setMinimumHeight(36)
        rc_layout.addWidget(self.btn_return_home)

        self.btn_reset_agv = QPushButton("RESET AGV")
        self.btn_reset_agv.setObjectName("WarnButton")
        self.btn_reset_agv.setMinimumHeight(40)
        rc_layout.addWidget(self.btn_reset_agv)

        rc_layout.addWidget(Divider())

        self.btn_estop = QPushButton("EMERGENCY  STOP")
        self.btn_estop.setObjectName("DangerButton")
        self.btn_estop.setMinimumHeight(54)
        f = QFont()
        f.setPointSize(12)
        f.setBold(True)
        self.btn_estop.setFont(f)
        rc_layout.addWidget(self.btn_estop)

        self.btn_reset_estop = QPushButton("Reset E-Stop")
        self.btn_reset_estop.setMinimumHeight(34)
        rc_layout.addWidget(self.btn_reset_estop)

        col.addWidget(rc_panel)
        col.addStretch(1)

        outer.setWidget(container)
        outer.setMinimumWidth(280)
        outer.setMaximumWidth(360)
        return outer

    # ---- center panel -------------------------------------------------
    def _build_center_panel(self):
        panel, layout = _panel("AGV Status")

        # status cards in a responsive grid
        grid = QGridLayout()
        grid.setHorizontalSpacing(10)
        grid.setVerticalSpacing(10)

        self.cards = {}
        card_specs = [
            ("State", "IDLE", "ok"),
            ("Mission", "-", "muted"),
            ("Shelf", "-", "muted"),
            ("SKU", "-", "muted"),
            ("RFID", "-", "muted"),
            ("Carrying", "NO", "muted"),
            ("Pos X", "0.00 m", "info"),
            ("Pos Y", "0.00 m", "info"),
            ("Heading", "0.0 deg", "info"),
            ("Lin Vel", "0.00 m/s", "info"),
            ("Ang Vel", "0.00 rad/s", "info"),
            ("Nav", "READY", "ok"),
        ]
        cols = 4
        for i, (name, default, level) in enumerate(card_specs):
            card = StatusCard(name, default)
            card.set_status(level)
            self.cards[name] = card
            grid.addWidget(card, i // cols, i % cols)

        layout.addLayout(grid)

        # battery + connectivity row
        bottom_row = QHBoxLayout()
        bottom_row.setSpacing(10)
        self.battery = BatteryWidget()
        bottom_row.addWidget(self.battery, 2)

        conn_card = QFrame()
        conn_card.setObjectName("StatusCard")
        cl = QHBoxLayout(conn_card)
        cl.setContentsMargins(14, 10, 14, 10)
        cl.setSpacing(10)
        title = QLabel("CONNECTIVITY")
        title.setObjectName("CardTitle")
        cl.addWidget(title)
        cl.addStretch()
        self.conn_inline = ConnectionWidget()
        cl.addWidget(self.conn_inline)
        bottom_row.addWidget(conn_card, 1)

        layout.addLayout(bottom_row)
        layout.addStretch(1)
        return panel

    # ---- right panel --------------------------------------------------
    def _build_right_panel(self):
        outer = QFrame()
        col = QVBoxLayout(outer)
        col.setContentsMargins(0, 0, 0, 0)
        col.setSpacing(12)

        # mission queue --------------------------------------------------
        q_panel, q_layout = _panel("Mission Queue")
        self.queue_table = QTableWidget(0, 5)
        self.queue_table.setHorizontalHeaderLabels(
            ["ID", "Shelf", "SKU", "Prio", "Status"]
        )
        self.queue_table.verticalHeader().setVisible(False)
        self.queue_table.setEditTriggers(QAbstractItemView.NoEditTriggers)
        self.queue_table.setSelectionBehavior(QAbstractItemView.SelectRows)
        self.queue_table.setAlternatingRowColors(True)
        self.queue_table.horizontalHeader().setSectionResizeMode(
            QHeaderView.Stretch
        )
        self.queue_table.setMinimumHeight(140)
        q_layout.addWidget(self.queue_table)
        col.addWidget(q_panel, 2)

        # mission history -----------------------------------------------
        h_panel, h_layout = _panel("Mission History")
        self.history_table = QTableWidget(0, 5)
        self.history_table.setHorizontalHeaderLabels(
            ["Time", "ID", "Shelf", "SKU", "Result"]
        )
        self.history_table.verticalHeader().setVisible(False)
        self.history_table.setEditTriggers(QAbstractItemView.NoEditTriggers)
        self.history_table.setSelectionBehavior(QAbstractItemView.SelectRows)
        self.history_table.setAlternatingRowColors(True)
        self.history_table.horizontalHeader().setSectionResizeMode(
            QHeaderView.Stretch
        )
        self.history_table.setMinimumHeight(140)
        h_layout.addWidget(self.history_table)
        col.addWidget(h_panel, 2)

        # active task list ----------------------------------------------
        a_panel, a_layout = _panel("Active Task")
        self.active_table = QTableWidget(6, 2)
        self.active_table.verticalHeader().setVisible(False)
        self.active_table.horizontalHeader().setVisible(False)
        self.active_table.setEditTriggers(QAbstractItemView.NoEditTriggers)
        self.active_table.setSelectionMode(QAbstractItemView.NoSelection)
        self.active_table.setShowGrid(False)
        self.active_table.horizontalHeader().setSectionResizeMode(
            QHeaderView.Stretch
        )
        self.active_table.setFocusPolicy(Qt.NoFocus)
        self.active_rows = ["State", "Mission", "Target", "SKU", "RFID", "Carrying"]
        for i, name in enumerate(self.active_rows):
            k = QTableWidgetItem(name)
            k.setForeground(self._color_brush(T.TEXT_MUTED))
            v = QTableWidgetItem("-")
            v.setForeground(self._color_brush(T.ACCENT))
            v.setTextAlignment(Qt.AlignRight | Qt.AlignVCenter)
            self.active_table.setItem(i, 0, k)
            self.active_table.setItem(i, 1, v)
        self.active_table.setMinimumHeight(180)
        a_layout.addWidget(self.active_table)
        col.addWidget(a_panel, 1)

        return outer

    @staticmethod
    def _color_brush(hex_color):
        from PyQt5.QtGui import QBrush, QColor
        return QBrush(QColor(hex_color))

    # ---- bottom panel -------------------------------------------------
    def _build_bottom_panel(self):
        panel, layout = _panel("Event Log")

        toolbar = QHBoxLayout()
        toolbar.setContentsMargins(0, 0, 0, 0)
        toolbar.addStretch()
        self.btn_clear_log = QPushButton("Clear")
        self.btn_clear_log.setMaximumWidth(100)
        toolbar.addWidget(self.btn_clear_log)

        self.log_view = QTextEdit()
        self.log_view.setReadOnly(True)
        self.log_view.setLineWrapMode(QTextEdit.NoWrap)
        self.log_view.setMinimumHeight(120)

        layout.addLayout(toolbar)
        layout.addWidget(self.log_view, 1)
        return panel

    # ------------------------------------------------------------------
    # signal wiring
    # ------------------------------------------------------------------
    def _connect_signals(self):
        # buttons
        self.btn_start.clicked.connect(self._on_start_mission)
        self.btn_return_home.clicked.connect(self._on_return_home)
        self.btn_reset_agv.clicked.connect(self._on_reset_agv)
        self.btn_estop.clicked.connect(self._on_estop)
        self.btn_reset_estop.clicked.connect(self._on_reset_estop)
        self.btn_clear_log.clicked.connect(self.log_view.clear)

        # bridge
        self.bridge.state_signal.connect(self._on_state)
        self.bridge.odom_signal.connect(self._on_odom)
        self.bridge.log_signal.connect(self._on_ros_log)
        self.bridge.tag_signal.connect(self._on_tag)
        self.bridge.connection_signal.connect(self._on_connection)
        self.bridge.mission_sent_signal.connect(self._on_mission_sent)

    # ------------------------------------------------------------------
    # button handlers
    # ------------------------------------------------------------------
    def _on_start_mission(self):
        try:
            shelf = self.shelf_combo.currentText()
            sku = self.sku_combo.currentText()
            prio = int(self.prio_spin.value())
            mid = self.bridge.send_mission(shelf, sku, prio)
            if not mid:
                self._append_log(
                    "[GUI] Failed to publish mission - is mission_node running?",
                    "error",
                )
                QMessageBox.warning(
                    self, "Mission Failed",
                    "Could not publish on /atlas/mission_cmd.\n"
                    "Verify the mission_node is running.",
                )
        except Exception as ex:
            self._append_log("[GUI] Start mission error: %s" % ex, "error")

    def _on_return_home(self):
        if self.bridge.send_return_home():
            self._append_log(
                "[GUI] Return Home commanded (-> /atlas/reset_to_dock)",
                "mission",
            )
        else:
            self._append_log("[GUI] Return Home failed", "error")

    def _on_reset_agv(self):
        reply = QMessageBox.question(
            self,
            "Reset AGV",
            "Reset the AGV and return it to the home dock?\n\n"
            "This will:\n"
            "  - Cancel the active mission\n"
            "  - Clear the navigation goal\n"
            "  - Clear the mission queue\n"
            "  - Respawn the AGV at the home dock\n"
            "  - Reset state to IDLE",
            QMessageBox.Yes | QMessageBox.No,
            QMessageBox.No,
        )
        if reply != QMessageBox.Yes:
            return

        if not self.bridge.send_reset_agv():
            self._append_log("[GUI] RESET AGV failed", "error")
            return

        self._append_log("[GUI] RESET AGV commanded", "warn")
        # Mark anything still queued/active as cancelled locally.
        for m in self._missions:
            if m["status"] in ("QUEUED", "ACTIVE"):
                m["status"] = "CANCELLED"
                self._archive_mission(m, "CANCELLED")
        self._missions = [m for m in self._missions if m["status"]
                          in ("DONE", "CANCELLED")]
        self._refresh_queue_table()

    def _on_estop(self):
        if self.bridge.send_estop():
            self._append_log("[GUI] EMERGENCY STOP triggered", "error")
        else:
            self._append_log("[GUI] E-Stop publish failed", "error")

    def _on_reset_estop(self):
        if self.bridge.send_reset_estop():
            self._append_log("[GUI] E-Stop cleared", "mission")
        else:
            self._append_log("[GUI] Reset E-Stop publish failed", "error")

    # ------------------------------------------------------------------
    # ROS-driven slots (Qt main thread)
    # ------------------------------------------------------------------
    def _on_state(self, mission_id, target_shelf, current_sku, state,
                  battery, last_tag, carrying, _sku_dup):
        try:
            self.cards["State"].set_value(state or "IDLE")
            self.cards["State"].set_status(self._level_for_state(state))
            self.cards["Mission"].set_value(mission_id or "-")
            self.cards["Mission"].set_status(
                "ok" if mission_id else "muted"
            )
            self.cards["Shelf"].set_value(target_shelf or "-")
            self.cards["Shelf"].set_status(
                "ok" if target_shelf else "muted"
            )
            self.cards["SKU"].set_value(current_sku or "-")
            self.cards["SKU"].set_status(
                "ok" if current_sku else "muted"
            )
            self.cards["RFID"].set_value(last_tag or "-")
            self.cards["RFID"].set_status(
                "info" if last_tag else "muted"
            )
            self.cards["Carrying"].set_value("YES" if carrying else "NO")
            self.cards["Carrying"].set_status(
                "warn" if carrying else "muted"
            )

            nav_text, nav_level = self._nav_indicator(state)
            self.cards["Nav"].set_value(nav_text)
            self.cards["Nav"].set_status(nav_level)

            self.battery.set_percent(battery)

            # active task panel
            self._set_active_row("State", state or "-")
            self._set_active_row("Mission", mission_id or "-")
            self._set_active_row("Target", target_shelf or "-")
            self._set_active_row("SKU", current_sku or "-")
            self._set_active_row("RFID", last_tag or "-")
            self._set_active_row("Carrying", "YES" if carrying else "NO")

            # mission queue tracking
            self._update_queue_from_state(mission_id, state)

            self._last_active_id = mission_id
            self._last_state = state or ""
        except Exception as ex:
            self._append_log("[GUI] state slot error: %s" % ex, "error")

    def _on_odom(self, x, y, yaw, vx, wz):
        try:
            self.cards["Pos X"].set_value("%.2f m" % x)
            self.cards["Pos Y"].set_value("%.2f m" % y)
            self.cards["Heading"].set_value(
                "%.1f deg" % math.degrees(yaw)
            )
            self.cards["Lin Vel"].set_value("%.2f m/s" % vx)
            self.cards["Ang Vel"].set_value("%.2f rad/s" % wz)
        except Exception as ex:
            self._append_log("[GUI] odom slot error: %s" % ex, "error")

    def _on_ros_log(self, text):
        level = "info"
        low = text.lower()
        if any(k in low for k in ("error", "fail", "rejected", "estop", "e-stop")):
            level = "error"
        elif any(k in low for k in ("warn", "warning")):
            level = "warn"
        elif any(k in low for k in (
            "mission", "queued", "complete", "state ", "reset", "returned"
        )):
            level = "mission"
        self._append_log(text, level)

    def _on_tag(self, tag_id, shelf_id, is_home):
        if is_home:
            text = "[RFID] HOME tag %s" % tag_id
        else:
            text = "[RFID] %s -> %s" % (tag_id, shelf_id or "?")
        self._append_log(text, "info")

    def _on_connection(self, connected):
        self.conn_widget.set_connected(connected)
        self.conn_inline.set_connected(connected)
        if connected:
            self._append_log("[GUI] ROS connection LIVE", "mission")
        else:
            self._append_log("[GUI] ROS connection lost - waiting...", "warn")

    def _on_mission_sent(self, mission_id, shelf, sku, prio):
        entry = {
            "id": mission_id,
            "shelf": shelf,
            "sku": sku,
            "priority": int(prio),
            "status": "QUEUED",
        }
        self._missions.append(entry)
        self._refresh_queue_table()
        self._append_log(
            "[GUI] Mission %s queued -> %s (%s, prio=%s)"
            % (mission_id, shelf, sku, PRIORITY_LABELS.get(prio, str(prio))),
            "mission",
        )

    # ------------------------------------------------------------------
    # mission queue helpers
    # ------------------------------------------------------------------
    def _update_queue_from_state(self, mission_id, state):
        if mission_id:
            for m in self._missions:
                if m["id"] == mission_id and m["status"] != "ACTIVE":
                    m["status"] = "ACTIVE"
            self._refresh_queue_table()
            return

        # No active mission reported.  If we just transitioned away from a
        # previously-active mission, archive it as DONE.
        if self._last_active_id and not mission_id:
            for m in self._missions:
                if m["id"] == self._last_active_id and m["status"] == "ACTIVE":
                    m["status"] = "DONE"
                    self._archive_mission(m, "DONE")
            self._missions = [m for m in self._missions
                              if m["status"] not in ("DONE", "CANCELLED")]
            self._refresh_queue_table()

    def _refresh_queue_table(self):
        active = [m for m in self._missions
                  if m["status"] in ("QUEUED", "ACTIVE")]
        self.queue_table.setRowCount(len(active))
        for r, m in enumerate(active):
            self._set_cell(self.queue_table, r, 0, m["id"])
            self._set_cell(self.queue_table, r, 1, m["shelf"])
            self._set_cell(self.queue_table, r, 2, m["sku"])
            self._set_cell(
                self.queue_table, r, 3,
                PRIORITY_LABELS.get(m["priority"], str(m["priority"])),
            )
            color = T.ACCENT if m["status"] == "ACTIVE" else T.WARN
            self._set_cell(self.queue_table, r, 4, m["status"], color)

    def _archive_mission(self, m, result):
        ts = datetime.now().strftime("%H:%M:%S")
        self._history.insert(0, {
            "time": ts,
            "id": m["id"],
            "shelf": m["shelf"],
            "sku": m["sku"],
            "result": result,
        })
        self._history = self._history[: self.HISTORY_LIMIT]
        self._refresh_history_table()

    def _refresh_history_table(self):
        self.history_table.setRowCount(len(self._history))
        for r, h in enumerate(self._history):
            self._set_cell(self.history_table, r, 0, h["time"])
            self._set_cell(self.history_table, r, 1, h["id"])
            self._set_cell(self.history_table, r, 2, h["shelf"])
            self._set_cell(self.history_table, r, 3, h["sku"])
            color = T.ACCENT if h["result"] == "DONE" else T.DANGER
            self._set_cell(self.history_table, r, 4, h["result"], color)

    @staticmethod
    def _set_cell(table, row, col, text, color=None):
        item = QTableWidgetItem("" if text is None else str(text))
        if color is not None:
            from PyQt5.QtGui import QBrush, QColor
            item.setForeground(QBrush(QColor(color)))
        table.setItem(row, col, item)

    def _set_active_row(self, key, value):
        if key not in self.active_rows:
            return
        r = self.active_rows.index(key)
        item = self.active_table.item(r, 1)
        if item is None:
            item = QTableWidgetItem("")
            self.active_table.setItem(r, 1, item)
        item.setText("" if value is None else str(value))
        item.setTextAlignment(Qt.AlignRight | Qt.AlignVCenter)

    # ------------------------------------------------------------------
    # state helpers
    # ------------------------------------------------------------------
    @staticmethod
    def _level_for_state(state):
        if not state:
            return "muted"
        s = state.upper()
        if s in ("IDLE", "DOCKED"):
            return "ok"
        if s == "ERROR":
            return "error"
        if s in ("AT_SHELF", "PICKUP"):
            return "info"
        return "warn"

    @staticmethod
    def _nav_indicator(state):
        if not state:
            return ("UNKNOWN", "muted")
        s = state.upper()
        if s == "IDLE":
            return ("READY", "ok")
        if s == "ERROR":
            return ("E-STOP", "error")
        if s == "DOCKED":
            return ("DOCKED", "ok")
        return ("ACTIVE", "warn")

    # ------------------------------------------------------------------
    # log helpers
    # ------------------------------------------------------------------
    def _append_log(self, text, level="info"):
        if text is None:
            return
        ts = datetime.now().strftime("%H:%M:%S")
        color_map = {
            "info": T.LOG_INFO,
            "mission": T.LOG_MISSION,
            "warn": T.LOG_WARN,
            "error": T.LOG_ERROR,
        }
        color = color_map.get(level, T.LOG_INFO)

        # Escape minimal HTML so robot log can't inject markup.
        safe = (str(text)
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;"))
        line = (
            '<span style="color:%s;">[%s]</span> '
            '<span style="color:%s;">%s</span>'
            % (T.LOG_TS, ts, color, safe)
        )
        self.log_view.append(line)

        # Cap log length so memory stays bounded.
        if self.log_view.document().blockCount() > self.LOG_LIMIT:
            cursor = self.log_view.textCursor()
            cursor.movePosition(QTextCursor.Start)
            cursor.select(QTextCursor.BlockUnderCursor)
            cursor.removeSelectedText()
            cursor.deleteChar()

        sb = self.log_view.verticalScrollBar()
        sb.setValue(sb.maximum())

    def _update_clock(self):
        self.clock_label.setText(datetime.now().strftime("%H:%M:%S"))

    # ------------------------------------------------------------------
    def closeEvent(self, event):
        try:
            self.bridge.shutdown()
        except Exception:
            pass
        event.accept()
