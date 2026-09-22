#!/usr/bin/python3
"""HyDE's settings entry point. No configuration editor or background service."""

import argparse
import grp
import json
import os
from pathlib import Path
import platform
import pwd
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
import threading
import unicodedata
import urllib.parse
import urllib.request
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


# One pacman package name per desktop-backed entry: it is both the "Requires"
# hint and the exact pacman -S argument, so there is nothing to keep in sync.
PACKAGES = {
    "Audio devices": "pavucontrol",
    "Displays": "nwg-displays",
    "Network connections": "nm-connection-editor",
    "Bluetooth": "blueman",
    "Printers": "system-config-printer",
    "Scanner": "simple-scan",
    "Disk usage": "gnome-disk-utility",
    "GTK appearance": "nwg-look",
    "Font manager": "font-manager",
    "Qt 5 appearance": "qt5ct",
    "Qt 6 appearance": "qt6ct",
    "Kvantum": "kvantum",
    "Login screen": "sddm-kcm",
    "Package manager": "octopi",
    "Default apps": "kde-cli-tools",
    "Controller mapping": "antimicrox",
    "Magnifier": "kmag",
    "On-screen keyboard": "squeekboard",
    "Firewall": "plasma-firewall",
    "Flatpak permissions": "flatseal",
    "Power & battery": "xfce4-power-manager",
}

# Desktop IDs let GIO honour XDG overrides, quoting, TryExec and activation.
# HyDE actions are fixed argv, never commands assembled from search text.
ENTRIES = (
    Entry("Audio", "Audio devices", "Volume, output devices and microphone", "audio-volume-high-symbolic", ("org.pulseaudio.pavucontrol.desktop", "pavucontrol.desktop"), "sound ton lautstärke mikrofon kopfhörer"),
    Entry("Displays", "Displays", "Resolution, scaling and monitor arrangement", "video-display-symbolic", ("nwg-displays.desktop",), "bildschirm monitor auflösung anzeige"),
    Entry("Network", "Network connections", "Edit wired, Wi-Fi and VPN connection profiles", "network-wireless-symbolic", ("nm-connection-editor.desktop",), "netzwerk wlan ethernet internet"),
    Entry("Devices", "Bluetooth", "Pair and manage Bluetooth devices", "bluetooth-symbolic", ("blueman-manager.desktop",), "verbinden geräte"),
    Entry("Devices", "Printers", "Printers and print queues", "printer-symbolic", ("system-config-printer.desktop",), "drucker drucken"),
    Entry("Devices", "Scanner", "Scan documents with Document Scanner", "scanner-symbolic", ("org.gnome.SimpleScan.desktop", "simple-scan.desktop"), "scannen dokumente"),
    Entry("Devices", "Disk usage", "Storage devices, partitions and disk images", "drive-harddisk-symbolic", ("org.gnome.DiskUtility.desktop",), "speicher festplatte partition laufwerk"),
    Entry("Devices", "Power & battery", "Battery status and power/suspend behaviour", "battery-symbolic", ("xfce4-power-manager-settings.desktop",), "akku batterie strom energie profil"),
    Entry("Appearance", "Themes", "Choose a HyDE theme", "preferences-system-symbolic", ("theme.select",), "design farben stil", False),
    Entry("Appearance", "Wallpaper", "Choose a wallpaper for all displays", "preferences-desktop-wallpaper-symbolic", ("wallpaper", "--select", "--global"), "hintergrund bild", False),
    Entry("Appearance", "Bar layout", "Choose the Waybar module layout", "view-list-symbolic", ("waybar", "--select-layout"), "leiste panel waybar", False),
    Entry("Appearance", "Bar style", "Choose the Waybar style", "preferences-system-symbolic", ("waybar", "--select-style"), "leiste panel waybar", False),
    Entry("Appearance", "Weather location", "Set the Waybar weather module's location", "mark-location-symbolic", ("weather", "--select-location"), "wetter standort stadt ort waybar", False),
    Entry("Appearance", "Login screen", "Choose the SDDM login screen theme, with a live preview", "system-users-symbolic", ("kcm_sddm.desktop",), "sddm anmeldebildschirm login"),
    Entry("Appearance", "GTK appearance", "GTK application fonts, icons, cursor and theme", "preferences-system-symbolic", ("nwg-look.desktop",), "schrift symbole gtk cursor mauszeiger"),
    # The font-manager package ships its .desktop under a reverse-DNS id, not
    # "font-manager.desktop" -- that name resolves to nothing on any system.
    Entry("Appearance", "Font manager", "Browse installed fonts and install or remove new ones", "preferences-desktop-font-symbolic", ("com.github.FontManager.FontManager.desktop",), "schriftarten fonts installieren"),
    Entry("Appearance", "Qt 5 appearance", "Qt 5 application style", "preferences-system-symbolic", ("qt5ct.desktop",), "qt5"),
    Entry("Appearance", "Qt 6 appearance", "Qt 6 application style", "preferences-system-symbolic", ("qt6ct.desktop",), "qt6"),
    Entry("Appearance", "Kvantum", "Configure the Kvantum theme engine", "preferences-system-symbolic", ("kvantummanager.desktop",), "qt"),
    Entry("Desktop", "Animations", "Choose Hyprland window animations", "preferences-desktop-multitasking-symbolic", ("animations", "--select"), "effekte bewegung", False),
    Entry("Desktop", "Layouts", "Choose a window layout", "view-grid-symbolic", ("layouts", "--select"), "fenster anordnung", False),
    Entry("Desktop", "Workflows", "Choose a desktop workflow", "preferences-system-symbolic", ("workflows", "--select"), "arbeitsablauf", False),
    Entry("Desktop", "Shaders", "Choose a display shader", "preferences-color-symbolic", ("shaders", "--select"), "farbe filter", False),
    Entry("Desktop", "Lock screen", "Choose a lock screen layout", "system-lock-screen-symbolic", ("lockscreen", "--select"), "sperrbildschirm", False),
    Entry("Desktop", "Keyboard shortcuts", "View the current keyboard shortcuts", "preferences-desktop-keyboard-shortcuts-symbolic", ("keybinds_hint",), "tastatur tasten kürzel keybinds", False),
    Entry("Updates", "System updates", "Check for and install pending pacman/AUR updates", "software-update-available-symbolic", ("system.update", "up"), "pacman aur aktualisieren upgrade", False),
    Entry("Apps", "Package manager", "Install, remove and update packages", "system-software-install-symbolic", ("octopi.desktop",), "pakete installieren deinstallieren software"),
    # org.kde.keditfiletype.desktop needs a mimetype argv it never gets here and
    # just prints --help and exits; kcmshell6 filetypes is the standalone GUI.
    Entry("Apps", "Default apps", "Choose which app opens each file type", "preferences-desktop-apps-symbolic", ("hyde-default-apps.desktop",), "dateiendung dateityp standardprogramm zuordnung"),
    Entry("Gaming", "Controller mapping", "Map controller buttons with AntiMicroX", "input-gaming-symbolic", ("io.github.antimicrox.antimicrox.desktop", "antimicrox.desktop"), "gamepad joystick spiel steuerung"),
    Entry("Accessibility", "Magnifier", "Screen magnifier", "zoom-in-symbolic", ("org.kde.kmag.desktop",), "vergrößerung sehen lupe sehbehinderung"),
    Entry("Accessibility", "On-screen keyboard", "Squeekboard virtual keyboard", "preferences-desktop-keyboard-symbolic", ("sm.puri.Squeekboard.desktop",), "bildschirmtastatur eingabehilfe"),
    # gufw re-execs its whole GTK GUI as root via pkexec, which loses
    # WAYLAND_DISPLAY/XAUTHORITY and fails to open any window on Wayland.
    # plasma-firewall's KCM authorizes individual ufw actions via KAuth/Polkit
    # instead, so the GUI itself never needs to become root.
    Entry("Privacy & Security", "Firewall", "Configure the UFW firewall", "security-high-symbolic", ("hyde-firewall.desktop",), "netzwerk schutz sicherheit ufw"),
    Entry("Privacy & Security", "Flatpak permissions", "Review and adjust Flatpak app permissions", "application-certificate-symbolic", ("com.github.tchx84.Flatseal.desktop",), "berechtigungen flatpak sandbox"),
)
# Accounts has no launchable Entry -- it is a built-in read-only page (see
# render_account), so it is spliced in rather than derived from ENTRIES.
_categories = list(dict.fromkeys(e.category for e in ENTRIES))
_categories.insert(_categories.index("Devices"), "Accounts")
CATEGORIES = tuple(_categories) + ("System Information",)
CATEGORY_ICONS = {"Accounts": "avatar-default-symbolic", "System Information": "computer-symbolic"}


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


def atomic_write_text(path, text):
    """Same-directory temp file + os.replace(), matching config.lua's own
    write_lines_to_file()/make_temp_filename() pattern. Both files this is used
    for are read by something else while HyDE is running (globalcontrol.sh
    sourcing staterc, config.lua's inotify watcher on config.toml), which a
    plain path.write_text() could hand a truncated, briefly-empty file to."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(dir=path.parent, prefix=f".{path.name}.")
    tmp_path = Path(tmp_name)
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(text)
        try:
            tmp_path.chmod(path.stat().st_mode & 0o777)
        except OSError:
            pass  # target doesn't exist yet (first write) -- keep mkstemp's mode
        os.replace(tmp_path, path)
    except OSError:
        tmp_path.unlink(missing_ok=True)
        raise


def user_state_path():
    """HyDE's own persistent runtime-state file -- the same one globalcontrol.sh's
    set_conf() writes (HYDE_THEME, HYPR_LAYOUT, ...). Unlike $XDG_STATE_HOME/hyde/config,
    this file is never regenerated wholesale by config.lua, so a value written here
    survives the next config.toml edit or daemon restart instead of being silently
    dropped (config.lua rebuilds that other file's contents entirely from config.toml
    on every change, keeping only keys config.toml itself defines)."""
    return xdg_path("XDG_STATE_HOME", ".local/state") / "hyde/staterc"


def read_user_state(key):
    # Written by write_user_state() below via shlex.quote(); shlex.split()
    # is the matching unquote, so values with $, `, ", or spaces (e.g. a
    # geocoded place name) round-trip instead of corrupting the parse.
    match = re.search(rf"^{re.escape(key)}=(.*)$", read_text(user_state_path()), re.M)
    if not match:
        return ""
    try:
        parts = shlex.split(match[1])
    except ValueError:
        return ""
    return parts[0] if parts else ""


def write_user_state(key, value):
    path = user_state_path()
    # globalcontrol.sh's export_hyde_config() sources this file; some values
    # here (WEATHER_LOCATION_LABEL) come from an external geocoding API.
    # shlex.quote() single-quotes the value, which bash performs no expansion
    # inside of, so an API response can't inject shell commands.
    # A literal newline would still round-trip through a real shell (single
    # quotes preserve it), but read_user_state()'s line-based regex can't see
    # past it -- these are one-line display values, so collapse it instead.
    value = re.sub(r"[\r\n]+", " ", value)
    line = f"{key}={shlex.quote(value)}"
    lines = [line_ for line_ in read_text(path).splitlines() if not line_.startswith(f"{key}=")]
    lines.append(line)
    try:
        atomic_write_text(path, "\n".join(lines) + "\n")
        return True
    except OSError:
        # Best-effort persistence, same as command_output()'s probes: a full
        # disk or an unwritable state dir must not abort the caller (the UI
        # action that triggered this write, e.g. switching category, has
        # already happened and still needs to render). row_activated() below
        # is the one caller where losing this write matters to the user, and
        # it checks the return value instead of ignoring it like this one.
        return False


def config_toml_path():
    return xdg_path("XDG_CONFIG_HOME", ".config") / "hyde/config.toml"


def _weather_section_span(text):
    header = re.search(r"^\[weather\][ \t]*$", text, re.M)
    if not header:
        return None
    start = header.end()
    next_header = re.search(r"^\[", text[start:], re.M)
    end = start + next_header.start() if next_header else len(text)
    return start, end


def read_weather_location():
    """config.toml's [weather] location is the actual source of truth --
    config.lua's watcher regenerates and exports WEATHER_LOCATION from it on
    every change, so reading that generated file here would race the daemon
    right after write_weather_location() runs."""
    try:
        text = config_toml_path().read_text()
    except OSError:
        return ""
    span = _weather_section_span(text)
    if not span:
        return ""
    match = re.search(r'^[ \t]*location[ \t]*=[ \t]*"((?:[^"\\]|\\.)*)"', text[span[0]:span[1]], re.M)
    return match[1].replace('\\"', '"').replace("\\\\", "\\") if match else ""


def write_weather_location(value):
    """Set [weather] location in config.toml (creating the section if it's
    missing) instead of the generated env file. config.lua's watcher notices
    the edit, regenerates WEATHER_LOCATION, and reloads Hyprland -- the same
    path every other HyDE setting change already goes through."""
    path = config_toml_path()
    try:
        text = path.read_text()
    except OSError:
        text = ""
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    new_line = f'location = "{escaped}"'
    span = _weather_section_span(text)
    if not span:
        if text.strip():
            text = text if text.endswith("\n") else text + "\n"
            text += f"\n[weather]\n{new_line}\n"
        else:
            text = f"[weather]\n{new_line}\n"
    else:
        start, end = span
        section = text[start:end]
        key_match = re.search(r"^[ \t]*location[ \t]*=.*$", section, re.M)
        if key_match:
            section = section[:key_match.start()] + new_line + section[key_match.end():]
        else:
            section = section.rstrip("\n") + f"\n{new_line}\n"
        text = text[:start] + section + text[end:]
    try:
        atomic_write_text(path, text)
        return True
    except OSError:
        # Unlike write_user_state(), losing this write matters: it's the
        # user's actual chosen location, not cosmetic UI state, so the caller
        # (row_activated() below) checks this return value and reports the
        # failure instead of closing the dialog as if it had succeeded.
        return False


COORDINATE_PATTERN = re.compile(r"^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$")


def parse_coordinates(query):
    """A bare "lat,lon" pair, if query is one and both values are in range --
    lets the weather dialog accept exact coordinates directly instead of a
    place name, bypassing wttr.in's own nearest-station name resolution
    entirely (which can differ noticeably from the place actually searched)."""
    match = COORDINATE_PATTERN.match(query)
    if not match:
        return None
    lat, lon = float(match[1]), float(match[2])
    return (lat, lon) if -90 <= lat <= 90 and -180 <= lon <= 180 else None


def geocode_search(query):
    """Open-Meteo's free geocoding endpoint; no key, used only for this search dialog."""
    url = "https://geocoding-api.open-meteo.com/v1/search?" + urllib.parse.urlencode({"name": query, "count": 8, "format": "json"})
    try:
        with urllib.request.urlopen(url, timeout=8) as response:
            data = json.loads(response.read())
    except (OSError, ValueError, UnicodeError):
        return []
    return data.get("results") or []


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
    gpu, gpu_drivers, in_gpu = [], [], False
    for line in command_output(["lspci", "-k"]).splitlines():
        if not line.startswith(("\t", " ")):
            in_gpu = bool(re.search(r"VGA compatible controller|3D controller|Display controller", line))
            if in_gpu:
                gpu.append(line.split(": ", 1)[-1])
        elif in_gpu and "Kernel driver in use:" in line:
            gpu_drivers.append(line.split(":", 1)[-1].strip())
    disks = []
    for line in command_output(["lsblk", "-d", "-n", "-P", "-o", "NAME,MODEL,ROTA,TYPE"]).splitlines():
        fields = dict(re.findall(r'(\w+)="([^"]*)"', line))
        if fields.get("TYPE") != "disk" or not fields.get("MODEL"):
            continue
        disks.append(f"{fields['MODEL']} ({'HDD' if fields.get('ROTA') == '1' else 'SSD'})")
    try:
        monitors = json.loads(command_output(["hyprctl", "monitors", "-j"]))
        displays = "\n".join(
            f"{m.get('name', '?')}: {m.get('width', '?')}x{m.get('height', '?')} @ {round(m.get('refreshRate', 0))}Hz"
            for m in monitors
        ) if isinstance(monitors, list) else ""
    except (ValueError, AttributeError, TypeError):
        displays = ""
    info = [("Computer", "Hostname", platform.node()),
            ("Computer", "Manufacturer", read_text("/sys/class/dmi/id/sys_vendor")),
            ("Computer", "Model", read_text("/sys/class/dmi/id/product_name")),
            ("Computer", "Mainboard", read_text("/sys/class/dmi/id/board_name")),
            ("Hardware", "CPU", cpu),
            ("Hardware", "Logical CPUs", str(os.cpu_count() or UNAVAILABLE)),
            ("Hardware", "GPU", "\n".join(gpu)),
            ("Hardware", "GPU driver", "\n".join(gpu_drivers)),
            ("Hardware", "RAM", size_text(int(memory[1]) * 1024) if memory else ""),
            ("Hardware", "Disks", "\n".join(disks)),
            ("Hardware", "Displays", displays),
            ("Software", "Distribution", distro),
            ("Software", "Kernel", platform.release())]
    # Connection type, interface and Wi-Fi name only -- never the address
    # (IP/MAC), matching this function's "what, not who/where" boundary.
    for line in command_output(["nmcli", "-t", "-f", "NAME,TYPE,DEVICE", "connection", "show", "--active"]).splitlines():
        parts = line.split(":")
        if len(parts) != 3 or parts[1] == "loopback":
            continue
        name, kind, device = parts
        info.append(("Network", "Connection", "Wi-Fi" if kind == "802-11-wireless" else "Wired" if kind == "802-3-ethernet" else kind))
        info.append(("Network", "Interface", device))
        if kind == "802-11-wireless" and name:
            info.append(("Network", "Network name", name))
        break
    battery_dirs = sorted(Path("/sys/class/power_supply").glob("BAT*"))
    for index, battery in enumerate(battery_dirs, 1):
        capacity = read_text(battery / "capacity")
        status = read_text(battery / "status")
        label = "Battery" if len(battery_dirs) == 1 else f"Battery {index}"
        info.append(("Hardware", label, f"{capacity}% ({status})" if capacity else ""))
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


def set_hostname(name):
    """Runs hostnamectl (systemd-hostnamed); Polkit prompts for admin auth on its own."""
    try:
        result = subprocess.run(["hostnamectl", "set-hostname", name], capture_output=True, text=True, timeout=120)
        return result.returncode == 0, result.stderr.strip()
    except (OSError, subprocess.TimeoutExpired) as error:
        return False, str(error)


def account_overview():
    """The signed-in user's own record only -- never other accounts, never a password."""
    try:
        record = pwd.getpwuid(os.getuid())
    except KeyError:
        return []
    full_name = record.pw_gecos.split(",")[0].strip() or record.pw_name
    try:
        primary_group = grp.getgrgid(record.pw_gid).gr_name
    except KeyError:
        primary_group = str(record.pw_gid)
    groups = sorted({g.gr_name for g in grp.getgrall() if record.pw_name in g.gr_mem} | {primary_group})
    return [
        ("Username", record.pw_name),
        ("Full name", full_name),
        ("User ID", str(record.pw_uid)),
        ("Primary group", primary_group),
        ("Groups", ", ".join(groups)),
        ("Home directory", record.pw_dir),
        ("Shell", record.pw_shell),
    ]


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
# Text/background role pairs actually placed on top of each other in LAYOUT_CSS.
CONTRAST_PAIRS = (("main-fg", "main-bg"), ("wb-hvr-fg", "wb-hvr-bg"), ("wb-act-fg", "wb-act-bg"))


def _srgb_to_linear(channel):
    return channel / 12.92 if channel <= 0.03928 else ((channel + 0.055) / 1.055) ** 2.4


def _relative_luminance(rgb):
    r, g, b = rgb
    return 0.2126 * _srgb_to_linear(r) + 0.7152 * _srgb_to_linear(g) + 0.0722 * _srgb_to_linear(b)


def _contrast_ratio(rgb_a, rgb_b):
    high, low = sorted((_relative_luminance(rgb_a), _relative_luminance(rgb_b)), reverse=True)
    return (high + 0.05) / (low + 0.05)


def _composite(fg, bg):
    """fg, bg: (r, g, b, a) with each channel in 0..1. Returns the opaque (r, g, b) result."""
    fr, fg_g, fb, fa = fg
    br, bg_g, bb, ba = bg
    out_a = fa + ba * (1 - fa)
    if out_a == 0:
        return (0.0, 0.0, 0.0)
    return tuple((c_fg * fa + c_bg * ba * (1 - fa)) / out_a for c_fg, c_bg in ((fr, br), (fg_g, bg_g), (fb, bb)))


def readable_foreground(fg, bg, minimum=4.5):
    """Both fg and bg here can be translucent (the window uses a real RGBA visual
    over whatever desktop content sits behind it), and Waybar/Wallbash palettes are
    arbitrary -- so contrast depends on an unknown backdrop. Bracket that unknown
    with solid black and solid white; if either leaves `fg` under `minimum` against
    `bg`, return `fg` made fully opaque so its readability stops depending on the
    backdrop at all, instead of silently failing WCAG AA on some wallpapers.

    Known limitation: this only fixes translucency-driven contrast loss, which is
    what every case seen so far has been (see test_readable_foreground's real
    Waybar values). It does not guarantee `minimum` is met -- if a Wallbash
    palette ever derives `fg` and `bg` as the same (or too similar) opaque
    colour, forcing full opacity changes nothing, since the contrast ratio never
    depended on alpha in that case. Fixing that would mean picking a different
    RGB for `fg` (e.g. falling back to a fixed light/dark colour), which is a
    separate, bigger design decision -- not attempted here.
    """
    worst = min(
        _contrast_ratio(_composite(fg, (*_composite(bg, backdrop), 1.0)), _composite(bg, backdrop))
        for backdrop in ((0.0, 0.0, 0.0, 1.0), (1.0, 1.0, 1.0, 1.0))
    )
    if worst >= minimum:
        return fg
    r, g, b, _alpha = fg
    return (r, g, b, 1.0)


LAYOUT_CSS = b"""
.hyde-settings button { font: inherit; }
.hyde-settings .sidebar { padding: 22px 14px; }
.hyde-settings .content { padding: 28px; }
.hyde-settings .brand { font-size: 1.4em; font-weight: bold; margin-bottom: 16px; }
.hyde-settings .heading { font-size: 1.8em; font-weight: bold; margin-bottom: 6px; }
.hyde-settings .section { font-weight: bold; margin-top: 20px; margin-bottom: 8px; }
.hyde-settings .nav:selected { font-weight: bold; }
.hyde-settings .nav { padding: 12px 10px; border-radius: 8px; transition: background-color 120ms ease, color 120ms ease; }
.hyde-settings .entry { padding: 16px; margin-bottom: 6px; border-radius: 10px; transition: background-color 120ms ease, color 120ms ease; }
.hyde-settings .entry-title { font-weight: bold; }
.hyde-settings .subtitle { font-size: 1em; }
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
        colors[role] = rgba
    for fg_role, bg_role in CONTRAST_PAIRS:
        fg, bg = colors[fg_role], colors[bg_role]
        r, g, b, a = readable_foreground((fg.red, fg.green, fg.blue, fg.alpha), (bg.red, bg.green, bg.blue, bg.alpha))
        colors[fg_role] = Gdk.RGBA(red=r, green=g, blue=b, alpha=a)
    css = "\n".join(f"@define-color {role} {value.to_string()};" for role, value in colors.items())
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
        # should_show() also gates NoDisplay and OnlyShowIn/NotShowIn against
        # $XDG_CURRENT_DESKTOP -- correct for a generic app menu, wrong here:
        # this hub deliberately launches specific config tools regardless of
        # which desktop they were built for (KDE KCMs, XFCE panels, GNOME
        # panels, all on Hyprland). Only Hidden=true ("treat as uninstalled")
        # disqualifies a match; the constructor above already rejects entries
        # whose Exec binary cannot be found on PATH at all.
        # get_boolean("Hidden") reads the same key get_is_hidden() wraps, but
        # portably: CI's PyGObject/GioUnix binding requires an argument for
        # get_is_hidden() and raises TypeError without one, uncaught here.
        if app and not app.get_boolean("Hidden"):
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
            # Restored across a full cold start (not just a re-present of the
            # existing window); an unknown/stale saved value falls back safely.
            saved_category = read_user_state("HYDE_SETTINGS_LAST_CATEGORY")
            self.category = saved_category if saved_category in CATEGORIES else CATEGORIES[0]
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
                icon = next((e.icon for e in ENTRIES if e.category == category), CATEGORY_ICONS.get(category, "computer-symbolic"))
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
            self.nav.select_row(self.nav.get_row_at_index(CATEGORIES.index(self.category)))
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
            write_user_state("HYDE_SETTINGS_LAST_CATEGORY", self.category)
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
            account_match = bool(query and all(w in normalize("accounts account user username password konto benutzer passwort hostname computer name rechnername pc umbenennen rename") for w in normalize(query).split()))
            extra_matches = int(info_match) + int(account_match)
            heading = "Search results" if query else self.category
            self.content.pack_start(self.label(heading, "heading"), False, False, 0)
            if query:
                self.content.pack_start(self.label(f"{len(entries) + extra_matches} " + ("result" if len(entries) + extra_matches == 1 else "results"), "subtitle"), False, False, 0)
            if not query and self.category == "System Information":
                self.render_info()
            elif not query and self.category == "Accounts":
                self.render_account()
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
                    button.connect("clicked", lambda *_: self.nav.select_row(self.nav.get_row_at_index(CATEGORIES.index("System Information"))))
                    self.content.pack_start(button, False, False, 0)
                if account_match:
                    button = Gtk.Button(label="Open Accounts")
                    button.connect("clicked", lambda *_: self.nav.select_row(self.nav.get_row_at_index(CATEGORIES.index("Accounts"))))
                    self.content.pack_start(button, False, False, 0)
                if query and not entries and not info_match and not account_match:
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
            # get_display_name() honours the session locale (e.g. "Druckeinstellungen"
            # on a German system), breaking the hub's otherwise all-English text.
            # get_string("Name") reads the desktop file's base, non-localized key.
            is_selector = available and any("select" in arg for arg in entry.target)
            if entry.title == "Weather location":
                current = read_user_state("WEATHER_LOCATION_LABEL") or read_weather_location()
                detail = f"Current: {current}" if current else "Not set -- Waybar falls back to your network location"
            else:
                detail = (
                    f"Opens {app.get_string('Name') or app.get_display_name()}" if app
                    else "Opens HyDE selector" if is_selector
                    else "Runs a HyDE action" if available
                    else "Required tool is not installed"
                )
            texts.pack_start(self.label(detail, "subtitle"), False, False, 0)
            body.pack_start(texts, True, True, 0)
            body.pack_end(Gtk.Image.new_from_icon_name("window-new-symbolic", Gtk.IconSize.MENU), False, False, 0)
            button.add(body)
            button.set_sensitive(available)
            button.get_accessible().set_name(f"{entry.title}. {entry.description}. {detail}")
            outer.pack_start(button, False, False, 0)
            package = PACKAGES.get(entry.title, entry.target[0].removesuffix('.desktop'))
            message = self.label("" if available else f"Requires: {package}", "subtitle")
            message.set_no_show_all(True)
            message.set_visible(not available)
            if not available:
                install = f"pacman -S {package}"
                if entry.title == "Firewall":
                    install += "\nThen enable it: systemctl enable --now ufw"
                message.set_tooltip_text(install)
            outer.pack_start(message, False, False, 0)
            button.connect("clicked", self.launch, entry, message)
            self.content.pack_start(outer, False, False, 0)

        def launch(self, button, entry, message):
            try:
                if entry.title == "Weather location":
                    self.open_weather_location()
                elif entry.desktop:
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

        def open_weather_location(self):
            dialog = Gtk.Dialog(title="Weather location", transient_for=self.window, modal=True)
            dialog.set_default_size(420, 480)
            dialog.add_button("Cancel", Gtk.ResponseType.CANCEL)
            area = dialog.get_content_area()
            area.set_spacing(8)
            area.set_border_width(12)
            # wttr.in reports the *nearest weather station's* own name, which
            # can be a noticeably different, less familiar place than the one
            # searched -- exact coordinates route straight to a station near
            # that point instead of through wttr.in's own name resolution.
            hint = self.label("wttr.in shows the name of the nearest weather station, which "
                               "can differ from the place you pick below. Type exact coordinates "
                               "as \"lat,lon\" (e.g. New York: 40.7128,-74.0060) instead of a name "
                               "to bypass that.", "subtitle")
            area.pack_start(hint, False, False, 0)
            search = Gtk.SearchEntry(placeholder_text="Search for a city, or type \"lat,lon\"…")
            area.pack_start(search, False, False, 0)
            status_row = Gtk.Box(spacing=8)
            spinner = Gtk.Spinner()
            status_row.pack_start(spinner, False, False, 0)
            status = self.label("Type at least 2 characters.", "subtitle")
            status.set_name("weather-status")  # disambiguates from the static hint label above for tests
            status_row.pack_start(status, False, False, 0)
            area.pack_start(status_row, False, False, 0)
            results = Gtk.ListBox(selection_mode=Gtk.SelectionMode.NONE)
            scroll = Gtk.ScrolledWindow()
            scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
            scroll.add(results)
            area.pack_start(scroll, True, True, 0)
            state = {"timeout": 0, "generation": 0, "closed": False}
            dialog.connect("destroy", lambda *_: state.update(closed=True))

            def clear_results():
                for child in results.get_children():
                    child.destroy()

            def row_activated(_listbox, row):
                place = row.place
                if not write_weather_location(f"{place['latitude']},{place['longitude']}"):
                    status.set_text("Could not save the location -- check disk space and permissions.")
                    return
                # The manual "exact coordinates" entry has no country/admin1
                # (nothing geocoded it), so the name/admin1/country label
                # would just read "Exact coordinates" -- show the coordinates
                # themselves instead, since that's the only identifying detail.
                if place.get("country"):
                    label = ", ".join(str(part) for part in (place.get("name"), place.get("admin1"), place.get("country")) if part)
                else:
                    label = f"{place['latitude']:.4f}, {place['longitude']:.4f}"
                write_user_state("WEATHER_LOCATION_LABEL", label)
                # custom-weather.jsonc polls every 3600s and listens on signal
                # 10 for an immediate refresh (its own on-click runs this same
                # command) -- without it Waybar keeps showing the old
                # location's weather for up to an hour.
                command_output(["pkill", "-RTMIN+10", "waybar"])
                dialog.response(Gtk.ResponseType.OK)

            results.connect("row-activated", row_activated)

            def show_results(generation, places):
                if state["closed"] or generation != state["generation"]:
                    return False
                spinner.stop()
                clear_results()
                if not places:
                    status.set_text("No matches. Try a different spelling.")
                else:
                    status.set_text(f"{len(places)} match(es) -- pick one")
                    for place in places:
                        row = Gtk.ListBoxRow()
                        row.place = place
                        label = ", ".join(str(part) for part in (place.get("name"), place.get("admin1"), place.get("country")) if part)
                        label += f" ({place['latitude']:.4f}, {place['longitude']:.4f})"
                        row.add(self.label(label))
                        results.add(row)
                    results.show_all()
                return False

            def run_search(generation, query):
                places = geocode_search(query)
                GLib.idle_add(show_results, generation, places)

            def search_changed(*_):
                if state["timeout"]:
                    GLib.source_remove(state["timeout"])
                    state["timeout"] = 0
                # Bumped on every change, not just when a debounced search
                # actually fires: this is what invalidates an in-flight
                # request the moment the query is cleared/shortened below 2
                # characters below -- otherwise that request's generation
                # would still match state["generation"] when its result
                # arrives, and show_results() would repopulate the list the
                # user just cleared.
                state["generation"] += 1
                query = search.get_text().strip()
                clear_results()

                coordinates = parse_coordinates(query)
                if coordinates:
                    spinner.stop()
                    lat, lon = coordinates
                    show_results(state["generation"], [{"latitude": lat, "longitude": lon, "name": "Exact coordinates"}])
                    return

                if len(query) < 2:
                    spinner.stop()
                    status.set_text("Type at least 2 characters.")
                    return

                def fire():
                    state["timeout"] = 0
                    spinner.start()
                    status.set_text("Searching…")
                    threading.Thread(target=run_search, args=(state["generation"], query), daemon=True).start()
                    return False

                state["timeout"] = GLib.timeout_add(400, fire)

            search.connect("search-changed", search_changed)
            dialog.show_all()
            dialog.run()
            dialog.destroy()
            self.render()

        def render_info(self):
            if self.info is None:
                row = Gtk.Box(spacing=8)
                spinner = Gtk.Spinner()
                spinner.start()
                row.pack_start(spinner, False, False, 0)
                row.pack_start(self.label("Reading system information…"), False, False, 0)
                self.content.pack_start(row, False, False, 0)
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

        def render_account(self):
            change_password = Gtk.Button(label="Change password")
            change_password.set_halign(Gtk.Align.START)
            message = self.label("", "subtitle")
            message.set_no_show_all(True)
            message.set_visible(False)
            change_password.connect("clicked", self.open_change_password, message)
            self.content.pack_start(change_password, False, False, 0)
            self.content.pack_start(message, False, False, 0)
            rows = account_overview()
            if not rows:
                self.content.pack_start(self.label("Account details are not available on this system."), False, False, 0)
                return
            self.content.pack_start(self.label("Account", "section"), False, False, 0)
            for name, value in rows:
                row = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
                row.get_style_context().add_class("entry")
                row.pack_start(self.label(name, "entry-title"), False, False, 0)
                label = self.label(value)
                label.set_selectable(True)
                row.pack_start(label, False, False, 0)
                self.content.pack_start(row, False, False, 0)
            self.content.pack_start(self.label("Device", "section"), False, False, 0)
            outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
            outer.get_style_context().add_class("entry")
            outer.pack_start(self.label("Computer name", "entry-title"), False, False, 0)
            hostname_row = Gtk.Box(spacing=8)
            hostname_entry = Gtk.Entry(text=platform.node())
            hostname_entry.set_width_chars(24)
            hostname_entry.get_accessible().set_name("Computer name")
            rename = Gtk.Button(label="Rename")
            hostname_message = self.label("", "subtitle")
            hostname_message.set_no_show_all(True)
            hostname_message.set_visible(False)
            rename.connect("clicked", self.rename_computer, hostname_entry, hostname_message)
            hostname_entry.connect("activate", self.rename_computer, hostname_entry, hostname_message)
            hostname_row.pack_start(hostname_entry, False, False, 0)
            hostname_row.pack_start(rename, False, False, 0)
            outer.pack_start(hostname_row, False, False, 0)
            outer.pack_start(hostname_message, False, False, 0)
            self.content.pack_start(outer, False, False, 0)

        def rename_computer(self, trigger, entry, message):
            name = entry.get_text().strip()
            if not name:
                message.set_text("Enter a computer name first.")
                message.show()
                return
            trigger.set_sensitive(False)
            message.set_text("Renaming -- you may be asked to authenticate…")
            message.show()
            threading.Thread(target=self.run_rename, args=(name, entry, trigger, message), daemon=True).start()

        def run_rename(self, name, entry, trigger, message):
            ok, detail = set_hostname(name)
            GLib.idle_add(self.rename_done, ok, detail, entry, trigger, message)

        def rename_done(self, ok, detail, entry, trigger, message):
            trigger.set_sensitive(True)
            if ok:
                entry.set_text(platform.node())
                message.set_text("Computer name updated.")
            else:
                message.set_text(detail or "Could not change the computer name.")
            message.show()
            return False

        def open_change_password(self, button, message):
            launcher = shutil.which("xdg-terminal-exec")
            try:
                if not launcher:
                    raise ValueError("No terminal launcher (xdg-terminal-exec) is installed")
                Gio.Subprocess.new([launcher, "--title=Change password", "--", "passwd"], Gio.SubprocessFlags.STDOUT_SILENCE | Gio.SubprocessFlags.STDERR_SILENCE)
                message.set_text("")
                message.hide()
            except (GLib.Error, OSError, ValueError) as error:
                message.set_text(f"Could not open a terminal: {error}")
                message.show()

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
