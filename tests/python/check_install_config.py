"""The configs the installer writes at run time have to load their group.

`install.sh` builds a small TOML file for every dependency step and points deez
at it. The file carries nothing but the machine-specific packages and an
include of the group that holds the rest. deez reads that include from inside
`[global]` and ignores a root-level one without a word, so a misplaced key
leaves the step resolving an empty dependency set and reporting success.
"""

from __future__ import annotations

import os
import pathlib
import re
import sys
import tomllib

REPO_ROOT = pathlib.Path(os.environ.get("REPO_ROOT", "."))
INSTALLER = REPO_ROOT / "Scripts" / "install.sh"
GROUPS_DIR = REPO_ROOT / "Scripts" / "dots-groups"

HEREDOC = re.compile(
    r'cat > "\$\{(?P<name>\w+)\}" <<-TOML\n(?P<body>.*?)\n\t+TOML\n',
    re.DOTALL,
)


def undent(body: str) -> str:
    """`<<-` strips leading tabs, so the shell sees the body without them."""
    return "\n".join(line.lstrip("\t") for line in body.split("\n"))


def expand(body: str) -> str:
    """Resolve the one variable the generated configs interpolate."""
    return body.replace("${scrDir}", str((REPO_ROOT / "Scripts").resolve()))


def parse(body: str) -> dict:
    """The generated body leaves its package array open for the caller to fill."""
    try:
        return tomllib.loads(body)
    except tomllib.TOMLDecodeError:
        return tomllib.loads(body + "\n]\n")


def main() -> int:
    """Reports every generated config that would not load its group."""
    if not INSTALLER.is_file():
        print(f"    fail: {INSTALLER} is missing")
        return 1

    blocks = list(HEREDOC.finditer(INSTALLER.read_text()))
    if not blocks:
        print("    fail: install.sh writes no TOML configs, or their shape changed")
        return 1

    failures = 0

    def fail(message: str) -> None:
        """Counts a defect and prints it the way the runner reads it."""
        nonlocal failures
        failures += 1
        print(f"    fail: {message}")

    for block in blocks:
        name = block.group("name")
        body = expand(undent(block.group("body")))

        try:
            document = parse(body)
        except tomllib.TOMLDecodeError as error:
            fail(f"{name} is not valid TOML: {error}")
            continue

        if "include" in document:
            fail(f"{name} declares include at the document root, where deez does not read it")

        includes = document.get("global", {}).get("include")
        if not includes:
            fail(f"{name} declares no [global].include, so its group is never loaded")
            continue

        for included in includes:
            resolved = pathlib.Path(included).resolve()
            if not resolved.is_file():
                fail(f"{name} includes a missing group {included!r}")
            elif resolved.suffix != ".toml" or resolved.parent != GROUPS_DIR.resolve():
                fail(f"{name} includes {included!r}, which is not a dot group")

    print(f"    {len(blocks)} generated config(s) checked")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
