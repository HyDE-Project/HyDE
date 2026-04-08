#!/usr/bin/env python3
import os
import subprocess
import sys
import argparse


def create_venv(venv_path):
    """Create a virtual environment."""
    subprocess.run([sys.executable, "-m", "venv", venv_path], check=True)
    print(f"Virtual environment created at {venv_path}")


def install_dependencies(venv_path, requirements):
    """Install dependencies in the virtual environment."""
    pip_executable = os.path.join(venv_path, "bin", "pip")
    subprocess.run([pip_executable, "install", "-r", requirements], check=True)
    print(f"Dependencies installed from {requirements}")


def install_package(venv_path, package):
    """Install a single package in the virtual environment."""
    pip_executable = os.path.join(venv_path, "bin", "pip")
    subprocess.run([pip_executable, "install", package], check=True)
    print(f"Package {package} installed")


def uninstall_package(venv_path, package):
    """Uninstall a single package from the virtual environment."""
    pip_executable = os.path.join(venv_path, "bin", "pip")
    subprocess.run([pip_executable, "uninstall", "-y", package], check=True)
    print(f"Package {package} uninstalled")


def main():
    parser = argparse.ArgumentParser(description="HyDe's Python env manager")
    parser.add_argument(
        "command",
        type=str,
        help="The command to run (e.g., create_venv, install, uninstall)",
    )
    parser.add_argument(
        "package",
        type=str,
        nargs="?",
        help="The package to install/uninstall (optional)",
    )
    args = parser.parse_args()

    home_dir = os.path.expanduser("~")
    venv_path = os.path.join(home_dir, ".local", "share", "hyde", "venv")
    requirements_file = os.path.join(
        home_dir, ".local", "lib", "hyde", "requirements.txt"
    )

    match args.command:
        case "create_venv":
            # Create the virtual environment
            create_venv(venv_path)
        case "install":
            if args.package:
                # Install a single package
                install_package(venv_path, args.package)
            else:
                # Install dependencies from requirements.txt
                if os.path.exists(requirements_file):
                    install_dependencies(venv_path, requirements_file)
                else:
                    print(f"No requirements.txt found at {requirements_file}")
        case "uninstall":
            if args.package:
                # Uninstall a single package
                uninstall_package(venv_path, args.package)
            else:
                print("Please specify a package to uninstall.")
        case _:
            print(f"Unknown command: {args.command}")


if __name__ == "__main__":
    main()
