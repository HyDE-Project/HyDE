"""Toggle mute for the focused window's audio sink inputs."""

from __future__ import annotations

import json
import os
import subprocess
import sys
from functools import lru_cache
from typing import Any
from pyutils.compositor import HyprctlWrapper


class _SinkInput:
    __slots__ = ("index", "mute", "proplist")

    def __init__(self, index: int, mute: bool, proplist: dict[str, str]):
        self.index = index
        self.mute = mute
        self.proplist = proplist


def _list_sink_inputs() -> list[_SinkInput]:
    """List sink inputs via pactl JSON, falling back to pulsectl."""
    try:
        result = subprocess.run(
            ["pactl", "--format=json", "list", "sink-inputs"],
            capture_output=True,
            text=True,
            timeout=3,
        )
        if result.returncode == 0:
            return [
                _SinkInput(int(e["index"]), e.get("mute", False), e.get("properties", {}))
                for e in json.loads(result.stdout)
                if "index" in e
            ]
    except FileNotFoundError:
        pass
    except (subprocess.TimeoutExpired, json.JSONDecodeError, UnicodeDecodeError):
        return []
    return _list_sink_inputs_pulsectl()


def _list_sink_inputs_pulsectl() -> list[_SinkInput]:
    pulse = _pulse_connect()
    if pulse is None:
        return []
    try:
        return [
            _SinkInput(s.index, bool(s.mute), dict(s.proplist or {}))
            for s in pulse.sink_input_list()
        ]
    except Exception:
        return []
    finally:
        _pulse_close(pulse)


def _mute_sink_inputs(sink_ids: list[int], want_mute: bool) -> tuple[int, int]:
    """Mute/unmute sink inputs. Returns (error_count, last_failed_id)."""
    mute_arg = "1" if want_mute else "0"
    errors = failed_id = 0
    try:
        for sid in sink_ids:
            ret = subprocess.run(
                ["pactl", "set-sink-input-mute", str(sid), mute_arg],
                capture_output=True,
                timeout=3,
            )
            if ret.returncode != 0:
                errors += 1
                failed_id = sid
        return errors, failed_id
    except FileNotFoundError:
        pass
    except subprocess.TimeoutExpired:
        return len(sink_ids), sink_ids[-1] if sink_ids else 0
    return _mute_sink_inputs_pulsectl(sink_ids, want_mute)


def _mute_sink_inputs_pulsectl(sink_ids: list[int], want_mute: bool) -> tuple[int, int]:
    pulse = _pulse_connect()
    if pulse is None:
        return len(sink_ids), sink_ids[-1] if sink_ids else 0
    errors = failed_id = 0
    try:
        for sid in sink_ids:
            try:
                pulse.sink_input_mute(sid, want_mute)
            except Exception:
                errors += 1
                failed_id = sid
    finally:
        _pulse_close(pulse)
    return errors, failed_id


def _pulse_connect() -> Any | None:
    """Lazy-import pulsectl and return a connection, or None."""
    try:
        import pulsectl
    except ImportError:
        return None
    try:
        return pulsectl.Pulse("window-mute")
    except Exception:
        return None


def _pulse_close(pulse: Any) -> None:
    try:
        pulse.close()
    except Exception:
        pass


@lru_cache(maxsize=1)
def _wallbash_dir() -> str:
    import pyutils.xdg_base_dirs as xdg

    roots = list(
        dict.fromkeys(
            filter(
                None,
                [
                    os.environ.get("iconsDir"),
                    str(xdg.xdg_data_home() / "icons"),
                    *(str(p / "icons") for p in xdg.xdg_data_dirs()),
                ],
            )
        )
    )

    for root in roots:
        candidate = os.path.join(root, "Wallbash-Icon")
        if os.path.isdir(candidate):
            return candidate

    fallback = roots[0] if roots else os.path.expanduser("~/.local/share/icons")
    return os.path.join(fallback, "Wallbash-Icon")


def _icon(name: str) -> str:
    return os.path.join(_wallbash_dir(), name)


ICON_HYPRDOTS = "wallbash.svg"
ICON_MUTED = "media/muted-speaker.svg"
ICON_UNMUTED = "media/unmuted-speaker.svg"


def _notify(summary: str, **kwargs: Any) -> None:
    import pyutils.wrapper.libnotify as notify

    notify.send(summary, **kwargs)


def _read_proc_stat(pid: int, cache: dict[int, tuple[int, str] | None]) -> tuple[int, str] | None:
    """Read (ppid, comm) from /proc/<pid>/stat with caching."""
    if pid in cache:
        return cache[pid]
    try:
        data = open(f"/proc/{pid}/stat", encoding="utf-8", errors="ignore").read()
        right = data.rindex(")")
        comm = data[data.find("(") + 1 : right]
        ppid = int(data[right + 2 :].split()[1])
        result: tuple[int, str] | None = (ppid, comm)
    except (OSError, ValueError, IndexError):
        result = None
    cache[pid] = result
    return result


def _is_descendant(pid: int, ancestor: int, cache: dict[int, tuple[int, str] | None]) -> bool:
    """Check if *pid* is a descendant of *ancestor* via /proc walk."""
    cur = pid
    seen: set[int] = set()
    while cur > 1 and cur not in seen:
        if cur == ancestor:
            return True
        seen.add(cur)
        info = _read_proc_stat(cur, cache)
        if info is None:
            return False
        cur = info[0]
    return cur == ancestor


def _has_name_in_lineage(pid: int, name: str, cache: dict[int, tuple[int, str] | None]) -> bool:
    """Check if any ancestor of *pid* has comm == *name*."""
    cur = pid
    seen: set[int] = set()
    while cur > 1 and cur not in seen:
        seen.add(cur)
        info = _read_proc_stat(cur, cache)
        if info is None:
            return False
        if info[1] == name:
            return True
        cur = info[0]
    return False


def _normalize(text: str) -> str:
    lowered = (text or "").lower()
    for ch in "-_~.":
        lowered = lowered.replace(ch, " ")
    return " ".join(lowered.split())


def _sink_pid(proplist: dict[str, str]) -> int | None:
    try:
        return int(proplist.get("application.process.id", ""))
    except (TypeError, ValueError):
        return None


def _find_sink_ids(
    sink_inputs: list[_SinkInput],
    focused_pid: int,
    app_class: str,
    title: str,
) -> list[int]:
    """Resolve which sink-input indices belong to the focused window."""
    proc_cache: dict[int, tuple[int, str] | None] = {}

    ids = [s.index for s in sink_inputs if _sink_pid(s.proplist) == focused_pid]
    if ids:
        return ids

    cls = (app_class or "").lower()
    title_n = _normalize(title)
    for s in sink_inputs:
        p = s.proplist
        if cls and any(
            cls in str(p.get(k, "")).lower()
            for k in ("application.name", "application.id", "application.process.binary")
        ):
            ids.append(s.index)
        elif title_n and title_n in _normalize(str(p.get("media.name", ""))):
            ids.append(s.index)
    if ids:
        return ids

    ids = [
        s.index
        for s in sink_inputs
        if (pid := _sink_pid(s.proplist)) is not None
        and _is_descendant(pid, focused_pid, proc_cache)
    ]
    if ids:
        return ids

    if app_class:
        ids = [
            s.index
            for s in sink_inputs
            if (pid := _sink_pid(s.proplist)) is not None
            and _has_name_in_lineage(pid, app_class, proc_cache)
        ]
    return ids


def _default_sink_label() -> str:
    """Get default sink human-readable description via pactl."""
    try:
        name = subprocess.run(
            ["pactl", "get-default-sink"],
            capture_output=True,
            text=True,
            timeout=2,
        ).stdout.strip()
        if not name:
            return ""
        sinks = json.loads(
            subprocess.run(
                ["pactl", "--format=json", "list", "sinks"],
                capture_output=True,
                text=True,
                timeout=2,
            ).stdout
        )
        return next((s.get("description", name) for s in sinks if s.get("name") == name), name)
    except Exception:
        return ""


def main() -> int:

    try:
        window = json.loads(HyprctlWrapper._send("j/activewindow"))
    except Exception as exc:
        print(f"Did hyprctl fail to run? {exc}", file=sys.stderr)
        return 1

    focused_pid = int(window.get("pid") or 0)
    if focused_pid <= 0:
        print("Could not resolve PID for focused window.", file=sys.stderr)
        return 1

    app_class = str(window.get("class") or "")
    title = str(window.get("title") or "")
    label = str(window.get("initialTitle") or title or app_class or "audio")

    sink_inputs = _list_sink_inputs()
    sink_ids = list(dict.fromkeys(_find_sink_ids(sink_inputs, focused_pid, app_class, title)))

    if not sink_ids:
        if os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
            _notify(
                "No sink input available.",
                app_name="t1",
                replace_id=91190,
                expire_time=1200,
                icon=_icon(ICON_HYPRDOTS),
            )
        print(f"No sink input for focused window: {app_class}", file=sys.stderr)
        return 1

    selected = [s for s in sink_inputs if s.index in set(sink_ids)]
    want_mute = not all(s.mute for s in selected)
    state_msg = "Muted" if want_mute else "Unmuted"
    state_icon = ICON_MUTED if want_mute else ICON_UNMUTED

    errors, failed_id = _mute_sink_inputs(sink_ids, want_mute)
    if errors:
        print(f"PulseAudio failed to set '{failed_id}' to '{state_msg}'.", file=sys.stderr)
        _notify(
            f"Failed to set '{failed_id}' to '{state_msg}'!",
            app_name="t1",
            replace_id=91190,
            expire_time=1200,
            icon=_icon(ICON_HYPRDOTS),
        )
        return 1

    _notify(
        f"{state_msg} {label}",
        body=_default_sink_label() or None,
        app_name="t2",
        replace_id=91190,
        expire_time=800,
        icon=_icon(state_icon),
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
