def count_updates(ctx) -> int:
    # zypper list-updates returns a table, skip header lines
    output = ctx.capture(["zypper", "list-updates"])
    count = 0
    for line in output.splitlines():
        if line.strip() and not line.startswith("#") and not line.startswith("Loading") and not line.startswith("Repository") and not line.startswith("S |"):
            count += 1
    return count

def list_updates(ctx) -> None:
    ctx.run(["zypper", "list-updates"])
"""Zypper manager implementation for pm.py."""

from __future__ import annotations
from typing import Sequence

PackageEntry = tuple[str, str | None, str | None, str | None]

def install(ctx, packages: Sequence[str], no_confirm: bool = False) -> None:
    args = ["sudo", "zypper", "install"]
    if no_confirm:
        args.append("-y")
    args.extend(packages)
    ctx.run(args)

def remove(ctx, packages: Sequence[str], no_confirm: bool = False) -> None:
    args = ["sudo", "zypper", "remove"]
    if no_confirm:
        args.append("-y")
    args.extend(packages)
    ctx.run(args)

def upgrade(ctx, no_confirm: bool = False) -> None:
    args = ["sudo", "zypper", "update"]
    if no_confirm:
        args.append("-y")
    ctx.run(args)

def fetch(ctx, no_confirm: bool = False) -> None:
    args = ["sudo", "zypper", "refresh"]
    if no_confirm:
        args.append("-y")
    ctx.run(args)

def info(ctx, package: str) -> None:
    ctx.run(["zypper", "info", package])

def list_all(ctx) -> list[PackageEntry]:
    output = ctx.capture(["zypper", "se", "-u", "--details"])
    entries: list[PackageEntry] = []
    for line in output.splitlines():
        if line.startswith("S |") or not line.strip():
            continue
        parts = line.split("|")
        if len(parts) >= 5:
            name = parts[1].strip()
            repo = parts[2].strip()
            version = parts[3].strip()
            status = parts[0].strip()
            entries.append((name, repo, version, status))
    return entries

def list_installed(ctx) -> list[PackageEntry]:
    output = ctx.capture(["zypper", "se", "-i", "--details"])
    entries: list[PackageEntry] = []
    for line in output.splitlines():
        if line.startswith("S |") or not line.strip():
            continue
        parts = line.split("|")
        if len(parts) >= 5:
            name = parts[1].strip()
            repo = parts[2].strip()
            version = parts[3].strip()
            status = parts[0].strip()
            entries.append((name, repo, version, status))
    return entries

def is_installed(ctx, package: str) -> bool:
    return ctx.run(["rpm", "-q", package], check=False).returncode == 0

def file_query(ctx, target: str) -> None:
    ctx.run(["zypper", "wp", target])
