"""Session manager for named session files (save, list, delete, etc).

Handles named session snapshots for each compositor backend.
"""

import argparse
import os
from pathlib import Path
from typing import List
from pyutils.logger import get_logger
from pyutils.xdg_base_dirs import xdg_cache_home
from session.compositor import detect, backend_short_name


def build_parser() -> "argparse.ArgumentParser":
    p = argparse.ArgumentParser(
        prog="session.py",
        description="Snapshot-based session manager for Hyprland/Niri/etc.",
    )
    p.add_argument(
        "-v",
        action="store_true",
        dest="verbose",
        help="Show debug output for commands",
    )
    sub = p.add_subparsers(dest="action", required=True)

    sp = sub.add_parser("save", help="Take a session snapshot (optionally named)")
    sp.add_argument(
        "name",
        nargs="?",
        default="default",
        help="Name for the session (default: default)",
    )
    sp.add_argument(
        "--verbose",
        action="store_true",
        help="Show debug output for save",
    )

    rp = sub.add_parser("restore", help="Restore a saved snapshot (optionally named)")
    rp.add_argument(
        "name",
        nargs="?",
        default="default",
        help="Name of the session to restore (default: default)",
    )
    rp.add_argument(
        "--verbose",
        action="store_true",
        help="Show debug output for restore",
    )
    rp.add_argument(
        "--force",
        action="store_true",
        help="Force relaunch from snapshot; skip live matching of running windows",
    )
    rp.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview restore actions without executing",
    )

    sub.add_parser("list", help="List all saved sessions")

    dp = sub.add_parser("delete", help="Delete a named session")
    dp.add_argument(
        "name",
        help="Name of the session to delete",
    )

    return p


def cli_list_sessions():
    sessions = [s for s in list_sessions() if s not in ("latest", "latest")]
    if sessions:
        print("Saved sessions:")
        for s in sessions:
            print(f"  {s}")
    else:
        print("No saved sessions found.")


def _session_dir(backend=None) -> Path:
    if backend is None:
        backend = detect()
    return xdg_cache_home() / "session" / backend_short_name(backend)


def save_named(name: str = "latest") -> Path:
    """Save a session snapshot under a given name (default: latest)."""
    logger = get_logger()
    logger.debug("Saving session named: %s", name)

    import importlib.util
    import sys

    session_path = os.path.join(os.path.dirname(__file__), "..", "session.py")
    session_path = os.path.abspath(session_path)
    spec = importlib.util.spec_from_file_location("_session_mod", session_path)
    session_mod = importlib.util.module_from_spec(spec)
    sys.modules["_session_mod"] = session_mod
    spec.loader.exec_module(session_mod)
    save = session_mod.save
    backend = detect()
    dest = _session_dir(backend) / f"{name}.json"
    save(dest)
    logger.info("Saved session '%s'", name)
    return dest


def restore_named(
    name: str = "latest",
    *,
    dry_run: bool = False,
    force: bool = False,
) -> None:
    """Restore a session snapshot by name."""
    logger = get_logger()
    logger.debug(
        "Restoring session named: %s (force=%s dry_run=%s)",
        name,
        force,
        dry_run,
    )

    import importlib.util
    import sys

    session_path = os.path.join(os.path.dirname(__file__), "..", "session.py")
    session_path = os.path.abspath(session_path)
    spec = importlib.util.spec_from_file_location("_session_mod", session_path)
    session_mod = importlib.util.module_from_spec(spec)
    sys.modules["_session_mod"] = session_mod
    spec.loader.exec_module(session_mod)
    restore = session_mod.restore
    backend = detect()
    src = _session_dir(backend) / f"{name}.json"
    apply_snapshot = not force
    restore(src, apply_snapshot=apply_snapshot, dry_run=dry_run)
    logger.info("Restored session '%s'", name)


def list_sessions(backend=None) -> List[str]:
    """List all saved session names for the current backend."""
    d = _session_dir(backend)
    if not d.exists():
        return []
    return [f.stem for f in d.glob("*.json")]


def delete_session(name: str, backend=None) -> bool:
    """Delete a named session file. Returns True if deleted."""
    d = _session_dir(backend)
    f = d / f"{name}.json"
    if f.exists():
        f.unlink()
        return True
    return False
