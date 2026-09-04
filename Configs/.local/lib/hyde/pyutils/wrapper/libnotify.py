#!/usr/bin/env python3
# coding: utf-8

import json
import os
import shutil
from subprocess import run, CalledProcessError, TimeoutExpired
from typing import Optional

DEFAULT_APP_NAME = "HyDE"
DEFAULT_URGENCY = "normal"

_notify_send_path: Optional[str] = None
_notify_send_checked = False


def _load_locale_json(path: str) -> dict:
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {}
    return data if isinstance(data, dict) else {}


def _load_translations() -> dict:
    """Load this process's locale/<lang>.json, if one exists.

    Same DESKTOP_LANG detection and same file/overlay precedence as
    shutils/l10n.sh (bash) uses -- an existing DESKTOP_LANG wins over
    LC_ALL/LANG, and a config-home locale file overrides the data-home
    one, key by key. One JSON file per language is the single source of
    truth for every runtime, bash loads it via jq, Python via json.load
    here.
    """
    lang = (os.environ.get("DESKTOP_LANG") or os.environ.get("LC_ALL") or os.environ.get("LANG") or "en")[
        :2
    ].lower()
    if lang in ("c", "po"):  # "C"/"POSIX" locale, not an actual language
        lang = "en"
    data_home = os.environ.get("XDG_DATA_HOME") or os.path.expanduser("~/.local/share")
    config_home = os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config")
    translations = _load_locale_json(os.path.join(data_home, "hyde", "locale", f"{lang}.json"))
    translations.update(_load_locale_json(os.path.join(config_home, "hyde", "locale", f"{lang}.json")))
    return translations


_T = _load_translations()


def translate(text: str) -> str:
    """Look up one fragment against the loaded locale file.

    send() already does this for a whole summary/body automatically, so
    callers only need this directly for messages built from an f-string:
    the interpolated value makes the whole string impossible to match as
    a fixed dictionary key, so the static part has to be looked up on its
    own before the dynamic part is spliced in.
    """
    return _T.get(text, text)


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
    summary = _T.get(summary, summary)
    if body:
        body = _T.get(body, body)

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
