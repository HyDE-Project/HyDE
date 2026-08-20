#!/usr/bin/env python3
"""Reload script for HyDE components."""

# @name: reload
# @ver: 0.1.0
# @short: reload
# @cmd: all
# @cmd.desc: Reload all HyDE components
# @cmd: python
# @cmd.desc: Rebuild/sync Python virtual environment
# @cmd: lua
# @cmd.desc: Rebuild/sync Lua environment
# @cmd: cache
# @cmd.desc: Reload wallpaper cache
# @cmd: theme
# @cmd.desc: Reload theme / color scheme
# @cmd: --list-targets
# @cmd.desc: List available reload targets

import argparse
import os
import subprocess
import sys
from pathlib import Path
import pyutils.logger as logger

logger = logger.get_logger()


def print_log(*args):
    """Call the exported bash print_log function if available, fallback to stderr."""
    try:
        subprocess.run(
            ["bash", "-c", 'type print_log >/dev/null 2>&1 && print_log "$@" || echo "$*" >&2', "--"] + list(args),
            check=False,
        )
    except Exception:
        print(" ".join(args), file=sys.stderr)


def get_lib_dir() -> Path:
    """Resolve LIB_DIR from environment or fallback to relative path."""
    # Fallback to grandparent directory of reload.py (Configs/.local/lib)
    return Path(os.environ.get("LIB_DIR", Path(__file__).resolve().parent.parent))


LIB_DIR = get_lib_dir()


def run_cmd(cmd, quiet=False) -> bool:
    """Run system command and return exit status as boolean."""
    try:
        kwargs = {"stdout": subprocess.DEVNULL, "stderr": subprocess.DEVNULL} if quiet else {}
        subprocess.run(cmd, check=True, **kwargs)
        return True
    except subprocess.CalledProcessError as e:
        print_log("-err", f"Command failed: {' '.join(cmd)}: {e}")
        return False


def reload_cache() -> bool:
    """Reload wallpaper cache."""
    cache_script = LIB_DIR / "hyde" / "wallpaper" / "cache.sh"
    if not cache_script.exists():
        print_log("-err", f"Cache script not found at {cache_script}")
        return False
    print_log("-sec", "hyde", "Reloading wallpaper cache...")
    return run_cmd(["bash", str(cache_script), "commence", "-t", ""])


def reload_theme() -> bool:
    """Reload theme switch."""
    theme_script = LIB_DIR / "hyde" / "theme.switch.sh"
    if not theme_script.exists():
        print_log("-err", f"Theme switch script not found at {theme_script}")
        return False
    print_log("-sec", "hyde", "Reloading theme...")
    return run_cmd(["bash", str(theme_script)])


def reload_python() -> bool:
    """Reload/sync Python virtual environment."""
    python_script = LIB_DIR / "hyde" / "pyutils" / "python_env.py"
    if not python_script.exists():
        print_log("-err", f"Python env script not found at {python_script}")
        return False

    print_log("-sec", "hyde", "Reloading Python environment...")
    state_home = os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state")
    venv_python = Path(state_home) / "hyde" / "python_env" / "bin" / "python"

    if os.access(venv_python, os.X_OK):
        if run_cmd([str(venv_python), str(python_script), "sync"], quiet=True):
            return True
        print_log("-warn", "Sync failed; rebuilding Python environment...")
        return run_cmd([str(venv_python), str(python_script), "rebuild"])
    else:
        print_log("-info", "Python environment not found; creating...")
        if run_cmd(["python3", str(python_script), "create"], quiet=True):
            return True
        print_log("-warn", "Create failed; attempting rebuild...")
        return run_cmd(["python3", str(python_script), "rebuild"])


def reload_lua() -> bool:
    """Reload/sync Lua environment."""
    lua_script = LIB_DIR / "hyde" / "pyutils" / "lua_env.py"
    if not lua_script.exists():
        print_log("-err", f"Lua env script not found at {lua_script}")
        return False

    print_log("-sec", "hyde", "Reloading Lua environment...")
    python_bin = sys.executable or "python3"

    if run_cmd([python_bin, str(lua_script), "sync"]):
        return True
    print_log("-warn", "Sync failed; rebuilding Lua environment...")
    return run_cmd([python_bin, str(lua_script), "rebuild"])


TARGETS = {
    "python": reload_python,
    "lua": reload_lua,
    "cache": reload_cache,
    "theme": reload_theme,
}


def main():
    parser = argparse.ArgumentParser(description="Reload HyDE components.")
    parser.add_argument(
        "targets",
        nargs="*",
        default=["all"],
        help=f"Components to reload ({', '.join(TARGETS.keys())}, all). Defaults to all.",
    )
    parser.add_argument(
        "--list-targets",
        action="store_true",
        help="List available reload targets and exit.",
    )

    args = parser.parse_args()

    if args.list_targets:
        targets = ["all"] + list(TARGETS.keys())
        print(" ".join(targets))
        sys.exit(0)

    targets_to_run = set(args.targets)

    if "all" in targets_to_run:
        targets_to_run = set(TARGETS.keys())

    invalid = targets_to_run - set(TARGETS.keys())
    if invalid:
        print_log("-err", f"Invalid reload target(s): {', '.join(invalid)}")
        print_log("-warn", f"Valid targets are: {', '.join(TARGETS.keys())} or 'all'")
        sys.exit(1)

    print_log("-sec", "hyde", f"Reloading HyDE components: {', '.join(targets_to_run)}")

    success = True
    for name in TARGETS:
        if name in targets_to_run:
            if not TARGETS[name]():
                success = False

    if not success:
        sys.exit(1)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print_log("-warn", "Reload interrupted by user.")
        sys.exit(130)
