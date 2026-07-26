"""Brave browser plugin — Flatpak-aware restore via transient windowrules.

Brave runs as a Flatpak (``com.brave.Browser``) which **forks**, so
Hyprland's PID-based exec-rule tracking doesn't work.  This plugin
uses transient named windowrules matched by ``initialClass`` instead.

The windowrule is cleaned up after restore via a config-only reload
(handled by session.py's main cleanup logic).
"""

import sys
from pathlib import Path

# Add project root for imports
_here = str(Path(__file__).resolve().parent.parent.parent)
if _here not in sys.path:
    sys.path.insert(0, _here)

from pyutils.compositor import HyprctlWrapper  # noqa: E402
from session.compositor.hyprland import HyprlandBackend  # noqa: E402

MATCH_CLASSES = {"brave-browser"}
PRIORITY = 30

# Counter for unique rule names across multiple brave windows
_rule_counter = 0


def _ipc_eval(code: str) -> str:
    return HyprctlWrapper._send(f"/eval {code}")


def _apply_window_rule(rule_name: str, client: dict, ws_target: str) -> None:
    backend = HyprlandBackend()
    rule = backend._lua_window_rule(rule_name, client, ws_target)
    _ipc_eval(f"hl.window_rule({HyprlandBackend._lua_table(rule)})")


def build_restore_cmd(client: dict, ws_target: str) -> str | None:
    """Restore Brave via transient windowrule + plain exec.

    Sets a named windowrule that matches ``initial_class = brave-browser``
    and assigns the workspace, then launches ``flatpak run com.brave.Browser``.

    Returns the plain ``exec`` dispatch string (no bracket rules — the
    windowrule handles placement).
    """
    global _rule_counter
    command = client.get("_launchString") or "flatpak run com.brave.Browser"
    rule_name = f"_hydesession_brave_{_rule_counter}"
    _rule_counter += 1

    try:
        _apply_window_rule(rule_name, client, ws_target)
    except Exception as exc:
        print(f"  [plugin:brave] windowrule setup failed: {exc}", file=sys.stderr)
        return None

    # Return plain exec (no bracket rules) — windowrule handles placement
    return f"exec {command}"
