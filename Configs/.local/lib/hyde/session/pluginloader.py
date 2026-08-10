"""Plugin loader and registry for session.py.

Plugins are Python modules under session/plugins/.
Each plugin declares MATCH_CLASSES and optional hooks for save/restore.
"""

import importlib
import os
import sys
from pathlib import Path
from types import ModuleType

_PLUGIN_DIR = Path(__file__).parent / "plugins"


class _PluginEntry:
    __slots__ = ("name", "module", "match_classes", "priority")

    def __init__(self, name: str, module: ModuleType):
        self.name = name
        self.module = module
        self.match_classes: set[str] = {c.lower() for c in getattr(module, "MATCH_CLASSES", set())}
        self.priority: int = getattr(module, "PRIORITY", 50)


_plugins: list[_PluginEntry] = []
_loaded = False


def load_plugins() -> list[_PluginEntry]:
    """Discover and import all ``*.py`` files in ``session/plugins/``.

    Safe to call multiple times; only loads once.
    """
    global _loaded
    if _loaded:
        return _plugins

    if not _PLUGIN_DIR.is_dir():
        _loaded = True
        return _plugins

    plugin_parent = str(_PLUGIN_DIR.parent)
    if plugin_parent not in sys.path:
        sys.path.insert(0, plugin_parent)

    for py_file in sorted(_PLUGIN_DIR.glob("*.py")):
        if py_file.name.startswith("_"):
            continue
        mod_name = f"session.plugins.{py_file.stem}"
        try:
            mod = importlib.import_module(mod_name)
            entry = _PluginEntry(py_file.stem, mod)
            if entry.match_classes:
                _plugins.append(entry)
        except Exception as exc:
            print(
                f"  [plugin] failed to load {py_file.name}: {exc}",
                file=sys.stderr,
            )

    _plugins.sort(key=lambda p: p.priority)
    _loaded = True
    return _plugins


def find_plugin(initial_class: str) -> _PluginEntry | None:
    """Return the highest-priority plugin that matches *initial_class*."""
    key = initial_class.lower()
    for p in _plugins:
        if key in p.match_classes:
            return p
    return None


def call_save_enrich(plugin: _PluginEntry, client: dict, pid: int) -> dict:
    """Call plugin's ``save_enrich`` if it exists, returning extra keys."""
    fn = getattr(plugin.module, "save_enrich", None)
    if fn is None:
        return {}
    try:
        return fn(client, pid) or {}
    except Exception as exc:
        print(
            f"  [plugin:{plugin.name}] save_enrich error: {exc}",
            file=sys.stderr,
        )
        return {}


def call_build_restore_cmd(plugin: _PluginEntry, client: dict, ws_target: str) -> str | None:
    """Call plugin's ``build_restore_cmd`` if it exists."""
    fn = getattr(plugin.module, "build_restore_cmd", None)
    if fn is None:
        return None
    try:
        return fn(client, ws_target)
    except Exception as exc:
        print(
            f"  [plugin:{plugin.name}] build_restore_cmd error: {exc}",
            file=sys.stderr,
        )
        return None


def call_match_running(plugin: _PluginEntry, saved: dict, running: dict) -> bool | None:
    """Call plugin's running-window matching hook if it exists.

    Returns ``True`` (match), ``False`` (not a match), or ``None`` if
    the plugin does not implement the hook (caller should fall back to
    default class-based matching).

    Preferred hook name is ``match_running``.
    """
    fn = getattr(plugin.module, "match_running", None)
    if fn is None:
        return None
    try:
        return fn(saved, running)
    except Exception as exc:
        print(
            f"  [plugin:{plugin.name}] match hook error: {exc}",
            file=sys.stderr,
        )
        return None
