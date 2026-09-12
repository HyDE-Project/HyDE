"""Check that Steam game names cannot alter launcher row delimiters."""

from __future__ import annotations

import contextlib
import importlib.util
import io
import json
import os
import pathlib
import sys
import tempfile
import types

REPO_ROOT = pathlib.Path(os.environ.get("REPO_ROOT", "."))
SCRIPT_PATH = REPO_ROOT / "Configs/.local/lib/hyde/gamelauncher/steam.py"


def write_manifest(steamapps: pathlib.Path, appid: int, name: str) -> None:
    (steamapps / f"appmanifest_{appid}.acf").write_text(
        f'"AppState"\n{{\n    "appid" "{appid}"\n    "name" "{name}"\n}}\n'
    )


def main() -> int:
    if not SCRIPT_PATH.is_file():
        print(f"fail: steam.py not found at {SCRIPT_PATH}")
        return 1

    # list_games does not fetch icons unless requested, so this stub keeps the
    # test independent of steam.py's optional HTTP dependency.
    sys.modules.setdefault("requests", types.ModuleType("requests"))
    spec = importlib.util.spec_from_file_location("gamelauncher_steam", SCRIPT_PATH)
    if spec is None or spec.loader is None:
        print(f"fail: could not load {SCRIPT_PATH}")
        return 1
    steam = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(steam)

    with tempfile.TemporaryDirectory() as tmp:
        steamapps = pathlib.Path(tmp) / "steamapps"
        steamapps.mkdir()
        write_manifest(steamapps, 10, "Safe Game")
        write_manifest(steamapps, 20, "Injected\tCommand")
        write_manifest(steamapps, 30, "Steam Runtime")

        steam.find_steam_roots = lambda: [steamapps]
        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            status = steam.main(["--json"])
        games = json.loads(stdout.getvalue())
        by_id = {game["id"]: game for game in games}

    if status != 0:
        print(f"fail: steam.py --json exited {status}")
        return 1
    if set(by_id) != {10}:
        print(f"fail: expected only the safe game, got app IDs {sorted(by_id)}")
        return 1
    if by_id[10]["run_command"] != "xdg-open steam://rungameid/10":
        print(f"fail: the safe game's run command changed: {by_id[10]['run_command']!r}")
        return 1
    if by_id[10]["rofi_string"] != "Safe Game\txdg-open steam://rungameid/10":
        print(f"fail: the safe game's launcher row is malformed: {by_id[10]['rofi_string']!r}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
