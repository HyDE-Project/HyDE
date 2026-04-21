import os
import sys
import subprocess
import shutil
import argparse
import importlib
from collections.abc import Iterable
from types import ModuleType

lib_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, lib_dir)

import xdg_base_dirs  # noqa: E402
import wrapper.libnotify as notify  # noqa: E402


# =========================
# Core helpers
# =========================

def get_venv_path() -> str:
    """Returns the path to the virtual environment directory."""
    return os.path.join(str(xdg_base_dirs.xdg_state_home()), "hyde", "python_env")


def get_project_dir() -> str:
    """Returns the path to the project directory (parent of this file)."""
    return os.path.dirname(lib_dir)


def get_uv() -> str:
    """Finds the 'uv' executable in the system."""
    uv = shutil.which("uv")
    if uv is None:
        raise FileNotFoundError(
            "uv is not installed. Install it with 'pacman -S uv' or "
            "'curl -LsSf https://astral.sh/uv/install.sh | sh'"
        )
    return uv


# =========================
# Execution layer
# =========================

def run_uv(args, venv_path: str = None, notify_msg: str = None, stream: bool = False) -> subprocess.CompletedProcess[str]:
    """Runs a uv command with the given arguments and environment.

    If stream=True, uv output is written directly to the terminal (for animations/progress).
    """
    try:
        uv = get_uv()
    except FileNotFoundError as e:
        notify.send("HyDE UV", str(e), urgency="critical")
        raise

    venv_path = venv_path or get_venv_path()
    project_dir = get_project_dir()

    env = os.environ.copy()
    env["UV_PROJECT_ENVIRONMENT"] = venv_path

    if notify_msg:
        notify.send("HyDE UV", notify_msg, replace_id=9)

    cmd = [uv] + args + ["--project", project_dir]

    if stream:
        result = subprocess.run(cmd, env=env)
        if result.returncode != 0:
            notify.send("HyDE UV", "Command failed", urgency="critical")
            raise RuntimeError(f"uv {args[0]} failed with exit code {result.returncode}")
        return result

    result = subprocess.run(cmd, capture_output=True, text=True, env=env)

    if result.returncode != 0:
        err = result.stderr.strip() or result.stdout.strip() or "Unknown error"
        notify.send("HyDE UV", f"Error:\n{err}", urgency="critical")
        raise RuntimeError(err)

    return result


# =========================
# Venv logic
# =========================

def is_venv_valid(venv_path: str) -> bool:
    """Checks if the virtual environment at the given path is valid."""
    python_exe = os.path.join(venv_path, "bin", "python")
    pyvenv_cfg = os.path.join(venv_path, "pyvenv.cfg")

    if not (os.path.isfile(python_exe) and os.access(python_exe, os.X_OK)):
        return False

    if os.path.exists(pyvenv_cfg):
        try:
            with open(pyvenv_cfg, "r") as f:
                for line in f:
                    key, sep, value = line.partition("=")
                    if sep and key.strip() == "version":
                        venv_version = value.strip()
                        cur_version = f"{sys.version_info.major}.{sys.version_info.minor}"
                        if not venv_version.startswith(cur_version):
                            return False
        except Exception:
            return False

    return True


def create_venv() -> None:
    """Creates and syncs the virtual environment. Skips if a valid one already exists."""
    venv_path = get_venv_path()
    if os.path.exists(venv_path):
        if is_venv_valid(venv_path):
            notify.send("HyDE UV", "ℹ️ Virtual environment already exists and is valid")
            return
        notify.send("HyDE UV", "⚠️ Broken venv detected, recreating…")
        destroy_venv(venv_path)
    run_uv(["sync"], notify_msg="⏳ Creating virtual environment...")
    notify.send("HyDE UV", "✅ Virtual environment ready")


def destroy_venv(venv_path=None) -> None:
    """Removes the virtual environment directory."""
    venv_path = venv_path or get_venv_path()
    if os.path.exists(venv_path):
        shutil.rmtree(venv_path)
        notify.send("HyDE UV", "🗑️ Virtual environment removed")


def rebuild_venv() -> None:
    """Destroys and recreates the virtual environment."""
    venv_path = get_venv_path()

    if os.path.exists(venv_path):
        destroy_venv(venv_path)

    run_uv(["sync"])
    notify.send("HyDE UV", "✅ Rebuild complete")


# =========================
# Package management
# =========================


def sync_packages() -> None:
    """Installs dependencies from pyproject.toml explicitly."""
    project_dir = get_project_dir()
    toml_file = os.path.join(project_dir, "pyproject.toml")
    run_uv(["pip", "install", "-U", "-r", toml_file],notify_msg="📦 Syncing dependencies...")
    notify.send("HyDE UV", "✅ Dependencies are up to date", replace_id=9)

def install_package(package: str | Iterable[str]) -> None:
    """Installs a package or list of packages using uv."""
    if isinstance(package, str):
        pkgs = [package]
    else:
        pkgs = list(package)

    if not pkgs:
        notify.send("HyDE UV", "No packages specified for installation", urgency="warning")
        return

    notify.send("HyDE UV", f"Installing {', '.join(pkgs)}...")
    try:
        run_uv(["add"] + pkgs, stream=True)
    except RuntimeError as e:
        notify.send("HyDE UV", f"Error installing packages: {e}", urgency="critical")
        raise


def uninstall_package(package: str | Iterable[str]) -> None:
    """Uninstalls a package or list of packages using uv."""
    if isinstance(package, str):
        pkgs = [package]
    else:
        pkgs = list(package)

    if not pkgs:
        notify.send("HyDE UV", "No packages specified for uninstallation", urgency="warning")
        return

    notify.send("HyDE UV", f"Uninstalling {', '.join(pkgs)}...")
    try:
        run_uv(["remove"] + pkgs, stream=True)
    except RuntimeError as e:
        notify.send("HyDE UV", f"Error uninstalling packages: {e}", urgency="critical")
        raise

# =========================
# Import helpers
# =========================

def inject_site_packages() -> None:
    """Ensures the virtual environment's site-packages is in sys.path."""
    venv_path = get_venv_path()
    site_packages = os.path.join(
        venv_path,
        "lib",
        f"python{sys.version_info.major}.{sys.version_info.minor}",
        "site-packages",
    )

    for path in (site_packages, venv_path):
        if path not in sys.path:
            sys.path.insert(0, path)


def v_import(module_name: str, auto_install: bool = True, extra: str = None) -> ModuleType:
    """Imports a module from the virtual environment, optionally auto-installing it if missing.

    If `extra` is provided (e.g. 'amd'), installs via `uv sync --extra <extra>` instead of
    `uv add`, keeping the package declared in pyproject.toml optional-dependencies.
    """
    inject_site_packages()

    try:
        return importlib.import_module(module_name)
    except ImportError:
        if not auto_install:
            raise ImportError(f"Module '{module_name}' not found and auto_install is disabled")

        notify.send("HyDE UV", f"Installing missing module: {module_name}")
        if extra:
            run_uv(["sync", "--extra", extra])
        else:
            install_package(module_name)

        inject_site_packages()
        importlib.invalidate_caches()

        try:
            module = importlib.import_module(module_name)
            notify.send("HyDE UV", f"{module_name} installed successfully")
            return module
        except ImportError as e:
            notify.send(
                "HyDE UV",
                f"Failed to import {module_name} after installation: {e}",
                urgency="critical",
            )
            raise RuntimeError(f"Failed to import {module_name} after installation: {e}")


# =========================
# CLI commands
# =========================

def cmd_create(_) -> None:
    create_venv()


def cmd_sync(_) -> None:
    sync_packages()


def cmd_install(args) -> None:
    install_package(args.packages)


def cmd_uninstall(args) -> None:
        uninstall_package(args.packages)


def cmd_destroy(_) -> None:
    destroy_venv()


def cmd_rebuild(_) -> None:
    rebuild_venv()


def cmd_uv(args) -> None:
    uv = get_uv()
    env = os.environ.copy()
    cmd = [uv] + args.uv_args
    if args.hyde:
        env["UV_PROJECT_ENVIRONMENT"] = get_venv_path()
        cmd += ["--project", get_project_dir()]
    result = subprocess.run(cmd, env=env)
    if result.returncode != 0:
        raise SystemExit(result.returncode)


COMMANDS = {
    "create": cmd_create,
    "sync": cmd_sync,
    "install": cmd_install,
    "uninstall": cmd_uninstall,
    "destroy": cmd_destroy,
    "rebuild": cmd_rebuild,
    "uv": cmd_uv,
}


# =========================
# CLI entry
# =========================

def main(argv) -> None:
    parser = argparse.ArgumentParser(
        prog="python-env",
        usage="%(prog)s [command] <options>",
        description="HyDE's Python virtual environment manager",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    subparsers = parser.add_subparsers(dest="command", metavar="[command]")

    subparsers.add_parser("create", help="Create the virtual environment")
    subparsers.add_parser("sync", help="Sync dependencies from pyproject.toml")
    subparsers.add_parser("destroy", help="Destroy the virtual environment")
    subparsers.add_parser("rebuild", help="Rebuild the virtual environment (destroy + create)")

    install_p = subparsers.add_parser("install", help="Install packages")
    install_p.add_argument("packages", nargs="+", metavar="package")

    uninstall_p = subparsers.add_parser("uninstall", help="Uninstall packages")
    uninstall_p.add_argument("packages", nargs="+", metavar="package")

    uv_p = subparsers.add_parser("uv", help="Run a raw uv command. Use --hyde to scope HyDE's venv")
    uv_p.add_argument("--hyde", action="store_true", help="Run within HyDE's virtualenv context")
    uv_p.add_argument("uv_args", nargs=argparse.REMAINDER, metavar="args")

    args = parser.parse_args(argv)

    if args.command in COMMANDS:
        COMMANDS[args.command](args)
    else:
        parser.print_help()


def hyde(args) -> None:
    main(args)


if __name__ == "__main__":
    hyde(sys.argv[1:])
