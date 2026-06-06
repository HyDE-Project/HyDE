import json
import os
from functools import lru_cache
from pathlib import Path


def _normalize_locale(lang: str | None) -> str:
    lang = (lang or "en").split(".", 1)[0].split("@", 1)[0]

    if lang in {"zh", "zh_CN", "zh_SG"}:
        return "zh_CN"
    if lang in {"zh_TW", "zh_HK", "zh_MO"}:
        return "zh_TW"
    if lang in {"", "C", "POSIX"}:
        return "en"
    return lang


def _language() -> str:
    return _normalize_locale(
        os.getenv("HYDE_LANG")
        or os.getenv("I18N_LANGUAGE")
        or os.getenv("LC_MESSAGES")
        or os.getenv("LANG")
        or "en"
    )


def _base_dir() -> Path:
    share_dir = os.getenv("SHARE_DIR")
    if share_dir:
        return Path(share_dir) / "hyde" / "i18n"

    xdg_data_home = os.getenv("XDG_DATA_HOME")
    if xdg_data_home:
        return Path(xdg_data_home) / "hyde" / "i18n"

    return Path.home() / ".local" / "share" / "hyde" / "i18n"


@lru_cache(maxsize=None)
def _load(lang: str) -> dict[str, str]:
    path = _base_dir() / f"{lang}.json"
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError):
        return {}
    return {key: value for key, value in data.items() if isinstance(value, str)}


def t(key: str, default: str | None = None, *args: object) -> str:
    msg = _load(_language()).get(key) or _load("en").get(key) or default or key
    if not args:
        return msg

    try:
        return msg % args
    except (TypeError, ValueError):
        return msg
