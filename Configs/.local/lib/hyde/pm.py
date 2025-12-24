#!/usr/bin/env python3
"""Python rewrite of the pm.sh helper."""

from __future__ import annotations

import argparse
import os
import re
import shlex
import shutil
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path
from types import ModuleType
from typing import Callable, Iterable, Sequence

PMS = ["paru", "yay", "pacman", "apt", "dnf", "zypper", "apk", "brew", "scoop", "flatpak"]
PACKAGE_ENTRY = tuple[str, str | None, str | None, str | None]
ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")
_MANAGER_CACHE: dict[str, ModuleType] = {}


@dataclass(slots=True)
class ColorProfile:
    name: str
    group: str
    version: str
    status: str
    reset: str


@dataclass(slots=True)
class ManagerContext:
    name: str
    color_mode: str
    cache_dir: Path

    def run(
        self,
        args: Sequence[str],
        *,
        check: bool = True,
        capture: bool = False,
        env: dict[str, str] | None = None,
        cwd: str | Path | None = None,
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(  # noqa: PLW1510
            list(args),
            check=check,
            capture_output=capture,
            text=True,
            env=env,
            cwd=str(cwd) if cwd is not None else None,
        )

    def capture(self, args: Sequence[str], **kwargs: object) -> str:
        return self.run(args, capture=True, **kwargs).stdout


@dataclass(slots=True)
class PMState:
    name: str
    module: object
    ctx: ManagerContext
    colors: ColorProfile
    script_path: Path

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog=Path(sys.argv[0]).name,
        description="Package manager wrapper over multiple backends.",
    )
    parser.add_argument("--pm", dest="force_pm", help="Force package manager to use a specific backend.")
    subparsers = parser.add_subparsers(dest="action", required=True)

    def add_cmd(name: str, action: str, *, aliases: Sequence[str] = (), help_text: str) -> argparse.ArgumentParser:
        cmd = subparsers.add_parser(
            name,
            aliases=list(aliases),
            help=help_text,
            description=help_text,
        )
        cmd.set_defaults(action=action)
        return cmd

    install = add_cmd("install", "install", aliases=["i"], help_text="Install packages (interactive when none specified).")
    install.add_argument("packages", nargs="*", help="Packages to install")

    remove = add_cmd("remove", "remove", aliases=["r"], help_text="Remove packages (interactive when none specified).")
    remove.add_argument("packages", nargs="*", help="Packages to remove")

    add_cmd("upgrade", "upgrade", aliases=["u"], help_text="Upgrade all packages using the current manager.")
    add_cmd("fetch", "fetch", aliases=["f"], help_text="Refresh the package database.")

    info = add_cmd("info", "info", aliases=["n"], help_text="Show information about a package.")
    info.add_argument("package", help="Package name to inspect")

    list_cmd = add_cmd("list", "list", aliases=["l"], help_text="List packages from the specified source.")
    list_cmd.add_argument("source", choices=["all", "installed"], help="Package source to list")

    add_cmd("list-installed", "list_installed", aliases=["li"], help_text="List installed packages.")
    add_cmd("list-all", "list_all", aliases=["la"], help_text="List every package available.")

    search = add_cmd("search", "search", aliases=["s"], help_text="Search packages from the specified source.")
    search.add_argument("source", choices=["all", "installed"], help="Where to search")
    add_cmd("search-installed", "search_installed", aliases=["si"], help_text="Search within installed packages interactively.")
    add_cmd("search-all", "search_all", aliases=["sa"], help_text="Search within all packages interactively.")

    add_cmd("which", "which", aliases=["w"], help_text="Print the active package manager.")

    query = add_cmd("query", "query", aliases=["pq"], help_text="Check whether a package is installed.")
    query.add_argument("package", help="Package to query")

    file_query = add_cmd("file-query", "file_query", aliases=["fq"], help_text="Find the owner of a given file.")
    file_query.add_argument("target", help="File path to inspect")

    add_cmd("count-updates", "count_updates", aliases=["cu"], help_text="Count pending updates.")
    add_cmd("list-updates", "list_updates", aliases=["lu"], help_text="List details about pending updates.")

    return parser


def main(argv: Sequence[str] | None = None) -> None:
    parser = build_parser()
    args = parser.parse_args(argv)

    pm_name = determine_pm(args.force_pm)
    color_mode = os.environ.get("PM_COLOR")
    if not color_mode:
        color_mode = "always" if sys.stdout.isatty() else "never"
    pm_module = load_manager(pm_name)
    cache_dir = Path(os.environ.get("XDG_CACHE_DIR", Path.home() / ".cache")) / "pm" / pm_name
    cache_dir.mkdir(parents=True, exist_ok=True)
    ctx = ManagerContext(pm_name, color_mode, cache_dir)
    state = PMState(
        name=pm_name,
        module=pm_module,
        ctx=ctx,
        colors=build_color_profile(color_mode),
        script_path=Path(__file__).resolve(),
    )

    handler = COMMAND_HANDLERS[args.action]
    handler(state, args)


def determine_pm(forced: str | None) -> str:
    if forced:
        if forced not in PMS:
            die(f"forced package manager '{forced}' is not supported")
        ensure_command(forced)
        return forced
    env_pm = os.environ.get("PM")
    if env_pm and env_pm in PMS and shutil.which(env_pm):
        return env_pm
    for name in PMS:
        if shutil.which(name):
            return name
    die("no supported package manager found (%s)" % " ".join(PMS))


def load_manager(name: str) -> ModuleType:
    if name in _MANAGER_CACHE:
        return _MANAGER_CACHE[name]
    module_path = Path(__file__).with_name("pm") / f"{name}.py"
    if not module_path.is_file():
        die(f"missing manager module for '{name}'")
    spec = spec_from_file_location(f"pm_handlers.{name}", module_path)
    if spec is None or spec.loader is None:
        die(f"unable to load manager '{name}'")
    module = module_from_spec(spec)
    spec.loader.exec_module(module)  # type: ignore[attr-defined]
    required = [
        "install",
        "remove",
        "upgrade",
        "fetch",
        "info",
        "list_all",
        "list_installed",
    ]
    for func in required:
        if not hasattr(module, func):
            die(f"manager '{name}' is missing required function '{func}'")
    _MANAGER_CACHE[name] = module
    return module


def handle_install(state: PMState, packages: Sequence[str]) -> None:
    packages = list(packages)
    if not packages:
        ensure_fresh_cache(state)
        packages = interactive_select(state, "all")
        if not packages:
            return
    call_module(state, "install", packages)


def handle_remove(state: PMState, packages: Sequence[str]) -> None:
    packages = list(packages)
    if not packages:
        packages = interactive_select(state, "installed")
    if not packages:
        return
    call_module(state, "remove", packages)


def handle_fetch(state: PMState) -> None:
    call_module(state, "fetch")
    write_last_fetch(state)


def handle_info(state: PMState, package: str) -> None:
    if not package:
        die("expected <pkg> argument")
    call_module(state, "info", package)


def handle_list(state: PMState, source: str) -> None:
    entries = get_entries(state, source)
    for line in format_entries(entries, source, state.colors):
        print(line)


def handle_search_command(state: PMState, source: str) -> None:
    selected = interactive_select(state, source)
    for pkg in selected:
        print(pkg)


def handle_query(state: PMState, package: str) -> None:
    if not package:
        die("expected <pkg> argument")
    func = getattr(state.module, "is_installed", None)
    if not func:
        die(f"is-installed command is not supported for package manager '{state.name}'")
    result = func(state.ctx, package)
    print("Installed" if result else "Not installed")


def handle_file_query(state: PMState, target: str) -> None:
    if not target:
        die("expected <file> argument")
    func = getattr(state.module, "file_query", None)
    if not func:
        die(f"file-query command is not supported for package manager '{state.name}'")
    func(state.ctx, target)


def handle_count_updates(state: PMState) -> None:
    func = getattr(state.module, "count_updates", None)
    if not func:
        die(f"count-updates is not supported for package manager '{state.name}'")
    print(func(state.ctx))


def handle_list_updates(state: PMState) -> None:
    func = getattr(state.module, "list_updates", None)
    if not func:
        die(f"list-updates is not supported for package manager '{state.name}'")
    func(state.ctx)


def cmd_install(state: PMState, args: argparse.Namespace) -> None:
    handle_install(state, args.packages)


def cmd_remove(state: PMState, args: argparse.Namespace) -> None:
    handle_remove(state, args.packages)


def cmd_upgrade(state: PMState, args: argparse.Namespace) -> None:  # noqa: ARG001
    call_module(state, "upgrade")


def cmd_fetch(state: PMState, args: argparse.Namespace) -> None:  # noqa: ARG001
    handle_fetch(state)


def cmd_info(state: PMState, args: argparse.Namespace) -> None:
    handle_info(state, args.package)


def cmd_list(state: PMState, args: argparse.Namespace) -> None:
    handle_list(state, args.source)


def cmd_list_installed(state: PMState, args: argparse.Namespace) -> None:  # noqa: ARG001
    handle_list(state, "installed")


def cmd_list_all(state: PMState, args: argparse.Namespace) -> None:  # noqa: ARG001
    handle_list(state, "all")


def cmd_search(state: PMState, args: argparse.Namespace) -> None:
    handle_search_command(state, args.source)


def cmd_search_installed(state: PMState, args: argparse.Namespace) -> None:  # noqa: ARG001
    handle_search_command(state, "installed")


def cmd_search_all(state: PMState, args: argparse.Namespace) -> None:  # noqa: ARG001
    handle_search_command(state, "all")


def cmd_which(state: PMState, args: argparse.Namespace) -> None:  # noqa: ARG001
    print(state.name)


def cmd_query(state: PMState, args: argparse.Namespace) -> None:
    handle_query(state, args.package)


def cmd_file_query(state: PMState, args: argparse.Namespace) -> None:
    handle_file_query(state, args.target)


def cmd_count_updates(state: PMState, args: argparse.Namespace) -> None:  # noqa: ARG001
    handle_count_updates(state)


def cmd_list_updates(state: PMState, args: argparse.Namespace) -> None:  # noqa: ARG001
    handle_list_updates(state)


COMMAND_HANDLERS: dict[str, Callable[[PMState, argparse.Namespace], None]] = {
    "install": cmd_install,
    "remove": cmd_remove,
    "upgrade": cmd_upgrade,
    "fetch": cmd_fetch,
    "info": cmd_info,
    "list": cmd_list,
    "list_installed": cmd_list_installed,
    "list_all": cmd_list_all,
    "search": cmd_search,
    "search_installed": cmd_search_installed,
    "search_all": cmd_search_all,
    "which": cmd_which,
    "query": cmd_query,
    "file_query": cmd_file_query,
    "count_updates": cmd_count_updates,
    "list_updates": cmd_list_updates,
}


def ensure_fresh_cache(state: PMState) -> None:
    marker = state.ctx.cache_dir / "last-fetch"
    today = current_date()
    if marker.exists() and marker.read_text(encoding="utf-8").strip() == today:
        return
    call_module(state, "fetch")
    write_last_fetch(state)


def write_last_fetch(state: PMState) -> None:
    marker = state.ctx.cache_dir / "last-fetch"
    marker.parent.mkdir(parents=True, exist_ok=True)
    marker.write_text(current_date(), encoding="utf-8")


def get_entries(state: PMState, source: str) -> list[PACKAGE_ENTRY]:
    func_name = "list_all" if source == "all" else "list_installed"
    entries: list[PACKAGE_ENTRY] = call_module(state, func_name)
    return entries


def format_entries(entries: Iterable[PACKAGE_ENTRY], source: str, colors: ColorProfile) -> list[str]:
    lines: list[str] = []
    for name, group, version, status in entries:
        segments = [f"{colors.name}{name}"]
        if source == "all":
            if group:
                segments.append(f"{colors.group}{group}")
            if version:
                segments.append(f"{colors.version}{version}")
            if status:
                segments.append(f"{colors.status}{status}")
        else:
            if version:
                segments.append(f"{colors.version}{version}")
        segments.append(colors.reset)
        lines.append("".join(segments).strip())
    return lines


def interactive_select(state: PMState, source: str) -> list[str]:
    entries = get_entries(state, source)
    lines = format_entries(entries, source, state.colors)
    if not lines:
        return []
    usable = lines
    if not sys.stdin.isatty():
        patterns = compile_stdin_filter(sys.stdin)
        usable = [line for line in lines if matches_any(line, patterns)]
        if not usable:
            return []
    selected_lines = run_fzf(state, usable)
    packages = [line_to_package(line) for line in selected_lines]
    return packages


def run_fzf(state: PMState, lines: list[str]) -> list[str]:
    if not shutil.which("fzf"):
        die("fzf is not available, run 'pm install fzf' first")
    preview_cmd = build_preview_command(state)
    proc = subprocess.run(  # noqa: PLW1510
        [
            "fzf",
            "--exit-0",
            "--multi",
            "--no-sort",
            "--ansi",
            "--layout=reverse",
            "--exact",
            "--cycle",
            "--preview",
            preview_cmd,
        ],
        input="\n".join(lines),
        text=True,
        capture_output=True,
        env={**os.environ, "PM": state.name, "PM_COLOR": state.ctx.color_mode},
    )
    if proc.returncode == 2:
        return []
    if proc.returncode not in (0,):
        die("fzf exited with an unexpected status")
    return [line for line in proc.stdout.splitlines() if line.strip()]


def build_preview_command(state: PMState) -> str:
    script = shlex.quote(str(state.script_path))
    python = shlex.quote(sys.executable)
    return f"PM={state.name} PM_COLOR={state.ctx.color_mode} {python} {script} --pm {state.name} info {{1}}"


def compile_stdin_filter(stdin: Iterable[str]) -> list[re.Pattern[str]]:
    patterns: list[re.Pattern[str]] = []
    for raw in stdin:
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        patterns.append(re.compile(fr"^{line}(?:$|\s)"))
    if not patterns:
        die("empty stdin filter")
    return patterns


def matches_any(line: str, patterns: Iterable[re.Pattern[str]]) -> bool:
    stripped = strip_ansi(line)
    return any(pattern.search(stripped) for pattern in patterns)


def line_to_package(line: str) -> str:
    stripped = strip_ansi(line).strip()
    return stripped.split()[0]


def strip_ansi(value: str) -> str:
    return ANSI_RE.sub("", value)


def call_module(state: PMState, func_name: str, *args: object):
    func = getattr(state.module, func_name)
    return func(state.ctx, *args)


def ensure_command(name: str) -> None:
    if not shutil.which(name):
        die(f"required command '{name}' is not available")


def build_color_profile(mode: str) -> ColorProfile:
    if mode == "always":
        return ColorProfile(
            name="\033[1m",
            group=" \033[1;35m",
            version=" \033[1;36m",
            status=" \033[1;32m",
            reset="\033[0m",
        )
    return ColorProfile(name="", group=" ", version=" ", status=" ", reset="")


def current_date() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%d")


def die(message: str) -> None:
    raise SystemExit(f"pm: {message}")


if __name__ == "__main__":
    main()
