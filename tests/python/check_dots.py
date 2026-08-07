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

# Packages the Arch repositories do not carry, checked against
# https://archlinux.org/packages/search/json/?name=<package>. pacman installs a
# whole dependency block with one command, so a single name it cannot resolve
# aborts the command and leaves every other package in the block uninstalled.
# These belong to an AUR helper instead.
AUR_ONLY = {"hyprquery", "libinput-gestures", "wlogout"}

REPO_ROOT = pathlib.Path(os.environ.get("REPO_ROOT", "."))
DOTS_DIR = REPO_ROOT / "Scripts" / "dots"


def declared_paths(table: dict) -> list:
    """`paths` is a single string or a list of them.

    Anything else is wrapped rather than iterated, so a malformed value is
    reported as a wrong type instead of crashing the checker.
    """
    paths = table.get("paths", [])
    if isinstance(paths, str):
        return [paths]
    if isinstance(paths, list):
        return list(paths)
    return [paths]


def has_glob(relative: str) -> bool:
    """A pattern is resolved at deploy time, so it cannot be checked here."""
    return any(character in relative for character in "*?[")


def inside(root: pathlib.Path, relative: str) -> bool:
    """A declared path has to stay under `root`, absolute or `..` included."""
    try:
        return (root / relative).resolve().is_relative_to(root)
    except (OSError, RuntimeError, ValueError):
        # Older Python raises RuntimeError rather than OSError on a symlink loop.
        return False


def inside_repo(relative: str) -> bool:
    """A source root has to stay in the checkout."""
    return inside(REPO_ROOT.resolve(), relative)


def declared_sources(document: dict) -> list[tuple[str, object]]:
    """Yields (where, source) for every source declared in a metafile."""
    found = []
    for component, body in document.items():
        if isinstance(body, dict):
            if "source" in body:
                found.append((component, body["source"]))
            for index, table in enumerate(body.get("files", []) or []):
                if isinstance(table, dict) and "source" in table:
                    found.append((f"{component}.files[{index}]", table["source"]))
    return found


def is_remote_source(source: object) -> bool:
    """Only a non-empty string names something the installer can fetch."""
    return isinstance(source, str) and bool(source.strip())


def entries(document: dict) -> list[tuple[str, dict, bool]]:
    """Yields (component, table, remote) for every files table in a metafile.

    `remote` is true when the component or the entry declares a usable `source`.
    Those files come from an archive the installer downloads, so their paths
    resolve against the extracted tree rather than this checkout and cannot be
    validated here. A malformed `source` does not earn that exemption.
    """
    found = []
    for component, body in document.items():
        if isinstance(body, dict):
            component_remote = is_remote_source(body.get("source"))
            for table in body.get("files", []) or []:
                remote = component_remote or is_remote_source(table.get("source"))
                found.append((component, table, remote))
    return found


def dependencies(document: dict) -> list[tuple[str, dict]]:
    """The dependency tables of a metafile, paired with the component naming them."""
    found = []
    for component, body in document.items():
        if isinstance(body, dict):
            for table in body.get("dependency", []) or []:
                found.append((component, table))
    return found


def main() -> int:
    """Reports every metafile defect found and returns the exit status."""
    metafiles = sorted(DOTS_DIR.glob("*.toml"))
    if not metafiles:
        print(f"    fail: no metafiles found under {DOTS_DIR}")
        return 1

    failures = 0

    def fail(message: str) -> None:
        """Counts a defect and prints it the way the runner reads it."""
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

        for where_source, source in declared_sources(document):
            if not is_remote_source(source):
                fail(f"{name} [{where_source}] declares an unusable source {source!r}")

        for component, table, remote in entries(document):
            where = f"{name} [{component}.files]"

            if "paths" not in table:
                fail(f"{where} has no paths")
            if "target_root" not in table:
                fail(f"{where} has no target_root")

            action = table.get("action")
            if action is not None and action not in ACTIONS:
                fail(f"{where} has an unknown action {action!r}")

            for relative in declared_paths(table):
                if not isinstance(relative, str):
                    fail(f"{where} declares a path as {type(relative).__name__}, expected a string")

            source_root = table.get("source_root")
            if source_root is not None and not isinstance(source_root, str):
                fail(f"{where} declares source_root as {type(source_root).__name__}, expected a string")
            elif isinstance(source_root, str) and not remote:
                if not inside_repo(source_root):
                    fail(f"{where} points outside the repository with source_root {source_root!r}")
                elif not (REPO_ROOT / source_root).is_dir():
                    fail(f"{where} points at a missing source_root {source_root!r}")
                else:
                    root = (REPO_ROOT / source_root).resolve()
                    for relative in declared_paths(table):
                        if not isinstance(relative, str):
                            continue
                        if not inside(root, relative):
                            fail(f"{where} points outside its source_root with path {relative!r}")
                        elif not has_glob(relative) and not (root / relative).exists():
                            fail(f"{where} points at a missing path {relative!r}")

        for component, table in dependencies(document):
            where = f"{name} [{component}.dependency]"
            unknown = set(table) - PACKAGE_MANAGERS
            if unknown:
                fail(f"{where} lists unknown package managers {sorted(unknown)}")
            for manager, packages in table.items():
                if not isinstance(packages, list):
                    fail(f"{where} declares {manager} as {type(packages).__name__}, expected a list")
                    continue
                for package in packages:
                    if not isinstance(package, str):
                        fail(f"{where} declares a package as {type(package).__name__}, expected a string")
                    elif manager == "pacman" and package in AUR_ONLY:
                        fail(f"{where} asks pacman for {package!r}, which only the AUR carries")

    print(f"    {len(metafiles)} metafile(s) checked")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
