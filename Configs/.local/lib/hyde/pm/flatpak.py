"""Flatpak manager implementation."""

from __future__ import annotations

from typing import Sequence

PackageEntry = tuple[str, str | None, str | None, str | None]


def install(ctx, packages: Sequence[str]) -> None:
    ctx.run(["flatpak", "install", "-y", *packages])


def remove(ctx, packages: Sequence[str]) -> None:
    ctx.run(["flatpak", "uninstall", "-y", *packages])


def upgrade(ctx) -> None:
    ctx.run(["flatpak", "update", "-y"])


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
