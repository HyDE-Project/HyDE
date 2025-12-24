"""Paru manager implementation."""

from __future__ import annotations

from typing import Sequence

PackageEntry = tuple[str, str | None, str | None, str | None]


def install(ctx, packages: Sequence[str]) -> None:
    ctx.run(["paru", "-S", "--needed", *packages])


def remove(ctx, packages: Sequence[str]) -> None:
    ctx.run(["paru", "-Rsc", *packages])


def upgrade(ctx) -> None:
    ctx.run(["paru", "-Su"])


def fetch(ctx) -> None:
    ctx.run(["paru", "-Sy"])


def info(ctx, package: str) -> None:
    ctx.run(["paru", "-Si", f"--color={_color_flag(ctx)}", package])


def list_all(ctx) -> list[PackageEntry]:
    entries: list[PackageEntry] = []
    output = ctx.capture(["paru", "-Sl", "--color=never"])
    for line in output.splitlines():
        parts = line.split()
        if len(parts) < 3:
            continue
        repo, name, version = parts[:3]
        status = parts[3] if len(parts) > 3 else None
        entries.append((name, repo, version, status))
    return entries


def list_installed(ctx) -> list[PackageEntry]:
    output = ctx.capture(["paru", "-Q", "--color=never"])
    entries: list[PackageEntry] = []
    for line in output.splitlines():
        parts = line.split()
        if len(parts) >= 2:
            entries.append((parts[0], None, parts[1], None))
    return entries


def is_installed(ctx, package: str) -> bool:
    return ctx.run(["paru", "-Q", package], check=False).returncode == 0


def file_query(ctx, target: str) -> None:
    ctx.run(["paru", "-F", "--", target])


def count_updates(ctx) -> int:
    output = ctx.capture(["paru", "-Qu"], check=False)
    return sum(1 for line in output.splitlines() if line.strip())


def list_updates(ctx) -> None:
    ctx.run(["paru", "-Qu"], check=False)


def _color_flag(ctx) -> str:
    return "always" if ctx.color_mode == "always" else "never"
