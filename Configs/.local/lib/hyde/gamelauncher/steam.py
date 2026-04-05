#!/usr/bin/env python3
"""
Steam library inspector for gamelauncher.sh

- Finds Steam library folders (native and flatpak common paths)
- Reads appmanifest_*.acf files to list installed Steam apps
- CLI:
    --detect  -> print list of steam apps directories found (JSON)
    --json    -> print JSON array of games {appid, name, install_dir, header_image}

"""

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import List, Dict
import shutil
import requests


XDG_DATA_HOME = os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local" / "share"))
DEFAULT_STEAM_PATHS = [
    Path(XDG_DATA_HOME) / "Steam",
    Path(
        os.environ.get(
            "XDG_DATA_HOME",
            str(Path.home() / ".var" / "app" / "com.valvesoftware.Steam" / ".local" / "share"),
        )
    )
    / "Steam",
    Path(os.environ.get("XDG_DATA_HOME", str(Path.home() / ".steam"))) / "steam",
]


def find_steam_roots() -> List[Path]:
    roots = []

    for p in DEFAULT_STEAM_PATHS:
        if str(p).startswith("${"):
            continue
        if p.exists():
            roots.append(p)

    extra = []
    for base in [
        Path.home() / ".local" / "share" / "Steam",
        Path.home() / ".var" / "app" / "com.valvesoftware.Steam" / ".local" / "share" / "Steam",
    ]:
        vdf = base / "steamapps" / "libraryfolders.vdf"
        if vdf.exists():
            extra.append((base, vdf))

    for base, vdf in extra:
        roots.append(base)
        try:
            txt = vdf.read_text(errors="ignore")

            for m in re.finditer(r'"path"\s*"([^"]+)"', txt):
                raw = m.group(1)

                raw = raw.replace("\\\\", "\\")
                p = Path(raw)
                if p.exists():
                    roots.append(p)
                else:
                    candidate = Path(os.path.expanduser(raw))
                    if candidate.exists():
                        roots.append(candidate)
                    else:
                        alt = candidate / "steamapps"
                        if alt.exists():
                            roots.append(candidate)
        except Exception:
            pass

    seen = set()
    out = []
    for r in roots:
        r = r.resolve()
        if r in seen:
            continue
        seen.add(r)
        steamapps = r / "steamapps"
        if steamapps.exists():
            out.append(steamapps)
    return out


def parse_acf(acf_path: Path) -> Dict:
    data = {"appid": None, "name": None}
    try:
        txt = acf_path.read_text(errors="ignore")
        m_id = re.search(r'"appid"\s*"(\d+)"', txt)
        m_name = re.search(r'"name"\s*"([^"]+)"', txt)
        if m_id:
            data["appid"] = int(m_id.group(1))
        if m_name:
            data["name"] = m_name.group(1)
    except Exception:
        pass
    return data


def fetch_icon(appid: int, cache_dir: Path) -> str:
    """Fetch the icon from Steam and save it to the cache directory."""
    icon_url = f"https://cdn.cloudflare.steamstatic.com/steam/apps/{appid}/header.jpg"
    icon_path = cache_dir / f"steam_{appid}.jpg"

    if not icon_path.is_file():
        try:
            response = requests.get(icon_url, timeout=10)
            if response.status_code == 200:
                icon_path.parent.mkdir(parents=True, exist_ok=True)
                with open(icon_path, "wb") as f:
                    f.write(response.content)
                print(f"Fetched icon for AppID {appid} and saved to {icon_path}", file=sys.stderr)
            else:
                print(f"Failed to fetch icon for AppID {appid}: HTTP {response.status_code}", file=sys.stderr)
        except Exception as e:
            print(f"Error fetching icon for AppID {appid}: {e}", file=sys.stderr)
    return str(icon_path) if icon_path.is_file() else ""


def should_exclude_game(name: str) -> bool:
    """Determine if a game should be excluded based on its name."""
    return (
        re.search(r"(?i)\b(proton|steam runtime|steamworks|steam client|steam)\b", name) is not None
    )


def list_games(steamapps_dirs: List[Path], fetch_icons: bool = False) -> List[Dict]:
    games = []
    xdg_cache = Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache")))
    cache_dir = xdg_cache / "hyde" / "gamelauncher"

    # Collect all unique appcache/librarycache dirs across all Steam roots
    librarycache_roots: List[Path] = []
    seen_lc: set = set()
    for sa in steamapps_dirs:
        lc = sa.parent / "appcache" / "librarycache"
        if lc not in seen_lc:
            seen_lc.add(lc)
            if lc.is_dir():
                librarycache_roots.append(lc)

    def find_header(appid: int) -> str | None:
        """Search all known librarycache roots for a portrait cover image for appid.

        Lookup is phased globally across all roots so a portrait asset in any
        root beats a landscape asset in any other root.

        Priority (best for portrait card UI):
          1. library_600x900.jpg  — old flat structure, explicit portrait
          2. library_capsule.jpg  — new hashed-subdir structure, ~300x450 portrait
          3. library_hero.jpg     — landscape fallback (flat or hashed subdir)
          4. header.jpg           — landscape fallback (flat or hashed subdir)
        Small thumbnails (.jpg files directly in the appid dir) are skipped.
        OSError on iterdir() for a given cache dir is treated as a miss.
        """
        # Collect (appid_dir, subdirs) pairs once, skipping unreadable dirs.
        candidates: list[tuple[Path, list[Path]]] = []
        for lc in librarycache_roots:
            appid_dir = lc / str(appid)
            if not appid_dir.is_dir():
                continue
            try:
                subdirs = sorted(d for d in appid_dir.iterdir() if d.is_dir())
            except OSError:
                subdirs = []
            candidates.append((appid_dir, subdirs))

        # Phase 1 — flat portrait (library_600x900.jpg / library_capsule.jpg)
        for appid_dir, _ in candidates:
            for name in ("library_600x900.jpg", "library_capsule.jpg"):
                c = appid_dir / name
                if c.is_file():
                    return str(c)

        # Phase 2 — hashed-subdir portrait
        for _, subdirs in candidates:
            for subdir in subdirs:
                for name in ("library_capsule.jpg", "library_600x900.jpg"):
                    c = subdir / name
                    if c.is_file():
                        return str(c)

        # Phase 3 — library_hero.jpg (flat then hashed)
        for appid_dir, subdirs in candidates:
            c = appid_dir / "library_hero.jpg"
            if c.is_file():
                return str(c)
            for subdir in subdirs:
                c = subdir / "library_hero.jpg"
                if c.is_file():
                    return str(c)

        # Phase 4 — header.jpg (flat then hashed)
        for appid_dir, subdirs in candidates:
            c = appid_dir / "header.jpg"
            if c.is_file():
                return str(c)
            for subdir in subdirs:
                c = subdir / "header.jpg"
                if c.is_file():
                    return str(c)

        return None

    for sa in steamapps_dirs:
        try:
            for p in sa.glob("appmanifest_*.acf"):
                info = parse_acf(p)
                if not info.get("appid") or should_exclude_game(info.get("name", "")):
                    continue
                appid = info["appid"]
                name = info.get("name") or ""

                header = find_header(appid)

                if not header:
                    cached_icon = cache_dir / f"steam_{appid}.jpg"
                    if cached_icon.is_file():
                        header = str(cached_icon)
                if not header and fetch_icons:
                    header = fetch_icon(appid, cache_dir)

                rofi_string = f"{name}\x00icon\x1f{header}" if header else name

                games.append(
                    {
                        "appid": appid,
                        "name": name,
                        "install_dir": str(sa),
                        "header": header,
                        "rofi_string": rofi_string,
                    }
                )
        except Exception as e:
            print(f"Error processing {sa}: {e}")
            continue
    return games


def fetch_all_icons(steamapps_dirs: List[Path]) -> None:
    """Fetch icons for all games in the Steam libraries, excluding unwanted entries."""
    xdg_cache = Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache")))
    cache_dir = xdg_cache / "hyde" / "gamelauncher"

    for sa in steamapps_dirs:
        try:
            for p in sa.glob("appmanifest_*.acf"):
                info = parse_acf(p)
                if not info.get("appid") or should_exclude_game(info.get("name", "")):
                    continue
                appid = info["appid"]
                fetch_icon(appid, cache_dir)
        except Exception as e:
            print(f"Error processing {sa}: {e}")
            continue


def detect_launch_cmd() -> str:
    """Detect how to launch Steam on this system.

    Returns a shell command string suitable for exec/launch, e.g. 'steam' or
    'flatpak run com.valvesoftware.Steam'. Always prefer the native `steam`
    binary when present, otherwise fall back to the common flatpak invocation.
    """

    if shutil.which("steam"):
        return "steam"

    flatpak_dir = Path.home() / ".var" / "app" / "com.valvesoftware.Steam"
    if flatpak_dir.exists():
        if shutil.which("flatpak"):
            return "flatpak run com.valvesoftware.Steam"

    return "steam"


def main(argv=None):
    p = argparse.ArgumentParser(allow_abbrev=False)
    p.add_argument("--detect", action="store_true", help="Print detected Steam library paths")
    p.add_argument("--json", action="store_true", help="Print JSON list of games")
    p.add_argument(
        "--rofi-string",
        action="store_true",
        help="Output rofi-formatted strings for games",
    )
    p.add_argument("--fetch-icons", action="store_true", help="Fetch missing icons from Steam")
    args = p.parse_args(argv)

    roots = find_steam_roots()

    if args.detect:
        print(json.dumps([str(p) for p in roots]))
        return 0

    if not roots:
        print(json.dumps({"error": "No Steam libraries found"}))
        return 1

    if args.fetch_icons:
        fetch_all_icons(roots)
        print("Icons fetched successfully.")
        return 0

    games = list_games(roots, fetch_icons=args.fetch_icons)

    result = []
    for g in games:
        g2 = {
            "id": g["appid"],
            "name": g["name"],
            "slug": g["name"].lower().replace(" ", "-"),
            "runner": "steam",
            "path": g["install_dir"],
            "icon": g["header"],
            "cover": g["header"],
            "run_command": f"xdg-open steam://rungameid/{g['appid']}",
            "rofi_string": f"{g['name']}\txdg-open steam://rungameid/{g['appid']}\t\x00icon\x1f{g['header']}"
            if g["header"]
            else f"{g['name']}\txdg-open steam://rungameid/{g['appid']}",
        }
        result.append(g2)

    if args.json:
        print(json.dumps(result, indent=4))
        return 0

    if args.rofi_string:
        for g in result:
            print(g["rofi_string"])
        return 0

    print("No valid arguments provided. Use --detect, --json, --rofi-string, or --fetch-icons.")
    return 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as e:
        print(f"Unhandled exception: {e}")
