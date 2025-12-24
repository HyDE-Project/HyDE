"""Pacman manager implementation."""

from __future__ import annotations

from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Sequence

AUR_HELPERS = ("paru", "paru-bin", "yay", "yay-bin")
PackageEntry = tuple[str, str | None, str | None, str | None]


def install(ctx, packages: Sequence[str]) -> None:
    remaining = list(packages)
    for helper in AUR_HELPERS:
        if helper in remaining:
            _install_aur_helper(ctx, helper)
            remaining = [pkg for pkg in remaining if pkg != helper]
    if remaining:
        ctx.run(["sudo", "pacman", "-S", "--needed", *remaining])


def remove(ctx, packages: Sequence[str]) -> None:
    ctx.run(["sudo", "pacman", "-Rsc", *packages])


def upgrade(ctx) -> None:
    ctx.run(["sudo", "pacman", "-Su"])


def fetch(ctx) -> None:
    ctx.run(["sudo", "pacman", "-Sy"])


def info(ctx, package: str) -> None:
    if package in AUR_HELPERS:
        print("\033[1mRepository  :\033[0m aur")
        print(f"\033[1mName        :\033[0m {package}")
        print("\033[1mDescription :\033[0m AUR helper")
        return
    ctx.run(["pacman", "-Si", f"--color={_color_flag(ctx)}", package])


def list_all(ctx) -> list[PackageEntry]:
    entries: list[PackageEntry] = []
    output = ctx.capture(["pacman", "-Sl", "--color=never"])
    for line in output.splitlines():
        parts = line.split()
        if len(parts) < 3:
            continue
        repo, name, version = parts[:3]
        status = parts[3] if len(parts) > 3 else None
        entries.append((name, repo, version, status))
    entries.extend((helper, "aur", None, "AUR helper") for helper in AUR_HELPERS)
    return entries


def list_installed(ctx) -> list[PackageEntry]:
    entries: list[PackageEntry] = []
    output = ctx.capture(["pacman", "-Q", "--color=never"])
    for line in output.splitlines():
        parts = line.split()
        if len(parts) >= 2:
            entries.append((parts[0], None, parts[1], None))
    return entries


def is_installed(ctx, package: str) -> bool:
    return ctx.run(["pacman", "-Q", package], check=False).returncode == 0


def file_query(ctx, target: str) -> None:
    ctx.run(["pacman", "-F", target])


def count_updates(ctx) -> int:
    output = ctx.capture(["pacman", "-Qu"], check=False)
    return sum(1 for line in output.splitlines() if line.strip())


def list_updates(ctx) -> None:
    ctx.run(["pacman", "-Qu"], check=False)


def _install_aur_helper(ctx, helper: str) -> None:
    ctx.run(["sudo", "pacman", "-S", "--needed", "git", "base-devel"])
    with TemporaryDirectory() as tmp:
        repo_path = Path(tmp) / helper
        ctx.run(["git", "clone", f"https://aur.archlinux.org/{helper}.git", str(repo_path)])
        ctx.run(["makepkg", "-si"], cwd=repo_path)


def _color_flag(ctx) -> str:
    return "always" if ctx.color_mode == "always" else "never"
