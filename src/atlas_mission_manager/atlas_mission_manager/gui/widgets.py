"""Custom widgets used by the ATLAS Fleet Control Center."""

from PyQt5.QtCore import Qt
from PyQt5.QtGui import QFont
from PyQt5.QtWidgets import (
    QFrame, QHBoxLayout, QLabel, QProgressBar, QSizePolicy, QVBoxLayout,
    QWidget,
)

from . import theme as T


class Card(QFrame):
    """Generic rounded panel container."""

    def __init__(self, parent=None, object_name="Card"):
        super().__init__(parent)
        self.setObjectName(object_name)
        self.setFrameShape(QFrame.NoFrame)


class StatusCard(QFrame):
    """A single labelled metric card for the centre status panel."""

    LEVELS = {
        "ok": T.ACCENT,
        "info": T.INFO,
        "warn": T.WARN,
        "error": T.DANGER,
        "muted": T.TEXT_DIM,
    }

    def __init__(self, title, default="-", parent=None):
        super().__init__(parent)
        self.setObjectName("StatusCard")
        self.setFrameShape(QFrame.NoFrame)
        layout = QVBoxLayout(self)
        layout.setContentsMargins(14, 10, 14, 10)
        layout.setSpacing(4)
        self._title = QLabel(title.upper())
        self._title.setObjectName("CardTitle")
        self._value = QLabel(default)
        self._value.setObjectName("CardValue")
        self._value.setFont(QFont("Segoe UI", 14, QFont.Bold))
        self._value.setWordWrap(False)
        layout.addWidget(self._title)
        layout.addWidget(self._value)
        self.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Fixed)
        self.set_status("ok")

    def set_value(self, text):
        self._value.setText("" if text is None else str(text))

    def set_status(self, level):
        color = self.LEVELS.get(level, T.TEXT_PRIMARY)
        self._value.setStyleSheet(
            "color: %s; font-weight: 700; font-size: 16px;" % color
        )


class BatteryWidget(QFrame):
    """Battery percent gauge with adaptive colour."""

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setObjectName("StatusCard")
        layout = QVBoxLayout(self)
        layout.setContentsMargins(14, 10, 14, 10)
        layout.setSpacing(6)

        self._title = QLabel("BATTERY")
        self._title.setObjectName("CardTitle")
        self._value = QLabel("100%")
        self._value.setObjectName("CardValue")

        top = QHBoxLayout()
        top.setContentsMargins(0, 0, 0, 0)
        top.addWidget(self._title)
        top.addStretch()
        top.addWidget(self._value)

        self._bar = QProgressBar()
        self._bar.setRange(0, 100)
        self._bar.setValue(100)
        self._bar.setTextVisible(False)
        self._bar.setMinimumHeight(12)
        self._bar.setMaximumHeight(12)

        layout.addLayout(top)
        layout.addWidget(self._bar)
        self.set_percent(100.0)

    def set_percent(self, pct):
        try:
            v = max(0, min(100, int(round(float(pct)))))
        except Exception:
            v = 0
        self._bar.setValue(v)
        self._value.setText("%d%%" % v)
        if v >= 60:
            color = T.ACCENT
        elif v >= 25:
            color = T.WARN
        else:
            color = T.DANGER
        self._value.setStyleSheet("color: %s; font-weight: 700;" % color)
        self._bar.setStyleSheet(
            "QProgressBar { border: 1px solid %s; border-radius: 6px; "
            "background: %s; }"
            "QProgressBar::chunk { background: %s; border-radius: 5px; }"
            % (T.BORDER, T.BG_INPUT, color)
        )


class ConnectionWidget(QFrame):
    """Live / Offline indicator pill."""

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setObjectName("ConnPill")
        layout = QHBoxLayout(self)
        layout.setContentsMargins(12, 6, 12, 6)
        layout.setSpacing(8)

        self._dot = QLabel("\u25CF")
        self._dot.setAlignment(Qt.AlignVCenter | Qt.AlignHCenter)
        self._label = QLabel("CONNECTING")
        self._label.setAlignment(Qt.AlignVCenter)

        layout.addWidget(self._dot)
        layout.addWidget(self._label)
        self.set_connected(False)

    def set_connected(self, connected):
        if connected:
            self._label.setText("LIVE")
            color = T.ACCENT
        else:
            self._label.setText("OFFLINE")
            color = T.DANGER
        self._dot.setStyleSheet("color: %s; font-size: 14px;" % color)
        self._label.setStyleSheet(
            "color: %s; font-weight: 700; letter-spacing: 1px;" % color
        )


class SectionLabel(QLabel):
    """Small uppercase section header."""

    def __init__(self, text, parent=None):
        super().__init__(text.upper(), parent)
        self.setObjectName("SectionTitle")


class Divider(QFrame):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setObjectName("Divider")
        self.setFrameShape(QFrame.NoFrame)
        self.setFixedHeight(1)
