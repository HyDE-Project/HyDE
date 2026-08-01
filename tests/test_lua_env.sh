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

# Runs `create` against a bootstrap list written for the case at hand.
create_with() {
    printf '%s\n' "$1" > "$work_dir/lua_env.json"
    XDG_STATE_HOME="$work_dir/state" \
        LUA="$work_dir/lua" \
        LUAROCKS="$work_dir/luarocks" \
        python3 "$work_dir/lua_env.py" create >"$work_dir/out" 2>&1
}

create_with '{"bootstrap_install": [{"name": "dkjson", "version": "2.11-1"}, {"name": "unbuildable", "optional": true}]}' ||
    fail "an optional package that failed to build ended the run: $(cat "$work_dir/out")"

grep -q 'unbuildable' "$work_dir/out" ||
    fail "the skipped optional package was not reported"

create_with '{"bootstrap_install": [{"name": "unbuildable"}]}' &&
    fail "a required package that failed to build did not end the run"

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

printf '    %d bootstrap case(s) checked\n' 3

finish
