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
    
    m = re.match(r"rgba\((\d+),(\d+),(\d+),", rgba_str)
    if m:
        r, g, b = map(int, m.groups())
        return f"{r:02X}{g:02X}{b:02X}"
    return "FFFFFF"


def extract_colors(lines):
    mode = None
    primaries = []
    texts = []
    accents = []  
    other = []
    for line in lines:
        if line.startswith("dcol_mode="):
            mode = line
        elif re.match(r"dcol_pry[1-4]=", line):
            primaries.append(line)
        elif re.match(r"dcol_pry[1-4]_rgba=", line):
            pass  
        elif re.match(r"dcol_txt[1-4]=", line):
            texts.append(line)
        elif re.match(r"dcol_txt[1-4]_rgba=", line):
            pass  
        elif re.match(r"dcol_([1-9])xa([1-9])=", line):
            m = re.match(r"dcol_([1-9])xa([1-9])=\"?([0-9A-Fa-f]{6}|[a-zA-Z])\"?", line)
            if m:
                x = int(m.group(1)) - 1
                y = int(m.group(2)) - 1
                val = m.group(3)
                while len(accents) <= x:
                    accents.append([])
                
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
                accents[x].append(val)
        else:
            other.append(line)
    
    while len(accents) < 4:
        accents.append([])
    
    for row in accents:
        while len(row) < 9:
            row.append("FFFFFF")
    
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

    def __init__(self, points=None, parent=None):
        super().__init__(parent)
        self.setMinimumHeight(120)
        self.setMinimumWidth(400)
        self.radius = 8
        self.drag_idx = None
        self.hover_idx = None
        self.anim_scale = 1.0
        if points is None:
            self.points = [(i * 40, 100 - i * 10) for i in range(9)]
        else:
            self.points = points
        self.setMouseTracking(True)
        
        
        
        

    def paintEvent(self, event):
        qp = QtGui.QPainter(self)
        qp.setRenderHint(QtGui.QPainter.RenderHint.Antialiasing)
        w, h = self.width(), self.height()
        
        pen = QtGui.QPen(QtGui.QColor("
        qp.setPen(pen)
        for i in range(8):
            p1 = self._to_screen(self.points[i], w, h)
            p2 = self._to_screen(self.points[i + 1], w, h)
            qp.drawLine(*p1, *p2)
        
        for idx, pt in enumerate(self.points):
            x, y = self._to_screen(pt, w, h)
            is_hover = idx == self.hover_idx
            is_drag = idx == self.drag_idx
            scale = 1.0
            if is_drag:
                scale = 1.6  
            elif is_hover:
                scale = 1.15
            r = self.radius * scale
            
            shadow_color = QtGui.QColor(0, 0, 0, 60)
            qp.setBrush(shadow_color)
            qp.setPen(QtCore.Qt.PenStyle.NoPen)
            qp.drawEllipse(QtCore.QPointF(x + 2, y + 3), r, r)
            
            if is_drag:
                color = QtGui.QColor("
                
                if hasattr(self, "_drag_pos") and self._drag_pos:
                    ghost_x, ghost_y = self._drag_pos
                    qp.setBrush(QtGui.QColor(255, 64, 129, 120))
                    qp.setPen(QtGui.QPen(QtGui.QColor("
                    qp.drawEllipse(QtCore.QPointF(ghost_x, ghost_y), r, r)
            elif is_hover:
                color = QtGui.QColor("
            else:
                color = QtGui.QColor("
            qp.setBrush(color)
            qp.setPen(QtGui.QPen(QtGui.QColor("
            qp.drawEllipse(QtCore.QPointF(x, y), r, r)

    def _to_screen(self, pt, w, h):
        
        x = pt[0] / 100 * (w - 2 * self.radius) + self.radius
        y = (100 - pt[1]) / 100 * (h - 2 * self.radius) + self.radius
        return int(x), int(y)

    def _from_screen(self, x, y, w, h):
        bri = (x - self.radius) / (w - 2 * self.radius) * 100
        sat = 100 - (y - self.radius) / (h - 2 * self.radius) * 100
        return max(0, min(100, bri)), max(0, min(100, sat))

    def mousePressEvent(self, event):
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
        w, h = self.width(), self.height()
        found = False
        for idx, pt in enumerate(self.points):
            px, py = self._to_screen(pt, w, h)
            if (event.position().x() - px) ** 2 + (event.position().y() - py) ** 2 < (
                self.radius * 1.3
            ) ** 2 * 2:
                self.hover_idx = idx
                self.setCursor(QtCore.Qt.CursorShape.PointingHandCursor)
                found = True
                break
        if not found:
            self.hover_idx = None
            self.setCursor(QtCore.Qt.CursorShape.ArrowCursor)
        if self.drag_idx is not None:
            bri, sat = self._from_screen(
                event.position().x(), event.position().y(), w, h
            )
            self.points[self.drag_idx] = (bri, sat)
            self._drag_pos = (event.position().x(), event.position().y())
            self.curveChanged.emit(self.points)
            self.update()
        else:
            self._drag_pos = None
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
        while len(pts) < 9:
            pts.append((100, 100))
        self.points = pts[:9]
        self.update()





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
        self.setWindowTitle("Color Shuffle GUI (Qt)")
        self.resize(900, 400)
        self.input_path = input_path
        self.output_path = output_path
        self.curve_presets = curve_presets or {
            "Mono": "10 0\n17 0\n24 0\n39 0\n51 0\n58 0\n72 0\n84 0\n99 0",
            "Pastel": "10 99\n17 66\n24 49\n39 41\n51 37\n58 34\n72 30\n84 26\n99 22",
            "Vibrant": "18 99\n32 97\n48 95\n55 90\n70 80\n80 70\n88 60\n94 40\n99 24",
            "Contrast+": "10 100\n20 100\n30 100\n40 100\n55 100\n70 100\n80 100\n90 100\n100 100",
            "Contrast-": "10 10\n20 20\n30 30\n40 40\n55 55\n70 70\n80 80\n90 90\n100 100",
        }
        self.curve_str = curve_str
        self.mode = mode
        ColorRow = type("ColorRow", (), {})
        self.color_rows = []
        for i in range(4):
            row = ColorRow()
            row.primary = initial_colors[i]
            row.text = initial_texts[i]
            for j in range(9):
                setattr(row, f"accent{j + 1}", accent_colors[i][j][1])
            self.color_rows.append(row)
        self.drag_row_idx = None
        self._setup_ui()

    def _setup_ui(self):
        layout = QtWidgets.QVBoxLayout(self)
        layout.setSpacing(1)  
        layout.setContentsMargins(2, 2, 2, 2)

        
        self.row_list = QtWidgets.QListWidget()
        self.row_list.setDragDropMode(QtWidgets.QAbstractItemView.DragDropMode.InternalMove)
        self.row_list.setDefaultDropAction(QtCore.Qt.DropAction.MoveAction)
        self.row_list.setSpacing(1)  
        self.row_list.setSelectionMode(QtWidgets.QAbstractItemView.SelectionMode.NoSelection)
        self.row_list.setVerticalScrollBarPolicy(QtCore.Qt.ScrollBarPolicy.ScrollBarAlwaysOff)
        self.row_list.setHorizontalScrollBarPolicy(QtCore.Qt.ScrollBarPolicy.ScrollBarAlwaysOff)
        self.row_list.setFrameShape(QtWidgets.QFrame.Shape.NoFrame)
        self.row_list.setStyleSheet("QListWidget { padding: 0; margin: 0; border: none; } QListWidget::item { margin: 0; padding: 0; } QPushButton { min-width: 0; min-height: 0; padding: 0; margin: 0; }")
        self.row_widgets = []
        for i in range(4):
            w = QtWidgets.QWidget()
            hbox = QtWidgets.QHBoxLayout(w)
            hbox.setSpacing(1)  
            hbox.setContentsMargins(1, 1, 1, 1)  
            pry_btn = QtWidgets.QPushButton()
            pry_btn.setFixedSize(40, 30)  
            pry_btn.setStyleSheet("QPushButton { background-color: 
            pry_btn.setSizePolicy(QtWidgets.QSizePolicy.Policy.Fixed, QtWidgets.QSizePolicy.Policy.Fixed)
            pry_btn.clicked.connect(lambda _, idx=i: self.pick_color(idx, "primary"))
            hbox.addWidget(pry_btn)
            txt_btn = QtWidgets.QPushButton()
            txt_btn.setFixedSize(40, 30)  
            txt_btn.setStyleSheet("QPushButton { background-color: 
            txt_btn.setSizePolicy(QtWidgets.QSizePolicy.Policy.Fixed, QtWidgets.QSizePolicy.Policy.Fixed)
            txt_btn.clicked.connect(lambda _, idx=i: self.pick_color(idx, "text"))
            hbox.addWidget(txt_btn)
            acc_btns = []
            for j in range(9):
                color = getattr(self.color_rows[i], f"accent{j + 1}")
                acc_btn = QtWidgets.QPushButton()
                acc_btn.setFixedSize(40, 30)  
                acc_btn.setStyleSheet("QPushButton { background-color: 
                acc_btn.setSizePolicy(QtWidgets.QSizePolicy.Policy.Fixed, QtWidgets.QSizePolicy.Policy.Fixed)
                acc_btn.clicked.connect(lambda _, ii=i, jj=j: self.pick_color((ii, jj), "accent"))
                hbox.addWidget(acc_btn)
                acc_btns.append(acc_btn)
            
            hbox.addStretch()
            w.setLayout(hbox)
            w.setMinimumHeight(30)  
            w.setMaximumHeight(30)  
            item = QtWidgets.QListWidgetItem()
            item.setSizeHint(QtCore.QSize(w.sizeHint().width(), 30))  
            self.row_list.addItem(item)
            self.row_list.setItemWidget(item, w)
            self.row_widgets.append((pry_btn, txt_btn, acc_btns))
        self.row_list.setMinimumHeight(120)  
        self.row_list.setMaximumHeight(120)  
        self.row_list.setStyleSheet("QListWidget { padding: 0; margin: 0; border: none; } QListWidget::item { margin: 0; padding: 0; } QPushButton { min-width: 0; min-height: 0; padding: 0; margin: 0; }")
        layout.addWidget(self.row_list)

        
        curve_box = QtWidgets.QHBoxLayout()
        self.curve_combo = QtWidgets.QComboBox()
        for name in self.curve_presets:
            self.curve_combo.addItem(name)
        self.curve_combo.addItem("Custom")
        self.curve_combo.currentTextChanged.connect(self.on_curve_preset)
        curve_box.addWidget(QtWidgets.QLabel("Curve Preset:"))
        curve_box.addWidget(self.curve_combo)
        self.curve_entry = QtWidgets.QLineEdit(self.curve_str)
        curve_box.addWidget(QtWidgets.QLabel("Curve String:"))
        curve_box.addWidget(self.curve_entry)
        apply_curve_btn = QtWidgets.QPushButton("Apply Curve")
        apply_curve_btn.clicked.connect(self.on_apply_curve)
        curve_box.addWidget(apply_curve_btn)
        layout.addLayout(curve_box)

        
        self.curve_editor = CurveEditor()
        self.curve_editor.set_curve_str(self.curve_str)
        self.curve_editor.curveChanged.connect(self.on_curve_changed)
        layout.addWidget(self.curve_editor)

        
        ctrl_box = QtWidgets.QHBoxLayout()
        self.mode_switch = QtWidgets.QCheckBox("Dark Mode")
        self.mode_switch.setChecked(self.mode == "dark")
        ctrl_box.addWidget(self.mode_switch)
        rotate_btn = QtWidgets.QPushButton("Rotate")
        rotate_btn.clicked.connect(self.on_rotate)
        ctrl_box.addWidget(rotate_btn)
        save_btn = QtWidgets.QPushButton("Save")
        save_btn.clicked.connect(self.on_save)
        ctrl_box.addWidget(save_btn)
        layout.addLayout(ctrl_box)

        
        file_box = QtWidgets.QHBoxLayout()
        self.input_entry = QtWidgets.QLineEdit(self.input_path)
        self.output_entry = QtWidgets.QLineEdit(self.output_path)
        input_btn = QtWidgets.QPushButton("Open Input")
        output_btn = QtWidgets.QPushButton("Save As")
        input_btn.clicked.connect(self.on_input_pick)
        output_btn.clicked.connect(self.on_output_pick)
        file_box.addWidget(QtWidgets.QLabel("Input:"))
        file_box.addWidget(self.input_entry)
        file_box.addWidget(input_btn)
        file_box.addWidget(QtWidgets.QLabel("Output:"))
        file_box.addWidget(self.output_entry)
        file_box.addWidget(output_btn)
        layout.addLayout(file_box)

    def update_from_color_rows(self):
        self.colors = [row.primary for row in self.color_rows]
        self.texts = [row.text for row in self.color_rows]
        self.accent_colors = [
            [
                (f"dcol_{i + 1}xa{j + 1}", getattr(row, f"accent{j + 1}"))
                for j in range(9)
            ]
            for i, row in enumerate(self.color_rows)
        ]
        for i, (pry_btn, txt_btn, acc_btns) in enumerate(self.row_widgets):
            pry_btn.setStyleSheet(
                f"QPushButton {{ background-color: 
            )
            txt_btn.setStyleSheet(
                f"QPushButton {{ background-color: 
            )
            for j, btn in enumerate(acc_btns):
                color = (
                    self.accent_colors[i][j][1]
                    if j < len(self.accent_colors[i])
                    else "FFFFFF"
                )
                btn.setStyleSheet(f"QPushButton {{ background-color: 
        
        new_rows = []
        for idx in range(self.row_list.count()):
            w = self.row_list.itemWidget(self.row_list.item(idx))
            
            for row in self.color_rows:
                if (
                    getattr(row, "primary")
                    == w.layout()
                    .itemAt(0)
                    .widget()
                    .palette()
                    .button()
                    .color()
                    .name()[1:]
                    .upper()
                ):
                    new_rows.append(row)
                    break
        if len(new_rows) == 4:
            self.color_rows = new_rows

    def pick_color(self, idx, kind):
        if kind == "primary":
            color = self.color_rows[idx].primary
        elif kind == "text":
            color = self.color_rows[idx].text
        else:
            i, j = idx
            color = getattr(self.color_rows[i], f"accent{j + 1}")
        dlg = QtWidgets.QColorDialog(QtGui.QColor(f"
        if dlg.exec():
            new_color = dlg.selectedColor().name()[1:].upper()
            if kind == "primary":
                self.color_rows[idx].primary = new_color
            elif kind == "text":
                self.color_rows[idx].text = new_color
            else:
                i, j = idx
                setattr(self.color_rows[i], f"accent{j + 1}", new_color)
            self.update_from_color_rows()

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

    def on_curve_preset(self, text):
        if text in self.curve_presets:
            self.curve_entry.setText(self.curve_presets[text])
            self.curve_editor.set_curve_str(self.curve_presets[text])

    def on_apply_curve(self):
        self.curve_str = self.curve_entry.text()
        self.curve_editor.set_curve_str(self.curve_str)
        self.apply_curve_to_accents_and_text(self.curve_str)

    def on_curve_changed(self, points):
        curve_str = "\n".join(f"{int(bri)} {int(sat)}" for bri, sat in points)
        self.curve_entry.setText(curve_str)
        self.apply_curve_to_accents_and_text(curve_str)

    def apply_curve_to_accents_and_text(self, curve_str):
        self.update_from_color_rows()  
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
        while len(curve) < 9:
            curve.append((100, 100))
        for i in range(4):
            base = self.colors[i]
            r = int(base[0:2], 16) / 255.0
            g = int(base[2:4], 16) / 255.0
            b = int(base[4:6], 16) / 255.0
            h, s, v = colorsys.rgb_to_hsv(r, g, b)
            for j in range(9):
                bri, sat = curve[j]
                v2 = max(0, min(1, bri / 100.0))
                s2 = max(0, min(1, sat / 100.0))
                r2, g2, b2 = colorsys.hsv_to_rgb(h, s2, v2)
                hexcol = f"{int(r2 * 255):02X}{int(g2 * 255):02X}{int(b2 * 255):02X}"
                self.accent_colors[i][j] = (self.accent_colors[i][j][0], hexcol)
                self.row_widgets[i][2][j].setStyleSheet(
                    f"QPushButton {{ background-color: 
                )
            self.texts[i] = self.accent_colors[i][8][1]
            self.row_widgets[i][1].setStyleSheet(
                f"QPushButton {{ background-color: 
            )

    def on_rotate(self):
        self.color_rows = self.color_rows[1:] + self.color_rows[:1]
        self.update_from_color_rows()

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
        accent_idx = [0, 0, 0, 0]
        for line in orig_lines:
            if line.startswith("dcol_mode="):
                new_lines.append(f'dcol_mode="{mode_str}"\n')
            elif re.match(r"dcol_pry[1-4]=", line):
                if pry_idx < 4:
                    new_lines.append(
                        f'dcol_pry{pry_idx + 1}="{self.colors[pry_idx]}"\n'
                    )
                    pry_idx += 1
                else:
                    new_lines.append(line)
            elif re.match(r"dcol_pry[1-4]_rgba=", line):
                idx = int(re.search(r"dcol_pry([1-4])_rgba", line).group(1)) - 1
                c = self.colors[idx]
                r = int(c[0:2], 16)
                g = int(c[2:4], 16)
                b = int(c[4:6], 16)
                new_lines.append(f'dcol_pry{idx + 1}_rgba="rgba({r},{g},{b},1.00)"\n')
            elif re.match(r"dcol_txt[1-4]=", line):
                if txt_idx < 4:
                    new_lines.append(f'dcol_txt{txt_idx + 1}="{self.texts[txt_idx]}"\n')
                    txt_idx += 1
                else:
                    new_lines.append(line)
            elif re.match(r"dcol_txt[1-4]_rgba=", line):
                idx = int(re.search(r"dcol_txt([1-4])_rgba", line).group(1)) - 1
                c = self.texts[idx]
                r = int(c[0:2], 16)
                g = int(c[2:4], 16)
                b = int(c[4:6], 16)
                new_lines.append(f'dcol_txt{idx + 1}_rgba="rgba({r},{g},{b},1.00)"\n')
            elif re.match(r"dcol_([1-4])xa([1-9])=", line):
                m = re.match(r"dcol_([1-4])xa([1-9])=", line)
                i = int(m.group(1)) - 1
                j = accent_idx[i]
                if i < len(self.accent_colors) and j < len(self.accent_colors[i]):
                    new_lines.append(
                        f'dcol_{i + 1}xa{j + 1}="{self.accent_colors[i][j][1]}"\n'
                    )
                    accent_idx[i] += 1
                else:
                    new_lines.append(line)
            elif re.match(r"dcol_([1-4])xa([1-9])_rgba=", line):
                m = re.match(r"dcol_([1-4])xa([1-9])_rgba=", line)
                i = int(m.group(1)) - 1
                j = int(m.group(2)) - 1
                c = self.accent_colors[i][j][1]
                r = int(c[0:2], 16)
                g = int(c[2:4], 16)
                b = int(c[4:6], 16)
                new_lines.append(
                    f'dcol_{i + 1}xa{j + 1}_rgba="rgba({r},{g},{b},1.00)"\n'
                )
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
        self.update_from_color_rows()
        
        for line in lines:
            if line.startswith("wallbashCurve="):
                curve_str = line.split("=", 1)[1].strip().strip('"')
                self.curve_entry.setText(curve_str)
                self.curve_editor.set_curve_str(curve_str)
                break

    def eventFilter(self, obj, event):
        
        if event.type() == QtCore.QEvent.Type.MouseButtonPress:
            for i, btn in enumerate(self.pry_buttons):
                if obj is btn:
                    self.drag_row_idx = i
                    self.drag_start_pos = event.globalPosition().toPoint()
                    break
        elif (
            event.type() == QtCore.QEvent.Type.MouseMove
            and self.drag_row_idx is not None
        ):
            if (
                event.globalPosition().toPoint() - self.drag_start_pos
            ).manhattanLength() > 10:
                
                drag = QtGui.QDrag(self)
                mime = QtCore.QMimeData()
                mime.setText(str(self.drag_row_idx))
                drag.setMimeData(mime)
                drag.exec()
        elif event.type() == QtCore.QEvent.Type.Drop and self.drag_row_idx is not None:
            
            for i, btn in enumerate(self.pry_buttons):
                if obj is btn and i != self.drag_row_idx:
                    
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
    parser.add_argument(
        "--shuffle", action="store_true", help="Shuffle the 4 main colors"
    )
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
    parser.add_argument(
        "--curve", type=str, help="Override the accent curve (not implemented yet)"
    )
    parser.add_argument(
        "--gui", action="store_true", help="Open a Qt color picker UI for main colors"
    )
    parser.add_argument(
        "--mode",
        choices=["light", "dark"],
        help="Override dcol_mode (light or dark)",
    )
    args = parser.parse_args()

    
    if args.gui and not args.input:
        xdg_cache = os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache"))
        args.input = os.path.join(xdg_cache, "hyde", "wall.dcol")
        if not args.output:
            args.output = args.input

    
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
        
        mode, color_rows, other = extract_colors(lines)
        
        initial_colors = [row.primary for row in color_rows]
        initial_texts = [row.text for row in color_rows]
        accent_colors = [
            [
                (f"dcol_{i + 1}xa{j + 1}", getattr(row, f"accent{j + 1}"))
                for j in range(9)
            ]
            for i, row in enumerate(color_rows)
        ]
        
        curve_str = ""
        for line in lines:
            if line.startswith("wallbashCurve="):
                curve_str = line.split("=", 1)[1].strip().strip('"')
                break
        if not curve_str:
            curve_str = "10 99\n17 66\n24 49\n39 41\n51 37\n58 34\n72 30\n84 26\n99 22"
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

    
    if args.set_colors:
        for i, c in enumerate(args.set_colors):
            color_rows[i].primary = c.upper()

    
    if args.shuffle:
        idx = list(range(4))
        random.shuffle(idx)
    elif args.rotate:
        idx = [1, 2, 3, 0]
    else:
        idx = list(range(4))
    color_rows = [color_rows[i] for i in idx]

    
    out_lines = []
    if mode:
        if args.mode:
            out_lines.append(f'dcol_mode="{args.mode}")\n')
        else:
            out_lines.append(mode)
    
    for i, row in enumerate(color_rows):
        out_lines.append(f'dcol_pry{i + 1}="{row.primary}"\n')
    
    for i, row in enumerate(color_rows):
        out_lines.append(f'dcol_txt{i + 1}="{row.text}"\n')
    
    for i, row in enumerate(color_rows):
        for j in range(9):
            out_lines.append(
                f'dcol_{i + 1}xa{j + 1}="{getattr(row, f"accent{j + 1}")}"\n'
            )
    out_lines.extend(other)

    out_path = args.output or args.input + ".out"
    with open(out_path, "w") as f:
        f.writelines(out_lines)

    print(f"Wrote: {out_path}")


main()
