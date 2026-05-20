from __future__ import annotations
import os
from typing import Protocol

"""Compositor backends for session management.

Each backend implements the SessionBackend protocol, providing
compositor-specific IPC for save/restore operations.

To add a new compositor:
    1. Create ``session/compositor/<name>.py``
    2. Implement ``SessionBackend``
    3. Add detection logic to ``detect()``
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
