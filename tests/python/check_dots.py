"""Structural validation of the dot metafiles under Scripts/dots.

Each metafile describes what the installer copies and which packages a
component needs. A malformed entry is not reported by the installer, it is
simply skipped, so the component silently ships without part of its files.
"""

from __future__ import annotations

import os
import pathlib
import sys
import tomllib

ACTIONS = {"sync", "preserve", "tarball"}
PACKAGE_MANAGERS = {"pacman", "yay", "paru", "dnf", "flatpak", "apt", "zypper"}

REPO_ROOT = pathlib.Path(os.environ.get("REPO_ROOT", "."))
DOTS_DIR = REPO_ROOT / "Scripts" / "dots"


def declared_paths(table: dict) -> list:
    """`paths` is a single string or a list of them."""
    paths = table.get("paths", [])
    return [paths] if isinstance(paths, str) else list(paths)


def has_glob(relative: str) -> bool:
    """A pattern is resolved at deploy time, so it cannot be checked here."""
    return any(character in relative for character in "*?[")


def inside_repo(relative: str) -> bool:
    """A source path has to stay in the checkout, absolute or `..` included."""
    root = REPO_ROOT.resolve()
    try:
        return (root / relative).resolve().is_relative_to(root)
    except (OSError, ValueError):
        return False


def entries(document: dict) -> list[tuple[str, dict]]:
    """Yields (component, table) for every files table in a metafile."""
    found = []
    for component, body in document.items():
        if isinstance(body, dict):
            for table in body.get("files", []) or []:
                found.append((component, table))
    return found


def dependencies(document: dict) -> list[tuple[str, dict]]:
    found = []
    for component, body in document.items():
        if isinstance(body, dict):
            for table in body.get("dependency", []) or []:
                found.append((component, table))
    return found


def main() -> int:
    metafiles = sorted(DOTS_DIR.glob("*.toml"))
    if not metafiles:
        print(f"    fail: no metafiles found under {DOTS_DIR}")
        return 1

    failures = 0

    def fail(message: str) -> None:
        nonlocal failures
        failures += 1
        print(f"    fail: {message}")

    for metafile in metafiles:
        name = metafile.name

        try:
            document = tomllib.loads(metafile.read_text())
        except tomllib.TOMLDecodeError as error:
            fail(f"{name} is not valid TOML: {error}")
            continue

        for component, table in entries(document):
            where = f"{name} [{component}.files]"

            if "paths" not in table:
                fail(f"{where} has no paths")
            if "target_root" not in table:
                fail(f"{where} has no target_root")

            action = table.get("action")
            if action is not None and action not in ACTIONS:
                fail(f"{where} has an unknown action {action!r}")

            source_root = table.get("source_root")
            if source_root is not None:
                if not isinstance(source_root, str):
                    fail(f"{where} declares source_root as {type(source_root).__name__}, expected a string")
                elif not inside_repo(source_root):
                    fail(f"{where} points outside the repository with source_root {source_root!r}")
                elif not (REPO_ROOT / source_root).is_dir():
                    fail(f"{where} points at a missing source_root {source_root!r}")
                else:
                    for relative in declared_paths(table):
                        if not isinstance(relative, str):
                            fail(f"{where} declares a path as {type(relative).__name__}, expected a string")
                        elif not has_glob(relative) and not (REPO_ROOT / source_root / relative).exists():
                            fail(f"{where} points at a missing path {relative!r}")

        for component, table in dependencies(document):
            where = f"{name} [{component}.dependency]"
            unknown = set(table) - PACKAGE_MANAGERS
            if unknown:
                fail(f"{where} lists unknown package managers {sorted(unknown)}")
            for manager, packages in table.items():
                if not isinstance(packages, list):
                    fail(f"{where} declares {manager} as {type(packages).__name__}, expected a list")

    print(f"    {len(metafiles)} metafile(s) checked")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
