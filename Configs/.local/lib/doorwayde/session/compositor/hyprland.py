from __future__ import annotations
import os
import socket
import json
import threading
import time
from pyutils.compositor import HyprctlWrapper

"""Hyprland compositor backend for session management.

All Hyprland-specific IPC, dispatch syntax, window rules, and
experimental features (tab-group restore) live here.
"""


class HyprlandBackend:
    @staticmethod
    def _wait_for_window_mapped(addr: str = None, pid: int = None, timeout: float = 5.0) -> bool:
        """
        Listen to Hyprland's event socket and return True as soon as a window with the given address or pid is mapped.
        Returns False if timeout is reached.
        """

        xdg_runtime = os.environ.get("XDG_RUNTIME_DIR")
        hypr_sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
        if not xdg_runtime or not hypr_sig:
            return False
        sock_path = os.path.join(xdg_runtime, f"hypr/{hypr_sig}/.socket2.sock")

        try:
            clients = json.loads(HyprctlWrapper._send("j/clients"))
            for c in clients:
                if addr and c.get("address") == addr:
                    return True
                if pid and c.get("pid") == pid:
                    return True
        except Exception:
            pass
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
                s.settimeout(timeout)
                s.connect(sock_path)
                s.sendall(b"j\n")
                start = time.monotonic()
                while True:
                    if time.monotonic() - start > timeout:
                        break
                    data = s.recv(4096)
                    if not data:
                        break

                    try:
                        clients = json.loads(HyprctlWrapper._send("j/clients"))
                        for c in clients:
                            if addr and c.get("address") == addr:
                                return True
                            if pid and c.get("pid") == pid:
                                return True
                    except Exception:
                        pass
        except Exception:
            pass
        return False

    def __init__(self) -> None:
        self._transient_rules: list[str] = []
        self._dispatch_count: int = 0
        self._animations_prev: int | None = None

    @staticmethod
    def _ipc_json(endpoint: str):
        return json.loads(HyprctlWrapper._send(f"j/{endpoint}"))

    @staticmethod
    def _ipc_dispatch(cmd: str) -> str:
        return HyprctlWrapper._send(f"/dispatch {cmd}")

    @staticmethod
    def _ipc_keyword(args: str) -> str:
        return HyprctlWrapper._send(f"/keyword {args}")

    @staticmethod
    def _ipc_batch(cmds: list[str]) -> str:
        joined = ";".join(f"dispatch {c}" for c in cmds)
        return HyprctlWrapper._send(f"[[BATCH]]/{joined}")

    def begin_restore(self) -> None:
        """Best-effort: disable animations temporarily during restore."""
        opt = None
        for endpoint in ("getoption animations:enabled", "getoption/animations:enabled"):
            try:
                opt = self._ipc_json(endpoint)
                break
            except Exception:
                continue
        if not isinstance(opt, dict):
            self._animations_prev = None
            return
        self._animations_prev = int(opt.get("int", 1))

        try:
            self._ipc_keyword("animations:enabled 0")
        except Exception:
            pass

    def end_restore(self) -> None:
        """Restore animations setting if begin_restore changed it."""
        if self._animations_prev is None:
            return
        try:
            self._ipc_keyword(f"animations:enabled {self._animations_prev}")
        except Exception:
            pass
        finally:
            self._animations_prev = None

    def get_clients(self) -> list[dict]:
        return self._ipc_json("clients")

    def get_workspaces(self) -> list[dict]:
        return self._ipc_json("workspaces")

    def get_monitors(self) -> list[dict]:
        return self._ipc_json("monitors")

    def ws_target(self, ws: dict) -> str:
        """Convert a workspace dict to Hyprland dispatcher syntax.

        Positive ID → bare number (user-configured).
        Negative ID → ``name:X`` (dynamic named workspace).
        Special → ``special:name``.
        """
        name = ws.get("name", "")
        ws_id = ws.get("id")

        if name.startswith("special:"):
            return name

        if ws_id is not None:
            if ws_id >= 0:
                return str(ws_id)
            else:
                return f"name:{name}"

        if name.isdigit():
            return name
        return f"name:{name}"

    def _build_rules(self, client: dict, ws_target: str) -> list[str]:
        """Build Hyprland window-rule list from a saved client dict."""
        rules: list[str] = [f"workspace {ws_target} silent"]

        if client.get("floating", False):
            rules.append("float")
            x, y = client.get("at", [0, 0])
            w, h = client.get("size", [0, 0])
            if w > 0 and h > 0:
                rules.append(f"size {w} {h}")
            rules.append(f"move {x} {y}")

        if client.get("pseudo", False):
            rules.append("pseudo")
        if client.get("pinned", False):
            rules.append("pin")

        fs = client.get("fullscreenClient", client.get("fullscreen", 0))
        if fs in (1, 2):
            rules.append(f"fullscreen {fs}")

        group_rule = self._group_rule(client)
        if group_rule:
            rules.append(group_rule)

        return rules

    def launch(self, command: str, client: dict, ws_target: str) -> None:
        rules = self._build_rules(client, ws_target)
        rule_str = "; ".join(rules)
        self._ipc_dispatch(f"exec [{rule_str}] {command}")
        self._dispatch_count += 1

    def launch_forking(self, command: str, client: dict, ws_target: str) -> None:
        initial_class = client.get("initialClass", "")
        rule_name = f"_doorwaydesession_{self._dispatch_count}"

        self._ipc_keyword(f"windowrule[{rule_name}]:match:initial_class {initial_class}")
        self._ipc_keyword(f"windowrule[{rule_name}]:workspace {ws_target} silent")

        if client.get("floating", False):
            self._ipc_keyword(f"windowrule[{rule_name}]:float true")
            x, y = client.get("at", [0, 0])
            w, h = client.get("size", [0, 0])
            if w > 0 and h > 0:
                self._ipc_keyword(f"windowrule[{rule_name}]:size {w} {h}")
            self._ipc_keyword(f"windowrule[{rule_name}]:move {x} {y}")

        if client.get("pseudo", False):
            self._ipc_keyword(f"windowrule[{rule_name}]:pseudo true")
        if client.get("pinned", False):
            self._ipc_keyword(f"windowrule[{rule_name}]:pin true")

        fs = client.get("fullscreenClient", client.get("fullscreen", 0))
        if fs in (1, 2):
            self._ipc_keyword(f"windowrule[{rule_name}]:fullscreen true")

        group_rule = self._group_rule(client)
        if group_rule:
            self._ipc_keyword(f"windowrule[{rule_name}]:{group_rule}")

        self._transient_rules.append(rule_name)
        self._ipc_dispatch(f"exec {command}")
        self._dispatch_count += 1

    def dispatch_plugin_cmd(self, cmd: str, client: dict) -> None:
        group_rule = self._group_rule(client)
        if group_rule:
            cmd = self._inject_exec_rule(cmd, group_rule)
        self._ipc_dispatch(cmd)
        self._dispatch_count += 1

    def reposition(self, addr: str, saved: dict) -> None:
        ws = self.ws_target(saved.get("workspace", {}))
        self._ipc_dispatch(f"movetoworkspacesilent {ws},address:{addr}")

        is_float = bool(saved.get("floating", False))

        if is_float:
            self._wait_for_window_mapped(addr=addr, pid=saved.get("pid"), timeout=0.6)

        target_pos = saved.get("at", [0, 0])
        target_size = saved.get("size", [0, 0])
        fs = saved.get("fullscreenClient", saved.get("fullscreen", 0))

        if not is_float:
            if fs in (1, 2):
                self._ipc_dispatch(f"fullscreen {fs}")
            if saved.get("pinned", False):
                self._ipc_dispatch(f"pin address:{addr}")
            return

        start = time.monotonic()
        interval = 0.08
        while True:
            self._ipc_dispatch(f"setfloating address:{addr}")
            w, h = target_size
            x, y = target_pos
            if w > 0 and h > 0:
                self._ipc_dispatch(f"resizewindowpixel exact {w} {h},address:{addr}")
            self._ipc_dispatch(f"movewindowpixel exact {x} {y},address:{addr}")
            if fs in (1, 2):
                self._ipc_dispatch(f"fullscreen {fs}")
            if saved.get("pinned", False):
                self._ipc_dispatch(f"pin address:{addr}")

            clients = self.get_clients()
            client = next((c for c in clients if c.get("address") == addr), None)
            if client:
                pos = client.get("at", [None, None])
                size = client.get("size", [None, None])
                if list(pos) == list(target_pos) and list(size) == list(target_size):
                    break
            if time.monotonic() - start > 1.2:
                break
            time.sleep(interval)

    def schedule_cleanup(self) -> None:
        if not self._transient_rules:
            return

        count = len(self._transient_rules)

        def _cleanup(delay: float = 15.0) -> None:
            time.sleep(delay)
            try:
                HyprctlWrapper._send("/reload config-only")
            except Exception:
                pass

        threading.Thread(target=_cleanup, daemon=True).start()
        print(f"  ({count} transient rules — config reload in ~15s)")

    @staticmethod
    def _group_rule(client: dict) -> str | None:
        """Return ``"group set"`` if the client was in a tab-group.

        The ``grouped`` list from ``hyprctl clients`` contains >1 address
        when the window was part of a group.  Best-effort / experimental.
        """
        grouped = client.get("grouped", [])
        if len(grouped) > 1:
            return "group set"
        return None

    @staticmethod
    def _inject_exec_rule(cmd: str, rule: str) -> str:
        """Inject a rule into an ``exec [rules] command`` string."""
        if cmd.startswith("exec ["):
            idx = cmd.index("]")
            return cmd[:idx] + "; " + rule + cmd[idx:]
        return cmd
