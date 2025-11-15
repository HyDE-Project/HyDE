#!/usr/bin/env python3
import argparse
import random
import re
import os
import sys
from PyQt6 import QtWidgets, QtGui, QtCore
from dataclasses import dataclass

os.environ["QT_PLUGIN_PATH"] = "/usr/lib/qt6/plugins"


@dataclass
class ColorRow:
    primary: str
    text: str
    accent1: str
    accent2: str
    accent3: str
    accent4: str
    accent5: str
    accent6: str
    accent7: str
    accent8: str
    accent9: str


def hex_from_rgba(rgba_str):
    # Expects rgba_str like 'rgba(26,26,26,1)' or 'rgba(26,26,26,1)'
    m = re.match(r"rgba\((\d+),(\d+),(\d+),", rgba_str)
    if m:
        r, g, b = map(int, m.groups())
        return f"{r:02X}{g:02X}{b:02X}"
    return "FFFFFF"


def extract_colors(lines):
    mode = None
    primaries = []
    texts = []
    accents = []  # List of lists, one per primary color
    other = []
    for line in lines:
        if line.startswith("dcol_mode="):
            mode = line
        elif re.match(r"dcol_pry[1-4]=", line):
            primaries.append(line)
        elif re.match(r"dcol_pry[1-4]_rgba=", line):
            pass  # skip, not needed for preview
        elif re.match(r"dcol_txt[1-4]=", line):
            texts.append(line)
        elif re.match(r"dcol_txt[1-4]_rgba=", line):
            pass  # skip, not needed for preview
        elif re.match(r"dcol_([1-4])xa([1-9])=", line):
            m = re.match(r"dcol_([1-4])xa([1-9])=\"?([0-9A-Fa-f]{6}|[a-zA-Z])\"?", line)
            if m:
                x = int(m.group(1)) - 1
                y = int(m.group(2)) - 1
                val = m.group(3)
                while len(accents) <= x:
                    accents.append([])
                # Ensure the current row has enough slots
                while len(accents[x]) <= y:
                    accents[x].append("FFFFFF")
                # Find corresponding rgba if val is not valid hex
                if not re.match(r"^[0-9A-Fa-f]{6}$", val):
                    key = f"dcol_{x + 1}xa{y + 1}_rgba"
                    rgba_val = None
                    for line2 in lines:
                        if line2.startswith(key):
                            rgba_val = line2.split("=", 1)[1].strip().strip('"')
                            break
                    if rgba_val:
                        val = hex_from_rgba(rgba_val)
                    else:
                        val = "FFFFFF"
                accents[x][y] = val  # Use assignment instead of append
        else:
            other.append(line)
    # Ensure accents has 4 lists for downstream logic
    while len(accents) < 4:
        accents.append([])
    # Pad each accent row to 9
    for row in accents:
        while len(row) < 9:
            row.append("FFFFFF")
    # Parse primaries and texts
    pry = [
        re.search(r'"([0-9A-Fa-f]{6})"', line).group(1)
        if re.search(r'"([0-9A-Fa-f]{6})"', line)
        else "FFFFFF"
        for line in primaries
    ]
    while len(pry) < 4:
        pry.append("FFFFFF")
    txt = [
        re.search(r'"([0-9A-Fa-f]{6})"', line).group(1)
        if re.search(r'"([0-9A-Fa-f]{6})"', line)
        else "FFFFFF"
        for line in texts
    ]
    while len(txt) < 4:
        txt.append("FFFFFF")
    # Build ColorRow objects
    color_rows = []
    for i in range(4):
        color_rows.append(
            ColorRow(
                primary=pry[i],
                text=txt[i],
                accent1=accents[i][0],
                accent2=accents[i][1],
                accent3=accents[i][2],
                accent4=accents[i][3],
                accent5=accents[i][4],
                accent6=accents[i][5],
                accent7=accents[i][6],
                accent8=accents[i][7],
                accent9=accents[i][8],
            )
        )
    return mode, color_rows, other


class CurveEditor(QtWidgets.QWidget):
    """A modern draggable curve editor for 9 points (0-100, 0-100)"""

    curveChanged = QtCore.pyqtSignal(list)
    userTouchedCurve = QtCore.pyqtSignal()  # Signal when user manually modifies curve

    def __init__(self, points=None, parent=None):
        super().__init__(parent)
        self.setMinimumHeight(160)  # Increased from 120 to 160
        self.setMinimumWidth(500)  # Increased from 400 to 500
        self.radius = 6
        self.drag_idx = None
        self.hover_idx = None
        self.enabled = False  # Start disabled until a preset is selected
        self.has_been_touched = False  # Track if user has interacted
        if points is None:
            # Initialize 10 points: A1-A9 for accents, T for text
            # Points 0-8 = Accents 1-9, Point 9 = Text
            # Distribute points evenly across the width
            self.points = []
            for i in range(9):  # A1-A9 accents
                x = (i + 1) * 10  # 10, 20, 30, ..., 90 (equal spacing)
                y = 80 - i * 5  # 80, 75, 70, ..., 40 (gradual decrease)
                self.points.append((x, y))
            # Text point at the end
            self.points.append((95, 20))  # Text point at far right, low
        else:
            self.points = points
        self.setMouseTracking(True)

    def paintEvent(self, event):
        qp = QtGui.QPainter(self)
        qp.setRenderHint(QtGui.QPainter.RenderHint.Antialiasing)
        w, h = self.width(), self.height()

        # Get system colors from palette
        palette = self.palette()
        base_color = palette.color(QtGui.QPalette.ColorRole.Base)
        text_color = palette.color(QtGui.QPalette.ColorRole.Text)
        disabled_text = palette.color(QtGui.QPalette.ColorRole.PlaceholderText)
        highlight_color = palette.color(QtGui.QPalette.ColorRole.Highlight)
        window_color = palette.color(QtGui.QPalette.ColorRole.Window)

        # Apply disabled state
        if not self.enabled:
            qp.setOpacity(0.4)

        # Draw background
        qp.fillRect(self.rect(), base_color)

        # Draw minimal grid
        grid_color = disabled_text if not self.enabled else text_color
        grid_color.setAlpha(30)
        qp.setPen(QtGui.QPen(grid_color, 1))

        # Simple grid lines without labels - 11 vertical lines create 10 equal spaces
        for i in range(1, 11):  # 10 vertical lines (plus the edges = 11 total)
            x = i * (w - 2 * self.radius) / 10 + self.radius
            qp.drawLine(int(x), self.radius, int(x), h - self.radius)
        for i in range(1, 10):  # Keep 9 horizontal lines
            y = i * (h - 2 * self.radius) / 10 + self.radius
            qp.drawLine(self.radius, int(y), w - self.radius, int(y))

        # Draw curve
        curve_color = disabled_text if not self.enabled else highlight_color
        pen = QtGui.QPen(curve_color, 2)
        qp.setPen(pen)

        if len(self.points) > 1:
            for i in range(len(self.points) - 1):
                p1 = self._to_screen(self.points[i], w, h)
                p2 = self._to_screen(self.points[i + 1], w, h)
                qp.drawLine(*p1, *p2)

        # Draw control points
        for idx, pt in enumerate(self.points):
            x, y = self._to_screen(pt, w, h)
            is_hover = idx == self.hover_idx and self.enabled
            is_drag = idx == self.drag_idx and self.enabled

            # Point styling
            if is_drag:
                r = 8
                color = highlight_color.lighter(120)
                border_color = highlight_color
            elif is_hover:
                r = 7
                color = highlight_color.lighter(150)
                border_color = highlight_color
            else:
                r = 5
                if not self.enabled:
                    color = disabled_text
                    border_color = disabled_text
                elif idx == 9:  # Text point
                    color = window_color
                    border_color = text_color
                else:  # Accent points
                    color = base_color
                    border_color = highlight_color

            # Draw point
            qp.setBrush(color)
            qp.setPen(QtGui.QPen(border_color, 1))
            qp.drawEllipse(QtCore.QPointF(x, y), r, r)

    def _to_screen(self, pt, w, h):
        # pt: (bri, sat) in 0-100
        x = pt[0] / 100 * (w - 2 * self.radius) + self.radius
        y = (100 - pt[1]) / 100 * (h - 2 * self.radius) + self.radius
        return int(x), int(y)

    def _from_screen(self, x, y, w, h):
        bri = (x - self.radius) / (w - 2 * self.radius) * 100
        sat = 100 - (y - self.radius) / (h - 2 * self.radius) * 100
        return max(0, min(100, bri)), max(0, min(100, sat))

    def mousePressEvent(self, event):
        if not self.enabled:
            return
        w, h = self.width(), self.height()
        for idx, pt in enumerate(self.points):
            px, py = self._to_screen(pt, w, h)
            if (event.position().x() - px) ** 2 + (event.position().y() - py) ** 2 < (
                self.radius * 1.3
            ) ** 2 * 2:
                self.drag_idx = idx
                self._drag_pos = (event.position().x(), event.position().y())
                self.update()
                break

    def mouseMoveEvent(self, event):
        if not self.enabled:
            return
        w, h = self.width(), self.height()
        found = False
        for idx, pt in enumerate(self.points):
            px, py = self._to_screen(pt, w, h)
            if (event.position().x() - px) ** 2 + (event.position().y() - py) ** 2 < (
                self.radius * 1.3
            ) ** 2 * 2:
                self.hover_idx = idx
                self.setCursor(QtCore.Qt.CursorShape.PointingHandCursor)
                # Show tooltip with current values
                bri, sat = pt
                if idx == 9:
                    self.setToolTip(
                        f"Text: Brightness={int(bri)}%, Saturation={int(sat)}%\nDrag to adjust text color properties"
                    )
                else:
                    self.setToolTip(
                        f"Accent {idx + 1}: Brightness={int(bri)}%, Saturation={int(sat)}%\nDrag to adjust this accent color's properties"
                    )
                found = True
                break
        if not found:
            self.hover_idx = None
            self.setCursor(QtCore.Qt.CursorShape.ArrowCursor)
            self.setToolTip("")
        if self.drag_idx is not None:
            bri, sat = self._from_screen(event.position().x(), event.position().y(), w, h)
            self.points[self.drag_idx] = (bri, sat)
            self._drag_pos = (event.position().x(), event.position().y())
            # Mark as touched when user drags
            if not self.has_been_touched:
                self.has_been_touched = True
                self.userTouchedCurve.emit()  # Signal to switch to "Custom"
            # Update tooltip during drag
            if self.drag_idx == 9:
                self.setToolTip(f"Text: Brightness={int(bri)}%, Saturation={int(sat)}%")
            else:
                self.setToolTip(
                    f"Accent {self.drag_idx + 1}: Brightness={int(bri)}%, Saturation={int(sat)}%"
                )
            self.curveChanged.emit(self.points)
            self.update()
        else:
            self._drag_pos = None
            self.update()

    def setEnabled(self, enabled):
        """Enable or disable the curve editor"""
        self.enabled = enabled
        if not enabled:
            self.hover_idx = None
            self.drag_idx = None
            self.setCursor(QtCore.Qt.CursorShape.ArrowCursor)
            self.setToolTip("Curve editor is disabled")
        else:
            self.setToolTip("")
        self.update()

    def mouseReleaseEvent(self, event):
        self.drag_idx = None
        self._drag_pos = None
        self.update()

    def leaveEvent(self, event):
        self.hover_idx = None
        self.setCursor(QtCore.Qt.CursorShape.ArrowCursor)
        self.update()

    def _animate(self):
        # For future: smooth animation if needed
        self.update()

    def get_curve_str(self):
        return "\n".join(f"{int(bri)} {int(sat)}" for bri, sat in self.points)

    def set_curve_str(self, curve_str):
        pts = []
        for line in curve_str.strip().splitlines():
            parts = line.strip().replace(",", " ").replace(":", " ").split()
            if len(parts) >= 2:
                try:
                    bri = float(parts[0])
                    sat = float(parts[1])
                    pts.append((bri, sat))
                except Exception:
                    continue
        while len(pts) < 10:  # Now need 10 points
            pts.append((100, 100))
        self.points = pts[:10]
        self.update()


# ---- Qt GUI ----


class ColorShuffleQt(QtWidgets.QWidget):
    def __init__(
        self,
        initial_colors,
        initial_texts,
        mode,
        input_path,
        output_path,
        accent_colors,
        curve_str,
        curve_presets,
    ):
        super().__init__()
        self.setWindowTitle("Hyde Color Editor")

        # FORCE FLOATING - This WILL work!
        self.setWindowFlags(QtCore.Qt.WindowType.Window | QtCore.Qt.WindowType.WindowStaysOnTopHint)

        # Set window properties
        self.setAttribute(QtCore.Qt.WidgetAttribute.WA_AlwaysShowToolTips)

        # Setup keyboard shortcuts
        self.save_shortcut = QtGui.QShortcut(QtGui.QKeySequence("Ctrl+S"), self)
        self.save_shortcut.activated.connect(self.on_save)

        self.input_path = input_path
        self.output_path = output_path
        self.curve_presets = curve_presets or {
            "Wallbash": "32 50\n42 46\n49 40\n56 39\n64 38\n76 37\n90 33\n94 29\n100 20",
            "Mono": "10 0\n17 0\n24 0\n39 0\n51 0\n58 0\n72 0\n84 0\n99 0\n20 0",
            "Pastel": "10 99\n17 66\n24 49\n39 41\n51 37\n58 34\n72 30\n84 26\n99 22\n30 40",
            "Vibrant": "18 99\n32 97\n48 95\n55 90\n70 80\n80 70\n88 60\n94 40\n99 24\n40 85",
            "Contrast+": "10 100\n20 100\n30 100\n40 100\n55 100\n70 100\n80 100\n90 100\n100 100\n5 100",
            "Contrast-": "10 10\n20 20\n30 30\n40 40\n55 55\n70 70\n80 80\n90 90\n100 100\n15 15",
        }
        self.curve_str = curve_str
        self.mode = mode
        ColorRow = type("ColorRow", (), {})
        self.color_rows = []
        self.text_locked = [True, True, True, True]  # Text colors locked by default
        self.primary_locked = [
            False,
            False,
            False,
            False,
        ]  # Primary colors unlocked by default
        self.accent_locked = [[False] * 9 for _ in range(4)]  # Accent colors unlocked by default
        # Store original colors for reset functionality
        self.original_colors = initial_colors.copy()
        self.original_texts = initial_texts.copy()
        self.original_accents = []
        for i in range(4):  # Back to 4 rows
            row = ColorRow()
            row.primary = initial_colors[i]
            row.text = initial_texts[i]
            # Store original accent colors
            row_accents = []
            for j in range(9):
                accent_color = accent_colors[i][j][1]
                setattr(row, f"accent{j + 1}", accent_color)
                row_accents.append(accent_color)
            self.original_accents.append(row_accents)
            self.color_rows.append(row)
        self.drag_row_idx = None
        self._setup_ui()

    def _setup_ui(self):
        layout = QtWidgets.QVBoxLayout(self)
        layout.setSpacing(2)  # Very compact spacing
        layout.setContentsMargins(3, 3, 3, 3)  # Minimal margins

        # === TOP BAR: Title with Save/Reset buttons ===
        top_bar = QtWidgets.QHBoxLayout()
        top_bar.setContentsMargins(0, 0, 0, 0)
        top_bar.setSpacing(5)

        # Title
        title_label = QtWidgets.QLabel("Hyde Color Editor")
        title_label.setStyleSheet("font-weight: bold; font-size: 14px;")
        top_bar.addWidget(title_label)

        top_bar.addStretch()  # Push buttons to the right

        # Reset button with icon
        reset_btn = QtWidgets.QPushButton("↻")  # Reset symbol
        reset_btn.setFixedSize(30, 30)
        reset_btn.setToolTip("Reset to original colors")
        reset_btn.clicked.connect(self.on_reset)
        top_bar.addWidget(reset_btn)

        # Save button with icon
        save_btn = QtWidgets.QPushButton("💾")  # Save icon
        save_btn.setFixedSize(30, 30)
        save_btn.setToolTip("Save colors (Ctrl+S)")
        save_btn.clicked.connect(self.on_save)
        top_bar.addWidget(save_btn)

        layout.addLayout(top_bar)

        # === MAIN SECTION: Color Grid + Curve Editor (Side by Side) ===
        main_content = QtWidgets.QHBoxLayout()
        main_content.setSpacing(6)

        # LEFT: Color Palette (Direct, no wrapper)
        palette_label = QtWidgets.QLabel("Color Palette")
        palette_label.setStyleSheet("font-weight: bold;")
        palette_label.setContentsMargins(0, 0, 0, 0)

        # Color grid as QListWidget for drag-and-drop
        self.row_list = QtWidgets.QListWidget()
        self.row_list.setFixedWidth(420)  # Increased width for extra text column
        self.row_list.setDragDropMode(QtWidgets.QAbstractItemView.DragDropMode.InternalMove)
        self.row_list.setDefaultDropAction(QtCore.Qt.DropAction.MoveAction)
        self.row_list.setSpacing(1)  # 1px spacing between rows
        self.row_list.setSelectionMode(QtWidgets.QAbstractItemView.SelectionMode.NoSelection)
        self.row_list.setVerticalScrollBarPolicy(QtCore.Qt.ScrollBarPolicy.ScrollBarAlwaysOff)
        self.row_list.setHorizontalScrollBarPolicy(QtCore.Qt.ScrollBarPolicy.ScrollBarAlwaysOff)
        self.row_list.setFrameShape(QtWidgets.QFrame.Shape.NoFrame)
        self.row_list.setStyleSheet(
            "QListWidget { padding: 1; margin: 0; border: none; border-radius: 0px; background: transparent; } QListWidget::item { margin: 0; padding: 0; background: transparent; } QPushButton { min-width: 0; min-height: 0; padding: 0; margin: 0; }"
        )
        self.row_widgets = []
        for i in range(4):  # Back to 4 rows
            w = QtWidgets.QWidget()
            hbox = QtWidgets.QHBoxLayout(w)
            hbox.setSpacing(1)  # Set 1px spacing between color boxes
            hbox.setContentsMargins(2, 2, 2, 2)  # Small margins around the widget
            pry_btn = QtWidgets.QPushButton()
            pry_btn.setFixedSize(35, 25)  # Smaller color boxes for compact layout
            pry_btn.setSizePolicy(
                QtWidgets.QSizePolicy.Policy.Fixed, QtWidgets.QSizePolicy.Policy.Fixed
            )
            pry_btn.clicked.connect(lambda _, idx=i: self.pick_color(idx, "primary"))
            pry_btn.setContextMenuPolicy(QtCore.Qt.ContextMenuPolicy.CustomContextMenu)
            pry_btn.customContextMenuRequested.connect(
                lambda pos, idx=i: self.toggle_primary_lock(idx)
            )
            # Set initial style and tooltip
            self.update_primary_button_style(pry_btn, i)
            self.update_primary_button_tooltip(pry_btn, i)
            hbox.addWidget(pry_btn)
            txt_btn = QtWidgets.QPushButton()
            txt_btn.setFixedSize(35, 25)  # Smaller color boxes for compact layout
            txt_btn.setSizePolicy(
                QtWidgets.QSizePolicy.Policy.Fixed, QtWidgets.QSizePolicy.Policy.Fixed
            )
            txt_btn.clicked.connect(lambda _, idx=i: self.pick_color(idx, "text"))
            txt_btn.setContextMenuPolicy(QtCore.Qt.ContextMenuPolicy.CustomContextMenu)
            txt_btn.customContextMenuRequested.connect(
                lambda pos, idx=i: self.toggle_text_lock(idx)
            )
            # Set initial text to lock icon since locked by default
            txt_btn.setText("🔒")
            # Set initial tooltip and style based on lock state
            self.update_text_button_style(txt_btn, i)
            self.update_text_button_tooltip(txt_btn, i)
            hbox.addWidget(txt_btn)
            acc_btns = []
            for j in range(9):
                color = getattr(self.color_rows[i], f"accent{j + 1}")
                acc_btn = QtWidgets.QPushButton()
                acc_btn.setFixedSize(35, 25)  # Smaller color boxes for compact layout
                acc_btn.setSizePolicy(
                    QtWidgets.QSizePolicy.Policy.Fixed,
                    QtWidgets.QSizePolicy.Policy.Fixed,
                )
                acc_btn.clicked.connect(lambda _, ii=i, jj=j: self.pick_color((ii, jj), "accent"))
                acc_btn.setContextMenuPolicy(QtCore.Qt.ContextMenuPolicy.CustomContextMenu)
                acc_btn.customContextMenuRequested.connect(
                    lambda pos, ii=i, jj=j: self.toggle_accent_lock(ii, jj)
                )
                # Set initial style and tooltip
                self.update_accent_button_style(acc_btn, i, j)
                self.update_accent_button_tooltip(acc_btn, i, j)
                hbox.addWidget(acc_btn)
                acc_btns.append(acc_btn)
            # Add a stretch to push all color boxes to the left and prevent expansion
            hbox.addStretch()
            w.setLayout(hbox)
            w.setMinimumHeight(25)  # Compact height
            w.setMaximumHeight(25)  # Compact height
            item = QtWidgets.QListWidgetItem()
            item.setSizeHint(QtCore.QSize(w.sizeHint().width(), 25))
            self.row_list.addItem(item)
            self.row_list.setItemWidget(item, w)
            self.row_widgets.append((pry_btn, txt_btn, acc_btns))
        self.row_list.setMinimumHeight(108)  # 4 rows × 25px + some spacing
        self.row_list.setMaximumHeight(108)

        # Add palette label and grid directly to main content with minimal spacing
        palette_layout = QtWidgets.QVBoxLayout()
        palette_layout.setContentsMargins(0, 0, 0, 0)
        palette_layout.setSpacing(1)  # Minimal spacing between label and grid
        palette_layout.addWidget(palette_label)

        # Add column headers
        header_widget = QtWidgets.QWidget()
        header_layout = QtWidgets.QHBoxLayout(header_widget)
        header_layout.setSpacing(1)
        header_layout.setContentsMargins(2, 0, 2, 0)

        # Header labels with same width as color buttons
        primary_header = QtWidgets.QLabel("P")
        primary_header.setFixedSize(35, 20)
        primary_header.setAlignment(QtCore.Qt.AlignmentFlag.AlignCenter)
        primary_header.setStyleSheet("font-weight: bold; font-size: 10px;")
        primary_header.setToolTip("Primary Color")
        header_layout.addWidget(primary_header)

        text_header = QtWidgets.QLabel("T")
        text_header.setFixedSize(35, 20)
        text_header.setAlignment(QtCore.Qt.AlignmentFlag.AlignCenter)
        text_header.setStyleSheet("font-weight: bold; font-size: 10px;")
        text_header.setToolTip("Text Color")
        header_layout.addWidget(text_header)

        for i in range(9):
            acc_header = QtWidgets.QLabel(f"A{i + 1}")
            acc_header.setFixedSize(35, 20)
            acc_header.setAlignment(QtCore.Qt.AlignmentFlag.AlignCenter)
            acc_header.setStyleSheet("font-weight: bold; font-size: 10px;")
            acc_header.setToolTip(f"Accent Color {i + 1}")
            header_layout.addWidget(acc_header)

        header_layout.addStretch()
        palette_layout.addWidget(header_widget)
        palette_layout.addWidget(self.row_list)
        main_content.addLayout(palette_layout)

        # RIGHT: Curve Editor
        curve_layout = QtWidgets.QVBoxLayout()
        curve_layout.setContentsMargins(0, 0, 0, 0)
        curve_layout.setSpacing(1)  # Minimal spacing

        curve_label = QtWidgets.QLabel("Accent Color Generator")
        curve_label.setStyleSheet("font-weight: bold;")
        curve_layout.addWidget(curve_label)

        # Curve editor
        self.curve_editor = CurveEditor()
        self.curve_editor.set_curve_str(self.curve_str)
        self.curve_editor.curveChanged.connect(self.on_curve_changed)
        self.curve_editor.userTouchedCurve.connect(self.on_user_touched_curve)
        self.curve_editor.setMinimumHeight(160)  # Increased to match CurveEditor
        self.curve_editor.setMaximumHeight(200)  # Increased for more space
        curve_layout.addWidget(self.curve_editor)

        # Add explanation text
        self.curve_explanation = QtWidgets.QLabel("Select a preset to enable curve generation")
        self.curve_explanation.setWordWrap(True)
        curve_layout.addWidget(self.curve_explanation)
        main_content.addLayout(curve_layout)

        layout.addLayout(main_content)

        # === CURVE CONTROLS ===
        curve_controls = QtWidgets.QHBoxLayout()
        curve_controls.setSpacing(5)

        curve_controls.addWidget(QtWidgets.QLabel("Preset:"))
        self.curve_combo = QtWidgets.QComboBox()
        self.curve_combo.setMaximumWidth(100)
        self.curve_combo.addItem("Wallbash")  # Start with wallbash as default
        for name in self.curve_presets:
            if name != "Wallbash":  # Don't add Wallbash twice
                self.curve_combo.addItem(name)
        self.curve_combo.addItem("Custom")
        self.curve_combo.currentTextChanged.connect(self.on_curve_preset)
        curve_controls.addWidget(self.curve_combo)

        self.curve_entry = QtWidgets.QLineEdit(self.curve_str)
        self.curve_entry.setPlaceholderText("Custom curve values...")
        self.curve_entry.textChanged.connect(self.on_curve_text_changed)
        curve_controls.addWidget(self.curve_entry)

        layout.addLayout(curve_controls)

        # === ACTIONS ===
        actions_layout = QtWidgets.QHBoxLayout()
        actions_layout.setSpacing(8)

        self.mode_switch = QtWidgets.QCheckBox("Dark Mode")
        self.mode_switch.setChecked("dark" in self.mode.lower() if self.mode else False)
        actions_layout.addWidget(self.mode_switch)

        rotate_btn = QtWidgets.QPushButton("Rotate")
        rotate_btn.setMaximumWidth(80)
        rotate_btn.clicked.connect(self.on_rotate)
        actions_layout.addWidget(rotate_btn)

        actions_layout.addStretch()  # Push buttons to the left
        layout.addLayout(actions_layout)

        # === FILE PATHS (Compact) ===
        files_layout = QtWidgets.QVBoxLayout()
        files_layout.setSpacing(2)

        # Input file row
        input_row = QtWidgets.QHBoxLayout()
        input_row.addWidget(QtWidgets.QLabel("Input:"))
        self.input_entry = QtWidgets.QLineEdit(self.input_path)
        input_row.addWidget(self.input_entry)
        input_btn = QtWidgets.QPushButton("...")
        input_btn.setMaximumWidth(30)
        input_btn.clicked.connect(self.on_input_pick)
        input_row.addWidget(input_btn)
        files_layout.addLayout(input_row)

        # Output file row
        output_row = QtWidgets.QHBoxLayout()
        output_row.addWidget(QtWidgets.QLabel("Output:"))
        self.output_entry = QtWidgets.QLineEdit(self.output_path)
        output_row.addWidget(self.output_entry)
        output_btn = QtWidgets.QPushButton("...")
        output_btn.setMaximumWidth(30)
        output_btn.clicked.connect(self.on_output_pick)
        output_row.addWidget(output_btn)
        files_layout.addLayout(output_row)

        layout.addLayout(files_layout)

        # Auto-resize to minimum needed size but allow expansion
        self.adjustSize()
        self.setMinimumSize(self.sizeHint())  # Allow window to be resized larger

    def toggle_primary_lock(self, row_idx):
        """Toggle primary lock state for a specific row"""
        self.primary_locked[row_idx] = not self.primary_locked[row_idx]
        # Update button appearance and tooltip
        pry_btn = self.row_widgets[row_idx][0]
        self.update_primary_button_style(pry_btn, row_idx)
        self.update_primary_button_tooltip(pry_btn, row_idx)

    def toggle_accent_lock(self, row_idx, accent_idx):
        """Toggle accent lock state for a specific accent color"""
        self.accent_locked[row_idx][accent_idx] = not self.accent_locked[row_idx][accent_idx]
        # Update button appearance and tooltip
        acc_btn = self.row_widgets[row_idx][2][accent_idx]
        self.update_accent_button_style(acc_btn, row_idx, accent_idx)
        self.update_accent_button_tooltip(acc_btn, row_idx, accent_idx)

    def toggle_text_lock(self, row_idx):
        """Toggle text lock state for a specific row"""
        self.text_locked[row_idx] = not self.text_locked[row_idx]
        # Update button appearance and tooltip
        txt_btn = self.row_widgets[row_idx][1]
        self.update_text_button_style(txt_btn, row_idx)
        self.update_text_button_tooltip(txt_btn, row_idx)

    def update_primary_button_style(self, pry_btn, row_idx):
        """Update primary button style based on lock state"""
        color = self.color_rows[row_idx].primary
        if self.primary_locked[row_idx]:
            # Locked: border with lock symbol overlay
            r = int(color[0:2], 16)
            g = int(color[2:4], 16)
            b = int(color[4:6], 16)
            brightness = (r * 0.299 + g * 0.587 + b * 0.114) / 255
            text_color = "black" if brightness > 0.5 else "white"

            pry_btn.setStyleSheet(
                f"QPushButton {{ background-color: #{color}; border: 2px solid #888; margin: 0px; padding: 0px; border-radius: 2px; color: {text_color}; font-weight: bold; font-size: 8px; min-width: 35px; max-width: 35px; min-height: 25px; max-height: 25px; }}"
            )
            pry_btn.setText("🔒")
        else:
            # Unlocked: no border, no symbol
            pry_btn.setStyleSheet(
                f"QPushButton {{ background-color: #{color}; border: 0px; margin: 0px; padding: 0px; border-radius: 2px; min-width: 35px; max-width: 35px; min-height: 25px; max-height: 25px; }}"
            )
            pry_btn.setText("")

    def update_primary_button_tooltip(self, pry_btn, row_idx):
        """Update primary button tooltip based on lock state"""
        if self.primary_locked[row_idx]:
            pry_btn.setToolTip("🔒 Primary color is LOCKED (fixed)\nRight-click to unlock")
        else:
            pry_btn.setToolTip("🔓 Primary color is unlocked\nRight-click to lock (fix color)")

    def update_accent_button_style(self, acc_btn, row_idx, accent_idx):
        """Update accent button style based on lock state"""
        color = getattr(self.color_rows[row_idx], f"accent{accent_idx + 1}")
        if self.accent_locked[row_idx][accent_idx]:
            # Locked: border with lock symbol overlay
            r = int(color[0:2], 16)
            g = int(color[2:4], 16)
            b = int(color[4:6], 16)
            brightness = (r * 0.299 + g * 0.587 + b * 0.114) / 255
            text_color = "black" if brightness > 0.5 else "white"

            acc_btn.setStyleSheet(
                f"QPushButton {{ background-color: #{color}; border: 2px solid #888; margin: 0px; padding: 0px; border-radius: 2px; color: {text_color}; font-weight: bold; font-size: 8px; min-width: 35px; max-width: 35px; min-height: 25px; max-height: 25px; }}"
            )
            acc_btn.setText("🔒")
        else:
            # Unlocked: no border, no symbol
            acc_btn.setStyleSheet(
                f"QPushButton {{ background-color: #{color}; border: 0px; margin: 0px; padding: 0px; border-radius: 2px; min-width: 35px; max-width: 35px; min-height: 25px; max-height: 25px; }}"
            )
            acc_btn.setText("")

    def update_accent_button_tooltip(self, acc_btn, row_idx, accent_idx):
        """Update accent button tooltip based on lock state"""
        if self.accent_locked[row_idx][accent_idx]:
            acc_btn.setToolTip(
                f"🔒 Accent {accent_idx + 1} is LOCKED (independent)\nRight-click to unlock and follow curve"
            )
        else:
            acc_btn.setToolTip(
                f"🔓 Accent {accent_idx + 1} follows curve\nRight-click to lock (make independent)"
            )

    def update_text_button_style(self, txt_btn, row_idx):
        """Update text button style based on lock state"""
        color = self.color_rows[row_idx].text
        if self.text_locked[row_idx]:
            # Locked: thick border with lock symbol overlay
            # Use contrasting text color based on background brightness
            r = int(color[0:2], 16)
            g = int(color[2:4], 16)
            b = int(color[4:6], 16)
            brightness = (r * 0.299 + g * 0.587 + b * 0.114) / 255
            text_color = "black" if brightness > 0.5 else "white"

            txt_btn.setStyleSheet(
                f"QPushButton {{ background-color: #{color}; border: 2px solid #888; margin: 0px; padding: 0px; border-radius: 2px; color: {text_color}; font-weight: bold; font-size: 8px; min-width: 35px; max-width: 35px; min-height: 25px; max-height: 25px; }}"
            )
            txt_btn.setText("🔒")
        else:
            # Unlocked: same border thickness, different color
            txt_btn.setStyleSheet(
                f"QPushButton {{ background-color: #{color}; border: 2px solid #ccc; margin: 0px; padding: 0px; border-radius: 2px; min-width: 35px; max-width: 35px; min-height: 25px; max-height: 25px; }}"
            )
            txt_btn.setText("")

    def update_text_button_tooltip(self, txt_btn, row_idx):
        """Update text button tooltip based on lock state"""
        if self.text_locked[row_idx]:
            txt_btn.setToolTip(
                "🔒 Text color is LOCKED (independent)\nRight-click to unlock and follow curve"
            )
        else:
            txt_btn.setToolTip(
                "🔓 Text color follows curve\nRight-click to lock (make independent)"
            )

    def update_from_color_rows(self):
        for i, (pry_btn, txt_btn, acc_btns) in enumerate(self.row_widgets):
            # Update primary button with lock state
            self.update_primary_button_style(pry_btn, i)
            # Update text button with lock state
            self.update_text_button_style(txt_btn, i)
            # Update accent buttons with lock state
            for j, btn in enumerate(acc_btns):
                self.update_accent_button_style(btn, i, j)

    def pick_color(self, idx, kind):
        if kind == "primary":
            color = self.color_rows[idx].primary
        elif kind == "text":
            color = self.color_rows[idx].text
        else:
            i, j = idx
            color = getattr(self.color_rows[i], f"accent{j + 1}")
        dlg = QtWidgets.QColorDialog(QtGui.QColor(f"#{color}"), self)
        if dlg.exec():
            new_color = dlg.selectedColor().name()[1:].upper()
            if kind == "primary":
                self.color_rows[idx].primary = new_color
                # Auto-update accents based on current curve when primary changes
                if self.curve_editor.enabled:
                    self.apply_curve_to_accents_and_text(self.curve_entry.text())
                else:
                    # If no curve is active, use default curve for this row only
                    self.apply_default_curve_to_row(idx)
            elif kind == "text":
                self.color_rows[idx].text = new_color
            else:
                i, j = idx
                setattr(self.color_rows[i], f"accent{j + 1}", new_color)
            self.update_from_color_rows()

    def apply_default_curve_to_row(self, row_idx):
        """Apply default curve to a single row when primary color changes"""
        import colorsys

        # Use the EXACT wallbash default curve from the script
        default_curve_str = "32 50\n42 46\n49 40\n56 39\n64 38\n76 37\n90 33\n94 29\n100 20"
        curve = []
        for line in default_curve_str.strip().splitlines():
            parts = line.strip().split()
            if len(parts) >= 2:
                try:
                    bri = float(parts[0])
                    sat = float(parts[1])
                    curve.append((bri, sat))
                except Exception:
                    continue

        # Apply curve to this row only
        base = self.color_rows[row_idx].primary
        r = int(base[0:2], 16) / 255.0
        g = int(base[2:4], 16) / 255.0
        b = int(base[4:6], 16) / 255.0
        h, s, v = colorsys.rgb_to_hsv(r, g, b)

        # Update accent colors (A1-A9) for this row (only if not locked)
        for j in range(9):
            if len(curve) > j and not self.accent_locked[row_idx][j]:
                bri, sat = curve[j]
                v2 = max(0, min(1, bri / 100.0))
                s2 = max(0, min(1, sat / 100.0))
                r2, g2, b2 = colorsys.hsv_to_rgb(h, s2, v2)
                hexcol = f"{int(r2 * 255):02X}{int(g2 * 255):02X}{int(b2 * 255):02X}"
                setattr(self.color_rows[row_idx], f"accent{j + 1}", hexcol)

        # Update text color if not locked
        if not self.text_locked[row_idx]:
            if len(curve) > 9:
                # Use curve's 10th point for text (respects the curve)
                bri, sat = curve[9]  # This is the 10th point for text
                v_text = max(0, min(1, bri / 100.0))
                s_text = max(0, min(1, sat / 100.0))
                r_text, g_text, b_text = colorsys.hsv_to_rgb(h, s_text, v_text)
                text_hex = f"{int(r_text * 255):02X}{int(g_text * 255):02X}{int(b_text * 255):02X}"
                self.color_rows[row_idx].text = text_hex
            else:
                # Use wallbash text color algorithm - RGB negative + brightness modulation
                primary_r = int(base[0:2], 16)
                primary_g = int(base[2:4], 16)
                primary_b = int(base[4:6], 16)

                # Step 1: Create RGB negative (wallbash rgb_negative function)
                neg_r = 255 - primary_r
                neg_g = 255 - primary_g
                neg_b = 255 - primary_b

                # Step 2: Check brightness of primary (wallbash fx_brightness function)
                # Uses ImageMagick's %[fx:mean] which is grayscale conversion
                primary_brightness = (
                    0.299 * primary_r + 0.587 * primary_g + 0.114 * primary_b
                ) / 255.0

                # Step 3: Apply brightness modulation like wallbash
                if primary_brightness < 0.5:
                    # Dark primary -> bright text (txtDarkBri=188)
                    brightness_mod = 188
                else:
                    # Light primary -> dark text (txtLightBri=16)
                    brightness_mod = 16

                # Step 4: Apply modulation to negative color (like ImageMagick -modulate)
                # Convert negative to HSV for brightness adjustment
                neg_h, neg_s, neg_v = colorsys.rgb_to_hsv(
                    neg_r / 255.0, neg_g / 255.0, neg_b / 255.0
                )

                # Apply brightness modulation (scale by percentage like ImageMagick)
                mod_v = min(1.0, neg_v * (brightness_mod / 100.0))
                mod_s = 0.1  # Low saturation like wallbash (,10,100 in modulate)

                # Convert back to RGB
                r_text, g_text, b_text = colorsys.hsv_to_rgb(neg_h, mod_s, mod_v)
                text_hex = f"{int(r_text * 255):02X}{int(g_text * 255):02X}{int(b_text * 255):02X}"
                self.color_rows[row_idx].text = text_hex

    def on_input_pick(self):
        path, _ = QtWidgets.QFileDialog.getOpenFileName(
            self, "Select Input .dcol File", "", "dcol files (*.dcol)"
        )
        if path:
            self.input_entry.setText(path)
            self.input_path = path
            self.load_dcol(path)

    def on_output_pick(self):
        path, _ = QtWidgets.QFileDialog.getSaveFileName(
            self, "Select Output .dcol File", "", "dcol files (*.dcol)"
        )
        if path:
            self.output_entry.setText(path)
            self.output_path = path

    def on_user_touched_curve(self):
        """Called when user manually drags a curve point"""
        # Switch to "Custom" if not already there
        if self.curve_combo.currentText() != "Custom":
            self.curve_combo.setCurrentText("Custom")
        self.curve_explanation.setText(
            "Custom curve - drag points to adjust accent and text colors"
        )

    def on_curve_text_changed(self):
        """Called when curve text entry is manually edited"""
        if self.curve_combo.currentText() != "Custom":
            self.curve_combo.setCurrentText("Custom")
        curve_str = self.curve_entry.text()
        self.curve_editor.set_curve_str(curve_str)
        if self.curve_editor.enabled:
            self.apply_curve_to_accents_and_text(curve_str)

    def on_curve_preset(self, text):
        if text == "Custom":
            # Enable curve for custom editing
            self.curve_editor.setEnabled(True)
            self.curve_explanation.setText(
                "Custom curve - drag points to adjust accent and text colors"
            )
        elif text in self.curve_presets:
            # Load preset and enable curve
            self.curve_entry.setText(self.curve_presets[text])
            self.curve_editor.set_curve_str(self.curve_presets[text])
            self.curve_editor.setEnabled(True)
            self.curve_editor.has_been_touched = False  # Reset touch state
            if text == "Wallbash":
                self.curve_explanation.setText(
                    "Wallbash default preset - drag points to customize or select another preset"
                )
            else:
                self.curve_explanation.setText(
                    f"{text} preset - drag points to customize or select another preset"
                )
            self.apply_curve_to_accents_and_text(self.curve_presets[text])

    def on_curve_changed(self, points):
        curve_str = "\n".join(f"{int(bri)} {int(sat)}" for bri, sat in points)
        self.curve_entry.setText(curve_str)
        if self.curve_editor.enabled:
            self.apply_curve_to_accents_and_text(curve_str)

    def apply_curve_to_accents_and_text(self, curve_str):
        import colorsys

        curve = []
        for line in curve_str.strip().splitlines():
            parts = line.strip().replace(",", " ").replace(":", " ").split()
            if len(parts) >= 2:
                try:
                    bri = float(parts[0])
                    sat = float(parts[1])
                    curve.append((bri, sat))
                except Exception:
                    continue
        while len(curve) < 10:  # Need 10 points (A1-A9, T)
            curve.append((100, 100))

        # Update colors for each row
        for i in range(4):  # Back to 4 rows
            # Use primary color as base for generating accents and text
            # But DON'T modify the primary color itself
            base = self.color_rows[i].primary
            r = int(base[0:2], 16) / 255.0
            g = int(base[2:4], 16) / 255.0
            b = int(base[4:6], 16) / 255.0
            h, s, v = colorsys.rgb_to_hsv(r, g, b)

            # Points 0-8 control accent colors (A1-A9) ONLY (if not locked)
            for j in range(9):
                if len(curve) > j and not self.accent_locked[i][j]:
                    bri, sat = curve[j]  # Points 0-8 for accents A1-A9
                    v2 = max(0, min(1, bri / 100.0))
                    s2 = max(0, min(1, sat / 100.0))
                    r2, g2, b2 = colorsys.hsv_to_rgb(h, s2, v2)
                    hexcol = f"{int(r2 * 255):02X}{int(g2 * 255):02X}{int(b2 * 255):02X}"
                    setattr(self.color_rows[i], f"accent{j + 1}", hexcol)
                # Update button styling regardless of whether color changed
                self.update_accent_button_style(self.row_widgets[i][2][j], i, j)

            # Point 9 controls text color ONLY (if not locked)
            if len(curve) > 9 and not self.text_locked[i]:
                bri, sat = curve[9]
                v_text = max(0, min(1, bri / 100.0))
                s_text = max(0, min(1, sat / 100.0))
                r_text, g_text, b_text = colorsys.hsv_to_rgb(h, s_text, v_text)
                text_hex = f"{int(r_text * 255):02X}{int(g_text * 255):02X}{int(b_text * 255):02X}"
                self.color_rows[i].text = text_hex
                # Update text button with proper lock styling
                self.update_text_button_style(self.row_widgets[i][1], i)

            # Primary color is NEVER modified by the curve - it stays as manually set

    def on_rotate(self):
        self.color_rows = self.color_rows[1:] + self.color_rows[:1]
        self.update_from_color_rows()

    def on_reset(self):
        """Reset all colors to their original values"""
        for i in range(4):  # Back to 4 rows
            self.color_rows[i].primary = self.original_colors[i]
            self.color_rows[i].text = self.original_texts[i]
            for j in range(9):
                setattr(self.color_rows[i], f"accent{j + 1}", self.original_accents[i][j])
        self.update_from_color_rows()
        # Reset curve preset to "Wallbash"
        self.curve_combo.setCurrentText("Wallbash")
        self.curve_editor.setEnabled(True)
        self.curve_explanation.setText(
            "Wallbash default preset - drag points to customize or select another preset"
        )

    def on_save(self):
        out_path = self.output_entry.text()
        mode_str = "dark" if self.mode_switch.isChecked() else "light"
        curve_str = self.curve_entry.text()
        try:
            with open(self.input_entry.text()) as f:
                orig_lines = f.readlines()
        except Exception as e:
            QtWidgets.QMessageBox.warning(self, "Error", f"Error reading input: {e}")
            return
        new_lines = []
        pry_idx = 0
        txt_idx = 0
        accent_idx = [0, 0, 0, 0]  # Back to 4 elements
        for line in orig_lines:
            if line.startswith("dcol_mode="):
                new_lines.append(f'dcol_mode="{mode_str}"\n')
            elif re.match(r"dcol_pry[1-4]=", line):  # Back to handling 4 rows
                if pry_idx < 4:
                    new_lines.append(
                        f'dcol_pry{pry_idx + 1}="{self.color_rows[pry_idx].primary}"\n'
                    )
                    pry_idx += 1
                else:
                    new_lines.append(line)
            elif re.match(r"dcol_pry[1-4]_rgba=", line):  # Back to handling 4 rows
                idx = int(re.search(r"dcol_pry([1-4])_rgba", line).group(1)) - 1
                if idx < 4:
                    c = self.color_rows[idx].primary
                    r = int(c[0:2], 16)
                    g = int(c[2:4], 16)
                    b = int(c[4:6], 16)
                    new_lines.append(f'dcol_pry{idx + 1}_rgba="rgba({r},{g},{b},1.00)"\n')
                else:
                    new_lines.append(line)
            elif re.match(r"dcol_txt[1-4]=", line):  # Back to handling 4 rows
                if txt_idx < 4:
                    new_lines.append(f'dcol_txt{txt_idx + 1}="{self.color_rows[txt_idx].text}"\n')
                    txt_idx += 1
                else:
                    new_lines.append(line)
            elif re.match(r"dcol_txt[1-4]_rgba=", line):  # Back to handling 4 rows
                idx = int(re.search(r"dcol_txt([1-4])_rgba", line).group(1)) - 1
                if idx < 4:
                    c = self.color_rows[idx].text
                    r = int(c[0:2], 16)
                    g = int(c[2:4], 16)
                    b = int(c[4:6], 16)
                    new_lines.append(f'dcol_txt{idx + 1}_rgba="rgba({r},{g},{b},1.00)"\n')
                else:
                    new_lines.append(line)
            elif re.match(r"dcol_([1-4])xa([1-9])=", line):  # Back to handling 4 rows
                m = re.match(r"dcol_([1-4])xa([1-9])=", line)
                i = int(m.group(1)) - 1
                j = accent_idx[i]
                if i < 4 and j < 9:
                    color = getattr(self.color_rows[i], f"accent{j + 1}")
                    new_lines.append(f'dcol_{i + 1}xa{j + 1}="{color}"\n')
                    accent_idx[i] += 1
                else:
                    new_lines.append(line)
            elif re.match(r"dcol_([1-4])xa([1-9])_rgba=", line):  # Back to handling 4 rows
                m = re.match(r"dcol_([1-4])xa([1-9])_rgba=", line)
                i = int(m.group(1)) - 1
                j = int(m.group(2)) - 1
                if i < 4:
                    c = getattr(self.color_rows[i], f"accent{j + 1}")
                    r = int(c[0:2], 16)
                    g = int(c[2:4], 16)
                    b = int(c[4:6], 16)
                    new_lines.append(f'dcol_{i + 1}xa{j + 1}_rgba="rgba({r},{g},{b},1.00)"\n')
                else:
                    new_lines.append(line)
            elif line.startswith("wallbashCurve="):
                new_lines.append(f'wallbashCurve="{curve_str}"\n')
            else:
                new_lines.append(line)
        with open(out_path, "w") as f:
            f.writelines(new_lines)
        QtWidgets.QMessageBox.information(self, "Saved", f"Saved: {out_path}")

    def load_dcol(self, path):
        try:
            with open(path) as f:
                lines = f.readlines()
        except Exception as e:
            QtWidgets.QMessageBox.warning(self, "Error", f"Error reading file: {e}")
            return
        mode, color_rows, other = extract_colors(lines)
        self.color_rows = color_rows
        self.mode = mode.split("=")[1].strip().strip('"') if mode else "light"
        self.mode_switch.setChecked("dark" in self.mode.lower())
        self.update_from_color_rows()
        # Optionally set curve string
        for line in lines:
            if line.startswith("wallbashCurve="):
                curve_str = line.split("=", 1)[1].strip().strip('"')
                self.curve_entry.setText(curve_str)
                self.curve_editor.set_curve_str(curve_str)
                break

    def eventFilter(self, obj, event):
        # Drag-and-drop for row reordering
        if event.type() == QtCore.QEvent.Type.MouseButtonPress:
            for i, btn in enumerate(self.pry_buttons):
                if obj is btn:
                    self.drag_row_idx = i
                    self.drag_start_pos = event.globalPosition().toPoint()
                    break
        elif event.type() == QtCore.QEvent.Type.MouseMove and self.drag_row_idx is not None:
            if (event.globalPosition().toPoint() - self.drag_start_pos).manhattanLength() > 10:
                # Start drag
                drag = QtGui.QDrag(self)
                mime = QtCore.QMimeData()
                mime.setText(str(self.drag_row_idx))
                drag.setMimeData(mime)
                drag.exec()
        elif event.type() == QtCore.QEvent.Type.Drop and self.drag_row_idx is not None:
            # Find which row we dropped on
            for i, btn in enumerate(self.pry_buttons):
                if obj is btn and i != self.drag_row_idx:
                    # Swap rows
                    self.color_rows[self.drag_row_idx], self.color_rows[i] = (
                        self.color_rows[i],
                        self.color_rows[self.drag_row_idx],
                    )
                    self.update_from_color_rows()
                    break
            self.drag_row_idx = None
        elif event.type() == QtCore.QEvent.Type.MouseButtonRelease:
            self.drag_row_idx = None
        return super().eventFilter(obj, event)


def main():
    parser = argparse.ArgumentParser(description="Manipulate .dcol color files.")
    parser.add_argument("input", nargs="?", help="Input .dcol file")
    parser.add_argument("-o", "--output", help="Output .dcol file", default=None)
    parser.add_argument("--shuffle", action="store_true", help="Shuffle the 4 main colors")
    parser.add_argument(
        "--rotate",
        action="store_true",
        help="Rotate the 4 main colors (1→2, 2→3, 3→4, 4→1)",
    )
    parser.add_argument(
        "--set-colors",
        nargs=4,
        metavar=("C1", "C2", "C3", "C4"),
        help="Override the 4 main primary colors (hex)",
    )
    parser.add_argument("--curve", type=str, help="Override the accent curve (not implemented yet)")
    parser.add_argument(
        "--gui", action="store_true", help="Open a Qt color picker UI for main colors"
    )
    parser.add_argument(
        "--mode",
        choices=["light", "dark"],
        help="Override dcol_mode (light or dark)",
    )
    args = parser.parse_args()

    # Set default input/output if --gui and not provided
    if args.gui and not args.input:
        xdg_cache = os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache"))
        args.input = os.path.join(xdg_cache, "hyde", "wall.dcol")
        if not args.output:
            args.output = args.input

    # Check if input file is provided and exists
    if not args.input:
        parser.error("Input file is required. Please provide an input .dcol file.")

    if not os.path.exists(args.input):
        parser.error(f"Input file does not exist: {args.input}")

    with open(args.input) as f:
        lines = f.readlines()

    if args.gui:
        print("[DEBUG] --gui flag detected, launching PyQt6 GUI...")
        app = QtWidgets.QApplication(sys.argv)
        print("[DEBUG] QApplication created, building main window...")
        # Read actual color data from .dcol file
        mode, color_rows, other = extract_colors(lines)
        # Parse colors from color_rows
        initial_colors = [row.primary for row in color_rows]
        initial_texts = [row.text for row in color_rows]
        accent_colors = [
            [(f"dcol_{i + 1}xa{j + 1}", getattr(row, f"accent{j + 1}")) for j in range(9)]
            for i, row in enumerate(color_rows)
        ]
        # Try to get curve string from wallbashCurve= if present
        curve_str = ""
        for line in lines:
            if line.startswith("wallbashCurve="):
                curve_str = line.split("=", 1)[1].strip().strip('"')
                break
        if not curve_str:
            curve_str = (
                "32 50\n42 46\n49 40\n56 39\n64 38\n76 37\n90 33\n94 29\n100 20"  # Wallbash default
            )
        curve_presets = {}
        input_path = args.input or ""
        output_path = args.output or input_path
        win = ColorShuffleQt(
            initial_colors,
            initial_texts,
            mode if mode and "dark" in mode else "light",
            input_path,
            output_path,
            accent_colors,
            curve_str,
            curve_presets,
        )
        print("[DEBUG] Showing main window...")
        win.show()
        sys.exit(app.exec())
    mode, color_rows, other = extract_colors(lines)

    # Optionally override primaries
    if args.set_colors:
        for i, c in enumerate(args.set_colors):
            color_rows[i].primary = c.upper()

    # Shuffle or rotate
    if args.shuffle:
        idx = list(range(4))
        random.shuffle(idx)
    elif args.rotate:
        idx = [1, 2, 3, 0]
    else:
        idx = list(range(4))
    color_rows = [color_rows[i] for i in idx]

    # Write output
    out_lines = []
    if mode:
        if args.mode:
            out_lines.append(f'dcol_mode="{args.mode}")\n')
        else:
            out_lines.append(mode)
    # Write primaries
    for i, row in enumerate(color_rows):
        out_lines.append(f'dcol_pry{i + 1}="{row.primary}"\n')
    # Write texts
    for i, row in enumerate(color_rows):
        out_lines.append(f'dcol_txt{i + 1}="{row.text}"\n')
    # Write accents
    for i, row in enumerate(color_rows):
        for j in range(9):
            out_lines.append(f'dcol_{i + 1}xa{j + 1}="{getattr(row, f"accent{j + 1}")}"\n')
    out_lines.extend(other)

    out_path = args.output or args.input + ".out"
    with open(out_path, "w") as f:
        f.writelines(out_lines)

    print(f"Wrote: {out_path}")


main()
