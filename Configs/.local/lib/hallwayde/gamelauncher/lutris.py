"""
Hi! This is lightweight Lutris DB inspector for gamelauncher.sh as the lutris command is slow and broken.

- Detects possible Lutris database locations (native & flatpak)
- Reads installed games from the SQLite DB and outputs JSON to stdout
- Usage:
    gamelaunche/lutris.py --detect     
    gamelaunche/lutris.py --list       

Output fields per game: {"id","name","slug","runner","path","icon"}

Assumptions/notes:
- Lutris stores a SQLite DB usually at:
    ~/.local/share/lutris/pga.db  (or ~/.local/share/lutris/lutris.db)
  Flatpak path: ~/.var/app/net.lutris.Lutris/data/lutris/pga.db
  Some distros or versions may use 'lutris.db' or 'pga.db'
- If multiple DB files exist, this script will prefer the newer one or allow listing all.\
- Please report if you know of other common locations or schema variations!

"""

import argparse
import json
import os
import sqlite3
from pathlib import Path
from typing import Dict, List, Optional

DEFAULT_LOCATIONS = [
    Path(os.environ.get("XDG_DATA_HOME", os.path.expanduser("~/.local/share")) + "/lutris/pga.db"),
    Path(
        os.environ.get("XDG_DATA_HOME", os.path.expanduser("~/.local/share")) + "/lutris/lutris.db"
    ),
    Path(
        os.environ.get("XDG_DATA_HOME", os.path.expanduser("~/.local/share")) + "/lutris/db.sqlite"
    ),
    Path(
        os.environ.get(
            "XDG_DATA_HOME",
            os.path.expanduser("~/.var/app/net.lutris.Lutris/data"),
        )
        + "/lutris/pga.db"
    ),
    Path(
        os.environ.get(
            "XDG_DATA_HOME",
            os.path.expanduser("~/.var/app/net.lutris.Lutris/data"),
        )
        + "/lutris/lutris.db"
    ),
    Path(
        os.environ.get(
            "XDG_DATA_HOME",
            os.path.expanduser("~/.var/app/net.lutris.Lutris/data"),
        )
        + "/lutris/db.sqlite"
    ),
    Path(
        os.environ.get("HOME", os.path.expanduser("~"))
        + "/snap/lutris/current/.local/share/lutris/pga.db"
    ),
]


def find_dbs(paths: List[Path] = DEFAULT_LOCATIONS) -> List[Path]:
    found = [p for p in paths if p.exists() and p.is_file()]

    if not found:
        home = Path.home()
        lutris_dirs = [
            home / ".local/share/lutris",
            home / ".var/app/net.lutris.Lutris/data",
        ]
        for lutris_dir in lutris_dirs:
            if lutris_dir.exists():
                for candidate in lutris_dir.rglob("*.db"):
                    if candidate.is_file():
                        found.append(candidate)

    found.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    return found


def read_games_from_db(db_path: Path) -> List[Dict]:
    URI = f"file:{db_path}?mode=ro"
    conn = sqlite3.connect(URI, uri=True)
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()

    games = []

    try:
        cur.execute("SELECT id, name, slug, runner, prefix, IFNULL(icon, '') as icon FROM games")
        rows = cur.fetchall()
        for r in rows:
            games.append(
                {
                    "id": r["id"],
                    "name": r["name"],
                    "slug": r["slug"],
                    "runner": r["runner"],
                    "path": r.get("prefix") if "prefix" in r.keys() else None,
                    "icon": r["icon"],
                }
            )
        conn.close()
        if games:
            return games
    except sqlite3.Error:
        pass

    candidates = [
        ("installed_game", ["id", "name", "slug", "runner", "icon", "path"]),
        ("game", ["id", "name", "slug", "runner", "icon", "path"]),
        ("games", ["id", "name", "slug", "runner", "icon", "path"]),
    ]

    for tbl, cols in candidates:
        try:
            cur.execute(f"PRAGMA table_info({tbl})")
            info = cur.fetchall()
            if not info:
                continue
            col_names = [c[1] for c in info]

            select_cols = []
            for c in ["id", "name", "slug", "runner", "icon", "prefix", "path"]:
                if c in col_names:
                    select_cols.append(c)
            if not select_cols:
                continue
            cur.execute(f"SELECT {', '.join(select_cols)} FROM {tbl}")
            for r in cur.fetchall():
                row = dict(zip(select_cols, r))
                games.append(
                    {
                        "id": row.get("id"),
                        "name": row.get("name"),
                        "slug": row.get("slug"),
                        "runner": row.get("runner"),
                        "path": row.get("prefix") or row.get("path"),
                        "icon": row.get("icon") or "",
                    }
                )
            if games:
                conn.close()
                return games
        except sqlite3.Error:
            continue

    conn.close()
    return games


def guess_cover_path(game: Dict, db_path: Path) -> Optional[str]:
    slug = game.get("slug") or ""
    possible = [
        Path.home() / ".local/share/lutris/coverart" / f"{slug}.jpg",
        Path.home() / ".local/share/lutris/coverart" / f"{slug}.png",
        Path.home() / ".var/app/net.lutris.Lutris/data/lutris/coverart" / f"{slug}.jpg",
        Path.home() / ".var/app/net.lutris.Lutris/data/lutris/coverart" / f"{slug}.png",
        Path.home() / ".cache/lutris/coverart" / f"{slug}.jpg",
    ]
    for p in possible:
        if p.exists():
            return str(p)
    return None


def main(argv=None):
    p = argparse.ArgumentParser()
    p.add_argument("--detect", action="store_true", help="Print detected DB paths")
    p.add_argument("--json", action="store_true", help="Print JSON list of games (from best DB)")
    p.add_argument(
        "--rofi-string",
        action="store_true",
        help="Output rofi-formatted strings for games",
    )
    p.add_argument(
        "--get-exec",
        action="store_true",
        help="Output the command to launch the application",
    )
    p.add_argument("--db", type=str, help="Use specific DB path")
    args = p.parse_args(argv)

    dbs = find_dbs()

    if args.detect:
        out = [str(p) for p in dbs]
        print(json.dumps(out, indent=4))
        return 0

    use_db = None
    if args.db:
        use_db = Path(args.db)
        if not use_db.exists():
            print(json.dumps({"error": f"DB not found: {use_db}"}, indent=4))
            return 2
    else:
        if dbs:
            use_db = dbs[0]

    if not use_db:
        print(json.dumps({"error": "No Lutris DB found"}, indent=4))
        return 1

    if args.get_exec:
        print('xdg-open "lutris:rungame/{SLUG}"')
        return 0

    games = read_games_from_db(use_db)
    result = []
    for g in games:
        g2 = g.copy()
        cover = guess_cover_path(g, use_db)
        if cover:
            g2["cover"] = cover

        g2["run_command"] = f'xdg-open "lutris:rungame/{g2["slug"]}"'

        g2["rofi_string"] = (
            f"{g2['name']}\t{g2['run_command']}\t\x00icon\x1f{cover}"
            if cover
            else f"{g2['name']}\t{g2['run_command']}"
        )
        result.append(g2)

    if args.json:
        print(json.dumps(result, indent=4))
        return 0

    if args.rofi_string:
        for g in result:
            print(g["rofi_string"])
        return 0

    print("No valid arguments provided. Use --detect, --json, --rofi-string, --get-exec, or --db.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
