#!/usr/bin/env python3
"""Every notify_send(...) call in batterynotify.lua must pass its third
argument as an { urgency = ..., icon = ... } table.

notify_mod.send(summary, body, opts) reads opts.urgency/opts.icon -- passing
urgency as a bare string (and icon as an unused fourth positional argument,
which Lua silently drops) makes opts a string, and indexing a string with
.urgency/.icon in Lua returns nil rather than erroring, so both silently fell
back to their defaults ('normal', no icon) for every notification in this
file, regardless of what was actually passed.
"""

import re
import sys
from pathlib import Path


def _skip_lua_string(text, i):
    """i points at a ' or " that opens a Lua string; returns the index just
    past its matching close, honouring \\-escapes -- a stray ')' or '(' a
    battery-percentage message happens to contain (e.g. "Battery at 20%)")
    must not be mistaken for call syntax.
    """
    quote = text[i]
    i += 1
    while i < len(text):
        if text[i] == "\\":
            i += 2
            continue
        if text[i] == quote:
            return i + 1
        i += 1
    return i  # unterminated string -- stop where the text does


def extract_calls(text, name="notify_send"):
    """Every "name(...)" call in text, matched by tracking paren depth
    rather than a fixed-nesting-depth regex -- a regex like
    notify_send\\((?:[^()]|\\([^()]*\\))*\\) only handles exactly one level
    of nested parens; a call with two (e.g. a nested function call inside
    string.format's arguments) would fail to match at all and be silently
    dropped from the result, so a missing { urgency/icon } table on that
    call would never be checked -- not "no calls found" (which the caller
    below already fails loudly on), just fewer calls than actually exist.

    Parens and quote characters inside a Lua string literal or a `--` line
    comment are skipped rather than counted, so a message like "Battery at
    20%)" can't be mistaken for the call's own closing paren. Lua's
    `--[[ ]]` long-bracket comments are not handled -- batterynotify.lua
    doesn't use them and a notify_send call sitting inside one would be dead
    code anyway, so it's not worth the extra complexity here.
    """
    calls = []
    start = 0
    while True:
        idx = text.find(name + "(", start)
        if idx == -1:
            break
        depth = 0
        i = idx + len(name)
        end = None
        while i < len(text):
            ch = text[i]
            if ch in ("'", '"'):
                i = _skip_lua_string(text, i)
                continue
            if ch == "-" and text[i:i + 2] == "--":
                nl = text.find("\n", i)
                i = len(text) if nl == -1 else nl
                continue
            if ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
                if depth == 0:
                    end = i + 1
                    break
            i += 1
        if end is None:
            break  # unterminated call -- nothing sane left to scan
        calls.append(text[idx:end])
        start = end
    return calls


script = Path(sys.argv[1] if len(sys.argv) > 1 else
              "Configs/.local/lib/hyde/batterynotify.lua")
if not script.is_file():
    print(f"batterynotify.lua not found at {script}")
    sys.exit(1)

calls = extract_calls(script.read_text())

if not calls:
    print("no notify_send(...) calls found -- extract_calls() may be stale")
    sys.exit(1)

def split_args(text):
    """Split the *inner* text of a function call (everything between the outer
    parens) into top-level argument strings by comma, respecting nested
    parentheses, string literals, and Lua line comments.  A call like
    notify_send('A', 'B', { urgency = 'c', icon = 'i' }) yields three
    elements: the two string args and the table arg.
    """
    args = []
    depth = 0
    start = 0
    i = 0
    while i < len(text):
        ch = text[i]
        if ch in ("'", '"'):
            i = _skip_lua_string(text, i)
            continue
        if ch == "-" and text[i:i + 2] == "--":
            nl = text.find("\n", i)
            i = len(text) if nl == -1 else nl
            continue
        if ch in ("(", "{"):
            depth += 1
        elif ch in (")", "}"):
            depth -= 1
        elif ch == "," and depth == 0:
            args.append(text[start:i].strip())
            start = i + 1
        i += 1
    args.append(text[start:].strip())
    return args


def extract_call_args(call_text):
    """Given a full 'name(...)' call string, return the list of top-level
    argument strings.  Returns an empty list for malformed calls.
    """
    open_paren = call_text.find("(")
    close_paren = call_text.rfind(")")
    if open_paren == -1 or close_paren == -1 or close_paren <= open_paren:
        return []
    return split_args(call_text[open_paren + 1:close_paren])


failures = []
for call in calls:
    args = extract_call_args(call)
    if len(args) < 3:
        failures.append((call, ["options table (3rd arg)"]))
        continue
    opts_raw = args[2].strip()
    # A valid options table must start with '{' and contain 'urgency =' and
    # 'icon =' as keys -- bare string matches anywhere else are rejected.
    if not (opts_raw.startswith("{") and opts_raw.endswith("}")):
        failures.append((call, ["options table (3rd arg) must be { ... }" ]))
        continue
    opts_inner = opts_raw[1:-1]
    # Match 'urgency' / 'icon' followed by optional whitespace then '=' --
    # this catches both `urgency =` and `urgency=` forms while rejecting
    # bare occurrences inside string values.
    has_urgency = bool(re.search(r'\burgency\s*=', opts_inner))
    has_icon = bool(re.search(r'\bicon\s*=', opts_inner))
    if not (has_urgency and has_icon):
        missing = []
        if not has_urgency:
            missing.append("urgency")
        if not has_icon:
            missing.append("icon")
        failures.append((call, missing))

if failures:
    print(f"{len(failures)} of {len(calls)} notify_send(...) call(s) are missing "
          f"required options table key(s):")
    for call, missing in failures:
        print(f"  missing {', '.join(missing)}: " + " ".join(call.split()))
    sys.exit(1)

print(f"{len(calls)} notify_send(...) call(s) checked")
