#!/usr/bin/env python3
# coding: utf-8

import os
import shutil
from subprocess import run, CalledProcessError, TimeoutExpired
from typing import Optional

DEFAULT_APP_NAME = "HyDE"
DEFAULT_URGENCY = "normal"

_notify_send_path: Optional[str] = None
_notify_send_checked = False


def _has_notify_send() -> bool:
    """Check if notify-send command is available (cached)."""
    global _notify_send_path, _notify_send_checked
    if not _notify_send_checked:
        _notify_send_checked = True
        _notify_send_path = shutil.which("notify-send")
    return _notify_send_path is not None


def _is_gui_available() -> bool:
    """Check if a GUI environment is available."""
    return bool(
        os.environ.get("DISPLAY")
        or os.environ.get("WAYLAND_DISPLAY")
        or os.environ.get("XDG_SESSION_TYPE") in ("wayland", "x11")
    )


def _print_fallback(summary: str, body: Optional[str], app_name: Optional[str]) -> None:
    prefix = f"[{app_name or DEFAULT_APP_NAME}]"
    msg = f"{summary}: {body}" if body else summary
    print(f"{prefix} {msg}")


def send(
    summary: str,
    body: Optional[str] = None,
    urgency: Optional[str] = DEFAULT_URGENCY,
    expire_time: Optional[int] = None,
    icon: Optional[str] = None,
    category: Optional[str] = None,
    app_name: Optional[str] = DEFAULT_APP_NAME,
    replace_id: Optional[int] = None,
) -> None:
    """Send a desktop notification via notify-send, with console fallback."""
    if not _is_gui_available() or not _has_notify_send():
        _print_fallback(summary, body, app_name)
        return

    command = ["notify-send"]
    if urgency:
        command.extend(["-u", urgency])
    if expire_time:
        command.extend(["-t", str(expire_time)])
    if icon:
        command.extend(["-i", icon])
    if category:
        command.extend(["-c", category])
    if app_name:
        command.extend(["-a", app_name])
    if replace_id:
        command.extend(["-r", str(replace_id)])
    command.append(summary)
    if body:
        command.append(body)

    try:
        run(command, check=True, timeout=3, capture_output=True)
    except (CalledProcessError, TimeoutExpired, FileNotFoundError):
        _print_fallback(summary, body, app_name)
