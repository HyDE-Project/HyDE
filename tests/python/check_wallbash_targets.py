"""Wallbash writes into directories the installer has to have deployed.

Every template names the file it renders on its first line, and the scripts a
template hands off to write next to it. None of them create the directory: a
target whose parent is missing is skipped with a warning that reads as a
missing package, so the component keeps the colors of the previous theme and
the reason is reported nowhere near the dot that was never deployed.

The check is therefore the one the renderer makes at run time. A target that
the repository ships nothing for is reported and skipped; there is no file to
deploy, so the template is stale rather than the deployment incomplete.
"""

from __future__ import annotations

import os
import pathlib
import re
import sys
import tomllib

REPO_ROOT = pathlib.Path(os.environ.get("REPO_ROOT", "."))
WALLBASH = REPO_ROOT / "Configs" / ".local" / "share" / "wallbash"
DOTS_DIR = REPO_ROOT / "Scripts" / "dots"
GROUPS_DIR = REPO_ROOT / "Scripts" / "dots-groups"
INSTALLER = REPO_ROOT / "Scripts" / "install.sh"
CONFIG_ROOT = "Configs/.config"

# The config home as the templates and the scripts spell it.
CONFIG_HOME = re.compile(
    r"(?:\$\{confDir(?::-[^}]*)?\}|\$confDir"
    r"|\$\{XDG_CONFIG_HOME(?::-[^}]*)?\}|\$XDG_CONFIG_HOME"
    r"|\$HOME/\.config)/([A-Za-z0-9._/-]+)"
)
CONFIG_HOME_ROOT = re.compile(
    r"^(?:\$\{confDir(?::-[^}]*)?\}|\$confDir"
    r"|\$\{XDG_CONFIG_HOME(?::-[^}]*)?\}|\$XDG_CONFIG_HOME"
    r"|\$HOME/\.config)(?:/(.*))?$"
)


def below_config_home(target_root: object) -> str | None:
    """The part of a target root under the config home, None when elsewhere."""
    if not isinstance(target_root, str):
        return None
    matched = CONFIG_HOME_ROOT.match(target_root.rstrip("/"))
    return (matched.group(1) or "") if matched else None


def dot_paths() -> dict[str, set[str]]:
    """Deployment destinations below the config home, keyed by metafile name."""
    deployed: dict[str, set[str]] = {}
    for metafile in sorted(DOTS_DIR.glob("*.toml")):
        document = tomllib.loads(metafile.read_text())
        for body in document.values():
            if not isinstance(body, dict) or body.get("source"):
                continue
            for table in body.get("files", []) or []:
                if not isinstance(table, dict) or table.get("source"):
                    continue
                root = below_config_home(table.get("target_root", ""))
                if root is None:
                    continue
                paths = table.get("paths", [])
                if isinstance(paths, str):
                    paths = [paths]
                elif not isinstance(paths, list):
                    paths = []
                for relative in paths:
                    if isinstance(relative, str):
                        joined = os.path.normpath(os.path.join(root, relative))
                        deployed.setdefault(metafile.stem, set()).add(joined)
    return deployed


def installed_metafiles() -> set[str]:
    """Metafiles the groups install.sh loads pull in."""
    groups = set(re.findall(r"dots-groups/([A-Za-z0-9_-]+)\.toml", INSTALLER.read_text()))
    reachable: set[str] = set()
    for group in groups:
        group_file = GROUPS_DIR / f"{group}.toml"
        if group_file.is_file():
            reachable.update(re.findall(r'"\.\./dots/([A-Za-z0-9_-]+)\.toml"', group_file.read_text()))
    return reachable


def targets() -> list[tuple[str, str, bool]]:
    """Yields (where, path below the config home, reached by the installer)."""
    found: list[tuple[str, str, bool]] = []
    for directory, by_installer in (("always", True), ("theme", False), ("scripts", True)):
        # A group of templates is nested in a directory of its own, so the tree
        # is walked rather than listed.
        for template in sorted((WALLBASH / directory).rglob("*")):
            if not template.is_file():
                continue
            if directory == "scripts":
                text = template.read_text()
            else:
                text = template.read_text().split("\n", 1)[0].split("|", 1)[0]
            where = template.relative_to(WALLBASH).as_posix()
            for relative in CONFIG_HOME.findall(text):
                found.append((where, os.path.normpath(relative.strip('"')), by_installer))
    return found


def main() -> int:
    """Reports every wallbash target no deployed dot creates a directory for."""
    if not WALLBASH.is_dir():
        print(f"    fail: {WALLBASH} is missing")
        return 1

    deployed = dot_paths()
    reachable = installed_metafiles()
    failures = 0
    checked = 0

    def fail(message: str) -> None:
        """Counts a defect and prints it the way the runner reads it."""
        nonlocal failures
        failures += 1
        print(f"    fail: {message}")

    for where, relative, by_installer in targets():
        # A target names either a file to render or the directory it lands in.
        wanted = os.path.dirname(relative) if os.path.splitext(relative)[1] else relative
        shipped = os.path.join(CONFIG_ROOT, wanted) if wanted else CONFIG_ROOT
        if not (REPO_ROOT / shipped).is_dir():
            print(f"    note: {where} renders into {relative}, which this checkout ships nothing for")
            continue

        checked += 1
        owners = {
            name
            for name, paths in deployed.items()
            for path in paths
            if path == wanted or path.startswith(f"{wanted}/") or wanted.startswith(f"{path}/")
        }
        if not owners:
            fail(f"{where} renders into {relative}, which no dot metafile deploys")
        elif by_installer and not owners & reachable:
            listed = ", ".join(sorted(owners))
            fail(f"{where} renders into {relative}, deployed only by {listed}, which the installer never loads")

    print(f"    {checked} wallbash target(s) checked")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
