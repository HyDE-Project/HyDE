"""Flatpak manager implementation."""

from __future__ import annotations

from typing import Sequence

import sys
from pathlib import Path as _Path
_BASE_DIR = _Path(__file__).resolve().parent
if str(_BASE_DIR) not in sys.path:
    sys.path.insert(0, str(_BASE_DIR))

from meta import PMMetadata

PackageEntry = tuple[str, str | None, str | None, str | None]

# Metadata: flatpak is a universal package manager (not base, not AUR)
META = PMMetadata(
    name="flatpak",
    priority=30,
    is_base=False,
)


def install(ctx, packages: Sequence[str], no_confirm: bool = False) -> None:
    args = ["flatpak", "install"]
    if no_confirm:
        args.append("-y")
    args.extend(packages)
    ctx.run(args)


def remove(ctx, packages: Sequence[str], no_confirm: bool = False) -> None:
    args = ["flatpak", "uninstall"]
    if no_confirm:
        args.append("-y")
    args.extend(packages)
    ctx.run(args)


def upgrade(ctx, no_confirm: bool = False) -> None:
    args = ["flatpak", "update"]
    if no_confirm:
        args.append("-y")
    ctx.run(args)


def fetch(ctx) -> None:
    ctx.run(["flatpak", "update", "--appstream"])


def info(ctx, package: str) -> None:
    ctx.run(["flatpak", "info", package])


def list_all(ctx) -> list[PackageEntry]:
    output = ctx.capture(["flatpak", "remote-ls", "--columns=name,application,version"])
    return _parse_table(output)


def list_installed(ctx) -> list[PackageEntry]:
    output = ctx.capture(["flatpak", "list", "--columns=name,application,version"])
    return _parse_table(output)


def is_installed(ctx, package: str) -> bool:
    output = ctx.capture(["flatpak", "list", "--columns=application"])
    return any(line.strip() == package for line in output.splitlines())


def file_query(ctx, target: str) -> None:
    raise SystemExit("pm: file-query is not supported for Flatpak")


def count_updates(ctx) -> int:
    output = ctx.capture(["flatpak", "remote-ls", "--updates"], check=False)
    return sum(1 for line in output.splitlines() if line.strip() and not line.startswith("Application"))


def list_updates(ctx) -> None:
    ctx.run(["flatpak", "remote-ls", "--updates"], check=False)


def _parse_table(raw: str) -> list[PackageEntry]:
    entries: list[PackageEntry] = []
    for line in raw.splitlines():
        parts = [segment.strip() for segment in line.split("\t") if segment.strip()]
        if len(parts) >= 2:
            version = parts[2] if len(parts) > 2 else None
            entries.append((parts[0], parts[1], version, None))
    return entries
