#!/usr/bin/env python3
"""
Hyprland session snapshot manager.

High-fidelity save/restore of window layouts via Hyprland IPC.
Respects named workspaces, special workspaces, floating positions,
and exact command-line reconstruction via a three-step pipeline
(Flatpak → .desktop → /proc/cmdline with Electron filtering).

Usage:
        session.py save                # snapshot → ~/.cache/hypr_session/default.json
        session.py restore             # restore from the snapshot

IMPORTANT:  Workspace dispatch uses a hybrid ID/name strategy:
    - Positive ID (1, 2, …) = user-configured workspace → dispatch as ``id:N``
        (stable across sessions, Hyprland applies the display name automatically).
    - Negative ID (-1337, …) = named workspace → dispatch as ``name:X``
        (negative IDs are ephemeral and differ each session).
    - Special workspaces → ``special:name``.
"""

import configparser
import json
import os
import re
import shlex
import sys
import time
from pathlib import Path


_here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, _here)


from pyutils.xdg_base_dirs import xdg_cache_home  # noqa: E402
from pyutils.logger import get_logger  # noqa: E402
from session.compositor import detect as _detect_compositor  # noqa: E402
from session.pluginloader import (
    load_plugins,
    find_plugin,
    call_save_enrich,
    call_build_restore_cmd,
    call_match_running,
)


DEFAULT_SNAPSHOT = xdg_cache_home() / "hypr_session" / "default.json"


def _default_snapshot_for_backend(backend) -> Path:
    from session.compositor import backend_short_name

    return xdg_cache_home() / "session" / backend_short_name(backend) / "default.json"


# Executables that are session infrastructure and must never be snapshotted
_BLACKLIST_EXE = frozenset(
    {
        "Hyprland",
        "hyprland",
        "Xwayland",
        # portals & dbus
        "xdg-desktop-portal",
        "xdg-desktop-portal-hyprland",
        "xdg-desktop-portal-gtk",
        "xdg-desktop-portal-kde",
        "xdg-desktop-portal-wlr",
        "xdg-document-portal",
        "xdg-permission-store",
        "dbus-daemon",
        "dbus-broker",
        # bars & widgets
        "waybar",
        "ags",
        "eww",
        # notification daemons
        "dunst",
        "mako",
        "swaync",
        "fnott",
        # wallpaper
        "swww-daemon",
        "swww",
        "hyprpaper",
        "swaybg",
        "mpvpaper",
        # lock / idle / color
        "hyprlock",
        "swaylock",
        "hypridle",
        "swayidle",
        "hyprsunset",
        # clipboard
        "wl-paste",
        "wl-copy",
        "cliphist",
        # polkit agents
        "polkit-kde-authentication-agent-1",
        "polkit-gnome-authentication-agent-1",
        "lxqt-policykit-agent",
        # pipewire
        "pipewire",
        "pipewire-pulse",
        "wireplumber",
    }
)

# XDG field codes stripped from .desktop Exec= lines

_DESKTOP_FIELD_CODES = re.compile(r"\s+%[fFuUdDnNickvm]")

# Directories to search for .desktop files (in priority order)

_DESKTOP_DIRS = [
    Path.home() / ".local" / "share" / "applications",
    Path("/usr/share/applications"),
    Path("/var/lib/flatpak/exports/share/applications"),
]


# ── /proc helpers ─────────────────────────────────────────────────────────


def _proc_cmdline(pid: int) -> str | None:
    """Reconstruct the exact launch command from /proc/<pid>/cmdline.

    The file uses null bytes as argument separators.  Each argument is
    individually shell-quoted so the command can be safely re-executed.
    """
    try:
        raw = Path(f"/proc/{pid}/cmdline").read_bytes()
        if not raw:
            return None
        parts = raw.rstrip(b"\x00").split(b"\x00")
        return " ".join(shlex.quote(p.decode(errors="replace")) for p in parts)
    except (OSError, PermissionError):
        return None


def _proc_exe(pid: int) -> str | None:
    """Resolve /proc/<pid>/exe → absolute executable path."""
    try:
        exe = os.readlink(f"/proc/{pid}/exe")
        return None if exe.endswith(" (deleted)") else exe
    except (OSError, PermissionError):
        return None


# ── Flatpak detection (Step A) ────────────────────────────────────────────


def _flatpak_app_id(pid: int, exe: str) -> str | None:
    """Detect Flatpak sandbox via /proc/<pid>/root/.flatpak-info.

    If *exe* starts with ``/app/`` the process lives in a Flatpak sandbox.
    The sandbox's ``/proc/<pid>/root/.flatpak-info`` is an INI file with an
    ``[Application]`` section containing ``name=<app_id>``.

    Returns the application ID (e.g. ``com.brave.Browser``) or None.
    """
    if not exe.startswith("/app/"):
        return None
    try:
        cp = configparser.RawConfigParser()
        cp.read(f"/proc/{pid}/root/.flatpak-info", encoding="utf-8")
        return cp.get("Application", "name", fallback=None)
    except (configparser.Error, OSError, PermissionError):
        return None


# ── .desktop file matching (Step B) ──────────────────────────────────────


def _build_desktop_cache() -> dict[str, str]:
    """Build {lowercase_stem: exec_command} from all .desktop dirs.

    Parses the ``[Desktop Entry]`` section of each ``.desktop`` file to
    extract the ``Exec=`` value, with XDG field codes stripped.
    Later directories are overridden by earlier ones (user > system).
    """
    cache: dict[str, str] = {}

    for app_dir in reversed(_DESKTOP_DIRS):  # reverse so first wins
        if not app_dir.is_dir():
            continue
        for desktop_file in app_dir.glob("*.desktop"):
            try:
                cp = configparser.RawConfigParser()
                cp.read(str(desktop_file), encoding="utf-8")
                if not cp.has_section("Desktop Entry"):
                    continue
                exec_val = cp.get("Desktop Entry", "Exec", fallback=None)
                if not exec_val:
                    continue
                exec_val = _DESKTOP_FIELD_CODES.sub("", exec_val).strip()
                cache[desktop_file.stem.lower()] = exec_val
            except (configparser.Error, OSError):
                continue

    return cache


# ── Electron filter (used in Step C) ─────────────────────────────────────


_ELECTRON_JUNK_ARGS = frozenset(
    {
        "--type=renderer",
        "--type=gpu-process",
        "--type=zygote",
        "--type=utility",
        "--crashpad-handler",
        "--crashpad",
    }
)


def _is_electron_helper(cmdline_raw: str) -> bool:
    """True if the cmdline looks like an Electron child process."""
    return any(marker in cmdline_raw for marker in _ELECTRON_JUNK_ARGS)


# ── Three-step command resolution pipeline ────────────────────────────────


def _resolve_command(
    pid: int,
    exe: str,
    initial_class: str,
    desktop_cache: dict[str, str],
) -> dict[str, str | None]:
    """Resolve the launch command for *pid* using the three-step pipeline.

    Returns a dict with all extracted candidates for debugging plus the
    winning ``_launchString``:

    *  ``_exe``          – absolute path from ``/proc/<pid>/exe``
    *  ``_cmdline``      – shell-safe command from ``/proc/<pid>/cmdline``
    *  ``_flatpak``      – ``flatpak run <app_id>`` if sandbox detected
    *  ``_desktop``      – ``Exec=`` from matching ``.desktop`` file
    *  ``_launchString`` – the chosen command (winner of the pipeline)
    """
    result: dict[str, str | None] = {
        "_exe": exe,
        "_cmdline": _proc_cmdline(pid),
        "_flatpak": None,
        "_desktop": None,
        "_launchString": None,
    }

    # Step A: Flatpak (sandbox-aware, no flatpak ps)
    app_id = _flatpak_app_id(pid, exe)
    if app_id:
        result["_flatpak"] = f"flatpak run {app_id}"
        result["_launchString"] = result["_flatpak"]
        return result

    # Step B: .desktop file match
    if initial_class:
        key = initial_class.lower()
        if key in desktop_cache:
            result["_desktop"] = desktop_cache[key]
            result["_launchString"] = result["_desktop"]
            return result

    # Step C: /proc/cmdline with Electron filter
    cmdline = result["_cmdline"]
    if cmdline:
        if _is_electron_helper(cmdline):
            result["_launchString"] = exe  # just the base binary, no junk args
        else:
            result["_launchString"] = cmdline
        return result

    # Last resort: bare exe
    result["_launchString"] = exe
    return result


# ── Save ──────────────────────────────────────────────────────────────────


def save(dest: Path, *, verbose: bool = False) -> None:
    """Snapshot every Hyprland client into *dest*.

    The raw ``hyprctl clients -j`` dict for each window is kept as-is;
    debug keys from every resolution step are added:

    *  ``_exe``          – absolute path from ``/proc/<pid>/exe``
    *  ``_cmdline``      – shell-safe command from ``/proc/<pid>/cmdline``
    *  ``_flatpak``      – ``flatpak run <id>`` if Flatpak, else null
    *  ``_desktop``      – ``Exec=`` from ``.desktop`` match, else null
    *  ``_launchString`` – the winning command used by ``restore``

    Duplicate PIDs (grouped/tabbed windows) and swallowed windows are
    deduplicated so only one entry per logical application is saved.
    """
    backend = _detect_compositor()
    clients = backend.get_clients()
    workspaces = backend.get_workspaces()
    monitors = backend.get_monitors()

    desktop_cache = _build_desktop_cache()
    plugins = load_plugins()

    # Collect addresses being swallowed — these are hidden originals
    swallowed_addrs: set[str] = set()
    for c in clients:
        sw = c.get("swallowing", "0x0")
        if sw and sw != "0x0":
            swallowed_addrs.add(sw)

    # Pre-sort: visible (not hidden) windows first, then by most recent focus
    # so that when we dedup by PID we keep the best representative.
    clients.sort(key=lambda c: (c.get("hidden", False), c.get("focusHistoryID", 999)))

    enriched: list[dict] = []
    seen_pids: set[int] = set()
    seen_multi: set[tuple[int, int]] = set()
    skipped: list[str] = []

    for c in clients:
        addr = c.get("address", "")
        pid = c.get("pid", 0)

        # Skip swallowed windows (the swallower already represents them)
        if addr in swallowed_addrs:
            skipped.append(f"[skip] swallowed — addr={addr} class={c.get('class')}")
            continue

        if pid <= 0:
            skipped.append(f"[skip] no pid — class={c.get('class')}")
            continue

        initial_class = c.get("initialClass", "")
        plugin = find_plugin(initial_class)

        # MULTI_WINDOW plugins (e.g. VS Code) run many windows under
        # one PID.  Dedup by (pid, workspace) so grouped tabs collapse
        # but windows on different workspaces are each saved.
        if plugin and getattr(plugin.module, "MULTI_WINDOW", False):
            ws_id = c.get("workspace", {}).get("id", 0)
            multi_key = (pid, ws_id)
            if multi_key in seen_multi:
                skipped.append(f"[skip] duplicate pid+ws {pid}:{ws_id} — class={c.get('class')}")
                continue
            seen_multi.add(multi_key)
        else:
            # Skip duplicate PIDs (multi-window apps share a process —
            # launching once is correct; we keep the visible/focused one)
            if pid in seen_pids:
                skipped.append(f"[skip] duplicate pid={pid} — class={c.get('class')}")
                continue
            seen_pids.add(pid)

        exe = _proc_exe(pid)
        if not exe:
            skipped.append(f"[skip] exe unreadable — pid={pid} class={c.get('class')}")
            continue

        if os.path.basename(exe) in _BLACKLIST_EXE:
            continue

        resolved = _resolve_command(pid, exe, initial_class, desktop_cache)
        if not resolved.get("_launchString"):
            skipped.append(f"[skip] command unresolvable — pid={pid} exe={exe}")
            continue

        # Merge all debug keys into the client dict
        c.update(resolved)

        # Plugin enrichment — let plugins add extra snapshot data
        if plugin:
            extra = call_save_enrich(plugin, c, pid)
            if extra:
                c.update(extra)

        enriched.append(c)

    snapshot = {
        "version": 3,
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
        "monitors": monitors,
        "workspaces": workspaces,
        "clients": enriched,
    }

    dest.parent.mkdir(parents=True, exist_ok=True)
    tmp = dest.with_suffix(".tmp")
    tmp.write_text(json.dumps(snapshot, indent=2) + "\n")
    tmp.rename(dest)  # atomic on the same filesystem

    session_name = dest.stem
    if session_name == "default":
        session_name = "Default"
    print(f"Saved {len(enriched)} windows → {session_name}")
    if verbose:
        print(f"  [path] {dest}", file=sys.stderr)
        for msg in skipped:
            print(f"  {msg}", file=sys.stderr)


# ── Restore ───────────────────────────────────────────────────────────────


def restore(src: Path, *, apply_snapshot: bool = True, dry_run: bool = False) -> None:
    """Restore a session from a JSON snapshot at *src*.

    **Default mode** — apply snapshot to running windows: rearrange existing
    windows
    to match the snapshot and launch only missing ones.

    **Force mode** (``--force`` in CLI) — launch every saved app into
    its workspace via ``exec [rules…] command`` without matching running
    windows first.

    **Dry-run mode** (``--dry-run`` in CLI) — print what would happen
    without issuing any IPC commands.
    """
    if not src.exists():
        print(f"Snapshot not found: {src}", file=sys.stderr)
        sys.exit(1)

    snapshot = json.loads(src.read_text())
    clients = snapshot.get("clients", [])
    if not clients:
        print("Snapshot contains no windows.", file=sys.stderr)
        return

    log = get_logger()
    if dry_run:
        print("[dry-run] No IPC calls will be made.")

    plugins = load_plugins()

    backend = _detect_compositor()
    if not dry_run:
        begin_restore = getattr(backend, "begin_restore", None)
        end_restore = getattr(backend, "end_restore", None)
        if callable(begin_restore):
            begin_restore()
    else:
        end_restore = None

    # In apply_snapshot mode, index currently running windows by initialClass
    live_by_class: dict[str, list[dict]] = {}
    if apply_snapshot:
        for c in backend.get_clients():
            key = c.get("initialClass", "")
            if key:
                live_by_class.setdefault(key, []).append(c)

    dispatched = 0
    moved = 0
    launched = 0
    errors = 0
    seen_pids: set[int] = set()
    used_live_addrs: set[str] = set()
    launched_live_clients: list[dict] = []

    def _pick_live_target(saved_client: dict, candidates: list[dict]) -> dict | None:
        if not candidates:
            return None
        plugin = find_plugin(saved_client.get("initialClass", ""))
        if plugin:
            for idx, cand in enumerate(candidates):
                verdict = call_match_running(plugin, saved_client, cand)
                if verdict is True:
                    return candidates.pop(idx)
                if verdict is False:
                    continue
                return candidates.pop(0)
        return candidates.pop(0)

    try:
        for c in clients:
            pid = c.get("pid", 0)
            if pid in seen_pids:
                continue
            if pid > 0:
                seen_pids.add(pid)

            ws_target = backend.ws_target(c.get("workspace", {}))
            command = c.get("_launchString") or c.get("_command")  # v2 compat
            if not command:
                continue

            # ── Apply-snapshot mode: try to move an existing window first ─
            if apply_snapshot:
                iclass = c.get("initialClass", "")
                cands = [
                    w
                    for w in live_by_class.get(iclass, [])
                    if w.get("address") not in used_live_addrs
                ]
                target = _pick_live_target(c, cands)

                if target:
                    addr = target.get("address", "")
                    if addr:
                        ws = c.get("workspace", {}).get("name", ws_target)
                        float_info = " float" if c.get("floating") else ""
                        log.debug("[move] %s addr=%s → ws=%s%s", iclass, addr, ws, float_info)
                        if dry_run:
                            print(f"  [move]   {iclass}  {addr} → ws={ws}{float_info}")
                            used_live_addrs.add(addr)
                            moved += 1
                            dispatched += 1
                            continue
                        try:
                            backend.reposition(addr, c)
                            used_live_addrs.add(addr)
                            moved += 1
                            dispatched += 1
                            continue
                        except Exception as exc:
                            print(f"  [error] move {iclass}: {exc}", file=sys.stderr)
                            errors += 1
                            continue
                # No suitable running-window match → fall through to launch below

            # ── Launch path (or apply-snapshot fallback): launch the app ─
            initial_class = c.get("initialClass", "")
            is_forking = bool(c.get("_flatpak"))

            # ── Plugin override: let a plugin build a custom dispatch ─────
            plugin = find_plugin(initial_class)
            if plugin:
                custom_cmd = call_build_restore_cmd(plugin, c, ws_target)
                if custom_cmd:
                    log.debug("[launch:plugin] %s cmd=%s", plugin.name, custom_cmd)
                    if dry_run:
                        print(f"  [launch] {initial_class}  (plugin:{plugin.name}) {custom_cmd}")
                        launched += 1
                        dispatched += 1
                        if apply_snapshot:
                            launched_live_clients.append(c)
                        continue
                    try:
                        backend.dispatch_plugin_cmd(custom_cmd, c)
                        launched += 1
                        dispatched += 1
                        if apply_snapshot:
                            launched_live_clients.append(c)
                        continue
                    except Exception as exc:
                        print(f"  [plugin:{plugin.name}] {exc}", file=sys.stderr)
                        errors += 1
                        continue

            log.debug("[launch] %s cmd=%s", initial_class, command)
            if dry_run:
                print(f"  [launch] {initial_class}  {command}")
                launched += 1
                dispatched += 1
                if apply_snapshot:
                    launched_live_clients.append(c)
                continue
            try:
                if is_forking and initial_class:
                    backend.launch_forking(command, c, ws_target)
                else:
                    backend.launch(command, c, ws_target)
                launched += 1
                dispatched += 1
                if apply_snapshot:
                    launched_live_clients.append(c)
            except Exception as exc:
                print(f"  [error] {command}: {exc}", file=sys.stderr)
                errors += 1

        # In apply-snapshot mode, newly launched windows can appear shortly after dispatch.
        # Do a short second pass so floating geometry is applied in the same run.
        if apply_snapshot and launched_live_clients and not dry_run:
            pending = list(launched_live_clients)
            deadline = time.monotonic() + 2.0
            while pending and time.monotonic() < deadline:
                live_now = backend.get_clients()
                live_map: dict[str, list[dict]] = {}
                for w in live_now:
                    key = w.get("initialClass", "")
                    if key and w.get("address") not in used_live_addrs:
                        live_map.setdefault(key, []).append(w)

                still_pending: list[dict] = []
                for saved_client in pending:
                    iclass = saved_client.get("initialClass", "")
                    cands = live_map.get(iclass, [])
                    target = _pick_live_target(saved_client, cands)
                    if not target:
                        still_pending.append(saved_client)
                        continue
                    addr = target.get("address", "")
                    if not addr:
                        still_pending.append(saved_client)
                        continue
                    try:
                        backend.reposition(addr, saved_client)
                        used_live_addrs.add(addr)
                        moved += 1
                    except Exception:
                        still_pending.append(saved_client)

                pending = still_pending
                if pending:
                    time.sleep(0.08)
    finally:
        if not dry_run:
            if callable(end_restore):
                end_restore()
            backend.schedule_cleanup()

    prefix = "[dry-run] Would restore" if dry_run else "Restored"
    if apply_snapshot:
        print(
            f"{prefix} {dispatched} windows: {moved} moved, {launched} launched ({errors} errors)."
        )
    else:
        print(f"{prefix} {dispatched} windows ({errors} errors).")


# ── CLI ───────────────────────────────────────────────────────────────────


from session.manager import build_parser


def main() -> None:
    from session.manager import save_named, restore_named, list_sessions, delete_session

    args = build_parser().parse_args()
    # support verbose passed as global or per subcommand
    if getattr(args, "verbose", False):
        os.environ.setdefault("LOG_LEVEL", "DEBUG")

    if args.action == "save":
        save_named(args.name)
    elif args.action == "restore":
        restore_named(
            args.name,
            dry_run=args.dry_run,
            force=args.force,
        )
    elif args.action == "list":
        from session.manager import cli_list_sessions

        cli_list_sessions()
    elif args.action == "delete":
        if delete_session(args.name):
            print(f"Deleted session: {args.name}")
        else:
            print(f"Session not found: {args.name}")


if __name__ == "__main__":
    main()
