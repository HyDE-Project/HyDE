#!/usr/bin/env sh
# @name: app
# @ver: 0.1.0
# @short: Wrapper for scripts to optionally use systemd
# @cmd: service
# @cmd.desc: Run a script as a systemd service

# app2unit and xdg-terminal-exec fall back to the generic DEBUG variable,
# which may contain non-boolean build modes such as "release".
# Give both helpers an explicit, scoped default while preserving any
# user-provided values on both execution paths.
APP2UNIT_DEBUG=${APP2UNIT_DEBUG:-0}
XTE_DEBUG=${XTE_DEBUG:-0}
export APP2UNIT_DEBUG XTE_DEBUG

if [ -d "/run/systemd/system" ]; then
    exec app2unit "$@"
fi
# no systemd: drop args before -- and run only the command after --
while [ "$#" -gt 0 ] && [ "$1" != "--" ]; do
    shift
done
[ "$#" -gt 0 ] && shift
exec "$@"
