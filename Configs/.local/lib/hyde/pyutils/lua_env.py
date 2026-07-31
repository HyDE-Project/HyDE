#!/usr/bin/env python3
"""
HyDE's system Lua environment manager using system luarocks
usage: lua_env.py [command] <options>


Commands:
    create     Ensure system luarocks is available and install bootstrap packages
    destroy    Remove the Hyde Lua rocks tree
    rebuild    Recreate the Hyde Lua rocks tree and reinstall packages
    sync       Reinstall bootstrap packages and snapshot installed rocks
    install    Install a luarocks package
    uninstall  Uninstall a luarocks package
    luarocks   Run a raw luarocks command
    help       Show this help message
"""
import os
import sys
import subprocess
import shutil
import argparse
import json

XDG_STATE_HOME = os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state"))
HYDE_STATE_DIR = os.path.join(XDG_STATE_HOME, "hyde")
LUA_ENV_DIR = os.path.join(HYDE_STATE_DIR, "lua_env")
LUA_BIN = os.environ.get("LUA") or shutil.which("lua") or shutil.which("lua5.5") or shutil.which("lua5.4") or shutil.which("lua5.3")
LUAROCKS_BIN = os.environ.get("LUAROCKS") or shutil.which("luarocks") or shutil.which("luarocks-5.5") or shutil.which("luarocks-5.4") or shutil.which("luarocks-5.3")
ROCKS_SNAPSHOT = os.path.join(HYDE_STATE_DIR, "luarocks_env.json")
BOOTSTRAP_CONFIG = os.path.join(os.path.dirname(__file__), "lua_env.json")
LUA_ENV_ARGS = ["--tree", LUA_ENV_DIR]



def run(cmd, check=True, env=None):
    result = subprocess.run(cmd, check=False, env=env, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"[lua_env] $ {' '.join(cmd)}")
        if result.stdout:
            print(result.stdout, end="")
        if result.stderr:
            print(result.stderr, end="", file=sys.stderr)
        if check:
            raise subprocess.CalledProcessError(result.returncode, cmd, output=result.stdout, stderr=result.stderr)
    return result


def ensure_state_dir():
    os.makedirs(LUA_ENV_DIR, exist_ok=True)


def load_bootstrap_config():
    install = []
    snapshot_exclude = set()

    if not os.path.exists(BOOTSTRAP_CONFIG):
        return install, snapshot_exclude

    with open(BOOTSTRAP_CONFIG, "r", encoding="utf-8") as handle:
        try:
            config = json.load(handle)
        except ValueError:
            print(f"[lua_env] Warning: invalid bootstrap config at {BOOTSTRAP_CONFIG}, using defaults")
            return install, snapshot_exclude

    def _parse_pkg_entry(entry):
        if isinstance(entry, dict) and "name" in entry:
            return (entry["name"], entry.get("version"))
        elif isinstance(entry, str):
            return (entry, None)
        return None

    if isinstance(config, dict):
        install_cfg = config.get("bootstrap_install")
        exclude_cfg = config.get("snapshot_exclude")

        if install_cfg is None:
            install_cfg = config.get("install")
        if exclude_cfg is None:
            exclude_cfg = config.get("exclude")

        # install: list of (name, version) tuples
        if isinstance(install_cfg, list):
            install = []
            for item in install_cfg:
                parsed = _parse_pkg_entry(item)
                if parsed and parsed[0]:
                    install.append(parsed)

        # snapshot_exclude: set of names (ignore version for exclusion)
        if isinstance(exclude_cfg, list):
            snapshot_exclude = set()
            for item in exclude_cfg:
                parsed = _parse_pkg_entry(item)
                if parsed and parsed[0]:
                    snapshot_exclude.add(parsed[0])
        else:
            snapshot_exclude = set()
        # Always exclude bootstrap_install names
        snapshot_exclude = set([name for name, _ in install]) | snapshot_exclude

    return install, snapshot_exclude


def parse_installed_rocks(output):
    rocks = []
    _, bootstrap_exclude = load_bootstrap_config()

    for line in output.splitlines():
        fields = line.split()

        if len(fields) < 2:
            continue

        name, version = fields[0], fields[1]

        if name in bootstrap_exclude:
            continue

        rocks.append({"name": name, "version": version})

    return rocks


def load_saved_rocks():
    if not os.path.exists(ROCKS_SNAPSHOT):
        return []

    with open(ROCKS_SNAPSHOT, "r", encoding="utf-8") as handle:
        try:
            rocks = json.load(handle)
        except ValueError:
            return []

    if not isinstance(rocks, list):
        return []

    return [rock for rock in rocks if isinstance(rock, dict) and rock.get("name") and rock.get("version")]


def save_saved_rocks(rocks):
    ensure_state_dir()

    normalized = sorted(rocks, key=lambda rock: (rock["name"], rock["version"]))
    with open(ROCKS_SNAPSHOT, "w", encoding="utf-8") as handle:
        json.dump(normalized, handle, indent=2)
        handle.write("\n")


def snapshot_installed_rocks():
    if not LUAROCKS_BIN:
        return []

    result = subprocess.run(
        [LUAROCKS_BIN] + LUA_ENV_ARGS + ["list", "--porcelain"],
        check=True,
        capture_output=True,
        text=True,
    )
    rocks = parse_installed_rocks(result.stdout)
    save_saved_rocks(rocks)
    print(f"Saved {len(rocks)} user Lua rock(s) to {ROCKS_SNAPSHOT}")
    return rocks


def restore_saved_rocks(force=False):
    rocks = load_saved_rocks()

    if not rocks:
        return

    print(f"Restoring {len(rocks)} saved Lua rock(s).")
    for rock in rocks:
        install_rock(rock["name"], rock["version"], force=force)


def ensure_system_tools():
    if not LUA_BIN:
        print("[lua_env] error: system Lua interpreter not found. Install lua or set LUA environment variable.")
        sys.exit(1)
    if not LUAROCKS_BIN:
        print("[lua_env] error: system luarocks not found. Install luarocks or set LUAROCKS environment variable.")
        sys.exit(1)


def install_rock(name, version=None, force=False):
    args = [LUAROCKS_BIN] + LUA_ENV_ARGS + ["install", name]
    if version:
        args.append(version)
    if force:
        args.append("--force")

    action = "Installing"
    if force:
        action = "Reinstalling"
    if version:
        print(f"[lua_env] {action} {name} {version}")
    else:
        print(f"[lua_env] {action} {name}")

    run(args)


def create_env(force=False):
    ensure_system_tools()
    print(f"[lua_env] Using system Lua: {LUA_BIN}")
    print(f"[lua_env] Using system luarocks: {LUAROCKS_BIN}")
    print("System luarocks is active; no local LuaJIT environment is created.")

    bootstrap_install, _ = load_bootstrap_config()
    ensure_state_dir()
    for name, version in bootstrap_install:
        install_rock(name, version, force=force)

    restore_saved_rocks(force=force)


def destroy_env():
    if os.path.exists(LUA_ENV_DIR):
        shutil.rmtree(LUA_ENV_DIR)
        print(f"Removed Lua rocks tree at {LUA_ENV_DIR}.")
    else:
        print(f"Lua rocks tree not found at {LUA_ENV_DIR}.")


def rebuild_env():
    ensure_system_tools()
    snapshot_installed_rocks()
    destroy_env()
    print("Rebuild: recreating the Lua rocks tree and reinstalling bootstrap packages.")
    create_env()


def sync_env():
    ensure_system_tools()
    ensure_state_dir()
    # Reinstall all bootstrap_install packages to latest or pinned version
    bootstrap_install, _ = load_bootstrap_config()
    for name, version in bootstrap_install:
        install_rock(name, version, force=True)
    # Now snapshot only user-installed rocks
    snapshot_installed_rocks()


def install_pkg(pkg):
    ensure_system_tools()
    ensure_state_dir()
    run([LUAROCKS_BIN] + LUA_ENV_ARGS + ["install", pkg])
    snapshot_installed_rocks()


def uninstall_pkg(pkg):
    ensure_system_tools()
    ensure_state_dir()
    run([LUAROCKS_BIN] + LUA_ENV_ARGS + ["remove", pkg])
    snapshot_installed_rocks()


def luarocks_cmd(args):
    ensure_system_tools()
    ensure_state_dir()
    run([LUAROCKS_BIN] + LUA_ENV_ARGS + args)


def usage():
    print(__doc__)


def main():
    parser = argparse.ArgumentParser(
        prog="lua_env",
        usage="lua_env.py [command] <options>",
        description="HyDE's system Lua environment manager",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    subparsers = parser.add_subparsers(dest="command", metavar="[command]")
    subparsers.add_parser("create", help="Ensure system luarocks is available and install bootstrap packages")
    subparsers.add_parser("destroy", help="Remove the Hyde Lua rocks tree")
    subparsers.add_parser("rebuild", help="Recreate the Hyde Lua rocks tree and reinstall packages")
    subparsers.add_parser("sync", help="Reinstall bootstrap packages and snapshot installed rocks")
    install_p = subparsers.add_parser("install", help="Install a luarocks package")
    install_p.add_argument("package", metavar="package")
    uninstall_p = subparsers.add_parser("uninstall", help="Uninstall a luarocks package")
    uninstall_p.add_argument("package", metavar="package")
    luarocks_p = subparsers.add_parser("luarocks", help="Run a raw luarocks command")
    luarocks_p.add_argument("args", nargs=argparse.REMAINDER, metavar="args")
    subparsers.add_parser("help", help="Show this help message")
    args = parser.parse_args()
    if args.command == "create":
        create_env()
    elif args.command == "destroy":
        destroy_env()
    elif args.command == "rebuild":
        rebuild_env()
    elif args.command == "sync":
        sync_env()
    elif args.command == "install":
        install_pkg(args.package)
    elif args.command == "uninstall":
        uninstall_pkg(args.package)
    elif args.command == "luarocks":
        if not args.args:
            print("Usage: lua_env.py luarocks <args>")
            sys.exit(1)
        luarocks_cmd(args.args)
    else:
        usage()

if __name__ == "__main__":
    main()
