#!/usr/bin/env python3
"""ATLAS Warehouse Fleet Control Center - entry point.

Brand-new replacement GUI for the ATLAS Warehouse AGV.

Registered as the ``atlas_gui`` console script in
``atlas_mission_manager/setup.py`` and launched automatically by
``atlas_bringup/launch/atlas_full.launch.py``.

Design goals
------------
* Never crash on missing topics, missing messages, or restarted nodes.
* All Qt widgets are mutated only on the Qt main thread; the rclpy
  spinner runs in a daemon thread and forwards data via Qt signals.
* Subscriptions are recreated transparently after a node restart -
  rclpy/DDS handles re-discovery, so we only have to keep the GUI
  process alive and wrap every callback in a try/except.
* Zero modifications to navigation, RFID, mission manager or Gazebo
  systems - communication uses the existing ``/atlas/*`` topics only.
"""

import signal
import sys

from PyQt5.QtCore import QTimer
from PyQt5.QtWidgets import QApplication

from atlas_mission_manager.gui.main_window import MainWindow
from atlas_mission_manager.gui.ros_bridge import RosBridge
from atlas_mission_manager.gui.theme import APP_STYLESHEET


def main(argv=None):
    if argv is None:
        argv = sys.argv

    # Allow Ctrl+C in the launching terminal to terminate the process.
    signal.signal(signal.SIGINT, signal.SIG_DFL)

    app = QApplication(argv)
    app.setApplicationName("ATLAS Fleet Control")
    app.setStyleSheet(APP_STYLESHEET)

    bridge = RosBridge()
    window = MainWindow(bridge)
    window.show()

    # Drain the Qt event loop frequently so signals/timers stay responsive
    # and SIGINT is honoured promptly.
    keepalive = QTimer()
    keepalive.timeout.connect(lambda: None)
    keepalive.start(200)

    try:
        rc = app.exec_()
    finally:
        try:
            bridge.shutdown()
        except Exception:
            pass
    sys.exit(rc)


if __name__ == "__main__":
    main()
