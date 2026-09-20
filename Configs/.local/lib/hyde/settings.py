#!/usr/bin/python3
"""HyDE's settings entry point. No configuration editor or background service."""

import argparse
import json
import os
from pathlib import Path
import platform
import re
import shutil
import subprocess
import sys
import threading
import unicodedata
from dataclasses import dataclass

UNAVAILABLE = "Not available"
APP_ID = "org.hyde.Settings"


@dataclass(frozen=True)
class Entry:
    category: str
    title: str
    description: str
    icon: str
    target: tuple
    aliases: str = ""
    desktop: bool = True


# Desktop IDs let GIO honour XDG overrides, quoting, TryExec and activation.
# HyDE actions are fixed argv, never commands assembled from search text.
ENTRIES = (
    Entry("Audio", "Audio devices", "Volume, output devices and microphone", "audio-volume-high-symbolic", ("org.pulseaudio.pavucontrol.desktop", "pavucontrol.desktop"), "sound ton lautstärke mikrofon kopfhörer"),
    Entry("Displays", "Displays", "Resolution, scaling and monitor arrangement", "video-display-symbolic", ("nwg-displays.desktop",), "bildschirm monitor auflösung anzeige"),
    Entry("Network & Bluetooth", "Network connections", "Edit wired, Wi-Fi and VPN connection profiles", "network-wireless-symbolic", ("nm-connection-editor.desktop",), "netzwerk wlan ethernet internet"),
    Entry("Network & Bluetooth", "Bluetooth", "Pair and manage Bluetooth devices", "bluetooth-symbolic", ("blueman-manager.desktop",), "verbinden geräte"),
    Entry("Devices", "Printers", "Printers and print queues", "printer-symbolic", ("system-config-printer.desktop",), "drucker drucken"),
    Entry("Devices", "Scanner", "Scan documents with Document Scanner", "scanner-symbolic", ("org.gnome.SimpleScan.desktop", "simple-scan.desktop"), "scannen dokumente"),
    Entry("Devices", "Controller mapping", "Map controller buttons with AntiMicroX", "input-gaming-symbolic", ("io.github.antimicrox.antimicrox.desktop", "antimicrox.desktop"), "gamepad joystick spiel steuerung"),
    Entry("Appearance", "Themes", "Choose a HyDE theme", "preferences-system-symbolic", ("theme.select",), "design farben stil", False),
    Entry("Appearance", "Wallpaper", "Choose a wallpaper for all displays", "preferences-desktop-wallpaper-symbolic", ("wallpaper", "--select", "--global"), "hintergrund bild", False),
    Entry("Appearance", "GTK appearance", "GTK application fonts, icons and theme", "preferences-system-symbolic", ("nwg-look.desktop",), "schrift symbole gtk"),
    Entry("Appearance", "Qt 5 appearance", "Qt 5 application style", "preferences-system-symbolic", ("qt5ct.desktop",), "qt5"),
    Entry("Appearance", "Qt 6 appearance", "Qt 6 application style", "preferences-system-symbolic", ("qt6ct.desktop",), "qt6"),
    Entry("Appearance", "Kvantum", "Configure the Kvantum theme engine", "preferences-system-symbolic", ("kvantummanager.desktop",), "qt"),
    Entry("Desktop", "Animations", "Choose Hyprland window animations", "preferences-desktop-effects-symbolic", ("animations", "--select"), "effekte bewegung", False),
    Entry("Desktop", "Layouts", "Choose a window layout", "view-grid-symbolic", ("layouts", "--select"), "fenster anordnung", False),
    Entry("Desktop", "Workflows", "Choose a desktop workflow", "preferences-system-symbolic", ("workflows", "--select"), "arbeitsablauf", False),
    Entry("Desktop", "Shaders", "Choose a display shader", "weather-clear-night-symbolic", ("shaders", "--select"), "farbe filter", False),
    Entry("Desktop", "Lock screen", "Choose a lock screen layout", "system-lock-screen-symbolic", ("lockscreen", "--select"), "sperrbildschirm", False),
    Entry("Desktop", "Keyboard shortcuts", "View the current keyboard shortcuts", "input-keyboard-symbolic", ("keybinds_hint",), "tastatur tasten kürzel keybinds", False),
    Entry("Waybar", "Bar layout", "Choose the Waybar module layout", "view-list-symbolic", ("waybar", "--select-layout"), "leiste panel", False),
    Entry("Waybar", "Bar style", "Choose the Waybar style", "preferences-system-symbolic", ("waybar", "--select-style"), "leiste panel", False),
)
CATEGORIES = tuple(dict.fromkeys(e.category for e in ENTRIES)) + ("System Information",)


def normalize(value):
    return unicodedata.normalize("NFKC", value).casefold()


def matches(entry, query):
    haystack = normalize(" ".join((entry.category, entry.title, entry.description, entry.aliases)))
    return all(word in haystack for word in normalize(query).split())


def xdg_path(variable, fallback):
    value = os.environ.get(variable, "")
    return Path(value) if value.startswith("/") else Path.home() / fallback


def read_text(path):
    try:
        with Path(path).open(errors="replace") as stream:
            return stream.read(1024 * 1024).strip()
    except OSError:
        return ""


def command_output(argv):
    """Bound optional probes; a failed driver/tool never prevents opening settings."""
    try:
        result = subprocess.run(argv, capture_output=True, text=True, timeout=3, check=False)
        return result.stdout.strip() if result.returncode == 0 else ""
    except (OSError, subprocess.TimeoutExpired, UnicodeError):
        return ""


def size_text(value):
    if value < 0:
        return UNAVAILABLE
    return f"{value / (1024 ** 3):.1f} GiB"


def system_information():
    """Allowlisted overview only: never collect serials, addresses or environment."""
    cpu = next((line.split(":", 1)[1].strip() for line in read_text("/proc/cpuinfo").splitlines()
                if line.startswith("model name") and ":" in line), platform.machine())
    memory = re.search(r"^MemTotal:\s+(\d{1,16})\s+kB$", read_text("/proc/meminfo"), re.M)
    try:
        distro = platform.freedesktop_os_release().get("PRETTY_NAME", UNAVAILABLE)
    except OSError:
        distro = UNAVAILABLE
    gpu = [line.split(": ", 1)[-1] for line in command_output(["lspci"]).splitlines()
           if re.search(r"VGA compatible controller|3D controller|Display controller", line)]
    info = [("Computer", "Hostname", platform.node()),
            ("Computer", "Manufacturer", read_text("/sys/class/dmi/id/sys_vendor")),
            ("Computer", "Model", read_text("/sys/class/dmi/id/product_name")),
            ("Hardware", "CPU", cpu),
            ("Hardware", "Logical CPUs", str(os.cpu_count() or UNAVAILABLE)),
            ("Hardware", "GPU", "\n".join(gpu)),
            ("Hardware", "RAM", size_text(int(memory[1]) * 1024) if memory else ""),
            ("Software", "Distribution", distro),
            ("Software", "Kernel", platform.release())]
    # Ask the compositor rather than interpreting its binary or private state files.
    try:
        version = json.loads(command_output(["hyprctl", "version", "-j"]))
        hyprland = version.get("version") or version.get("tag") or ""
        if not isinstance(hyprland, str):
            hyprland = ""
    except (ValueError, AttributeError):
        hyprland = ""
    info += [("Software", "Hyprland", hyprland)]
    # Read only the installer's version assignment. Never source this shell file:
    # commit messages and other fields are arbitrary text, not trusted code.
    cached = read_text(xdg_path("XDG_STATE_HOME", ".local/state") / "hyde/version")
    release = re.search(r"^HYDE_VERSION='([^'\n]*)'$", cached, re.M)
    info += [("Software", "HyDE", release[1] if release else "")]
    seen = set()
    for label, path in (("System (/)", Path("/")), ("Home", Path.home())):
        try:
            device = path.stat().st_dev
            if device in seen:
                continue
            seen.add(device)
            usage = shutil.disk_usage(path)
            value = f"{size_text(usage.free)} free of {size_text(usage.total)}"
        except OSError:
            value = UNAVAILABLE
        info.append(("Storage", label, value))
    return [(group, label, value or UNAVAILABLE) for group, label, value in info]


def information_text(info):
    return "\n".join(f"{group} / {label}: {value}" for group, label, value in info)


def load_gtk():
    global Gtk, Gdk, Gio, GLib, Pango, DesktopAppInfo
    import gi
    gi.require_version("Gtk", "3.0")
    from gi.repository import Gtk, Gdk, Gio, GLib, Pango
    try:
        gi.require_version("GioUnix", "2.0")
        from gi.repository import GioUnix
        DesktopAppInfo = GioUnix.DesktopAppInfo
    except (ImportError, ValueError):
        DesktopAppInfo = Gio.DesktopAppInfo


COLORS = ("main-bg", "main-fg", "wb-act-bg", "wb-act-fg", "wb-hvr-bg", "wb-hvr-fg")
LAYOUT_CSS = b"""
.hyde-settings button { font: inherit; }
.hyde-settings .sidebar { padding: 22px 14px; }
.hyde-settings .content { padding: 28px; }
.hyde-settings .brand { font-size: 1.4em; font-weight: bold; margin-bottom: 16px; }
.hyde-settings .heading { font-size: 1.8em; font-weight: bold; margin-bottom: 6px; }
.hyde-settings .section { font-weight: bold; margin-top: 20px; margin-bottom: 8px; }
.hyde-settings .nav:selected { font-weight: bold; }
.hyde-settings .nav { padding: 12px 10px; border-radius: 8px; }
.hyde-settings .entry { padding: 16px; margin-bottom: 6px; border-radius: 10px; }
.hyde-settings .entry-title { font-weight: bold; }
.hyde-settings .subtitle { font-size: 0.92em; }
.hyde-settings button { background-image: none; box-shadow: none; }
.hyde-settings button:focus, .hyde-settings entry:focus { outline-width: 2px; outline-style: solid; outline-offset: -3px; }
.hyde-settings list { background: transparent; }
"""


def palette_provider(path):
    """Let GTK parse CSS, including imports and symbolic colour expressions.

    Resolve roles in an isolated context so unrelated Waybar selectors never style
    the app. Only a complete, valid palette can replace the last good provider.
    """
    source = Gtk.CssProvider()
    errors = []
    source.connect("parsing-error", lambda _p, _s, error: errors.append(error))
    source.load_from_path(str(path))
    if errors:
        raise ValueError("Waybar CSS contains errors")
    # Even an isolated style context can inherit screen providers. Require the
    # roles in GTK's canonical serialization, so an incomplete update cannot
    # accidentally borrow a missing role from the previous screen palette.
    declared = set(re.findall(r"@define-color\s+([\w-]+)\s", source.to_string()))
    if not set(COLORS).issubset(declared):
        raise ValueError("Waybar colour roles are incomplete")
    context = Gtk.StyleContext()
    # Outrank the already installed screen palette when resolving the new one.
    # Otherwise lookup_color silently returns the old colours on every reload.
    context.add_provider(source, Gtk.STYLE_PROVIDER_PRIORITY_USER + 1)
    colors = {}
    for role in COLORS:
        found, rgba = context.lookup_color(role)
        if not found:
            raise ValueError(f"Waybar colour missing: {role}")
        colors[role] = rgba.to_string()
    css = "\n".join(f"@define-color {role} {value};" for role, value in colors.items())
    css += """
.hyde-settings { background-color: @main-bg; color: @main-fg; }
.hyde-settings .sidebar { background-color: alpha(@main-bg, 0.65); }
.hyde-settings label, .hyde-settings image { color: inherit; }
.hyde-settings .nav, .hyde-settings .entry, .hyde-settings entry {
 background-color: transparent; color: @main-fg; border-color: alpha(@main-fg, 0.18); }
.hyde-settings .entry { background-color: alpha(@main-bg, 0.65); }
.hyde-settings .nav:hover, .hyde-settings .entry:hover {
 background-color: @wb-hvr-bg; color: @wb-hvr-fg; }
.hyde-settings .nav:selected, .hyde-settings .entry:active {
 background-color: @wb-act-bg; color: @wb-act-fg; }
.hyde-settings button:focus, .hyde-settings entry:focus { outline-color: @wb-act-fg; }
.hyde-settings button:disabled { opacity: 0.6; }
"""
    provider = Gtk.CssProvider()
    provider.load_from_data(css.encode())
    return provider


def desktop_info(entry):
    for desktop_id in entry.target:
        try:
            app = DesktopAppInfo.new(desktop_id)
        except (TypeError, GLib.Error):
            # PyGObject releases differ: missing IDs return None or raise TypeError.
            continue
        if app and not app.get_is_hidden() and app.should_show():
            return app
    return None


def hyde_available(entry):
    directories = os.environ.get("HYDE_SCRIPTS_PATH", "").split(":")
    directories += [str(Path(__file__).parent)]
    return bool(shutil.which("hyde-shell")) and any(
        (Path(directory) / (entry.target[0] + suffix)).is_file()
        for directory in directories if directory for suffix in (".lua", ".sh", ".py")
    )


def hyde_command(entry):
    return ["hyde-shell", "app", "-t", "scope", "--", "hyde-shell", *entry.target]


def create_application():
    class Settings(Gtk.Application):
        def __init__(self):
            super().__init__(application_id=APP_ID)
            self.window = None
            self.palette = None
            self.monitors = []
            self.reload_id = 0
            self.info = None
            self.category = CATEGORIES[0]
            self.last_query = ""
            self.positions = {}
            self.rows = []
            self.theme_path = xdg_path("XDG_CONFIG_HOME", ".config") / "waybar/theme.css"

        def do_activate(self):
            if self.window:
                self.window.present()
                return
            self.window = Gtk.ApplicationWindow(application=self, title="HyDE Settings")
            self.window.set_default_size(960, 680)
            self.window.set_size_request(650, 420)
            self.window.get_style_context().add_class("hyde-settings")
            visual = self.window.get_screen().get_rgba_visual()
            if visual:
                self.window.set_visual(visual)
            self.window.connect("key-press-event", self.key_press)
            layout = Gtk.CssProvider()
            layout.load_from_data(LAYOUT_CSS)
            Gtk.StyleContext.add_provider_for_screen(self.window.get_screen(), layout, 600)
            root = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
            self.window.add(root)
            sidebar = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
            sidebar.get_style_context().add_class("sidebar")
            sidebar.set_size_request(230, -1)
            root.pack_start(sidebar, False, False, 0)
            sidebar.pack_start(self.label("HyDE", "brand"), False, False, 0)
            self.search = Gtk.SearchEntry(placeholder_text="Search settings…")
            self.search.set_width_chars(18)
            self.search.get_accessible().set_name("Search all settings")
            self.search.connect("search-changed", self.search_changed)
            sidebar.pack_start(self.search, False, False, 0)
            self.nav = Gtk.ListBox(selection_mode=Gtk.SelectionMode.SINGLE)
            nav_scroll = Gtk.ScrolledWindow()
            nav_scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
            nav_scroll.add(self.nav)
            sidebar.pack_start(nav_scroll, True, True, 0)
            for category in CATEGORIES:
                row = Gtk.ListBoxRow()
                row.get_style_context().add_class("nav")
                nav_item = Gtk.Box(spacing=10)
                icon = next((e.icon for e in ENTRIES if e.category == category), "computer-symbolic")
                nav_item.pack_start(Gtk.Image.new_from_icon_name(icon, Gtk.IconSize.MENU), False, False, 0)
                nav_item.pack_start(self.label(category), True, True, 0)
                row.add(nav_item)
                self.nav.add(row)
            self.nav.connect("row-selected", self.category_changed)
            self.scroll = Gtk.ScrolledWindow()
            self.scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
            root.pack_start(self.scroll, True, True, 0)
            self.content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
            self.content.get_style_context().add_class("content")
            self.scroll.add(self.content)
            self.notice = self.label("", "subtitle")
            sidebar.pack_end(self.notice, False, False, 0)
            self.nav.select_row(self.nav.get_row_at_index(0))
            self.reload_theme()
            # Monitor directories, not the replaced inode. A slow fallback also
            # catches imported CSS changes and directories created after launch.
            for folder in (self.theme_path.parent, self.theme_path.parent.parent):
                try:
                    monitor = Gio.File.new_for_path(str(folder)).monitor_directory(Gio.FileMonitorFlags.NONE, None)
                    monitor.set_rate_limit(100)
                    monitor.connect("changed", self.theme_changed)
                    self.monitors.append(monitor)
                except GLib.Error:
                    pass
            self.poll_id = GLib.timeout_add_seconds(2, self.poll_theme)
            self.window.connect("destroy", self.cleanup)
            self.window.show_all()
            self.search.grab_focus()

        @staticmethod
        def label(text, style=None):
            label = Gtk.Label(label=text, xalign=0)
            label.set_line_wrap(True)
            label.set_line_wrap_mode(Pango.WrapMode.WORD_CHAR)
            label.set_max_width_chars(56)
            if style:
                label.get_style_context().add_class(style)
            return label

        def cleanup(self, *_):
            GLib.source_remove(self.poll_id)
            if self.reload_id:
                GLib.source_remove(self.reload_id)
            for monitor in self.monitors:
                monitor.cancel()
            self.window = None

        def key_press(self, _widget, event):
            if event.state & Gdk.ModifierType.CONTROL_MASK and event.keyval in (Gdk.KEY_f, Gdk.KEY_F):
                self.search.grab_focus()
                return True
            if event.keyval == Gdk.KEY_Escape and self.search.get_text():
                self.search.set_text("")
                return True
            return False

        def theme_changed(self, *_):
            if self.reload_id:
                GLib.source_remove(self.reload_id)
            self.reload_id = GLib.timeout_add(150, self.reload_theme)

        def poll_theme(self):
            self.reload_theme()
            return True

        def reload_theme(self):
            if self.reload_id:
                GLib.source_remove(self.reload_id)
                self.reload_id = 0
            try:
                provider = palette_provider(self.theme_path)
                # Do not invalidate all widget styles when the palette is unchanged.
                if not self.palette or provider.to_string() != self.palette.to_string():
                    screen = self.window.get_screen()
                    Gtk.StyleContext.add_provider_for_screen(screen, provider, 601)
                    if self.palette:
                        Gtk.StyleContext.remove_provider_for_screen(screen, self.palette)
                    self.palette = provider
                self.notice.set_text("")
            except (GLib.Error, OSError, ValueError):
                self.notice.set_text("Waybar colours unavailable. Keeping previous colours." if self.palette
                                     else "Waybar colours unavailable. Using GTK appearance.")
            return False

        def category_changed(self, _nav, row):
            if row is None:
                return
            self.save_position()
            self.category = CATEGORIES[row.get_index()]
            self.search.handler_block_by_func(self.search_changed)
            self.search.set_text("")
            self.search.handler_unblock_by_func(self.search_changed)
            self.last_query = ""
            self.render()

        def save_position(self):
            if not self.last_query:
                self.positions[self.category] = self.scroll.get_vadjustment().get_value()

        def search_changed(self, *_):
            self.save_position()
            self.last_query = self.search.get_text().strip()
            self.render()

        def render(self):
            for child in self.content.get_children():
                child.destroy()
            self.rows = []
            query = self.last_query
            entries = [e for e in ENTRIES if matches(e, query) and (query or e.category == self.category)]
            info_match = bool(query and all(w in normalize("system information computer cpu gpu ram memory storage rechner speicher systeminformationen hardware kernel distribution") for w in normalize(query).split()))
            heading = "Search results" if query else self.category
            self.content.pack_start(self.label(heading, "heading"), False, False, 0)
            if query:
                self.content.pack_start(self.label(f"{len(entries) + int(info_match)} " + ("result" if len(entries) + int(info_match) == 1 else "results"), "subtitle"), False, False, 0)
            if not query and self.category == "System Information":
                self.render_info()
            else:
                group = None
                for entry in entries:
                    if entry.category != group:
                        group = entry.category
                        if query:
                            self.content.pack_start(self.label(group, "section"), False, False, 0)
                    self.add_entry(entry)
                if info_match:
                    button = Gtk.Button(label="Open System Information")
                    button.connect("clicked", lambda *_: self.nav.select_row(self.nav.get_row_at_index(len(CATEGORIES) - 1)))
                    self.content.pack_start(button, False, False, 0)
                if query and not entries and not info_match:
                    self.content.pack_start(self.label("No settings found. Try a different term."), False, False, 0)
            self.content.show_all()
            GLib.idle_add(self.restore_position, 0 if query else self.positions.get(self.category, 0))

        def restore_position(self, value):
            if self.window:
                self.scroll.get_vadjustment().set_value(value)
            return False

        def add_entry(self, entry):
            app = desktop_info(entry) if entry.desktop else None
            available = bool(app) if entry.desktop else hyde_available(entry)
            outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
            button = Gtk.Button()
            button.get_style_context().add_class("entry")
            body = Gtk.Box(spacing=14)
            body.pack_start(Gtk.Image.new_from_icon_name(entry.icon, Gtk.IconSize.LARGE_TOOLBAR), False, False, 0)
            texts = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
            texts.pack_start(self.label(entry.title, "entry-title"), False, False, 0)
            texts.pack_start(self.label(entry.description, "subtitle"), False, False, 0)
            detail = f"Opens {app.get_display_name()}" if app else ("Opens HyDE selector" if available else "Required tool is not installed")
            texts.pack_start(self.label(detail, "subtitle"), False, False, 0)
            body.pack_start(texts, True, True, 0)
            body.pack_end(Gtk.Image.new_from_icon_name("window-new-symbolic", Gtk.IconSize.MENU), False, False, 0)
            button.add(body)
            button.set_sensitive(available)
            button.get_accessible().set_name(f"{entry.title}. {entry.description}. {detail}")
            outer.pack_start(button, False, False, 0)
            message = self.label("" if available else "Requires: " + {"Printers": "system-config-printer", "Scanner": "Document Scanner (simple-scan)", "Controller mapping": "AntiMicroX"}.get(entry.title, entry.target[0].removesuffix('.desktop')), "subtitle")
            message.set_no_show_all(True)
            message.set_visible(not available)
            outer.pack_start(message, False, False, 0)
            button.connect("clicked", self.launch, entry, message)
            self.content.pack_start(outer, False, False, 0)

        def launch(self, button, entry, message):
            try:
                if entry.desktop:
                    app = desktop_info(entry)
                    if not app:
                        raise ValueError("Required application is no longer available")
                    if not app.launch([], self.window.get_display().get_app_launch_context()):
                        raise ValueError("Application could not be started")
                else:
                    process = Gio.Subprocess.new(hyde_command(entry), Gio.SubprocessFlags.STDOUT_SILENCE | Gio.SubprocessFlags.STDERR_SILENCE)
                    button.set_sensitive(False)
                    process.wait_check_async(None, self.launch_finished, (button, message))
                message.set_text("")
                message.hide()
            except (GLib.Error, OSError, ValueError) as error:
                message.set_text(f"Could not open {entry.title}: {error}")
                message.show()

        def launch_finished(self, process, result, widgets):
            button, message = widgets
            try:
                process.wait_check_finish(result)
            except GLib.Error:
                message.set_text("The tool exited with an error. Try opening it from a terminal for details.")
                message.show()
            button.set_sensitive(True)

        def render_info(self):
            if self.info is None:
                self.content.pack_start(self.label("Reading system information…"), False, False, 0)
                if not getattr(self, "reading_info", False):
                    self.reading_info = True
                    threading.Thread(target=self.collect_info, daemon=True).start()
                return
            copy = Gtk.Button(label="Copy system information")
            copy.set_halign(Gtk.Align.START)
            copy.connect("clicked", self.copy_info)
            self.content.pack_start(copy, False, False, 0)
            group = None
            for section, name, value in self.info:
                if section != group:
                    self.content.pack_start(self.label(section, "section"), False, False, 0)
                    group = section
                row = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
                row.get_style_context().add_class("entry")
                row.pack_start(self.label(name, "entry-title"), False, False, 0)
                label = self.label(value)
                label.set_selectable(True)
                row.pack_start(label, False, False, 0)
                self.content.pack_start(row, False, False, 0)

        def collect_info(self):
            info = system_information()
            GLib.idle_add(self.info_ready, info)

        def info_ready(self, info):
            self.info = info
            self.reading_info = False
            if self.window and self.category == "System Information" and not self.last_query:
                self.render()
            return False

        def copy_info(self, button):
            clipboard = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD)
            clipboard.set_text(information_text(self.info), -1)
            clipboard.store()
            button.set_label("Copied system information")

    return Settings()


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, epilog="Ctrl+F: search all settings. Escape: clear search.")
    parser.add_argument("--system-info", action="store_true", help="print the allowlisted system overview as JSON without opening a window")
    args = parser.parse_args(argv)
    if args.system_info:
        print(json.dumps(system_information(), ensure_ascii=False, indent=2))
        return 0
    try:
        load_gtk()
    except (ImportError, ValueError) as error:
        print(f"HyDE Settings requires GTK 3 and distribution PyGObject: {error}", file=sys.stderr)
        return 1
    GLib.set_prgname(APP_ID)
    if not Gtk.init_check()[0]:
        print("HyDE Settings needs a graphical session (Wayland or X11).", file=sys.stderr)
        return 1
    return create_application().run([sys.argv[0]])


if __name__ == "__main__":
    sys.exit(main())
