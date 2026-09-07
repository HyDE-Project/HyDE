"""Checks lutris.py's slug validation, added alongside restoring gamelauncher.sh's
`eval exec "$cmd"` (#2018).

run_command is built as f'xdg-open "lutris:rungame/{slug}"' and later run
through eval by gamelauncher.sh -- a slug isn't validated by anything upstream
(it comes straight from Lutris's own SQLite database), so a slug containing a
stray '"' could break out of that quoted argument and inject arbitrary shell
code. This checks that only a plain lowercase-hyphenated slug (what Lutris
actually generates) makes it into run_command at all; anything else is
dropped rather than passed through.
"""

from __future__ import annotations

import json
import os
import pathlib
import sqlite3
import subprocess
import sys
import tempfile

REPO_ROOT = pathlib.Path(os.environ.get("REPO_ROOT", "."))
SCRIPT_PATH = REPO_ROOT / "Configs/.local/lib/hyde/gamelauncher/lutris.py"

failures = 0


def check(condition: bool, message: str) -> None:
    global failures
    if not condition:
        failures += 1
        print(f"    fail: {message}")


def make_db(path: pathlib.Path, games: list[tuple]) -> None:
    """games: list of (id, name, slug, runner, prefix, icon)."""
    conn = sqlite3.connect(str(path))
    conn.execute(
        "CREATE TABLE games (id INTEGER, name TEXT, slug TEXT, runner TEXT, "
        "prefix TEXT, icon TEXT)"
    )
    conn.executemany(
        "INSERT INTO games (id, name, slug, runner, prefix, icon) VALUES (?, ?, ?, ?, ?, ?)",
        games,
    )
    conn.commit()
    conn.close()


def run_lutris_json(db_path: pathlib.Path):
    result = subprocess.run(
        [sys.executable, str(SCRIPT_PATH), "--json", "--db", str(db_path)],
        capture_output=True,
        text=True,
    )
    return result


def main() -> int:
    if not SCRIPT_PATH.is_file():
        print(f"fail: lutris.py not found at {SCRIPT_PATH}")
        return 1

    with tempfile.TemporaryDirectory() as tmp:
        db_path = pathlib.Path(tmp) / "pga.db"

        # A legitimate Lutris slug, an injection attempt (embeds a double
        # quote to try to break out of run_command's quoting), a slug with a
        # shell metacharacter that doesn't even need the quote to be
        # dangerous under eval, an empty slug, and one with an unexpected
        # uppercase/space shape a real Lutris slug would never have.
        make_db(
            db_path,
            [
                (1, "Counter-Strike 2", "counter-strike-2", "steam", "", ""),
                (2, "Evil Game", 'x"; touch /tmp/pwned; echo "', "wine", "", ""),
                (3, "Semicolon Game", "foo;rm -rf ~", "wine", "", ""),
                (4, "Empty Slug Game", "", "wine", "", ""),
                (5, "Weird Case Game", "Some Slug", "wine", "", ""),
            ],
        )

        result = run_lutris_json(db_path)
        check(result.returncode == 0, f"lutris.py --json exited {result.returncode}: {result.stderr}")

        try:
            games = json.loads(result.stdout)
        except ValueError:
            games = []
            check(False, f"lutris.py --json did not print valid JSON: {result.stdout!r}")

        by_id = {g["id"]: g for g in games} if isinstance(games, list) else {}

        check(1 in by_id, "the legitimate slug (counter-strike-2) was dropped")
        if 1 in by_id:
            check(
                by_id[1]["run_command"] == 'xdg-open "lutris:rungame/counter-strike-2"',
                f"the legitimate game's run_command is wrong: {by_id[1].get('run_command')!r}",
            )

        for bad_id, why in [
            (2, "a slug containing an embedded double-quote was not filtered out"),
            (3, "a slug containing a shell metacharacter (;) was not filtered out"),
            (4, "an empty slug was not filtered out"),
            (5, "a slug with spaces/uppercase (not what Lutris generates) was not filtered out"),
        ]:
            check(bad_id not in by_id, why)

        check(result.stderr.strip() != "", "no warning was printed for any of the rejected slugs")

        # Boundary: a single-character slug and a slug that is only digits
        # are both syntactically valid per Lutris's own convention and must
        # not be rejected just for being short or numeric-looking. A fresh
        # DB file: make_db() creates the table, and re-running it against
        # the same path would just collide with the one already there.
        db_path = pathlib.Path(tmp) / "pga2.db"
        make_db(
            db_path,
            [
                (10, "One Char", "a", "wine", "", ""),
                (11, "Numeric Slug", "12345", "wine", "", ""),
            ],
        )
        result2 = run_lutris_json(db_path)
        try:
            games2 = {g["id"]: g for g in json.loads(result2.stdout)}
        except ValueError:
            games2 = {}
            check(False, f"second run did not print valid JSON: {result2.stdout!r}")

        check(10 in games2, "a single-character slug was rejected")
        check(11 in games2, "a purely numeric slug was rejected")

    if failures:
        print(f"    {failures} failure(s)")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
