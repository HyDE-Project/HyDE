"""Checks the __lua bind resolution hint-hyprland.py adds for #1996.

hyde/binds.lua pairs each bind's canonical combo with the command it was
built from and writes that as JSON to a cache file (tested independently in
tests/lua/bind_commands_spec.lua). This checks the other side: that
hint-hyprland.py reads that cache the same way, degrades to an empty map on
anything but a well-formed file, computes the exact same canonical combo
Lua's hyde/binds.lua.canonicalize() does from modmask/key, and only rewrites
a bind's dispatcher when both agree on the key.
"""

from __future__ import annotations

import importlib.util
import json
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile

REPO_ROOT = pathlib.Path(os.environ.get("REPO_ROOT", "."))
SCRIPT_PATH = REPO_ROOT / "Configs/.local/lib/hyde/keybinds/hint-hyprland.py"

failures = 0


def check(condition: bool, message: str) -> None:
    global failures
    if not condition:
        failures += 1
        print(f"    fail: {message}")


def load_module():
    spec = importlib.util.spec_from_file_location("hint_hyprland", SCRIPT_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main() -> int:
    if not SCRIPT_PATH.is_file():
        print(f"fail: hint-hyprland.py not found at {SCRIPT_PATH}")
        return 1

    hh = load_module()

    # --- canonical_combo: mirrors hyde/binds.lua's canonicalize() ---

    check(
        hh.canonical_combo(64, "T") == "SUPER + T",
        "a single-modifier combo did not canonicalize",
    )
    check(
        hh.canonical_combo(64 + 4, "B") == "CTRL + SUPER + B",
        "two modifiers were not sorted alphabetically (CTRL before SUPER)",
    )
    check(
        hh.canonical_combo(4 + 64, "B") == "CTRL + SUPER + B",
        "modifier bit order changed the result -- must be order-independent",
    )
    check(
        hh.canonical_combo(0, "F10") == "F10",
        "a no-modifier bind (modmask 0) did not canonicalize to the bare key",
    )
    check(
        hh.canonical_combo(64, "slash") == "SUPER + SLASH",
        "a lowercase keysym was not upper-cased",
    )

    # Missing/absent and malformed input.
    check(hh.canonical_combo(64, "") is None, "an empty key string was not rejected")
    check(hh.canonical_combo(64, None) is None, "a None key was not rejected")
    check(hh.canonical_combo(None, "T") is None, "a None modmask was not rejected")
    check(hh.canonical_combo("64", "T") is None, "a string modmask (wrong type) was not rejected")
    check(hh.canonical_combo(64, 5) is None, "a non-string key (wrong type) was not rejected")

    # --- load_bind_commands: degrades to {} on anything but a well-formed file ---

    with tempfile.TemporaryDirectory() as tmp:
        env_backup = os.environ.get("XDG_CACHE_HOME")
        os.environ["XDG_CACHE_HOME"] = tmp

        try:
            # Missing/absent: no file at all.
            check(hh.load_bind_commands() == {}, "a missing cache file did not degrade to {}")

            cache_dir = pathlib.Path(tmp) / "hyde"
            cache_dir.mkdir(parents=True)
            cache_file = cache_dir / "lua_bind_commands.json"

            # Malformed/out-of-spec: not valid JSON at all.
            cache_file.write_text("{not json")
            check(hh.load_bind_commands() == {}, "malformed JSON did not degrade to {}")

            # Malformed/out-of-spec: valid JSON, wrong shape (a list, not an object).
            cache_file.write_text(json.dumps(["SUPER + T", "kitty"]))
            check(hh.load_bind_commands() == {}, "a JSON list (wrong shape) did not degrade to {}")

            # Malformed/out-of-spec: an object, but with a non-string value --
            # that one pair must be dropped, not raise or poison the rest.
            cache_file.write_text(json.dumps({"SUPER + T": "kitty", "SUPER + E": 5}))
            check(
                hh.load_bind_commands() == {"SUPER + T": "kitty"},
                "a non-string value was not filtered out of an otherwise-valid cache",
            )

            # Boundary: an empty object is valid and just means nothing resolves.
            cache_file.write_text("{}")
            check(hh.load_bind_commands() == {}, "an empty JSON object was not read as {}")

            # The well-formed case.
            cache_file.write_text(json.dumps({"SUPER + T": "kitty", "SUPER + E": "dolphin"}))
            check(
                hh.load_bind_commands() == {"SUPER + T": "kitty", "SUPER + E": "dolphin"},
                "a well-formed cache was not read back exactly",
            )
        finally:
            if env_backup is None:
                os.environ.pop("XDG_CACHE_HOME", None)
            else:
                os.environ["XDG_CACHE_HOME"] = env_backup

    # --- expand_meta_data: only __lua binds are touched, only when resolvable ---

    def make_bind(dispatcher, arg, modmask, key, keycode=0, description="test"):
        return {
            "dispatcher": dispatcher,
            "arg": arg,
            "modmask": modmask,
            "key": key,
            "keycode": keycode,
            "has_description": True,
            "description": description,
            "submap": "",
        }

    binds = [
        make_bind("__lua", "5", 64, "T"),  # resolvable
        make_bind("__lua", "9", 64, "Q"),  # not in the map -- must stay unresolved
        make_bind("exec", "firefox", 64, "B"),  # not __lua at all -- must be untouched
        make_bind("__lua", "3", 0, "F10"),  # no-modifier, resolvable
    ]
    bind_commands = {"SUPER + T": "kitty", "F10": 'notify-send "hi" \\ok'}

    hh.expand_meta_data(binds, bind_commands)

    resolved, unresolved_map, untouched, resolved_no_mod = binds

    check(
        resolved["dispatcher"] == 'hl.dsp.exec_cmd("kitty")',
        f"a resolvable __lua bind was not rewritten: got {resolved['dispatcher']!r}",
    )
    check(resolved["arg"] == "", "a resolved bind's arg was not cleared")

    check(
        unresolved_map["dispatcher"] == "__lua",
        "a __lua bind with no matching cache entry was rewritten anyway",
    )
    check(unresolved_map["arg"] == "9", "an unresolved bind's arg was changed")

    check(untouched["dispatcher"] == "exec", "a non-__lua bind's dispatcher was touched")
    check(untouched["arg"] == "firefox", "a non-__lua bind's arg was touched")

    check(
        resolved_no_mod["dispatcher"] == 'hl.dsp.exec_cmd("notify-send \\"hi\\" \\\\ok")',
        f"quotes/backslashes in the command were not escaped correctly: {resolved_no_mod['dispatcher']!r}",
    )

    # The rewritten dispatcher has to be syntactically valid Lua, and single
    # line (keybinds_hint.sh rejects a multi-line dispatch field outright) --
    # checked out-of-process against the real interpreter when available,
    # since that is what actually has to accept it.
    if shutil.which("lua"):
        expr = resolved_no_mod["dispatcher"]
        check("\n" not in expr, "the rewritten dispatcher spans more than one line")
        result = subprocess.run(
            ["lua", "-e", f"local hl = {{ dsp = {{ exec_cmd = function() end }} }}\nreturn {expr}"],
            capture_output=True,
            text=True,
        )
        check(
            result.returncode == 0,
            f"the rewritten dispatcher is not valid Lua: {result.stderr.strip()}",
        )

    # Default bind_commands (None) must behave like an empty map, not raise.
    default_binds = [make_bind("__lua", "5", 64, "T")]
    hh.expand_meta_data(default_binds)
    check(
        default_binds[0]["dispatcher"] == "__lua",
        "expand_meta_data with no bind_commands argument raised or resolved anyway",
    )

    if failures:
        print(f"    {failures} failure(s)")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
