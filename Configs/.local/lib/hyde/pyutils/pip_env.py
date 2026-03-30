import os
import sys
import subprocess
import shutil
import argparse
import importlib

lib_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, lib_dir)


<<<<<<< HEAD
import xdg_base_dirs  # noqa: E402
import wrapper.libnotify as notify  # noqa: E402
=======
import xdg_base_dirs
import wrapper.libnotify as notify
>>>>>>> master


if lib_dir is None:
    raise FileNotFoundError("None of the specified lib directories exist.")
    sys.exit(1)


<<<<<<< HEAD
=======
def is_venv_valid(venv_path):
    """Returns whether the venv is valid or not
    
    Args:
        venv_path: Path to the virtual environment to validate
    """
    python_exe = os.path.join(venv_path, "bin", "python")
    pyvenv_cfg = os.path.join(venv_path, "pyvenv.cfg")

    # To determine whether a venv is valid, the following three checks are performed:

    # 1.- Must have its own python file and it must be executable
    if not (os.path.isfile(python_exe) and os.access(python_exe, os.X_OK)):
        return False
    
    # 2.- Python inside venv must be able to import pip 
    try:
        res = subprocess.run(
            [python_exe, "-c", "import pip"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=5,
        )
        if res.returncode != 0:
            return False
    except Exception:
        return False
    
    # 3.- Python version used to create the venv must match current one
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


>>>>>>> master
def get_venv_path():
    """Set up the virtual environment path and modify sys.path."""
    venv_path = os.path.join(xdg_base_dirs.xdg_state_home(), "hyde", "pip_env")
    if not os.path.exists(venv_path):
        venv_path = os.path.join(xdg_base_dirs.xdg_state_home(), "hyde", "pip_env")
    site_packages_path = os.path.join(
        venv_path,
        "lib",
        f"python{sys.version_info.major}.{sys.version_info.minor}",
        "site-packages",
    )
    sys.path.insert(0, site_packages_path)
    return venv_path


def create_venv(venv_path, requirements_file=None):
    """Create a virtual environment and optionally install dependencies."""
    if not os.path.exists(os.path.join(venv_path, "bin", "pip")):
        subprocess.run([sys.executable, "-m", "venv", venv_path], check=True)
        pip_executable = os.path.join(venv_path, "bin", "pip")
        subprocess.run([pip_executable, "install", "--upgrade", "pip"], check=True)
        if requirements_file and os.path.exists(requirements_file):
            with open(requirements_file, "r") as f:
                list_requirements = "\n".join(
                    [
                        f"📦 {line.strip()}"
                        for line in f
                        if line.strip() and not line.startswith("#")
                    ]
                )

            notify.send(
                "HyDE PIP",
                f"⏳ Installing virtual environment Dependencies:\n {list_requirements}",
            )
            result = subprocess.run(
                [pip_executable, "install", "-r", requirements_file],
                capture_output=True,
                text=True,
            )
            result.check_returncode()
        notify.send("HyDE PIP", "✅ Virtual environment created successfully")
    else:
        pass


def destroy_venv(venv_path):
    """Destroy the virtual environment while retaining the requirements.txt file."""
    if os.path.exists(venv_path):
        shutil.rmtree(venv_path)
<<<<<<< HEAD
    # else:
=======
>>>>>>> master


def install_dependencies(venv_path, requirements_file):
    """Install dependencies in the virtual environment."""
    if not os.path.exists(venv_path):
        create_venv(venv_path, requirements_file)
    else:
        pip_executable = os.path.join(venv_path, "bin", "pip")
        command = [pip_executable, "install", "-r", requirements_file]
        result = subprocess.run(command, capture_output=True, text=True)
        result.check_returncode()


def install_package(venv_path, package):
    """Install a single package in the virtual environment."""
<<<<<<< HEAD
=======
    if os.path.exists(venv_path) and not is_venv_valid(venv_path):
        notify.send("HyDE PIP", "⚠️ Python version changed or virtualenv is broken, rebuilding…")
        destroy_venv(venv_path)
>>>>>>> master
    if not os.path.exists(venv_path):
        create_venv(venv_path)
    pip_executable = os.path.join(venv_path, "bin", "pip")
    result = subprocess.run(
        [pip_executable, "install", package],
        capture_output=True,
        text=True,
    )
    result.check_returncode()


def uninstall_package(venv_path, package):
    """Uninstall a single package from the virtual environment."""
    pip_executable = os.path.join(venv_path, "bin", "pip")
    result = subprocess.run(
        [pip_executable, "uninstall", "-y", package],
        capture_output=True,
        text=True,
    )
    result.check_returncode()


def rebuild_venv(venv_path=None, requirements_file=None):
    """Rebuild the virtual environment: reinstall if missing, install/upgrade requirements, and update all packages."""
<<<<<<< HEAD
    # Use XDG_STATE_HOME for venv_path if not provided
=======
>>>>>>> master
    if venv_path is None:
        venv_path = os.path.join(xdg_base_dirs.xdg_state_home(), "hyde", "pip_env")
        if not os.path.exists(venv_path):
            venv_path = os.path.join(xdg_base_dirs.xdg_state_home(), "hyde", "pip_env")
    pip_executable = os.path.join(venv_path, "bin", "pip")
<<<<<<< HEAD
    # Recreate venv if missing
    if not os.path.exists(pip_executable):
        create_venv(venv_path, requirements_file)
    # Helper to produce a short summary for informational pip output
=======

    if not os.path.exists(pip_executable):
        create_venv(venv_path, requirements_file)

>>>>>>> master
    def _short_summary(stdout: str, stderr: str) -> str:
        if stderr:
            for sline in stderr.splitlines():
                if sline.strip():
                    return sline.strip()
<<<<<<< HEAD
        req_lines = [line for line in stdout.splitlines() if line.startswith("Requirement already satisfied")]
=======
        req_lines = [
            line for line in stdout.splitlines() if line.startswith("Requirement already satisfied")
        ]
>>>>>>> master
        if req_lines:
            return f"{len(req_lines)} requirements already satisfied"
        for sline in stdout.splitlines():
            if sline.startswith("Successfully installed"):
                return sline.strip()
        return ""

<<<<<<< HEAD
    # Install/upgrade requirements (capture output)
=======
>>>>>>> master
    if requirements_file and os.path.exists(requirements_file):
        result = subprocess.run(
            [pip_executable, "install", "--upgrade", "-r", requirements_file],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            notify.send(
                "HyDE PIP",
                f"Failed to install requirements:\n{result.stderr or result.stdout}",
                urgency="critical",
            )
<<<<<<< HEAD
            # Don't re-raise; stop rebuild early after notifying the user
=======
>>>>>>> master
            return
        else:
            short = _short_summary(result.stdout, result.stderr)
            if short:
                notify.send("HyDE PIP", short)

<<<<<<< HEAD
    # Upgrade all installed packages (list outdated and upgrade)
    result = subprocess.run(
        [pip_executable, "list", "--outdated", "--format=freeze"],
=======
    result = subprocess.run(
        [pip_executable, "list", "--outdated", "--format=json"],
>>>>>>> master
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        notify.send(
            "HyDE PIP",
            f"Failed to list outdated packages:\n{result.stderr or result.stdout}",
            urgency="critical",
        )
<<<<<<< HEAD
    # Don't re-raise here; just stop after notifying so caller can continue
    return

    outdated = [line.split("==")[0] for line in result.stdout.splitlines() if line]
=======
        return

    import json

    try:
        outdated_packages = json.loads(result.stdout) if result.stdout.strip() else []
        outdated = [pkg["name"] for pkg in outdated_packages]
    except (json.JSONDecodeError, KeyError) as e:
        notify.send(
            "HyDE PIP",
            f"Failed to parse outdated packages: {e}",
            urgency="critical",
        )
        return
>>>>>>> master
    if outdated:
        res2 = subprocess.run(
            [pip_executable, "install", "--upgrade", "-q"] + outdated,
            capture_output=True,
            text=True,
        )
        if res2.returncode != 0:
            notify.send(
                "HyDE PIP",
                f"Failed to upgrade packages:\n{res2.stderr or res2.stdout}",
                urgency="critical",
            )
<<<<<<< HEAD
            # Don't re-raise; notify and exit rebuild
=======
>>>>>>> master
            return
        else:
            short2 = _short_summary(res2.stdout, res2.stderr)
            if short2:
                notify.send("HyDE PIP", short2)

    notify.send("HyDE PIP", "✅ Virtual environment rebuilt and packages updated.")


def v_import(module_name):
    """Dynamically import a module, installing it if necessary."""
    venv_path = get_venv_path()
<<<<<<< HEAD
    sys.path.insert(0, venv_path)  # Ensure sys.path is updated before import
=======
    sys.path.insert(0, venv_path)
>>>>>>> master
    try:
        module = importlib.import_module(module_name)
        return module
    except ImportError:
        notify.send("HyDE PIP", f"Installing {module_name} module...")
        install_package(venv_path, module_name)

<<<<<<< HEAD
        # Reload sys.path to include the new module
=======
>>>>>>> master
        importlib.invalidate_caches()
        sys.path.insert(0, venv_path)
        sys.path.insert(
            0,
            os.path.join(
                venv_path,
                "lib",
                f"python{sys.version_info.major}.{sys.version_info.minor}",
                "site-packages",
            ),
        )

        try:
            module = importlib.import_module(module_name)
            notify.send("HyDE PIP", f"Successfully installed {module_name}.")
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
    Args:
        module_name (str): Name of module to install
        force_reinstall (bool): If True, reinstall even if module exists
    """
    venv_path = get_venv_path()
    if not os.path.exists(os.path.join(venv_path, "bin", "pip")):
        create_venv(venv_path)
    pip_executable = os.path.join(venv_path, "bin", "pip")
<<<<<<< HEAD
    # Check if module is already installed
=======

>>>>>>> master
    result = subprocess.run(
        [pip_executable, "show", module_name],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0 or force_reinstall:
        notify.send("HyDE PIP", f"Installing {module_name} module...")
        install_package(venv_path, module_name)
        notify.send("HyDE PIP", f"Successfully installed {module_name}.")
    sys.path.insert(0, venv_path)
    sys.path.insert(
        0,
        os.path.join(
            venv_path,
            "lib",
            f"python{sys.version_info.major}.{sys.version_info.minor}",
            "site-packages",
        ),
    )


def main(args):
    parser = argparse.ArgumentParser(description="Python environment manager for HyDE")
    subparsers = parser.add_subparsers(dest="command")

<<<<<<< HEAD
    create_parser = subparsers.add_parser(
        "create", help="Create the virtual environment"
    )
=======
    create_parser = subparsers.add_parser("create", help="Create the virtual environment")
>>>>>>> master
    create_parser.set_defaults(func=create_venv)

    install_parser = subparsers.add_parser(
        "install", help="Install dependencies or a single package"
    )
    install_parser.add_argument("packages", nargs="*", help="Packages to install")
    install_parser.add_argument(
        "-f",
        "--requirements",
        type=str,
        help="The requirements file to use for installation",
    )
    install_parser.set_defaults(func=install_dependencies)

<<<<<<< HEAD
    uninstall_parser = subparsers.add_parser(
        "uninstall", help="Uninstall a single package"
    )
    uninstall_parser.add_argument("package", help="Package to uninstall")
    uninstall_parser.set_defaults(func=uninstall_package)

    destroy_parser = subparsers.add_parser(
        "destroy", help="Destroy the virtual environment"
    )
=======
    uninstall_parser = subparsers.add_parser("uninstall", help="Uninstall a single package")
    uninstall_parser.add_argument("package", help="Package to uninstall")
    uninstall_parser.set_defaults(func=uninstall_package)

    destroy_parser = subparsers.add_parser("destroy", help="Destroy the virtual environment")
>>>>>>> master
    destroy_parser.set_defaults(func=destroy_venv)

    rebuild_parser = subparsers.add_parser(
        "rebuild", help="Rebuild the virtual environment and update packages"
    )
    rebuild_parser.set_defaults(func=rebuild_venv)

    args = parser.parse_args(args)

    venv_path = get_venv_path()
    requirements_file = os.path.join(
<<<<<<< HEAD
        os.path.expanduser("~/.local/lib/hyde/pyutils"), "requirements.txt"
=======
        xdg_base_dirs.user_lib_dir(), "hyde", "pyutils", "requirements.txt"
>>>>>>> master
    )

    if args.command == "create":
        args.func(venv_path, requirements_file)
    elif args.command == "install":
        if args.packages:
            for package in args.packages:
                install_package(venv_path, package)
        else:
            args.func(venv_path, args.requirements or requirements_file)
    elif args.command == "uninstall":
        args.func(venv_path, args.package)
    elif args.command == "destroy":
        args.func(venv_path)
    elif args.command == "rebuild":
        args.func(venv_path, requirements_file)
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

<<<<<<< HEAD
# Call get_venv_path() to set up the virtual environment path
=======

>>>>>>> master
sys.path.insert(0, get_venv_path())
