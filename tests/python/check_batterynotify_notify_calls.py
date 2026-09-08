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

script = Path(sys.argv[1] if len(sys.argv) > 1 else
              "Configs/.local/lib/hyde/batterynotify.lua")
if not script.is_file():
    print(f"batterynotify.lua not found at {script}")
    sys.exit(1)

text = script.read_text()

# Matches notify_send(...) allowing one level of nested parens, which is
# enough for the string.format(...) calls used as the body argument here --
# a genuinely unbalanced call (parens nested deeper) would fail to match at
# all, which the "no calls found" check below turns into a loud failure
# rather than a silent false pass.
call_re = re.compile(r"notify_send\((?:[^()]|\([^()]*\))*\)", re.DOTALL)
calls = call_re.findall(text)

if not calls:
    print("no notify_send(...) calls found -- the extraction pattern above may be stale")
    sys.exit(1)

failures = []
for call in calls:
    if "{ urgency" not in call and "{urgency" not in call:
        failures.append(call)

if failures:
    print(f"{len(failures)} of {len(calls)} notify_send(...) call(s) do not pass "
          "an { urgency = ... } options table:")
    for call in failures:
        print("  " + " ".join(call.split()))
    sys.exit(1)

print(f"{len(calls)} notify_send(...) call(s) checked")
