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

import sys
from pathlib import Path


def extract_calls(text, name="notify_send"):
    """Every "name(...)" call in text, matched by tracking paren depth
    rather than a fixed-nesting-depth regex -- a regex like
    notify_send\\((?:[^()]|\\([^()]*\\))*\\) only handles exactly one level
    of nested parens; a call with two (e.g. a nested function call inside
    string.format's arguments) would fail to match at all and be silently
    dropped from the result, so a missing { urgency/icon } table on that
    call would never be checked -- not "no calls found" (which the caller
    below already fails loudly on), just fewer calls than actually exist.
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
            if text[i] == "(":
                depth += 1
            elif text[i] == ")":
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

failures = []
for call in calls:
    has_urgency = "urgency" in call
    has_icon = "icon" in call
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
