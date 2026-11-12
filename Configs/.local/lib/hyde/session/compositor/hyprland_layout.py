from __future__ import annotations

import time


def reposition_window(backend, addr: str, saved: dict) -> None:
    """Apply saved Hyprland window geometry/state for one address.

    This module intentionally contains Hyprland-specific layout behavior so
    the backend can keep a thin orchestration layer and fall back cleanly.
    """

    is_float = bool(saved.get("floating", False))

    if is_float:
        backend._wait_for_window_mapped(addr=addr, pid=saved.get("pid"), timeout=0.6)

    target_pos = saved.get("at", [0, 0])
    target_size = saved.get("size", [0, 0])
    fs = saved.get("fullscreenClient", saved.get("fullscreen", 0))

    if not is_float:
        x, y = target_pos
        if x is not None and y is not None:
            backend._lua_dispatch(
                "hl.dsp.window.move("
                + backend._lua_window_args(addr, {"x": x, "y": y, "exact": True})
                + ")"
            )

        if fs in (1, 2):
            backend._lua_dispatch(
                "hl.dsp.window.fullscreen_state("
                + backend._lua_window_args(addr, {"internal": fs, "client": fs})
                + ")"
            )
        if saved.get("pinned", False):
            backend._lua_dispatch(
                "hl.dsp.window.pin(" + backend._lua_window_args(addr, {}) + ")"
            )
        return

    start = time.monotonic()
    interval = 0.08
    while True:
        backend._lua_dispatch(
            "hl.dsp.window.float("
            + backend._lua_window_args(addr, {"action": "set"})
            + ")"
        )
        w, h = target_size
        x, y = target_pos
        if w > 0 and h > 0:
            backend._lua_dispatch(
                "hl.dsp.window.resize("
                + backend._lua_window_args(addr, {"x": w, "y": h, "exact": True})
                + ")"
            )
        backend._lua_dispatch(
            "hl.dsp.window.move("
            + backend._lua_window_args(addr, {"x": x, "y": y, "exact": True})
            + ")"
        )
        if fs in (1, 2):
            backend._lua_dispatch(
                "hl.dsp.window.fullscreen_state("
                + backend._lua_window_args(addr, {"internal": fs, "client": fs})
                + ")"
            )
        if saved.get("pinned", False):
            backend._lua_dispatch(
                "hl.dsp.window.pin(" + backend._lua_window_args(addr, {}) + ")"
            )

        clients = backend.get_clients()
        client = next((c for c in clients if c.get("address") == addr), None)
        if client:
            pos = client.get("at", [None, None])
            size = client.get("size", [None, None])
            if list(pos) == list(target_pos) and list(size) == list(target_size):
                break
        if time.monotonic() - start > 1.2:
            break
        time.sleep(interval)
