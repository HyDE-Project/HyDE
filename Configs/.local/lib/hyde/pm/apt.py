"""APT manager implementation."""

from __future__ import annotations

from typing import Sequence

PackageEntry = tuple[str, str | None, str | None, str | None]


def install(ctx, packages: Sequence[str]) -> None:
    ctx.run(["sudo", "apt", "install", *packages])


def remove(ctx, packages: Sequence[str]) -> None:
    ctx.run(["sudo", "apt", "remove", *packages])


def upgrade(ctx) -> None:
    ctx.run(["sudo", "apt", "upgrade"])


def fetch(ctx) -> None:
    ctx.run(["sudo", "apt", "update"])


def info(ctx, package: str) -> None:
    ctx.run(["apt-cache", "show", package])


def list_all(ctx) -> list[PackageEntry]:
    pkgs = sorted({line.strip() for line in ctx.capture(["apt-cache", "pkgnames"]).splitlines() if line.strip()})
    installed_lines = ctx.capture(["dpkg-query", "--show", "-f", "${package} ${version}\n"]).splitlines()
    installed_map: dict[str, str] = {}
    for line in installed_lines:
        parts = line.split()
        if not parts:
            continue
        version = parts[1] if len(parts) > 1 else None
        installed_map[parts[0]] = version or ""
    entries: list[PackageEntry] = []
    for name in pkgs:
        if not name:
            continue
        version = installed_map.get(name)
        status = "[installed]" if name in installed_map else None
        entries.append((name, None, version, status))
    return entries


def list_installed(ctx) -> list[PackageEntry]:
    entries: list[PackageEntry] = []
    output = ctx.capture(["dpkg-query", "--show"])
    for line in output.splitlines():
        parts = line.split()
        if len(parts) >= 2:
            entries.append((parts[0], None, parts[1], None))
    return entries


def is_installed(ctx, package: str) -> bool:
    return ctx.run(["dpkg", "-l", package], check=False).returncode == 0


def file_query(ctx, target: str) -> None:
    ctx.run(["apt-file", "search", target])


def count_updates(ctx) -> int:
    output = ctx.capture(["apt", "list", "--upgradeable"])
    return sum(1 for line in output.splitlines() if line and not line.startswith("Listing"))


def list_updates(ctx) -> None:
    ctx.run(["apt", "list", "--upgradeable"], check=False)
