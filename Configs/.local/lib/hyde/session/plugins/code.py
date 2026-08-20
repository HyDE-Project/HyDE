"""VS Code plugin — restore project folders to correct workspaces.

VS Code runs all windows under a single process, so every window
reports the same PID.  This plugin:

- Sets ``MULTI_WINDOW`` so ``save()`` keeps one entry per workspace
  instead of collapsing all Code windows into one.
- Extracts the project name from the window title.
- Resolves the full folder path from VS Code's ``workspaceStorage``.
- Restores each window with ``code /path/to/folder``.
- Matches live windows by project name for ``--live`` mode.
"""

import json
import os
import re
import shlex
from pathlib import Path
from urllib.parse import unquote, urlparse

MATCH_CLASSES = {"code", "code-url-handler", "codium", "code - oss"}
PRIORITY = 40
MULTI_WINDOW = True

# VS Code config dirs to scan (official, OSS, Codium)
_CONFIG_DIRS = ("Code", "Code - OSS", "VSCodium")

# Cached {project_name: folder_path} — case-sensitive first, with
# a secondary case-insensitive lookup for resilience.
_folder_cache: dict[str, str] | None = None
_folder_cache_lower: dict[str, str] | None = None

# Title markers for different VS Code flavours
_TITLE_MARKERS = (
    " - Visual Studio Code",
    " - Code - OSS",
    " - VSCodium",
)


def _normalize_project_name(name: str) -> str:
    """Normalize VS Code project names extracted from window titles."""
    name = name.strip()
    if not name:
        return name

    # VS Code may append workspace markers like " (Workspace)" or " (Workspace 1)".
    # Strip those so the project name can resolve to the actual folder name.
    if name.endswith(")"):
        normalized = re.sub(r"\s*\(Workspace(?: \d+)?\)$", "", name)
        if normalized != name:
            name = normalized.strip()

    return name


def _title_project(title: str) -> str | None:
    """Extract the project/folder name from a VS Code window title.

    Patterns:
      ``file.py - PROJECT - Visual Studio Code``
      ``PROJECT - Visual Studio Code``
    """
    for marker in _TITLE_MARKERS:
        idx = title.rfind(marker)
        if idx == -1:
            continue
        prefix = title[:idx]
        # The project name is the last segment before the marker
        parts = prefix.rsplit(" - ", 1)
        name = _normalize_project_name(parts[-1])
        return name if name else None
    return None


def _load_folder_cache() -> dict[str, str]:
    """Build {name: path} from VS Code's workspaceStorage."""
    global _folder_cache, _folder_cache_lower
    if _folder_cache is not None:
        return _folder_cache

    _folder_cache = {}
    _folder_cache_lower = {}
    config_base = Path.home() / ".config"

    for config_dir in _CONFIG_DIRS:
        ws_dir = config_base / config_dir / "User" / "workspaceStorage"
        if not ws_dir.is_dir():
            continue
        for sub in ws_dir.iterdir():
            ws_json = sub / "workspace.json"
            if not ws_json.is_file():
                continue
            try:
                data = json.loads(ws_json.read_text())
                uri = data.get("folder", "")
                if not uri.startswith("file://"):
                    continue
                path = unquote(urlparse(uri).path)
                name = Path(path).name
                _folder_cache.setdefault(name, path)
                _folder_cache_lower.setdefault(name.lower(), path)
            except (json.JSONDecodeError, OSError):
                pass

    return _folder_cache


def _resolve_folder(project: str) -> str | None:
    """Resolve a project name to a folder path (case-sensitive first)."""
    cache = _load_folder_cache()
    # Exact case match — distinguishes 'hyde' from 'HyDE'
    folder = cache.get(project)
    if folder:
        return folder
    # Case-insensitive fallback
    assert _folder_cache_lower is not None
    return _folder_cache_lower.get(project.lower())


def save_enrich(client: dict, pid: int) -> dict:
    """Extract the VS Code workspace folder from the window title."""
    extra: dict = {}

    title = client.get("title", "")
    project = _title_project(title)
    if not project:
        return extra

    extra["_p_project"] = project

    folder = _resolve_folder(project)
    if folder and Path(folder).is_dir():
        extra["_p_folder"] = folder

    return extra


def build_restore_cmd(client: dict, ws_target: str) -> str | None:
    """Launch VS Code with the project folder."""
    folder = client.get("_p_folder")
    base_cmd = client.get("_launchString", "/usr/bin/code")

    candidate_windows = client.get("_p_window_candidates", [])
    count = len(candidate_windows) if isinstance(candidate_windows, list) else 1
    if count <= 0:
        count = 1

    launch_cmds = []
    for _ in range(count):
        parts = [base_cmd]
        if folder and Path(folder).is_dir():
            parts.append("--new-window")
            parts.append(shlex.quote(folder))
        launch_cmds.append(" ".join(parts))

    cmd = " ; ".join(launch_cmds)
    if not cmd:
        return None

    # Delay the Code launch slightly so workspace targeting has time to settle
    # in the compositor before the first window appears.
    return f"exec [workspace {ws_target} silent] sh -c {shlex.quote(f'sleep 0.4; {cmd}') }"


def match_running(saved: dict, live: dict) -> bool | None:
    """Match VS Code windows by project title and, when available, workspace."""
    saved_project = saved.get("_p_project", "").lower()
    if not saved_project:
        return True  # no project info, accept any

    live_title = live.get("title", "")
    live_project = _title_project(live_title)
    if not live_project or live_project.lower() != saved_project:
        return False

    saved_ws = saved.get("workspace", {})
    live_ws = live.get("workspace", {})
    if saved_ws and live_ws:
        if saved_ws.get("id") == live_ws.get("id"):
            return True
        if saved_ws.get("name") == live_ws.get("name"):
            return True
        return None

    return True
