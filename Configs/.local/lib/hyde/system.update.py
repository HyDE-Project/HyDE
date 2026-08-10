#!/usr/bin/env python3
"""System update helper using pm.py backends."""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from dataclasses import asdict, dataclass
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
if str(BASE_DIR) not in sys.path:
    sys.path.insert(0, str(BASE_DIR))

import pm

XDG_RUNTIME_DIR = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp"))
STATE_DIR = XDG_RUNTIME_DIR / "hyde"
UPDATE_INFO = STATE_DIR / "update_info.json"
CACHE_DIR = STATE_DIR / "pm" / "system_update"
SCRIPT_PATH = Path(__file__).resolve()

RESET = "\033[0m"
BOLD = "\033[1m"
GREEN = "\033[1;32m"
YELLOW = "\033[1;33m"
RED = "\033[1;31m"


@dataclass(slots=True)
class UpdateRecord:
    name: str
    count: int


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="System update status helper.")
    parser.add_argument(
        "action",
        nargs="?",
        choices=["status", "up", "interactive", "refresh-waybar"],
        default="status",
    )
    return parser


def state_for(name: str, color_mode: str = "never") -> pm.PMState:
    cache_dir = CACHE_DIR / name
    cache_dir.mkdir(parents=True, exist_ok=True)
    ctx = pm.ManagerContext(name, color_mode, cache_dir, no_confirm=False)
    return pm.PMState(
        name=name,
        module=pm.load_manager(name),
        ctx=ctx,
        colors=pm.build_color_profile(color_mode),
        script_path=SCRIPT_PATH,
        no_confirm=False,
    )


def collect_records() -> list[UpdateRecord]:
    records: list[UpdateRecord] = []
    for name in pm.list_available_managers():
        state = state_for(name)
        if getattr(state.module, "count_updates", None) is None:
            continue
        try:
            count = int(pm.call_module(state, "count_updates") or 0)
        except (subprocess.CalledProcessError, OSError, SystemExit):
            count = 0
        records.append(UpdateRecord(name=name, count=max(count, 0)))
    return records


def store_records(records: list[UpdateRecord]) -> None:
    UPDATE_INFO.parent.mkdir(parents=True, exist_ok=True)
    payload = {"managers": [asdict(record) for record in records]}
    UPDATE_INFO.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")


def read_records() -> list[UpdateRecord]:
    if not UPDATE_INFO.exists():
        return []
    try:
        payload = json.loads(UPDATE_INFO.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return []
    records: list[UpdateRecord] = []
    for item in payload.get("managers", []):
        if not isinstance(item, dict):
            continue
        name = item.get("name")
        count = item.get("count")
        if isinstance(name, str) and isinstance(count, int):
            records.append(UpdateRecord(name=name, count=max(count, 0)))
    return records


def total_updates(records: list[UpdateRecord]) -> int:
    return sum(record.count for record in records)


def refresh_waybar() -> None:
    subprocess.run(["pkill", "-RTMIN+20", "waybar"], check=False)


def build_tooltip(records: list[UpdateRecord]) -> str:
    if not records:
        return "No supported package managers found"
    total = total_updates(records)
    if total == 0:
        return " Packages are up to date"
    lines = [f"Updates {total}"]
    for record in records:
        lines.append(f"{record.name}: {record.count}")
    return "\n".join(lines)


def status_json(records: list[UpdateRecord]) -> str:
    total = total_updates(records)
    payload = {
        "text": "" if total == 0 else f"󰮯 {total}",
        "tooltip": build_tooltip(records),
        "class": "up-to-date" if total == 0 else "updates",
    }
    return json.dumps(payload, ensure_ascii=False)


def show_fastfetch() -> None:
    if shutil.which("hyde-shell") is None:
        return
    subprocess.run(["hyde-shell", "fastfetch"], check=False)


def print_summary(records: list[UpdateRecord]) -> None:
    print(f"{BOLD}System Update{RESET}")
    print("=" * 60)
    print(f"{'Manager':<16}{'Pending':>8}  State")
    print("-" * 60)
    for record in records:
        state = f"{YELLOW}pending{RESET}" if record.count else f"{GREEN}up to date{RESET}"
        print(f"{record.name:<16}{record.count:>8}  {state}")
    print("-" * 60)
    total = total_updates(records)
    total_state = f"{YELLOW}updates pending{RESET}" if total else f"{GREEN}up to date{RESET}"
    print(f"{'Total':<16}{total:>8}  {total_state}")


def show_previews(records: list[UpdateRecord]) -> None:
    pending = [record for record in records if record.count > 0]
    if not pending:
        print(f"\n{GREEN}System is already up to date.{RESET}")
        return
    print(f"\n{BOLD}Pending Updates{RESET}")
    for record in pending:
        print(f"\n{record.name}")
        print("~" * 60)
        state = state_for(record.name, color_mode="always")
        try:
            pm.call_module(state, "list_updates")
        except (subprocess.CalledProcessError, OSError, SystemExit) as exc:
            print(f"{RED}Could not list updates: {exc}{RESET}")


def prompt_yes_no(prompt: str, default_yes: bool = True) -> bool:
    default = "[Y/n]" if default_yes else "[y/N]"
    answer = input(f"\n{prompt} {default} ").strip().lower()
    if not answer:
        return default_yes
    return answer in {"y", "yes"}


def run_upgrades(records: list[UpdateRecord]) -> int:
    for record in records:
        if record.count == 0:
            continue
        print(f"\n{BOLD}Updating {record.name}{RESET}")
        print("~" * 60)
        state = state_for(record.name, color_mode="always")
        try:
            pm.call_module(state, "upgrade")
        except subprocess.CalledProcessError as exc:
            return exc.returncode or 1
    return 0


def wait_for_enter() -> None:
    try:
        input("\nPress Enter to close...")
    except EOFError:
        pass


def interactive(records: list[UpdateRecord] | None = None) -> int:
    records = records or read_records() or collect_records()
    show_fastfetch()
    print()
    print_summary(records)
    show_previews(records)

    exit_code = 0
    had_updates = total_updates(records) > 0
    did_attempt_upgrade = False
    if had_updates:
        if prompt_yes_no("Apply updates now"):
            did_attempt_upgrade = True
            exit_code = run_upgrades(records)
        else:
            print(f"\n{YELLOW}Skipped updates.{RESET}")

    refreshed = collect_records()
    store_records(refreshed)
    refresh_waybar()
    if did_attempt_upgrade:
        print()
        print_summary(refreshed)
    wait_for_enter()
    return exit_code


def launch_interactive(records: list[UpdateRecord]) -> int:
    store_records(records)
    launcher = shutil.which("xdg-terminal-exec")
    if launcher is not None:
        subprocess.run([launcher, "--title=systemupdate", "--", sys.executable, str(SCRIPT_PATH), "interactive"], check=False)
        return 0
    if sys.stdout.isatty():
        return interactive(records)
    print("system_update: xdg-terminal-exec is not available", file=sys.stderr)
    return 1


def status_mode() -> int:
    records = collect_records()
    store_records(records)
    print(status_json(records))
    return 0


def cached_records() -> list[UpdateRecord]:
    records = read_records()
    if records:
        return records
    records = collect_records()
    store_records(records)
    return records


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    if args.action == "refresh-waybar":
        refresh_waybar()
        return 0
    if args.action == "interactive":
        return interactive()
    if args.action == "up":
        return launch_interactive(cached_records())
    return status_mode()


if __name__ == "__main__":
    raise SystemExit(main())
