#!/usr/bin/env bash
# DOORwayDE startup launcher: wraps systemd-run --user for named session units.
# Usage: launch-unit.sh -u <unit-id> -t scope|service -- <command> [args...]
set -euf -o pipefail

unit_id=""
unit_type="scope"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -u) unit_id="$2"; shift 2 ;;
        -t) unit_type="$2"; shift 2 ;;
        --) shift; break ;;
        *) echo "launch-unit.sh: unknown option '$1'" >&2; exit 1 ;;
    esac
done

[[ -n "$unit_id" ]]  || { echo "launch-unit.sh: -u <unit-id> required" >&2; exit 1; }
[[ $# -gt 0 ]]       || { echo "launch-unit.sh: command required after --" >&2; exit 1; }

run_args=(
    systemd-run --user
    --quiet --collect --same-dir
    --slice=app.slice
    --unit="$unit_id"
    --description="$1"
    --property=After=graphical-session.target
    --property=PartOf=graphical-session.target
)

case "$unit_type" in
    scope)   run_args+=(--scope) ;;
    service) run_args+=(--property=Type=exec --property=ExitType=cgroup) ;;
    *) echo "launch-unit.sh: -t must be scope or service, got '$unit_type'" >&2; exit 1 ;;
esac

exec "${run_args[@]}" -- "$@"
