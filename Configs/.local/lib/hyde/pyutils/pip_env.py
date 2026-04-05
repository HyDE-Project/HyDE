import os
import sys
import subprocess
import shutil
import argparse
import importlib

lib_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, lib_dir)

import xdg_base_dirs
import wrapper.libnotify as notify


def _get_uv():
    """Resolve the uv binary path. Raises FileNotFoundError if not found."""
    uv = shutil.which("uv")
    if uv is None:
        raise FileNotFoundError(
            "uv is not installed. Install it with 'pacman -S uv' or "
            "'curl -LsSf https://astral.sh/uv/install.sh | sh'"
        )
    return uv


def _get_project_dir():
    """Return the directory containing pyproject.toml."""
    return os.path.dirname(lib_dir)


def _inject_site_packages():
    """Insert the venv site-packages into sys.path."""
    venv_path = get_venv_path()
    site_packages = os.path.join(
        venv_path,
        "lib",
        f"python{sys.version_info.major}.{sys.version_info.minor}",
        "site-packages",
    )
    if site_packages not in sys.path:
        sys.path.insert(0, site_packages)
    if venv_path not in sys.path:
        sys.path.insert(0, venv_path)


def is_venv_valid(venv_path):
    """Returns whether the venv is valid or not.

    Args:
        venv_path: Path to the virtual environment to validate
    """
    python_exe = os.path.join(venv_path, "bin", "python")
    pyvenv_cfg = os.path.join(venv_path, "pyvenv.cfg")

    # 1.- Must have its own python file and it must be executable
    if not (os.path.isfile(python_exe) and os.access(python_exe, os.X_OK)):
        return False

    # 2.- Python version used to create the venv must match current one
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


def get_venv_path():
    """Return the virtual environment path."""
    return os.path.join(str(xdg_base_dirs.xdg_state_home()), "hyde", "pip_env")


def _uv_sync(frozen=False):
    """Run uv sync to converge the venv to match the lockfile.

    Args:
        frozen: If True, use --frozen to skip lockfile updates.
    """
    uv = _get_uv()
    venv_path = get_venv_path()
    project_dir = _get_project_dir()

    env = os.environ.copy()
    env["UV_PROJECT_ENVIRONMENT"] = venv_path

    cmd = [uv, "sync", "--project", project_dir]
    if frozen:
        cmd.append("--frozen")

    result = subprocess.run(cmd, capture_output=True, text=True, env=env)
    return result


def create_venv(venv_path=None, requirements_file=None):
    """Create/sync the virtual environment using uv."""
    notify.send("HyDE UV", "⏳ Syncing virtual environment...")
    result = _uv_sync()
    if result.returncode != 0:
        notify.send(
            "HyDE UV",
            f"Failed to sync environment:\n{result.stderr or result.stdout}",
            urgency="critical",
        )
        raise RuntimeError(f"uv sync failed: {result.stderr}")
    notify.send("HyDE UV", "✅ Virtual environment synced successfully")


def destroy_venv(venv_path=None):
    """Destroy the virtual environment."""
    if venv_path is None:
        venv_path = get_venv_path()
    if os.path.exists(venv_path):
        shutil.rmtree(venv_path)


def install_dependencies():
    """Sync dependencies using uv."""
    result = _uv_sync()
    if result.returncode != 0:
        raise RuntimeError(f"uv sync failed: {result.stderr}")


def install_package(venv_path=None, package=None):
    """Add a package to pyproject.toml and sync the venv via uv add + uv sync."""
    if package is None:
        return
    uv = _get_uv()
    project_dir = _get_project_dir()
    venv_path = venv_path or get_venv_path()

    env = os.environ.copy()
    env["UV_PROJECT_ENVIRONMENT"] = venv_path

    result = subprocess.run(
        [uv, "add", package, "--project", project_dir],
        capture_output=True,
        text=True,
        env=env,
    )
    if result.returncode != 0:
        raise RuntimeError(f"uv add {package} failed: {result.stderr}")


def uninstall_package(venv_path=None, package=None):
    """Remove a package from pyproject.toml and sync the venv via uv remove."""
    if package is None:
        return
    uv = _get_uv()
    project_dir = _get_project_dir()
    venv_path = venv_path or get_venv_path()

    env = os.environ.copy()
    env["UV_PROJECT_ENVIRONMENT"] = venv_path

    result = subprocess.run(
        [uv, "remove", package, "--project", project_dir],
        capture_output=True,
        text=True,
        env=env,
    )
    if result.returncode != 0:
        raise RuntimeError(f"uv remove {package} failed: {result.stderr}")


def rebuild_venv(venv_path=None, requirements_file=None):
    """Rebuild the virtual environment: destroy and re-sync."""
    if venv_path is None:
        venv_path = get_venv_path()

    if os.path.exists(venv_path) and not is_venv_valid(venv_path):
        notify.send("HyDE UV", "⚠️ Python version changed or venv is broken, rebuilding…")
        destroy_venv(venv_path)

    notify.send("HyDE UV", "⏳ Syncing virtual environment...")
    result = _uv_sync()
    if result.returncode != 0:
        notify.send(
            "HyDE UV",
            f"Failed to sync environment:\n{result.stderr or result.stdout}",
            urgency="critical",
        )
        return

    notify.send("HyDE UV", "✅ Virtual environment rebuilt and packages synced.")


def v_import(module_name):
    """Dynamically import a module, installing it if necessary.

    Uses uv add so pyproject.toml and uv.lock are updated — the dependency
    is tracked for all users going forward.
    """
    _inject_site_packages()
    try:
        return importlib.import_module(module_name)
    except ImportError:
        notify.send("HyDE UV", f"Installing {module_name} module...")
        install_package(package=module_name)
        _inject_site_packages()
        importlib.invalidate_caches()

        try:
            module = importlib.import_module(module_name)
            notify.send("HyDE UV", f"Successfully installed {module_name}.")
            return module
        except ImportError as e:
            notify.send(
                "HyDE Error",
                f"Failed to import module {module_name} after installation: {e}",
                urgency="critical",
            )
            raise


def v_install(module_name, force_reinstall=False):
    """Install a module in the virtual environment without importing it.

    Uses uv add so pyproject.toml and uv.lock are updated — the dependency
    is tracked for all users going forward.

    Args:
        module_name (str): Name of module to install
        force_reinstall (bool): If True, reinstall even if module exists
    """
    _inject_site_packages()

    if not force_reinstall:
        try:
            importlib.import_module(module_name)
            return
        except ImportError:
            pass

    notify.send("HyDE UV", f"Installing {module_name} module...")
    install_package(package=module_name)
    _inject_site_packages()
    importlib.invalidate_caches()
    notify.send("HyDE UV", f"Successfully installed {module_name}.")


def main(args):
    parser = argparse.ArgumentParser(description="Python environment manager for HyDE")
    subparsers = parser.add_subparsers(dest="command")

    subparsers.add_parser("create", help="Create/sync the virtual environment")

    install_parser = subparsers.add_parser(
        "install", help="Install dependencies or a single package"
    )
    install_parser.add_argument("packages", nargs="*", help="Packages to install")

    uninstall_parser = subparsers.add_parser("uninstall", help="Uninstall a single package")
    uninstall_parser.add_argument("package", help="Package to uninstall")

    subparsers.add_parser("destroy", help="Destroy the virtual environment")
    subparsers.add_parser("rebuild", help="Rebuild the virtual environment")

    args = parser.parse_args(args)

    venv_path = get_venv_path()

    if args.command == "create":
        create_venv(venv_path)
    elif args.command == "install":
        if args.packages:
            for package in args.packages:
                install_package(venv_path, package)
        else:
            install_dependencies()
    elif args.command == "uninstall":
        uninstall_package(venv_path, args.package)
    elif args.command == "destroy":
        destroy_venv(venv_path)
    elif args.command == "rebuild":
        rebuild_venv(venv_path)
    else:
        parser.print_help()


def hyde(args):
    """Python environment manager for HyDE.

    Args:
        args (string): options
    """
    main(args)


if __name__ == "__main__":
    hyde(sys.argv[1:])
