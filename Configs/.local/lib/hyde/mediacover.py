#!/usr/bin/env python3
"""Album-art popup for the mediaplayer/spotify Waybar modules (#2153).

Waybar tooltips are Pango text and cannot show images, so "Show Cover" in the
modules' right-click menu runs this script instead: a borderless layer-shell
window under the bar with the current track's cover, title, artist and album.
It follows track changes while open and is deliberately non-modal: it stays
up while you keep working, and closes on a click on it, Esc while the pointer
is over it (Hyprland's focus follows the mouse onto the popup), the player
going away, or running it again (one popup at a time).
Closing on focus loss is not possible: Hyprland hands an on-demand layer
surface the keyboard on map and takes it back right away, which would close
the popup instantly.

GTK 3 + gtk-layer-shell on purpose: Waybar itself depends on both, so they are
always installed, while gtk4-layer-shell is not a HyDE dependency and needs an
LD_PRELOAD workaround under Python.

Everything above main() is display-free and imports nothing from gi, so it
can be tested headless (tests/test_media_cover.sh).
"""

import argparse
import hashlib
import http.client
import json
import os
import pathlib
import signal
import subprocess
import sys
import urllib.parse
import urllib.request

SIZE = 300  # cover edge in logical px
EDGE_GAP = 8  # min distance from the monitor edge
BAR_GAP = 6  # distance from the bar
DOWNLOAD_TIMEOUT = 5  # seconds
MAX_ART_BYTES = 10 * 1024 * 1024  # mpris:artUrl is remote content; cap it


def art_path(url, cache_dir):
    """Resolve an mpris:artUrl to a local image file, or None.

    file:// URLs are used in place. http(s) URLs are downloaded once into
    cache_dir under a hash of the URL; prune_cache keeps only the cover on
    screen, so the hash just avoids refetching it. Any failure (bad
    scheme, 404, timeout, oversized body) gives None, never a partial file.
    """
    if not url:
        return None
    try:
        parsed = urllib.parse.urlparse(url)
    except ValueError:  # e.g. "http://[abc" (PR #2215 review)
        return None
    if parsed.scheme == "file":
        path = pathlib.Path(urllib.parse.unquote(parsed.path))
        return path if path.is_file() else None
    if parsed.scheme not in ("http", "https"):
        return None

    cache_dir = pathlib.Path(cache_dir)
    target = cache_dir / hashlib.sha1(url.encode()).hexdigest()
    if target.is_file():
        return target
    tmp = target.with_suffix(".part")
    try:
        cache_dir.mkdir(parents=True, exist_ok=True)
        with urllib.request.urlopen(url, timeout=DOWNLOAD_TIMEOUT) as resp:
            data = resp.read(MAX_ART_BYTES + 1)
        if not data or len(data) > MAX_ART_BYTES:
            return None
        tmp.write_bytes(data)
        os.replace(tmp, target)
        return target
    # http.client.InvalidURL (spaces) and BadStatusLine (non-HTTP reply) are
    # neither OSError nor ValueError; uncaught they would kill the fetch thread
    # and leave the previous track's cover up (PR #2215 review).
    except (OSError, ValueError, http.client.HTTPException):
        return None
    finally:
        tmp.unlink(missing_ok=True)


def base_dir(runtime_dir, cache_home):
    """XDG_RUNTIME_DIR, or the user's own cache dir when it is unset.

    Never the shared /tmp: another local user could pre-create /tmp/hyde with
    symlinks that prune_cache and the pidfile write would follow (PR #2215
    review). The cache dir is still pruned, it just isn't tmpfs.
    """
    return runtime_dir or cache_home


def allowed_players(value):
    """MEDIAPLAYER_PLAYERS ("spotify,vlc") as a list, or None for no limit."""
    names = [name.strip() for name in (value or "").split(",") if name.strip()]
    return names or None


def art_cache_dir(runtime_dir):
    """Where downloaded art goes: the runtime dir (tmpfs, wiped at logout)."""
    return pathlib.Path(runtime_dir) / "hyde/mediacover"


def prune_cache(cache_dir, keep=None):
    """Delete every downloaded cover except keep.

    Runs on start (leftovers of a killed popup), on every cover change and on
    exit, so at most the cover on screen is ever stored. Only files inside
    cache_dir are deleted; file:// art from the player is never touched.
    """
    try:
        entries = list(pathlib.Path(cache_dir).iterdir())
    except OSError:
        return
    for entry in entries:
        if entry != keep:
            entry.unlink(missing_ok=True)


def pick_player(players, wanted, allowed=None):
    """Choose a player from (name, status) pairs, like mediaplayer.py does.

    With --player, that player regardless of status. Otherwise only players in
    MEDIAPLAYER_PLAYERS (allowed) count, in that order as in mediaplayer.py,
    plasma-browser-integration never does (it mirrors the browser's own
    player), and the first Playing one wins, else the first one at all.
    """
    if wanted:
        return wanted if any(name == wanted for name, _status in players) else None
    players = [
        (name, status)
        for name, status in players
        if name != "plasma-browser-integration" and (allowed is None or name in allowed)
    ]
    if allowed:
        players.sort(key=lambda player: allowed.index(player[0]))
    for name, status in players:
        if status == "Playing":
            return name
    return players[0][0] if players else None


def popup_margin(cursor_x, monitor_x, monitor_width, size=SIZE):
    """Left margin that centres the popup on the cursor within its monitor.

    All values are logical (layout) pixels, as Hyprland reports them.
    """
    margin = cursor_x - monitor_x - size // 2
    margin = min(margin, monitor_width - size - EDGE_GAP)
    return max(EDGE_GAP if monitor_width >= size + 2 * EDGE_GAP else 0, margin)


def popup_edge(cursor_y, monitor_y, monitor_height):
    """Screen edge to open at: the bar's, judged by the cursor's half.

    WAYBAR_POSITION can put the bar at the bottom; the click that opened the
    menu was on the bar, so the cursor's half of the monitor names its edge.
    """
    return "top" if cursor_y - monitor_y < monitor_height / 2 else "bottom"


def close_running(pidfile):
    """Close an open popup; True if there was one.

    The pid is only signalled if its command line is still mediacover's, so a
    pid the kernel has since reused for another program is never killed.
    Stale or unreadable pidfiles are removed.
    """
    pidfile = pathlib.Path(pidfile)
    try:
        pid = int(pidfile.read_text().strip())
        cmdline = pathlib.Path(f"/proc/{pid}/cmdline").read_bytes()
    except (OSError, ValueError):
        pidfile.unlink(missing_ok=True)
        return False
    if b"mediacover" not in cmdline:
        pidfile.unlink(missing_ok=True)
        return False
    try:
        os.kill(pid, signal.SIGTERM)
    except OSError:
        pidfile.unlink(missing_ok=True)
        return False
    pidfile.unlink(missing_ok=True)
    return True


def cursor_placement():
    """(left margin, edge) from Hyprland's cursor and its monitor, or None."""
    try:
        x, y = (int(v) for v in subprocess.run(["hyprctl", "cursorpos"], capture_output=True,
                                                text=True, timeout=2).stdout.split(","))
        monitors = json.loads(subprocess.run(["hyprctl", "-j", "monitors"], capture_output=True,
                                             text=True, timeout=2).stdout)
    except (OSError, ValueError, IndexError, subprocess.SubprocessError):
        return None
    for mon in monitors:
        # ponytail: ignores rotated monitors (transform 1/3 swap width/height)
        # and side bars (WAYBAR_POSITION left/right open at the top edge).
        width = round(mon["width"] / mon.get("scale", 1))
        height = round(mon["height"] / mon.get("scale", 1))
        if mon["x"] <= x < mon["x"] + width and mon["y"] <= y < mon["y"] + height:
            return popup_margin(x, mon["x"], width), popup_edge(y, mon["y"], height)
    return None


def configured(key, state_home):
    """A HyDE setting from $XDG_STATE_HOME/hyde/config, else the environment.

    The config (generated from config.toml) wins over an inherited value, and
    a repeated assignment uses the last one, as in mediaplayer.py, whose
    load_env_file writes every line into os.environ in turn.
    """
    try:
        text = (pathlib.Path(state_home) / "hyde/config").read_text(encoding="utf-8")
    except OSError:
        text = ""
    value = None
    for line in text.splitlines():
        line = line.strip().removeprefix("export ").strip()
        if line.startswith(key + "="):
            value = line.split("=", 1)[1].strip().strip('"')
    return value if value is not None else os.environ.get(key) or None


def theme_colors():
    """@define-color lines from Waybar's theme.css (wallbash), if present."""
    config = pathlib.Path(os.environ.get("XDG_CONFIG_HOME", pathlib.Path.home() / ".config"))
    try:
        text = (config / "waybar/theme.css").read_text(encoding="utf-8")
    except OSError:
        return ""
    return "\n".join(line for line in text.splitlines() if line.strip().startswith("@define-color"))


CSS = """
@define-color main-bg rgba(20,20,20,0.9);
@define-color main-fg rgba(230,230,230,0.9);
@define-color wb-act-bg rgba(120,120,120,0.6);
@define-color wb-act-fg rgba(255,255,255,1);
%s
window { background: transparent; }
/* GTK 3's alpha() multiplies the alpha; a large factor clamps the
   (translucent) wallbash main-bg to opaque so nothing shows through. */
#frame { background: alpha(@main-bg, 100); border: 2px solid @wb-act-bg; border-radius: 14px; }
#info { padding: 28px 12px 10px; border-radius: 0 0 12px 12px;
        background-image: linear-gradient(to bottom, alpha(@main-bg, 0), @main-bg 70%%); }
#title { color: @wb-act-fg; font-weight: bold; }
#artist, #album { color: @main-fg; }
#album { font-size: smaller; }
#noart { color: @main-fg; font-size: 96px; }
"""


def main():
    parser = argparse.ArgumentParser(description="Show the current track's album art.")
    parser.add_argument("--player", help="player to follow (default: the playing one)")
    args = parser.parse_args()

    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import pyutils.python_env as python_env
    import pyutils.wrapper.libnotify as notify
    from pyutils.xdg_base_dirs import xdg_cache_home, xdg_runtime_dir, xdg_state_home

    runtime_dir = base_dir(xdg_runtime_dir(), xdg_cache_home())
    runtime = runtime_dir / "hyde"
    runtime.mkdir(parents=True, exist_ok=True)
    pidfile = runtime / "mediacover.pid"
    if close_running(pidfile):
        return 0  # toggled off

    # gi (PyGObject) is an optional "wayland" extra of the managed venv;
    # v_import installs it on first use instead of crashing (#1552).
    python_env.v_import("gi", extra="wayland")
    import gi

    # Pin Gdk too: unpinned, PyGObject loads the newest (Gdk 4) and Gtk 3 then
    # refuses to load ("Requiring namespace 'Gdk' version '3.0'...").
    gi.require_version("Gtk", "3.0")
    gi.require_version("Gdk", "3.0")
    gi.require_version("GdkPixbuf", "2.0")
    gi.require_version("GtkLayerShell", "0.1")
    gi.require_version("Playerctl", "2.0")
    from gi.repository import Gdk, GdkPixbuf, GLib, Gtk, GtkLayerShell, Playerctl
    import threading

    manager = Playerctl.PlayerManager()
    candidates = []
    for name in manager.props.player_names:
        try:
            status = Playerctl.Player.new_from_name(name).props.status
        except GLib.Error:
            continue
        candidates.append((name.name, status))
    allowed = allowed_players(configured("MEDIAPLAYER_PLAYERS", xdg_state_home()))
    chosen = pick_player(candidates, args.player, allowed)
    if not chosen:
        notify.send("Media", "No active player", icon="audio-x-generic")
        return 0
    player = Playerctl.Player.new(chosen)
    art_cache = art_cache_dir(runtime_dir)
    prune_cache(art_cache)  # leftovers of a popup that was killed

    pidfile.write_text(str(os.getpid()))

    provider = Gtk.CssProvider()
    provider.load_from_data((CSS % theme_colors()).encode())
    Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider,
                                             Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

    win = Gtk.Window()
    visual = win.get_screen().get_rgba_visual()
    if visual:
        win.set_visual(visual)
    win.set_app_paintable(True)
    GtkLayerShell.init_for_window(win)
    GtkLayerShell.set_namespace(win, "hyde-mediacover")
    GtkLayerShell.set_layer(win, GtkLayerShell.Layer.TOP)
    placement = cursor_placement()
    edge = GtkLayerShell.Edge.BOTTOM if placement and placement[1] == "bottom" else GtkLayerShell.Edge.TOP
    GtkLayerShell.set_anchor(win, edge, True)
    GtkLayerShell.set_margin(win, edge, BAR_GAP)
    if placement is not None:  # otherwise centred horizontally
        GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.LEFT, True)
        GtkLayerShell.set_margin(win, GtkLayerShell.Edge.LEFT, placement[0])
    GtkLayerShell.set_keyboard_mode(win, GtkLayerShell.KeyboardMode.ON_DEMAND)

    frame = Gtk.Box(name="frame")
    overlay = Gtk.Overlay()
    canvas = Gtk.DrawingArea()
    canvas.set_size_request(SIZE, SIZE)
    noart = Gtk.Label(label="󰝚", name="noart")
    noart.set_no_show_all(True)  # shown only by set_art when there is no cover
    info = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, name="info", valign=Gtk.Align.END)
    labels = {}
    for key in ("title", "artist", "album"):
        label = Gtk.Label(name=key, xalign=0, max_width_chars=1, hexpand=True)
        label.set_ellipsize(3)  # Pango.EllipsizeMode.END
        info.pack_start(label, False, False, 0)
        labels[key] = label
    overlay.add(canvas)
    overlay.add_overlay(noart)
    overlay.add_overlay(info)
    frame.add(overlay)
    win.add(frame)

    state = {"pixbuf": None, "url": None}

    def draw(_widget, cr):
        pix = state["pixbuf"]
        if pix is None:
            return False
        r = 12
        cr.new_sub_path()
        cr.arc(SIZE - r, r, r, -1.5708, 0)
        cr.arc(SIZE - r, SIZE - r, r, 0, 1.5708)
        cr.arc(r, SIZE - r, r, 1.5708, 3.1416)
        cr.arc(r, r, r, 3.1416, 4.7124)
        cr.close_path()
        cr.clip()
        Gdk.cairo_set_source_pixbuf(cr, pix, 0, 0)
        cr.paint()
        return False

    canvas.connect("draw", draw)

    def set_art(url, path):
        if url != state["url"]:
            return False  # a newer track won the race
        try:
            pix = GdkPixbuf.Pixbuf.new_from_file(str(path)) if path else None
        except GLib.Error:
            pix = None
        if pix is not None:
            # Crop to a centred square, then scale to the popup.
            side = min(pix.get_width(), pix.get_height())
            pix = pix.new_subpixbuf((pix.get_width() - side) // 2, (pix.get_height() - side) // 2, side, side)
            pix = pix.scale_simple(SIZE, SIZE, GdkPixbuf.InterpType.BILINEAR)
        state["pixbuf"] = pix
        prune_cache(art_cache, keep=path)  # drop the previous track's cover
        noart.set_visible(pix is None)
        canvas.queue_draw()
        return False

    def update(*_args):
        labels["title"].set_text(player.get_title() or "")
        labels["artist"].set_text(player.get_artist() or "")
        labels["album"].set_text(player.get_album() or "")
        url = player.print_metadata_prop("mpris:artUrl") or ""
        if url == state["url"]:
            return
        state["url"] = url

        def fetch():
            path = art_path(url, art_cache)
            GLib.idle_add(set_art, url, path)

        threading.Thread(target=fetch, daemon=True).start()

    def quit_popup(*_args):
        Gtk.main_quit()
        return True

    def on_key(_widget, event):
        if event.keyval == Gdk.KEY_Escape:
            Gtk.main_quit()
        return False

    def on_vanished(_manager, name):
        if name.name == chosen:
            Gtk.main_quit()

    player.connect("metadata", update)
    manager.connect("name-vanished", on_vanished)
    win.connect("key-press-event", on_key)
    win.connect("button-press-event", quit_popup)
    win.connect("destroy", Gtk.main_quit)
    # A second "Show Cover" closes this popup via SIGTERM (close_running).
    # GLibUnix.signal_add replaces the deprecated GLib.unix_signal_add in
    # newer PyGObject; keep the old name for older installs.
    try:
        gi.require_version("GLibUnix", "2.0")
        from gi.repository import GLibUnix

        GLibUnix.signal_add(GLib.PRIORITY_DEFAULT, signal.SIGTERM, quit_popup)
    except (ValueError, ImportError):
        GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGTERM, quit_popup)

    update()
    win.show_all()
    try:
        Gtk.main()
    finally:
        prune_cache(art_cache)
        # Only drop the pidfile if it is still ours (a toggle removes it first).
        try:
            if pidfile.read_text().strip() == str(os.getpid()):
                pidfile.unlink()
        except OSError:
            pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
