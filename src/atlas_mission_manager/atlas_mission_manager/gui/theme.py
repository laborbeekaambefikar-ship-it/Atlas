"""Visual theme for the ATLAS Fleet Control Center.

Pure constants - no logic, no imports of Qt symbols required at module
import time.  Kept separate so colours and the stylesheet can be tuned
without touching widget code.
"""

# ---- Palette ----------------------------------------------------------
BG_DEEP = "#0b0f1a"
BG_PANEL = "#121a2c"
BG_CARD = "#172238"
BG_INPUT = "#1d2942"
BORDER = "#2c3650"
BORDER_SOFT = "#1f2940"

TEXT_PRIMARY = "#e6f1ff"
TEXT_MUTED = "#8aa0c2"
TEXT_DIM = "#5d6c87"

ACCENT = "#00d4aa"
ACCENT_DARK = "#008f74"
INFO = "#4ea1ff"
WARN = "#ffaa00"
DANGER = "#ff4d4d"
DANGER_DARK = "#a02828"

LOG_BG = "#0a1020"
LOG_TS = "#5d6c87"
LOG_INFO = "#cfd9ea"
LOG_MISSION = "#00d4aa"
LOG_WARN = "#ffaa00"
LOG_ERROR = "#ff6b6b"

# ---- Stylesheet -------------------------------------------------------
APP_STYLESHEET = f"""
* {{
    font-family: "Segoe UI", "Inter", "Roboto", "Cantarell", "Ubuntu", sans-serif;
    color: {TEXT_PRIMARY};
}}

QMainWindow, QWidget {{
    background-color: {BG_DEEP};
}}

QLabel {{
    background: transparent;
}}

QLabel#PageTitle {{
    font-size: 20px;
    font-weight: 700;
    color: {ACCENT};
    letter-spacing: 1px;
}}

QLabel#PageSubtitle {{
    font-size: 11px;
    color: {TEXT_MUTED};
    letter-spacing: 2px;
}}

QLabel#SectionTitle {{
    font-size: 11px;
    font-weight: 700;
    color: {TEXT_MUTED};
    letter-spacing: 2px;
    padding: 0 0 4px 2px;
}}

QLabel#CardTitle {{
    color: {TEXT_MUTED};
    font-size: 10px;
    font-weight: 600;
    letter-spacing: 1px;
}}

QLabel#CardValue {{
    color: {ACCENT};
    font-size: 16px;
    font-weight: 700;
}}

QFrame#Card, QFrame#StatusCard, QFrame#ConnPill {{
    background: {BG_CARD};
    border: 1px solid {BORDER};
    border-radius: 10px;
}}

QFrame#Panel {{
    background: {BG_PANEL};
    border: 1px solid {BORDER_SOFT};
    border-radius: 12px;
}}

QFrame#Divider {{
    background: {BORDER};
    max-height: 1px;
    min-height: 1px;
    border: none;
}}

QPushButton {{
    background-color: {BG_INPUT};
    border: 1px solid {BORDER};
    border-radius: 8px;
    padding: 10px 14px;
    color: {TEXT_PRIMARY};
    font-weight: 600;
    min-height: 24px;
}}

QPushButton:hover {{
    border-color: {ACCENT};
    color: {ACCENT};
}}

QPushButton:pressed {{
    background-color: {ACCENT};
    color: {BG_DEEP};
}}

QPushButton:disabled {{
    color: {TEXT_DIM};
    border-color: {BORDER_SOFT};
}}

QPushButton#PrimaryButton {{
    background-color: {ACCENT_DARK};
    border-color: {ACCENT};
    color: {BG_DEEP};
}}

QPushButton#PrimaryButton:hover {{
    background-color: {ACCENT};
}}

QPushButton#WarnButton {{
    background-color: #5a3a00;
    border-color: {WARN};
    color: {WARN};
}}

QPushButton#WarnButton:hover {{
    background-color: {WARN};
    color: {BG_DEEP};
}}

QPushButton#DangerButton {{
    background-color: {DANGER_DARK};
    border-color: {DANGER};
    color: #ffe6e6;
    font-weight: 700;
    letter-spacing: 1px;
}}

QPushButton#DangerButton:hover {{
    background-color: {DANGER};
    color: {BG_DEEP};
}}

QComboBox, QSpinBox, QLineEdit {{
    background-color: {BG_INPUT};
    border: 1px solid {BORDER};
    border-radius: 6px;
    padding: 6px 8px;
    color: {TEXT_PRIMARY};
    selection-background-color: {ACCENT};
    selection-color: {BG_DEEP};
    min-height: 22px;
}}

QComboBox:focus, QSpinBox:focus, QLineEdit:focus {{
    border-color: {ACCENT};
}}

QComboBox::drop-down {{
    border: none;
    width: 22px;
}}

QComboBox QAbstractItemView {{
    background-color: {BG_PANEL};
    border: 1px solid {BORDER};
    selection-background-color: {ACCENT_DARK};
    color: {TEXT_PRIMARY};
}}

QTableWidget {{
    background-color: {BG_CARD};
    alternate-background-color: {BG_PANEL};
    border: 1px solid {BORDER};
    border-radius: 8px;
    gridline-color: {BORDER_SOFT};
    color: {TEXT_PRIMARY};
    selection-background-color: {ACCENT_DARK};
    selection-color: {BG_DEEP};
}}

QHeaderView::section {{
    background-color: {BG_INPUT};
    color: {TEXT_MUTED};
    border: none;
    border-right: 1px solid {BORDER_SOFT};
    border-bottom: 1px solid {BORDER};
    padding: 6px 8px;
    font-weight: 700;
    letter-spacing: 1px;
}}

QTableWidget::item {{
    padding: 6px 8px;
}}

QTextEdit, QPlainTextEdit {{
    background-color: {LOG_BG};
    border: 1px solid {BORDER};
    border-radius: 8px;
    color: {TEXT_PRIMARY};
    font-family: "JetBrains Mono", "Fira Code", "Consolas", "DejaVu Sans Mono", monospace;
    font-size: 11px;
    padding: 6px;
}}

QScrollBar:vertical {{
    background: {BG_PANEL};
    width: 10px;
    border: none;
    margin: 0;
}}

QScrollBar::handle:vertical {{
    background: {BORDER};
    border-radius: 4px;
    min-height: 24px;
}}

QScrollBar::handle:vertical:hover {{
    background: {ACCENT_DARK};
}}

QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {{
    height: 0;
}}

QScrollBar:horizontal {{
    background: {BG_PANEL};
    height: 10px;
    border: none;
}}

QScrollBar::handle:horizontal {{
    background: {BORDER};
    border-radius: 4px;
    min-width: 24px;
}}

QGroupBox {{
    background: transparent;
    border: 1px solid {BORDER};
    border-radius: 10px;
    margin-top: 14px;
    padding: 14px 10px 10px 10px;
    font-weight: 700;
    color: {TEXT_MUTED};
    letter-spacing: 1px;
}}

QGroupBox::title {{
    subcontrol-origin: margin;
    subcontrol-position: top left;
    left: 12px;
    padding: 0 6px;
    color: {ACCENT};
}}

QToolTip {{
    background-color: {BG_PANEL};
    color: {TEXT_PRIMARY};
    border: 1px solid {ACCENT};
    padding: 4px;
}}

QMessageBox, QDialog {{
    background-color: {BG_PANEL};
}}
"""
