from __future__ import annotations
import os
from typing import Protocol

"""Compositor backend interface and detection for session restore.

Backends implement SessionBackend for save/restore via IPC.
To add one, create session/compositor/<name>.py, implement SessionBackend,
and extend detect().
"""


def backend_short_name(backend: SessionBackend) -> str:
    """Return a short canonical name for the backend (used in cache path).

    Examples: HyprlandBackend -> 'hypr', NiriBackend -> 'niri'
    """
    name = backend.__class__.__name__.lower()
    if name.endswith("backend"):
        name = name[: -len("backend")]

    if name == "hyprland":
        return "hypr"
    return name


class SessionBackend(Protocol):
    """Interface that compositor backends must implement."""

    def get_clients(self) -> list[dict]:
        """Return all open windows/clients as dicts."""
        ...

    def get_workspaces(self) -> list[dict]:
        """Return all workspaces as dicts."""
        ...

    def get_monitors(self) -> list[dict]:
        """Return all monitors as dicts."""
        ...

    def ws_target(self, ws: dict) -> str:
        """Convert a workspace dict ``{id, name}`` to dispatch syntax."""
        ...

    def multiwindow_key(self, client: dict) -> tuple[int, int] | int | None:
        """Return the key used to deduplicate multi-window apps in save."""
        return None

    def append_multiwindow_metadata(self, rep: dict, client: dict) -> None:
        """Append backend-specific metadata for compressed multi-window entries."""
        pass

    def restore_sort_key(self, client: dict) -> tuple:
        """Return a sort key for restore ordering.

        Backends may use workspace, monitor, and absolute screen position to
        define a natural restore order.
        """
        return (0, 0, 0, 0, 0)

    def launch(self, command: str, client: dict, ws_target: str) -> None:
        """Launch a non-forking app with appropriate window rules."""
        ...

    def launch_forking(self, command: str, client: dict, ws_target: str) -> None:
        """Launch a forking app (e.g. Flatpak) with transient rules."""
        ...

    def dispatch_plugin_cmd(self, cmd: str, client: dict) -> None:
        """Dispatch a plugin-generated command, injecting extra rules."""
        ...

    def reposition(self, addr: str, saved: dict) -> None:
        """Move an existing window to match its saved state."""
        ...

    def schedule_cleanup(self) -> None:
        """Schedule cleanup of transient rules (if any were created)."""
        ...


def detect() -> SessionBackend:
    """Auto-detect the running compositor and return its backend."""
    if os.getenv("HYPRLAND_INSTANCE_SIGNATURE"):
        from session.compositor.hyprland import HyprlandBackend
        return HyprlandBackend()

    def backend_short_name(backend: SessionBackend) -> str:
        """Return a short canonical name for the backend (used in cache path).

        Examples: HyprlandBackend -> 'hypr', NiriBackend -> 'niri'
        """
        name = backend.__class__.__name__.lower()
        if name.endswith("backend"):
            name = name[: -len("backend")]

        if name == "hyprland":
            return "hypr"
        return name
