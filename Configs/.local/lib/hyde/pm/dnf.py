"""DNF manager implementation."""

from __future__ import annotations

from typing import Sequence

PackageEntry = tuple[str, str | None, str | None, str | None]


def install(ctx, packages: Sequence[str]) -> None:
    ctx.run(["sudo", "dnf", "install", *packages])


def remove(ctx, packages: Sequence[str]) -> None:
    ctx.run(["sudo", "dnf", "remove", *packages])


def upgrade(ctx) -> None:
    ctx.run(["sudo", "dnf", "upgrade"])


def fetch(ctx) -> None:
    ctx.run(["sudo", "dnf", "check-update"], check=False)


def info(ctx, package: str) -> None:
    ctx.run(["dnf", "info", "-q", package])


def list_all(ctx) -> list[PackageEntry]:
    output = ctx.capture(["dnf", "repoquery", "-q", "--qf=%{name} %{repoid} %{evr}"])
    installed_output = ctx.capture(["dnf", "repoquery", "-q", "--installed", "--qf", "%{name} %{evr}"])
    installed_versions = {
        line.split()[0]: line.split()[1]
        for line in installed_output.splitlines()
        if len(line.split()) >= 2
    }
    entries: list[PackageEntry] = []
    for line in output.splitlines():
        parts = line.split()
        if len(parts) >= 3:
            name, repo, version = parts[:3]
            status = "[installed]" if name in installed_versions else None
            entries.append((name, repo, version, status))
    return entries


def list_installed(ctx) -> list[PackageEntry]:
    output = ctx.capture(["dnf", "repoquery", "-q", "--installed", "--qf", "%{name} %{evr}"])
    entries: list[PackageEntry] = []
    for line in output.splitlines():
        parts = line.split()
        if len(parts) >= 2:
            entries.append((parts[0], None, parts[1], None))
    return entries


def is_installed(ctx, package: str) -> bool:
    return ctx.run(["rpm", "-q", package], check=False).returncode == 0


def file_query(ctx, target: str) -> None:
    ctx.run(["dnf", "provides", target])


def count_updates(ctx) -> int:
    output = ctx.capture(["dnf", "check-update", "-q"], check=False)
    count = 0
    for line in output.splitlines():
        line = line.strip()
        if not line or line.startswith("Last ") or line.startswith("Obsoleting"):
            continue
        parts = line.split()
        if len(parts) >= 3 and "." in parts[0]:
            count += 1
    return count


def list_updates(ctx) -> None:
    ctx.run(["dnf", "check-update"], check=False)
