#!/usr/bin/env python3
from __future__ import annotations

import ast
import shutil
import subprocess
import sys
from pathlib import Path

DOMAIN = "hyde"
ROOT = Path(__file__).resolve().parents[2]
SOURCE_DIR = Path(__file__).resolve().parent
POT_FILE = SOURCE_DIR / f"{DOMAIN}.pot"
PO_FILES = [SOURCE_DIR / "zh_CN" / "LC_MESSAGES" / f"{DOMAIN}.po"]
PYTHON_SOURCES = [ROOT / "Configs/.local/lib/hyde/notifications.py"]
SHELL_SOURCES = [ROOT / "Configs/.local/lib/hyde/keybinds_hint.sh"]
RUNTIME_LOCALE_DIR = ROOT / "Configs/.local/share/hyde/locale"


def run_if_available(tool: str, args: list[str]) -> bool:
    executable = shutil.which(tool)
    if executable is None:
        print(f"skip: {tool} not found", file=sys.stderr)
        return False

    subprocess.run([executable, *args], check=True)
    return True


def normalize_gettext_header(path: Path) -> None:
    if not path.exists():
        return

    lines = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if line == "# This file is distributed under the same license as the PACKAGE package.":
            lines.append("# This file is distributed under the same license as the HyDE package.")
        elif line.startswith('"Project-Id-Version: '):
            lines.append('"Project-Id-Version: HyDE\\n"')
        elif line.startswith('"Report-Msgid-Bugs-To: '):
            lines.append('"Report-Msgid-Bugs-To: https://github.com/HyDE-Project/HyDE/issues\\n"')
        elif line.startswith('"POT-Creation-Date: '):
            lines.append('"POT-Creation-Date: YEAR-MO-DA HO:MI+ZONE\\n"')
        elif line == '"Content-Type: text/plain; charset=CHARSET\\n"':
            lines.append('"Content-Type: text/plain; charset=UTF-8\\n"')
        else:
            lines.append(line)

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def update_pot() -> None:
    if shutil.which("xgettext") is None:
        print("skip: xgettext not found", file=sys.stderr)
        return

    tmp_pot = POT_FILE.with_suffix(".pot.tmp")
    if tmp_pot.exists():
        tmp_pot.unlink()

    subprocess.run(
        [
            "xgettext",
            "--from-code=UTF-8",
            "--language=Python",
            "--package-name=HyDE",
            "--msgid-bugs-address=https://github.com/HyDE-Project/HyDE/issues",
            "--keyword=t:1",
            "--output",
            str(tmp_pot),
            *[str(path.relative_to(ROOT)) for path in PYTHON_SOURCES],
        ],
        check=True,
        cwd=ROOT,
    )
    normalize_gettext_header(tmp_pot)

    shell_args = [
        "xgettext",
        "--from-code=UTF-8",
        "--language=Shell",
        "--keyword=hyde_gettext:1",
        "--output",
        str(tmp_pot),
        *[str(path.relative_to(ROOT)) for path in SHELL_SOURCES],
    ]
    if tmp_pot.exists():
        shell_args.insert(4, "--join-existing")
    subprocess.run(shell_args, check=True, cwd=ROOT)

    tmp_pot.replace(POT_FILE)
    normalize_gettext_header(POT_FILE)


def merge_po_files() -> None:
    if not POT_FILE.exists():
        return

    for po_file in PO_FILES:
        if not po_file.exists():
            continue
        if run_if_available(
            "msgmerge",
            ["--update", "--backup=none", str(po_file), str(POT_FILE)],
        ):
            normalize_gettext_header(po_file)


def compile_mo_files() -> None:
    for po_file in PO_FILES:
        if not po_file.exists():
            continue

        locale = po_file.parents[1].name
        mo_file = RUNTIME_LOCALE_DIR / locale / "LC_MESSAGES" / f"{DOMAIN}.mo"
        mo_file.parent.mkdir(parents=True, exist_ok=True)
        run_if_available("msgfmt", ["--check", "--output-file", str(mo_file), str(po_file)])


def decode_po_string(value: str) -> str:
    return ast.literal_eval(value)


def parse_po(po_file: Path) -> dict[str, str]:
    entries: dict[str, str] = {}
    msgid: str | None = None
    msgstr: str | None = None
    section: str | None = None
    fuzzy = False

    def flush() -> None:
        nonlocal msgid, msgstr, section, fuzzy
        if msgid and msgstr and not fuzzy:
            entries[msgid] = msgstr
        msgid = None
        msgstr = None
        section = None
        fuzzy = False

    for raw_line in po_file.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line:
            flush()
            continue
        if line.startswith("#,") and "fuzzy" in line:
            fuzzy = True
            continue
        if line.startswith("#"):
            continue
        if line.startswith("msgid "):
            flush()
            msgid = decode_po_string(line[6:].strip())
            msgstr = ""
            section = "msgid"
            continue
        if line.startswith("msgstr "):
            msgstr = decode_po_string(line[7:].strip())
            section = "msgstr"
            continue
        if line.startswith('"'):
            if section == "msgid" and msgid is not None:
                msgid += decode_po_string(line)
            elif section == "msgstr" and msgstr is not None:
                msgstr += decode_po_string(line)

    flush()
    return entries


def bash_ansi_c_quote(value: str) -> str:
    escaped = (
        value.replace("\\", "\\\\")
        .replace("'", "\\'")
        .replace("\n", "\\n")
        .replace("\r", "\\r")
        .replace("\t", "\\t")
    )
    return f"$'{escaped}'"


def write_shell_map(po_file: Path) -> None:
    if not po_file.exists():
        return

    locale = po_file.parents[1].name
    map_file = RUNTIME_LOCALE_DIR / f"{locale}.sh"
    map_file.parent.mkdir(parents=True, exist_ok=True)
    entries = parse_po(po_file)

    lines = [
        "#!/usr/bin/env bash",
        "# Generated by Source/locale/build.py; do not edit manually.",
        "# shellcheck shell=bash disable=SC2034",
        "declare -gA _T 2>/dev/null || declare -A _T 2>/dev/null || :",
    ]
    for msgid, msgstr in sorted(entries.items()):
        lines.append(f"_T[{bash_ansi_c_quote(msgid)}]={bash_ansi_c_quote(msgstr)}")

    map_file.write_text("\n".join(lines) + "\n", encoding="utf-8")


def generate_shell_maps() -> None:
    for po_file in PO_FILES:
        write_shell_map(po_file)


def main() -> None:
    update_pot()
    merge_po_files()
    compile_mo_files()
    generate_shell_maps()


if __name__ == "__main__":
    main()
