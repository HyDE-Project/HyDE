#!/usr/bin/env bash
# Migrations have to run in version order, once each, and record what succeeded.

. "$(dirname -- "$0")/lib/common.sh"

# shellcheck source=/dev/null
if ! . "$REPO_ROOT/Scripts/global_fn.sh" 2>/dev/null; then
    fail "unable to source global_fn.sh"
    finish
fi

if ! command -v run_pending_migrations >/dev/null 2>&1 && ! type run_pending_migrations >/dev/null 2>&1; then
    fail "run_pending_migrations is not defined in global_fn.sh"
    finish
fi

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

migration_dir="$work_dir/migrations"
state_file="$work_dir/state/applied"
order_log="$work_dir/order.log"
mkdir -p "$migration_dir"

for version in v25.9.1 v26.10.1; do
    printf '#!/usr/bin/env sh\nprintf "%%s\\n" "%s" >>"%s"\n' "$version" "$order_log" \
        >"$migration_dir/$version.sh"
done
# Reads stdin: inheriting the runner's stdin would let it swallow the names of
# the migrations queued after it.
printf '#!/usr/bin/env sh\ncat >/dev/null\nprintf "%%s\\n" "v26.4.3" >>"%s"\n' "$order_log" \
    >"$migration_dir/v26.4.3.sh"
failure_log="$work_dir/failures.log"
printf '#!/usr/bin/env sh\nprintf "%%s\\n" "ran" >>"%s"\nexit 1\n' "$failure_log" \
    >"$migration_dir/v26.11.0.sh"
chmod +x "$migration_dir"/*.sh

run_pending_migrations "$migration_dir" "$state_file" >/dev/null 2>&1

expected_order='v25.9.1
v26.4.3
v26.10.1'
actual_order=$(cat "$order_log" 2>/dev/null || true)
[ "$actual_order" = "$expected_order" ] ||
    fail "migrations ran out of version order: $(echo "$actual_order" | tr '\n' ' ')"

for version in v25.9.1 v26.4.3 v26.10.1; do
    grep -qxF "$version.sh" "$state_file" ||
        fail "$version.sh succeeded but was not recorded as applied"
done

grep -qxF 'v26.11.0.sh' "$state_file" &&
    fail "a migration that exited non-zero was recorded as applied"

: >"$order_log"
run_pending_migrations "$migration_dir" "$state_file" >/dev/null 2>&1

[ -s "$order_log" ] &&
    fail "already applied migrations ran a second time: $(tr '\n' ' ' <"$order_log")"

failure_runs=$(wc -l <"$failure_log" 2>/dev/null || echo 0)
[ "$failure_runs" -eq 2 ] ||
    fail "a failed migration ran $failure_runs time(s) across two passes, expected 2"

second_pass=$(run_pending_migrations "$migration_dir" "$state_file" 2>&1 || true)
case $second_pass in
*"No outstanding migrations"*)
    fail "a migration was still pending but the run reported none outstanding"
    ;;
esac

# A mention in a comment is not a call: the name has to sit where a command goes.
grep -qE '^[[:space:]]*run_pending_migrations[[:space:]]+' "$REPO_ROOT/Scripts/install.sh" ||
    fail "install.sh does not invoke run_pending_migrations as a command"

missing_dir_output=$(run_pending_migrations "$work_dir/absent" "$state_file" 2>&1)
[ -z "$missing_dir_output" ] ||
    fail "a missing migration directory produced output: $missing_dir_output"

# The runner invokes each migration with sh, so the shebang decides nothing.
# A migration that promises bash and then uses a bashism breaks under dash;
# declaring sh also puts it under the dialect pass in test_shell.
shipped_count=0
for migration in "$REPO_ROOT"/Scripts/migrations/*.sh; do
    [ -f "$migration" ] || continue
    shipped_count=$((shipped_count + 1))

    case $(head -n 1 "$migration") in
    '#!'*[!a-z]sh | '#!'*[!a-z]sh' '*) ;;
    *) fail "${migration#"$REPO_ROOT"/} is run with sh but does not declare it" ;;
    esac
done

# Without this the check passes on an empty directory, reporting zero problems
# because it looked at nothing.
[ "$shipped_count" -gt 0 ] ||
    fail "no migrations found in Scripts/migrations, the shebang check inspected nothing"

printf '    %d shipped migration(s) checked\n' "$shipped_count"

finish
