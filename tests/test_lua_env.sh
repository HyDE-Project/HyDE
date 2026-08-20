#!/usr/bin/env sh
# The Lua environment is bootstrapped from a list of rocks, and one of them —
# lgi — is compiled against the GObject introspection headers. A machine
# without them cannot build it, and that used to end the whole installation at
# the Lua step, before a single dotfile was deployed.
#
# An optional rock that fails is reported and skipped; a required one still
# stops the run.

# shellcheck source=tests/lib/common.sh
. "$(dirname -- "$0")/lib/common.sh"

if ! command -v python3 >/dev/null 2>&1; then
    skip "python3 is not installed"
    finish
fi

module="$REPO_ROOT/Configs/.local/lib/hyde/pyutils/lua_env.py"
[ -f "$module" ] || {
    fail "lua_env.py is missing"
    finish
}

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

cp "$module" "$work_dir/lua_env.py"

# Stands in for luarocks: every install of the package named below fails, the
# rest succeeds. `list` answers with nothing, so the snapshot stays empty.
cat > "$work_dir/luarocks" <<'STUB'
#!/usr/bin/env sh
for arg in "$@"; do
    case $arg in
    list) exit 0 ;;
    *unbuildable*) exit 1 ;;
    esac
done
exit 0
STUB
chmod +x "$work_dir/luarocks"

printf '#!/usr/bin/env sh\nexit 0\n' > "$work_dir/lua"
chmod +x "$work_dir/lua"

# Runs one command against a bootstrap list written for the case at hand.
run_with() {
    printf '%s\n' "$2" > "$work_dir/lua_env.json"
    XDG_STATE_HOME="$work_dir/state" \
        LUA="$work_dir/lua" \
        LUAROCKS="$work_dir/luarocks" \
        python3 "$work_dir/lua_env.py" "$1" >"$work_dir/out" 2>&1
}

# The package name alone proves nothing — the failing command line carries it
# too. What has to appear is the handler's own account of the skip, so these
# look for the words only it writes.
expect_skip_report() {
    grep -q 'it is optional, continuing without it' "$work_dir/out" ||
        fail "$1 did not report the skipped optional package"
    grep -q 'optional package(s) skipped' "$work_dir/out" ||
        fail "$1 did not summarise what was skipped"
    grep -q 'hyde-shell luainit' "$work_dir/out" ||
        fail "$1 did not name the command that retries it"
}

# A non-zero status on its own would also be satisfied by a broken stub or a
# misspelled subcommand, so the reason has to be the package that failed.
expect_required_failure() {
    grep -q 'CalledProcessError' "$work_dir/out" ||
        fail "$1 ended for a reason other than the failed package: $(cat "$work_dir/out")"
}

run_with create '{"bootstrap_install": [{"name": "dkjson", "version": "2.11-1"}, {"name": "unbuildable", "optional": true}]}' ||
    fail "an optional package that failed to build ended the run: $(cat "$work_dir/out")"
expect_skip_report create

run_with create '{"bootstrap_install": [{"name": "unbuildable"}]}' &&
    fail "a required package that failed to build did not end the run"
expect_required_failure create

# `hyde-shell luainit` reinstalls through sync rather than create, and falls
# back to a full rebuild when it fails. Without the same tolerance there, an
# unbuildable optional rock would tear the rocks tree down on every routine
# refresh of the environment.
run_with sync '{"bootstrap_install": [{"name": "dkjson", "version": "2.11-1"}, {"name": "unbuildable", "optional": true}]}' ||
    fail "sync ended the run over an optional package: $(cat "$work_dir/out")"
expect_skip_report sync

run_with sync '{"bootstrap_install": [{"name": "unbuildable"}]}' &&
    fail "sync did not end the run over a required package"
expect_required_failure sync

# The shipped list has to mark lgi optional, otherwise the guard above protects
# nothing on a real installation.
python3 - "$REPO_ROOT/Configs/.local/lib/hyde/pyutils/lua_env.json" <<'CHECK' || fail "the shipped bootstrap list does not mark lgi optional"
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    config = json.load(handle)

entries = config.get("bootstrap_install", [])
lgi = [e for e in entries if isinstance(e, dict) and "lgi" in e.get("name", "")]
sys.exit(0 if lgi and lgi[0].get("optional") else 1)
CHECK

printf "    %d bootstrap case(s) checked\n" 5

finish
