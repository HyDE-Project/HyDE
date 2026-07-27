#!/usr/bin/env python3
#@name: completions
#@desc: provide completion interface
#todo translate them to the above format

"""
HyDE Shell Completions Engine — universal metadata parser.

Parses new-style (@name:, @cmd:, @cmd.alias:) metadata from all discoverable
scripts to generate shell completions, help, documentation, and manpages.

Usage:
  completions.py --list-builtins              List built-in command names
    completions.py --list-builtins-desc         Built-ins as name<TAB>description
  completions.py --list-script                List public script names (no ext)
    completions.py --list-script-desc           Scripts as name<TAB>description
  completions.py --list-script-path           List public script full paths
  completions.py --list-all                   Builtins + scripts (tab-completion)
    completions.py --list-all-desc              Builtins + scripts with descriptions
  completions.py --list-commands [script]     Subcommands for a script
    completions.py --list-commands-desc [script]  Subcommands as name<TAB>description
  completions.py --list-aliases  [script]     Alias map for a script
  completions.py --list-options  [script] [cmd]  Options for a subcommand
    completions.py --list-options-desc [script] [cmd]  Options as name<TAB>description
  completions.py --list-flags    [script] [cmd]  Flags for a subcommand
    completions.py --list-flags-desc [script] [cmd]  Flags as name<TAB>description
  completions.py bash|zsh|fish                Output completion template
  completions.py --json                       Full metadata dump
"""
import sys, re, os, json
from pathlib import Path
from collections import OrderedDict

HERE = Path(__file__).resolve().parent
COMPLETIONS_DIR = HERE / "completions"

# ──────────────────────────────────────────────────────────────
# Built-in command list (parsed from hyde-shell annotations)
# ──────────────────────────────────────────────────────────────
HYDE_SHELL_PATH = (HERE.parent.parent / "bin" / "hyde-shell").resolve()
if not HYDE_SHELL_PATH.is_file():
    HYDE_SHELL_PATH = Path("/usr/local/bin/hyde-shell")

BUILT_IN_COMMANDS = []  # populated lazily
BUILT_IN_DESCRIPTIONS = {}


def _ensure_builtins():
    """Parse @cmd annotations from hyde-shell and populate BUILT_IN_COMMANDS."""
    if BUILT_IN_COMMANDS:
        return
    meta = parse_new_style(str(HYDE_SHELL_PATH))
    cmds = {}
    for cmd_name, info in meta.get("commands", {}).items():
        desc = info.get("desc", "").strip()
        cmds[cmd_name] = desc or "HyDE command"
        for alias in info.get("aliases", []):
            cmds[alias] = f"Alias for {cmd_name}"
    # Also include known short flags
    for gf in meta.get("global_flags", []):
        for flag in gf["flag"].split(","):
            flag = flag.strip()
            if flag:
                cmds[flag] = gf.get("desc", "").strip() or "Global flag"
    BUILT_IN_COMMANDS[:] = sorted(cmds.keys(), key=_sort_key)
    BUILT_IN_DESCRIPTIONS.clear()
    BUILT_IN_DESCRIPTIONS.update(cmds)


def _sort_key(s):
    """Sort flags after alphanumerics, short flags after long flags."""
    if s.startswith("--"):
        return (2, s)
    if s.startswith("-"):
        return (3, s)
    return (1, s)


# ──────────────────────────────────────────────────────────────
# New-style metadata format constants
# ──────────────────────────────────────────────────────────────
# New format:  # @name: app
#              # @cmd: reload
#              # @cmd.alias: r,reload
#              # @cmd.desc: Reload configuration
#              # @cmd.opt: all | Reload all
#              # @cmd.flag: --force,-f | Force reload

COMMENT_PREFIX = r'\s*(?:#|--)\s*'
NEW_NAME_RE = re.compile(rf'^{COMMENT_PREFIX}@name:\s*(.+)')
NEW_VER_RE = re.compile(rf'^{COMMENT_PREFIX}@ver:\s*(.+)')
NEW_SHORT_RE = re.compile(rf'^{COMMENT_PREFIX}@short:\s*(.+)')
NEW_USAGE_RE = re.compile(rf'^{COMMENT_PREFIX}@usage:\s*(.+)')
NEW_GLOBAL_FLAG_RE = re.compile(rf'^{COMMENT_PREFIX}@global\.flag:\s*([^|]+)\s*(?:\|\s*(.*))?')
NEW_CMD_RE = re.compile(rf'^{COMMENT_PREFIX}@cmd:\s*(\S+)')
NEW_CMD_ALIAS_RE = re.compile(rf'^{COMMENT_PREFIX}@cmd\.alias:\s*(.+)')
NEW_CMD_DESC_RE = re.compile(rf'^{COMMENT_PREFIX}@cmd\.desc:\s*(.+)')
NEW_CMD_OPT_RE = re.compile(rf'^{COMMENT_PREFIX}@cmd\.opt:\s*(\S+)\s*(?:\|\s*(.*))?')
NEW_CMD_FLAG_RE = re.compile(rf'^{COMMENT_PREFIX}@cmd\.flag:\s*([^|]+)\s*(?:\|\s*(.*))?')


# ──────────────────────────────────────────────────────────────
# Parsing
# ──────────────────────────────────────────────────────────────
def parse_new_style(file_path: str) -> dict:
    """Parse new-style metadata (@name:, @cmd:, etc)."""
    meta = {"name": "", "version": "", "short": "", "usage": "",
            "global_flags": [], "commands": OrderedDict()}
    current_cmd = None
    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            for line in f:
                m = NEW_NAME_RE.match(line)
                if m:
                    meta["name"] = m.group(1).strip()
                    continue
                m = NEW_VER_RE.match(line)
                if m:
                    meta["version"] = m.group(1).strip()
                    continue
                m = NEW_SHORT_RE.match(line)
                if m:
                    meta["short"] = m.group(1).strip()
                    continue
                m = NEW_USAGE_RE.match(line)
                if m:
                    meta["usage"] = m.group(1).strip()
                    continue
                m = NEW_GLOBAL_FLAG_RE.match(line)
                if m:
                    flags_str = m.group(1).strip()
                    desc = (m.group(2) or "").strip()
                    for f in flags_str.split(","):
                        f = f.strip()
                        if f:
                            meta["global_flags"].append({"flag": f, "desc": desc})
                    continue
                m = NEW_CMD_RE.match(line)
                if m:
                    current_cmd = m.group(1).strip()
                    meta["commands"][current_cmd] = {
                        "aliases": [], "desc": "", "options": [], "flags": []
                    }
                    continue
                if current_cmd:
                    m = NEW_CMD_ALIAS_RE.match(line)
                    if m:
                        aliases = [a.strip() for a in m.group(1).split(",") if a.strip()]
                        meta["commands"][current_cmd]["aliases"] = aliases
                        continue
                    m = NEW_CMD_DESC_RE.match(line)
                    if m:
                        meta["commands"][current_cmd]["desc"] = m.group(1).strip()
                        continue
                    m = NEW_CMD_OPT_RE.match(line)
                    if m:
                        opt_name = m.group(1).strip()
                        opt_desc = (m.group(2) or "").strip()
                        meta["commands"][current_cmd]["options"].append({"opt": opt_name, "desc": opt_desc})
                        continue
                    m = NEW_CMD_FLAG_RE.match(line)
                    if m:
                        flags_str = m.group(1).strip()
                        flag_desc = (m.group(2) or "").strip()
                        for fl in flags_str.split(","):
                            fl = fl.strip()
                            if fl:
                                meta["commands"][current_cmd]["flags"].append({"flag": fl, "desc": flag_desc})
                        continue
    except (OSError, IOError):
        pass
    return meta


def script_has_public_metadata(file_path: str) -> bool:
    """Check if a script has a @name: annotation (first 50 lines)."""
    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            for _ in range(50):
                line = f.readline()
                if not line:
                    break
                if NEW_NAME_RE.match(line):
                    return True
    except (OSError, IOError):
        pass
    return False


# ──────────────────────────────────────────────────────────────
# Script scanning
# ──────────────────────────────────────────────────────────────
def get_script_paths() -> list:
    """Return list of full paths to discoverable scripts.

    Checks HYDE_SCRIPTS_PATH env var first, then falls back to
    scanning the hyde lib directory for scripts with metadata.
    """
    # Mirror hyde-shell defaults when HYDE_SCRIPTS_PATH is missing so
    # completions still include user/config scripts in non-initialized shells.
    xdg_config_home = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
    xdg_data_home = os.environ.get("XDG_DATA_HOME", os.path.expanduser("~/.local/share"))
    default_paths = [
        os.path.join(xdg_config_home, "hyde", "scripts"),
        str(HERE),
        os.path.join(xdg_data_home, "waybar", "scripts"),
        os.path.join(xdg_config_home, "waybar", "scripts"),
    ]
    env_paths = os.environ.get("HYDE_SCRIPTS_PATH", "")
    search_paths = [p for p in env_paths.split(":") if p.strip()] if env_paths else default_paths[:]
    seen = set()
    paths = []

    # Always include the hyde lib dir as a fallback path.
    if str(HERE) not in search_paths:
        search_paths.append(str(HERE))

    for raw_dir in search_paths:
        raw_dir = raw_dir.strip()
        if not raw_dir or raw_dir in seen or not os.path.isdir(raw_dir):
            continue
        seen.add(raw_dir)
        try:
            for entry in sorted(Path(raw_dir).iterdir()):
                if entry.suffix in ('.sh', '.py', '.lua') and entry.is_file():
                    paths.append(str(entry.resolve()))
        except PermissionError:
            pass

    return paths


def get_public_scripts() -> list:
    """Return sorted list of basenames with metadata (with extension)."""
    names = set()
    for path in get_script_paths():
        if script_has_public_metadata(path):
            names.add(os.path.basename(path))
    return sorted(names)


def get_public_script_paths() -> list:
    """Return sorted full paths for public scripts."""
    return sorted(p for p in get_script_paths() if script_has_public_metadata(p))


def get_public_script_names_stripped() -> list:
    """Return script names with extensions stripped."""
    names = []
    for name in get_public_scripts():
        stem, ext = os.path.splitext(name)
        if ext in ('.sh', '.py', '.lua'):
            names.append(stem)
        else:
            names.append(name)
    return sorted(names)


def _sanitize_desc(desc: str) -> str:
    return " ".join((desc or "").replace("\t", " ").split())


def _print_desc_items(items: list) -> None:
    for name, desc in items:
        print(f"{name}\t{_sanitize_desc(desc)}")


def get_public_script_entries() -> list:
    """Return [(script_name_without_ext, description)] for public scripts."""
    entries = {}
    for path in get_public_script_paths():
        meta = parse_new_style(path)
        stem = Path(path).stem
        desc = meta.get("short", "").strip() or meta.get("name", "").strip() or "Script"
        entries.setdefault(stem, desc)
    return sorted(entries.items(), key=lambda kv: _sort_key(kv[0]))


def get_all_entries() -> list:
    """Return [(name, desc)] for builtins + scripts."""
    _ensure_builtins()
    entries = OrderedDict()
    for name in BUILT_IN_COMMANDS:
        entries[name] = BUILT_IN_DESCRIPTIONS.get(name, "HyDE command")
    for name, desc in get_public_script_entries():
        entries.setdefault(name, desc)
    return list(entries.items())


def scan_all() -> dict:
    """Return {filename: {metadata}} for every script with metadata."""
    index = {}
    for path in get_script_paths():
        meta = parse_new_style(path)
        if meta and meta.get("name"):
            index[os.path.basename(path)] = meta
    return index


# ──────────────────────────────────────────────────────────────
# Subcommand / option / flag helpers
# ──────────────────────────────────────────────────────────────
def _find_script_meta(script_name: str) -> dict:
    """Find metadata for a script by basename (with or without extension)."""
    for path in get_script_paths():
        base = os.path.basename(path)
        stem, ext = os.path.splitext(base)
        if base == script_name or stem == script_name:
            meta = parse_new_style(path)
            if meta and meta.get("name"):
                return meta
    return {}


def get_commands_for_script(script_name: str) -> list:
    """Return list of subcommand names for a given script (inc. aliases)."""
    meta = _find_script_meta(script_name) if script_name else {}
    if not meta:
        return []
    cmds = set()
    for cmd, info in meta.get("commands", {}).items():
        cmds.add(cmd)
        for alias in info.get("aliases", []):
            cmds.add(alias)
    return sorted(cmds, key=_sort_key)


def get_commands_for_script_desc(script_name: str) -> list:
    """Return [(subcommand_or_alias, description)] for a script."""
    meta = _find_script_meta(script_name) if script_name else {}
    if not meta:
        return []
    entries = {}
    for cmd, info in meta.get("commands", {}).items():
        desc = info.get("desc", "").strip() or "Subcommand"
        entries[cmd] = desc
        for alias in info.get("aliases", []):
            entries[alias] = f"Alias for {cmd}"
    return sorted(entries.items(), key=lambda kv: _sort_key(kv[0]))


def get_aliases_for_script(script_name: str) -> list:
    """Return list of 'alias:cmd' pairs for a script."""
    meta = _find_script_meta(script_name)
    if not meta:
        return []
    result = []
    for cmd, info in meta.get("commands", {}).items():
        for alias in info.get("aliases", []):
            result.append(f"{alias}:{cmd}")
    return result


def get_options_for_script(script_name: str, cmd: str) -> list:
    """Return list of option names for a given subcommand."""
    meta = _find_script_meta(script_name)
    if not meta:
        return []
    for cname, info in meta.get("commands", {}).items():
        if cname == cmd or cmd in info.get("aliases", []):
            return [o["opt"] for o in info.get("options", [])]
    return []


def get_options_for_script_desc(script_name: str, cmd: str) -> list:
    """Return [(option, description)] for a subcommand."""
    meta = _find_script_meta(script_name)
    if not meta:
        return []
    for cname, info in meta.get("commands", {}).items():
        if cname == cmd or cmd in info.get("aliases", []):
            return [(o["opt"], o.get("desc", "").strip() or "Option") for o in info.get("options", [])]
    return []


def get_flags_for_script(script_name: str, cmd: str) -> list:
    """Return list of flag names for a given subcommand."""
    meta = _find_script_meta(script_name)
    if not meta:
        return []
    for cname, info in meta.get("commands", {}).items():
        if cname == cmd or cmd in info.get("aliases", []):
            return [f["flag"] for f in info.get("flags", [])]
    return []


def get_flags_for_script_desc(script_name: str, cmd: str) -> list:
    """Return [(flag, description)] for a subcommand."""
    meta = _find_script_meta(script_name)
    if not meta:
        return []
    for cname, info in meta.get("commands", {}).items():
        if cname == cmd or cmd in info.get("aliases", []):
            return [(f["flag"], f.get("desc", "").strip() or "Flag") for f in info.get("flags", [])]
    return []


def get_global_flags_for_script(script_name: str) -> list:
    """Return list of global flags for a given script."""
    meta = _find_script_meta(script_name)
    if not meta:
        return []
    flags = []
    for gf in meta.get("global_flags", []):
        for f in gf["flag"].split(","):
            f = f.strip()
            if f:
                flags.append(f)
    return flags


# ──────────────────────────────────────────────────────────────
# Output a shell completion template
# ──────────────────────────────────────────────────────────────
def output_completion_file(shell: str):
    """Cat the completion template for the given shell."""
    template = COMPLETIONS_DIR / f"hyde-shell.{shell}"
    if template.is_file():
        sys.stdout.write(template.read_text(encoding='utf-8'))
    else:
        print(f"Completion template not found: {template}", file=sys.stderr)
        sys.exit(1)


# ──────────────────────────────────────────────────────────────
# CLI dispatch
# ──────────────────────────────────────────────────────────────
def main():
    if len(sys.argv) < 2:
        print(__doc__.strip())
        sys.exit(0)

    cmd = sys.argv[1]

    # ── Lazy load builtins the first time they are needed ──
    if cmd in ("--list-builtins", "--list-builtins-desc", "--list-all", "--list-all-desc"):
        _ensure_builtins()

    if cmd == "--list-builtins":
        print("\n".join(BUILT_IN_COMMANDS))

    elif cmd == "--list-builtins-desc":
        _print_desc_items([(name, BUILT_IN_DESCRIPTIONS.get(name, "HyDE command")) for name in BUILT_IN_COMMANDS])

    elif cmd == "--list-script":
        for name in get_public_script_names_stripped():
            print(name)

    elif cmd == "--list-script-desc":
        _print_desc_items(get_public_script_entries())

    elif cmd == "--list-script-path":
        for path in get_public_script_paths():
            print(path)

    elif cmd == "--list-all":
        for c in BUILT_IN_COMMANDS:
            print(c)
        for name in get_public_script_names_stripped():
            print(name)

    elif cmd == "--list-all-desc":
        _print_desc_items(get_all_entries())

    elif cmd == "--list-commands":
        script_name = sys.argv[2] if len(sys.argv) > 2 else ""
        if script_name:
            for c in get_commands_for_script(script_name):
                print(c)
        else:
            for path in get_public_script_paths():
                fname = os.path.basename(path)
                for c in get_commands_for_script(fname):
                    print(c)

    elif cmd == "--list-commands-desc":
        script_name = sys.argv[2] if len(sys.argv) > 2 else ""
        if script_name:
            _print_desc_items(get_commands_for_script_desc(script_name))

    elif cmd == "--list-aliases":
        script_name = sys.argv[2] if len(sys.argv) > 2 else ""
        if script_name:
            for a in get_aliases_for_script(script_name):
                print(a)

    elif cmd == "--list-options":
        script_name = sys.argv[2] if len(sys.argv) > 2 else ""
        subcmd = sys.argv[3] if len(sys.argv) > 3 else ""
        if script_name and subcmd:
            for o in get_options_for_script(script_name, subcmd):
                print(o)

    elif cmd == "--list-options-desc":
        script_name = sys.argv[2] if len(sys.argv) > 2 else ""
        subcmd = sys.argv[3] if len(sys.argv) > 3 else ""
        if script_name and subcmd:
            _print_desc_items(get_options_for_script_desc(script_name, subcmd))

    elif cmd == "--list-flags":
        script_name = sys.argv[2] if len(sys.argv) > 2 else ""
        subcmd = sys.argv[3] if len(sys.argv) > 3 else ""
        if script_name and subcmd:
            for f in get_flags_for_script(script_name, subcmd):
                print(f)

    elif cmd == "--list-flags-desc":
        script_name = sys.argv[2] if len(sys.argv) > 2 else ""
        subcmd = sys.argv[3] if len(sys.argv) > 3 else ""
        if script_name and subcmd:
            _print_desc_items(get_flags_for_script_desc(script_name, subcmd))

    elif cmd == "--list-global-flags":
        script_name = sys.argv[2] if len(sys.argv) > 2 else ""
        if script_name:
            for f in get_global_flags_for_script(script_name):
                print(f)

    elif cmd in ("bash", "zsh", "fish"):
        output_completion_file(cmd)

    elif cmd == "--json":
        _ensure_builtins()
        data = scan_all()
        data["_hyde_shell"] = {
            "commands": {c: {"aliases": [], "desc": "", "options": [], "flags": []}
                         for c in BUILT_IN_COMMANDS}
        }
        print(json.dumps(data, indent=2))

    elif cmd in ("--help", "-h", "help"):
        print(__doc__.strip())

    else:
        print(f"Unknown option: {cmd}", file=sys.stderr)
        print(__doc__.strip())
        sys.exit(1)


if __name__ == "__main__":
    main()
