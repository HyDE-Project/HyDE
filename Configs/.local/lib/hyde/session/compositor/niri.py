"""Niri compositor backend for session save/restore.
Prototype support via niri msg --json.
"""

import json
import os
import subprocess
from typing import Any


class NiriBackend:
    """Session backend for Niri via niri msg --json."""

    def _niri_msg(self, *args: str) -> Any:
        """Call niri msg --json <args> and return parsed JSON."""
        cmd = ["niri", "msg", "--json"] + list(args)
        env = os.environ.copy()

        result = subprocess.run(cmd, env=env, capture_output=True, text=True)
        if result.returncode != 0:
            raise RuntimeError(f"niri msg failed: {result.stderr}")
        return json.loads(result.stdout)

    @staticmethod
    def is_available() -> bool:
        """Return True if a Niri instance appears usable on this system.

        Checks the `NIRI_SOCKET` env var first, then falls back to whether
        the `niri` helper is on PATH.
        """
        import shutil
        import os as _os

        if _os.getenv("NIRI_SOCKET"):
            return True
        return shutil.which("niri") is not None

    def get_clients(self) -> list[dict]:

        resp = self._niri_msg("Windows")
        return resp.get("Ok", {}).get("Windows", [])

    def get_workspaces(self) -> list[dict]:

        resp = self._niri_msg("Workspaces")
        return resp.get("Ok", {}).get("Workspaces", [])

    def get_monitors(self) -> list[dict]:

        resp = self._niri_msg("Outputs")
        return resp.get("Ok", {}).get("Outputs", [])

    def ws_target(self, ws: dict) -> str:

        return str(ws.get("id", ws.get("name", "")))

    def multiwindow_key(self, client: dict) -> tuple[int, int] | int | None:
        pid = client.get("pid", 0)
        return pid if pid > 0 else None

    def append_multiwindow_metadata(self, rep: dict, client: dict) -> None:
        return

    def launch(self, command: str, client: dict, ws_target: str) -> None:

        subprocess.Popen(command, shell=True)

    def launch_forking(self, command: str, client: dict, ws_target: str) -> None:

        self.launch(command, client, ws_target)

    def dispatch_plugin_cmd(self, cmd: str, client: dict) -> None:

        subprocess.Popen(cmd, shell=True)

    def reposition(self, addr: str, saved: dict) -> None:

        pass

    def restore_sort_key(self, client: dict) -> tuple:
        workspace = client.get("workspace", {})
        ws_id = workspace.get("id", 0)
        at = client.get("at", [0, 0])
        if not isinstance(at, (list, tuple)) or len(at) < 2:
            at = [0, 0]
        x = at[0] if isinstance(at[0], (int, float)) else 0
        y = at[1] if isinstance(at[1], (int, float)) else 0
        return (ws_id, x, y, client.get("_p_window_index", 0), client.get("focusHistoryID", 0))

    def schedule_cleanup(self) -> None:

        pass
