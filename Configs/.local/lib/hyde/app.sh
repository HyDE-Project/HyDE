#!/usr/bin/env sh
# @name: app
# @ver: 0.1.0
# @short: Wrapper for scripts to optionally use systemd
# @cmd: service
# @cmd.desc: Run a script as a systemd service

if [ -d "/run/systemd/system" ]; then
    exec app2unit "$@"
fi
# no systemd: drop args before -- and run only the command after --
while [ "$#" -gt 0 ] && [ "$1" != "--" ]; do
    shift
done
[ "$#" -gt 0 ] && shift
exec "$@"
