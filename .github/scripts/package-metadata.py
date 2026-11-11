#!/usr/bin/env python3
"""Print package names declared for one package manager in Scripts/dots."""

from __future__ import annotations

import pathlib
import sys
import tomllib


def main() -> int:
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} PACKAGE_MANAGER", file=sys.stderr)
        return 2

    package_manager = sys.argv[1]
    repo_root = pathlib.Path(__file__).resolve().parents[2]
    packages: set[str] = set()

    def collect(value: object) -> None:
        if isinstance(value, dict):
            manager_packages = value.get(package_manager)
            if isinstance(manager_packages, list):
                for package in manager_packages:
                    if not isinstance(package, str):
                        continue
                    if package_manager == "pacman":
                        package = package.split(r"\>=", maxsplit=1)[0]
                    if package:
                        packages.add(package)
            for child in value.values():
                collect(child)
        elif isinstance(value, list):
            for child in value:
                collect(child)

    for config in sorted((repo_root / "Scripts").rglob("*.toml")):
        try:
            document = tomllib.loads(config.read_text())
            if config.parent == repo_root / "Scripts/dots":
                collect(document)
        except (OSError, tomllib.TOMLDecodeError) as error:
            print(f"{config}: {error}", file=sys.stderr)
            return 1

    if not packages:
        print(f"No {package_manager} packages found", file=sys.stderr)
        return 1

    print("\n".join(sorted(packages)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
