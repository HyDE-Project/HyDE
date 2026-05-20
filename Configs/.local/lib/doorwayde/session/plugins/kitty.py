"""Kitty terminal plugin — restore CWD and last-command hint.

During **save**, walks the process tree to find the interactive shell
running inside kitty and reads *its* CWD from ``/proc``.  Reading
kitty's own ``/proc/<pid>/cwd`` would return the directory kitty was
launched from, not the directory the user ``cd``-ed to.

During **restore**, launches kitty with ``--directory <cwd>`` and
optionally ``--title`` showing a hint of the last command (from the
window title captured at save time).
"""

import os
import shlex
from pathlib import Path

MATCH_CLASSES = {"kitty"}
PRIORITY = 40

# Helper processes spawned by kitty that are *not* the interactive shell.
_SKIP_COMMANDS = frozenset({"kitten", "/usr/bin/kitten"})


def _get_child_pids(pid: int) -> list[int]:
    """Return direct child PIDs by reading /proc/<pid>/task/*/children."""
    children: list[int] = []
    task_dir = f"/proc/{pid}/task"
    try:
        for tid in os.listdir(task_dir):
            cfile = os.path.join(task_dir, tid, "children")
            try:
                data = open(cfile).read()  # noqa: SIM115
                for tok in data.split():
                    try:
                        children.append(int(tok))
                    except ValueError:
                        pass
            except OSError:
                pass
    except OSError:
        pass
    return children


def _shell_cwd(kitty_pid: int) -> str | None:
    """Find the interactive shell child of kitty and return its CWD."""
    for child_pid in _get_child_pids(kitty_pid):
        # Read the first token of /proc/<child>/cmdline to identify the process.
        try:
            raw = open(f"/proc/{child_pid}/cmdline", "rb").read()  # noqa: SIM115
            cmdline = raw.split(b"\x00")[0].decode(errors="replace")
        except OSError:
            continue

        if cmdline in _SKIP_COMMANDS:
            continue

        try:
            cwd = os.readlink(f"/proc/{child_pid}/cwd")
            if cwd and Path(cwd).is_dir():
                return cwd
        except OSError:
            continue

    return None


def save_enrich(client: dict, pid: int) -> dict:
    """Capture the shell's working directory from the process tree."""
    extra: dict = {}

    cwd = _shell_cwd(pid)
    if cwd:
        extra["_p_cwd"] = cwd

    # Save title as a hint of what was running (e.g. "vim session.py")
    title = client.get("title", "")
    if title and title != "~" and title != client.get("initialTitle", ""):
        extra["_p_title_hint"] = title

    return extra


def build_restore_cmd(client: dict, ws_target: str) -> str | None:
    """Build kitty launch command with --directory for CWD restoration."""
    base_cmd = client.get("_launchString", "kitty")
    cwd = client.get("_p_cwd")

    parts = [base_cmd]
    if cwd and Path(cwd).is_dir():
        parts.append(f"--directory {shlex.quote(cwd)}")

    cmd = " ".join(parts)
    return f"exec [workspace {ws_target} silent] {cmd}"


def live_match(saved: dict, live: dict) -> bool:
    """Match a saved kitty window to a live one by comparing shell CWD.

    In live mode multiple kitty windows may be open in different
    directories.  Plain class-based matching would grab the first one
    regardless.  Here we walk the live kitty's process tree to find the
    shell's CWD and compare it to the saved ``_p_cwd``.
    """
    saved_cwd = saved.get("_p_cwd")
    if not saved_cwd:
        # No CWD in snapshot — accept any candidate (class already matched).
        return True

    live_pid = live.get("pid", 0)
    if live_pid <= 0:
        return False

    live_cwd = _shell_cwd(live_pid)
    if not live_cwd:
        return False

    return os.path.realpath(saved_cwd) == os.path.realpath(live_cwd)
