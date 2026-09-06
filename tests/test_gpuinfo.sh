#!/usr/bin/env bash
# gpuinfo must not crash awk with a division-by-zero, must not leak its
# "Initialized Variable..." diagnostic banner into the JSON line it writes to
# stdout, and must always emit a JSON number for "percentage" even when no
# temperature sensor is present — all on the very first invocation after its
# /tmp state file is missing (a fresh boot, or a --reset). Running the script
# with no arguments exercises this on any machine: with no GPU vendor enabled
# it falls through to the generic general_query()/get_utilization() path
# regardless of hardware. `sensors` is shadowed so the case where no
# temperature is available reproduces deterministically, not just on runners
# that happen to have no hardware sensors (this is how a real CI failure of
# this test was first found: temperature came back empty there and "percentage"
# ended up empty in the JSON, e.g. `"percentage":,`).

. "$(dirname -- "$0")/lib/common.sh"

script="$REPO_ROOT/Configs/.local/lib/hyde/gpuinfo.sh"
state_file="/tmp/hyde-$(id -u)-gpuinfo"

if [ ! -f "$script" ]; then
    fail "gpuinfo.sh not found at $script"
    finish
fi

state_backup=$(mktemp)
had_state_file=0
if [ -f "$state_file" ]; then
    had_state_file=1
    cp -p "$state_file" "$state_backup"
fi
fake_bin=$(mktemp -d)
fake_ps=$(mktemp -d)
stderr_file=$(mktemp)
restore_state() {
    if [ "$had_state_file" -eq 1 ]; then
        cp -p "$state_backup" "$state_file"
    else
        rm -f "$state_file"
    fi
    rm -f "$state_backup" "$stderr_file"
    chmod -R u+rwX "$fake_ps" 2>/dev/null
    rm -rf "$fake_bin" "$fake_ps"
}
trap restore_state EXIT

rm -f "$state_file"

cat >"$fake_bin/sensors" <<'EOF'
#!/bin/sh
exit 1
EOF
chmod +x "$fake_bin/sensors"

stdout=$(PATH="$fake_bin:$PATH" bash "$script" 2>"$stderr_file")
stderr=$(cat "$stderr_file")

case $stderr in
    *"division by zero"*)
        fail "cold start crashed awk with a division-by-zero (see gpuinfo.sh:general_query/get_utilization)"
        ;;
esac

case $stdout in
    *"Initialized Variable"*)
        fail "cold start leaked the 'Initialized Variable' banner into stdout, which waybar reads as JSON"
        ;;
esac

# Every line of stdout has to be a JSON object on its own, not just the last
# one: waybar consumes the stream line by line, so a diagnostic line printed
# before the JSON breaks it just as surely as malformed JSON does. The script
# legitimately emits more than one object per cold-start run, because the
# startup detection re-invokes it, so each line is checked rather than the
# stream as a whole.
if [ -z "$stdout" ] || ! printf '%s\n' "$stdout" | python3 -c '
import json, sys
lines = [line for line in sys.stdin.read().splitlines() if line.strip()]
if not lines:
    raise SystemExit(1)
for line in lines:
    if not isinstance(json.loads(line), dict):
        raise SystemExit(1)
' >/dev/null 2>&1; then
    fail "cold start produced a line on stdout that is not a JSON object: $stdout"
fi

# A battery's power_now node can exist and still fail to read: some laptops'
# embedded controller exposes the attribute but answers ENXIO for it, so the
# `-f` guard passes and awk then dies with a fatal error on every single poll
# (once per waybar interval, forever). Guarding on existence alone is not
# enough — the read itself has to be checked. A mode-000 file reproduces the
# same "exists but cannot be read" shape portably; root bypasses the mode bits,
# so skip there rather than assert something that cannot hold.
#
# Note on what this does and does not prove: the injection point below only
# exists because of the fix, so running this case against the unfixed script
# does not exercise the mock at all -- the unfixed script ignores
# GPUINFO_POWER_SUPPLY_DIR and reads the real /sys, where it happens to fail
# only on hardware that actually has the defect. This case is therefore a
# guard against reintroducing the defect, not a from-scratch reproduction of
# it. A mode-000 file also fails with EACCES rather than the ENXIO a real
# unsupported power_now returns; both reach the same failure -- awk dies and
# the value comes back empty -- which is exactly what the guard checks.
if [ "$(id -u)" -eq 0 ]; then
    skip "cannot make a file unreadable as root"
else
    mkdir -p "$fake_ps/BAT0"
    : >"$fake_ps/BAT0/power_now"
    chmod 000 "$fake_ps/BAT0/power_now"

    rm -f "$state_file"
    GPUINFO_POWER_SUPPLY_DIR="$fake_ps" PATH="$fake_bin:$PATH" bash "$script" \
        >/dev/null 2>"$stderr_file"
    unreadable_stderr=$(cat "$stderr_file")

    # Match only a fatal that names power_now. The script has other awk calls
    # that open files directly -- the cpufreq ones -- and those fail the same
    # way wherever the host kernel has no cpufreq scaling driver loaded, which
    # is the case on this project's CI runner.
    # Matching any "awk: fatal" would fail this case for an unrelated reason.
    if printf '%s\n' "$unreadable_stderr" | grep -q 'awk: fatal.*power_now'; then
        fail "an unreadable power_now leaked an awk fatal error to stderr: $unreadable_stderr"
    fi
fi

# An AMD CPU's k10temp/zenpower sensor labels its reading "Tctl"/"Tdie", not
# "edge" (amdgpu GPU) or "Package id" (Intel CPU) -- the only two the
# temperature regex recognized, plus a literal unfinished "another keyword"
# placeholder that never matched anything. A system with neither an amdgpu
# GPU nor an Intel CPU (e.g. an AMD CPU with a non-amdgpu/non-detected GPU)
# got an empty temperature on every poll (#1952).
#
# "Tctl" and "Tdie" are separate alternatives in the regex -- a dump carrying
# only one of them has to match on its own, not just the pair together, or a
# driver/board that only ever exposes one of the two would still come back
# empty despite the fix.
cat >"$fake_bin/sensors" <<'EOF'
#!/bin/sh
cat <<'SENSORS'
k10temp-pci-00c3
Adapter: PCI adapter
Tctl:         +45.0°C

SENSORS
EOF
chmod +x "$fake_bin/sensors"

rm -f "$state_file"
tctl_stdout=$(PATH="$fake_bin:$PATH" bash "$script" 2>"$stderr_file")
tctl_stderr=$(cat "$stderr_file")

case $tctl_stdout in
*'45°C'*) ;;
*) fail "an AMD k10temp Tctl-only reading of 45°C was not picked up as the temperature: $tctl_stdout" ;;
esac
case $tctl_stderr in
*"division by zero"*) fail "a Tctl-only reading crashed awk with a division-by-zero: $tctl_stderr" ;;
esac

cat >"$fake_bin/sensors" <<'EOF'
#!/bin/sh
cat <<'SENSORS'
k10temp-pci-00c3
Adapter: PCI adapter
Tdie:         +52.0°C

SENSORS
EOF
chmod +x "$fake_bin/sensors"

rm -f "$state_file"
tdie_stdout=$(PATH="$fake_bin:$PATH" bash "$script" 2>"$stderr_file")
tdie_stderr=$(cat "$stderr_file")

case $tdie_stdout in
*'52°C'*) ;;
*) fail "an AMD k10temp Tdie-only reading of 52°C was not picked up as the temperature: $tdie_stdout" ;;
esac
case $tdie_stderr in
*"division by zero"*) fail "a Tdie-only reading crashed awk with a division-by-zero: $tdie_stderr" ;;
esac

# Out-of-spec: the matched line's value is not a number at all (a driver
# quirk, or a board that reports an unsupported/placeholder reading). awk's
# int() coerces this to 0 instead of dying on it -- this only confirms that
# still holds for the newly matched labels, not just the pre-existing ones.
cat >"$fake_bin/sensors" <<'EOF'
#!/bin/sh
cat <<'SENSORS'
k10temp-pci-00c3
Adapter: PCI adapter
Tctl:         N/A

SENSORS
EOF
chmod +x "$fake_bin/sensors"

rm -f "$state_file"
garbage_stdout=$(PATH="$fake_bin:$PATH" bash "$script" 2>"$stderr_file")
garbage_stderr=$(cat "$stderr_file")

case $garbage_stderr in
*"division by zero"*) fail "a non-numeric Tctl reading crashed awk with a division-by-zero: $garbage_stderr" ;;
esac
if [ -z "$garbage_stdout" ] || ! printf '%s\n' "$garbage_stdout" | python3 -c '
import json, sys
lines = [line for line in sys.stdin.read().splitlines() if line.strip()]
if not lines:
    raise SystemExit(1)
for line in lines:
    if not isinstance(json.loads(line), dict):
        raise SystemExit(1)
' >/dev/null 2>&1; then
    fail "a non-numeric Tctl reading produced a line on stdout that is not a JSON object: $garbage_stdout"
fi

# Ambiguous case the regex was already living with before this fix: a system
# that (however unusually) exposes both an amdgpu "edge" reading and a CPU
# "Tctl" reading. grep -m 1 takes whichever line comes first in the sensors
# dump -- asserting that pins the actual, currently-observed precedence as a
# known behavior instead of leaving it silently undefined.
cat >"$fake_bin/sensors" <<'EOF'
#!/bin/sh
cat <<'SENSORS'
k10temp-pci-00c3
Adapter: PCI adapter
Tctl:         +45.0°C

amdgpu-pci-0100
Adapter: PCI adapter
edge:         +60.0°C

SENSORS
EOF
chmod +x "$fake_bin/sensors"

rm -f "$state_file"
both_stdout=$(PATH="$fake_bin:$PATH" bash "$script" 2>"$stderr_file")
both_stderr=$(cat "$stderr_file")

case $both_stdout in
*'45°C'*) ;;
*) fail "with both a Tctl and an edge reading present, the first line (Tctl, 45°C) was not the one picked: $both_stdout" ;;
esac
case $both_stderr in
*"division by zero"*) fail "a combined Tctl+edge reading crashed awk with a division-by-zero: $both_stderr" ;;
esac

finish
