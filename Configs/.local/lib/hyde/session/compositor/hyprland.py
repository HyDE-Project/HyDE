from __future__ import annotations
import os
import socket
import json
import subprocess
import time
from pyutils.compositor import HyprctlWrapper

"""Hyprland compositor backend for session save/restore."""


class HyprlandBackend:
    @staticmethod
    def _lua_quote(value: str) -> str:
        return json.dumps(str(value), ensure_ascii=False)

    @classmethod
    def _lua_value(cls, value) -> str:
        if isinstance(value, str) and value.startswith("__RAW__"):
            return value[len("__RAW__") :]
        if isinstance(value, bool):
            return "true" if value else "false"
        if isinstance(value, (int, float)):
            return str(value)
        if isinstance(value, (list, tuple)):
            return "{ " + ", ".join(cls._lua_value(v) for v in value) + " }"
        if isinstance(value, dict):
            return cls._lua_table(value)
        return cls._lua_quote(value)

    @classmethod
    def _lua_table(cls, values: dict) -> str:
        parts = []
        for key, value in values.items():
            if value is None:
                continue
            parts.append(f"{key} = {cls._lua_value(value)}")
        return "{ " + ", ".join(parts) + " }"

    @staticmethod
    def _lua_config(path: str, value: bool | int | str) -> str:
        keys = path.split(":")
        lua_value = "true" if value is True else "false" if value is False else str(value)
        expr = lua_value
        for key in reversed(keys[1:]):
            expr = f"{{ {key} = {expr} }}"
        return f"hl.config({{ {keys[0]} = {expr} }})"

    @classmethod
    def _lua_client_expr(cls, addr: str) -> str:
        return f"hl.get_window({cls._lua_quote(f'address:{addr}')})"

    @classmethod
    def _lua_window_args(cls, addr: str, values: dict) -> str:
        args = {"window": f"__RAW__{cls._lua_client_expr(addr)}"}
        args.update(values)
        return cls._lua_table(args)

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
    def _ipc_eval(code: str) -> str:
        return HyprctlWrapper._send(f"/eval {code}")

    def _lua_exec_cmd(self, command: str, rules: dict | None = None) -> str:
        if rules:
            return self._ipc_eval(
                "hl.dispatch(hl.dsp.exec_cmd("
                + self._lua_quote(command)
                + ", "
                + self._lua_table(rules)
                + "))"
            )
        return self._ipc_eval(f"hl.dispatch(hl.dsp.exec_cmd({self._lua_quote(command)}))")

    def _lua_dispatch(self, dispatcher: str) -> str:
        return self._ipc_eval(f"hl.dispatch({dispatcher})")

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
        if "bool" in opt:
            self._animations_prev = 1 if opt.get("bool") else 0
        else:
            self._animations_prev = int(opt.get("int", 1))

        try:
            self._set_config("animations:enabled", False)
        except Exception:
            pass

    def end_restore(self) -> None:
        """Restore animations setting if begin_restore changed it."""
        if self._animations_prev is None:
            return
        try:
            self._set_config("animations:enabled", bool(self._animations_prev))
        except Exception:
            pass
        finally:
            self._animations_prev = None

    def _set_config(self, path: str, value: bool | int | str) -> None:
        self._ipc_eval(self._lua_config(path, value))

    def get_clients(self) -> list[dict]:
        return self._ipc_json("clients")

    def get_workspaces(self) -> list[dict]:
        return self._ipc_json("workspaces")

    def get_monitors(self) -> list[dict]:
        return self._ipc_json("monitors")

    def multiwindow_key(self, client: dict) -> tuple[int, int] | int | None:
        pid = client.get("pid", 0)
        if pid <= 0:
            return None
        ws_id = client.get("workspace", {}).get("id", 0)
        return (pid, ws_id)

    def append_multiwindow_metadata(self, rep: dict, client: dict) -> None:
        candidates = rep.setdefault("_p_window_candidates", [])
        candidates.append(
            {
                "address": client.get("address", ""),
                "class": client.get("class", ""),
                "initialClass": client.get("initialClass", ""),
                "title": client.get("title", ""),
                "initialTitle": client.get("initialTitle", ""),
                "workspace": client.get("workspace", {}),
                "at": client.get("at", [0, 0]),
                "size": client.get("size", [0, 0]),
                "floating": client.get("floating", False),
                "fullscreen": client.get("fullscreen", 0),
                "fullscreenClient": client.get("fullscreenClient", 0),
                "pinned": client.get("pinned", False),
                "pseudo": client.get("pseudo", False),
                "grouped": client.get("grouped", []),
                "monitor": client.get("monitor"),
            }
        )

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

    def restore_sort_key(self, client: dict) -> tuple:
        workspace = client.get("workspace", {})
        ws_id = workspace.get("id", 0)
        at = client.get("at", [0, 0])
        if not isinstance(at, (list, tuple)) or len(at) < 2:
            at = [0, 0]
        x = at[0] if isinstance(at[0], (int, float)) else 0
        y = at[1] if isinstance(at[1], (int, float)) else 0
        return (ws_id, x, y, client.get("_p_window_index", 0), client.get("focusHistoryID", 0))

    def _monitor_info(self, client: dict) -> dict:
        monitor_id = client.get("monitor")
        if monitor_id is None:
            return {}

        for mon in self.get_monitors():
            if mon.get("id") == monitor_id:
                return mon
            if str(mon.get("id")) == str(monitor_id):
                return mon
            if mon.get("name") == monitor_id:
                return mon
            if str(mon.get("name")) == str(monitor_id):
                return mon

        return {}

    def _local_move(self, client: dict) -> tuple[int, int] | None:
        at = client.get("at", [0, 0])
        if not isinstance(at, (list, tuple)) or len(at) < 2:
            return None
        monitor = self._monitor_info(client)
        if not monitor:
            return (at[0], at[1])
        mx = monitor.get("x", 0)
        my = monitor.get("y", 0)
        return (at[0] - mx, at[1] - my)

    def _monitor_target(self, client: dict) -> str | None:
        monitor = self._monitor_info(client)
        if not monitor:
            monitor_id = client.get("monitor")
            return str(monitor_id) if monitor_id is not None else None
        return monitor.get("name") or str(monitor.get("id", ""))

    def _build_lua_exec_rules(self, client: dict, ws_target: str) -> dict:
        """Build rules for ``hl.dsp.exec_cmd(command, rules)``."""
        rules: dict = {"workspace": f"{ws_target} silent"}

        monitor_target = self._monitor_target(client)
        if monitor_target is not None:
            rules["monitor"] = monitor_target

        if client.get("floating", False):
            move = self._local_move(client)
            w, h = client.get("size", [0, 0])
            rules["float"] = True
            if w > 0 and h > 0:
                rules["size"] = [w, h]
            if move is not None:
                rules["move"] = [move[0], move[1]]

        if client.get("pseudo", False):
            rules["pseudo"] = True
        if client.get("pinned", False):
            rules["pin"] = True

        fs = client.get("fullscreenClient", client.get("fullscreen", 0))
        if fs in (1, 2):
            rules["fullscreen"] = True

        grouped = client.get("grouped", [])
        if len(grouped) > 1:
            rules["group"] = "set"

        return rules

    def launch(self, command: str, client: dict, ws_target: str) -> None:
        self._lua_exec_cmd(command, self._build_lua_exec_rules(client, ws_target))
        self._dispatch_count += 1

    def launch_forking(self, command: str, client: dict, ws_target: str) -> None:
        rule_name = f"_hydesession_{self._dispatch_count}"

        if self._apply_transient_rule(rule_name, client, ws_target):
            self._transient_rules.append(rule_name)
            self._lua_exec_cmd(command)
            self._dispatch_count += 1
            return

        self._lua_exec_cmd(command)
        self._dispatch_count += 1

    def _apply_transient_rule(self, rule_name: str, client: dict, ws_target: str) -> bool:
        initial_class = client.get("initialClass", "")
        if not initial_class:
            return False

        rule = self._lua_window_rule(rule_name, client, ws_target)
        self._ipc_eval(f"hl.window_rule({self._lua_table(rule)})")
        return True

    def _lua_window_rule(self, rule_name: str, client: dict, ws_target: str) -> dict:
        rule = {
            "name": rule_name,
            "match": {"initial_class": client.get("initialClass", "")},
            "workspace": f"{ws_target} silent",
        }

        monitor_target = self._monitor_target(client)
        if monitor_target is not None:
            rule["monitor"] = monitor_target

        if client.get("floating", False):
            move = self._local_move(client)
            w, h = client.get("size", [0, 0])
            rule["float"] = True
            if w > 0 and h > 0:
                rule["size"] = f"{w} {h}"
            if move is not None:
                rule["move"] = f"{move[0]} {move[1]}"

        if client.get("pseudo", False):
            rule["pseudo"] = True
        if client.get("pinned", False):
            rule["pin"] = True

        fs = client.get("fullscreenClient", client.get("fullscreen", 0))
        if fs in (1, 2):
            rule["fullscreen"] = True

        grouped = client.get("grouped", [])
        if len(grouped) > 1:
            rule["group"] = "set"

        return rule

    def dispatch_plugin_cmd(self, cmd: str, client: dict) -> None:
        command = self._command_from_exec_dispatch(cmd)
        if command:
            ws_target = self.ws_target(client.get("workspace", {}))
            self._lua_exec_cmd(command, self._build_lua_exec_rules(client, ws_target))
        else:
            self._lua_dispatch(self._legacy_dispatch_to_lua(cmd))
        self._dispatch_count += 1

    def reposition(self, addr: str, saved: dict) -> None:
        ws = self.ws_target(saved.get("workspace", {}))
        self._lua_dispatch(
            "hl.dsp.window.move("
            + self._lua_window_args(addr, {"workspace": ws, "follow": False})
            + ")"
        )

        is_float = bool(saved.get("floating", False))

        if is_float:
            self._wait_for_window_mapped(addr=addr, pid=saved.get("pid"), timeout=0.6)

        target_pos = saved.get("at", [0, 0])
        target_size = saved.get("size", [0, 0])
        fs = saved.get("fullscreenClient", saved.get("fullscreen", 0))

        if not is_float:
            x, y = target_pos
            if x is not None and y is not None:
                self._lua_dispatch(
                    "hl.dsp.window.move("
                    + self._lua_window_args(addr, {"x": x, "y": y, "exact": True})
                    + ")"
                )

            if fs in (1, 2):
                self._lua_dispatch(
                    "hl.dsp.window.fullscreen_state("
                    + self._lua_window_args(addr, {"internal": fs, "client": fs})
                    + ")"
                )
            if saved.get("pinned", False):
                self._lua_dispatch(
                    "hl.dsp.window.pin(" + self._lua_window_args(addr, {}) + ")"
                )
            return

        start = time.monotonic()
        interval = 0.08
        while True:
            self._lua_dispatch(
                "hl.dsp.window.float("
                + self._lua_window_args(addr, {"action": "set"})
                + ")"
            )
            w, h = target_size
            x, y = target_pos
            if w > 0 and h > 0:
                self._lua_dispatch(
                    "hl.dsp.window.resize("
                    + self._lua_window_args(addr, {"x": w, "y": h, "exact": True})
                    + ")"
                )
            self._lua_dispatch(
                "hl.dsp.window.move("
                + self._lua_window_args(addr, {"x": x, "y": y, "exact": True})
                + ")"
            )
            if fs in (1, 2):
                self._lua_dispatch(
                    "hl.dsp.window.fullscreen_state("
                    + self._lua_window_args(addr, {"internal": fs, "client": fs})
                    + ")"
                )
            if saved.get("pinned", False):
                self._lua_dispatch(
                    "hl.dsp.window.pin(" + self._lua_window_args(addr, {}) + ")"
                )

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

    @staticmethod
    def _command_from_exec_dispatch(cmd: str) -> str | None:
        stripped = cmd.strip()
        if not stripped.startswith("exec "):
            return None
        rest = stripped[len("exec ") :].lstrip()
        if rest.startswith("["):
            end = rest.find("]")
            if end < 0:
                return None
            rest = rest[end + 1 :].lstrip()
        return rest or None

    @classmethod
    def _legacy_dispatch_to_lua(cls, cmd: str) -> str:
        stripped = cmd.strip()
        if " " not in stripped:
            return f"hl.dsp.{stripped}()"
        dispatcher, arg = stripped.split(" ", 1)
        return f"hl.dsp.{dispatcher}({cls._lua_quote(arg)})"

    def schedule_cleanup(self) -> None:
        if not self._transient_rules:
            return

        count = len(self._transient_rules)

        subprocess.Popen(
            ["sh", "-c", "sleep 15; hyprctl reload config-only >/dev/null 2>&1"],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
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
