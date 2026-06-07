import gettext
import os
from functools import lru_cache
from pathlib import Path

DOMAIN = "hyde"


def _normalize_locale(lang: str | None) -> str:
    lang = (lang or "en").split(":", 1)[0].split(".", 1)[0].split("@", 1)[0]
    lang = lang.replace("-", "_")
    lowered = lang.lower()

    if lowered in {"", "c", "posix"}:
        return "en"
    if lowered in {"zh", "zh_cn", "zh_sg"}:
        return "zh_CN"
    return lang


def _language() -> str:
    return _normalize_locale(
        os.getenv("HYDE_LANG")
        or os.getenv("I18N_LANGUAGE")
        or os.getenv("LC_MESSAGES")
        or os.getenv("LANG")
        or "en"
    )


def _locale_dir() -> Path:
    share_dir = os.getenv("SHARE_DIR")
    if share_dir:
        return Path(share_dir) / "hyde" / "locale"

    return Path(os.getenv("XDG_DATA_HOME", Path.home() / ".local/share")) / "hyde" / "locale"


@lru_cache(maxsize=None)
def _translation(lang: str) -> gettext.NullTranslations:
    try:
        return gettext.translation(
            DOMAIN,
            localedir=str(_locale_dir()),
            languages=[lang],
            fallback=True,
        )
    except Exception:
        return gettext.NullTranslations()


def t(message: str, default: str | None = None, *args: object) -> str:
    translated = _translation(_language()).gettext(message)
    if translated == message and default is not None:
        translated = default

    if not args:
        return translated

    try:
        return translated % args
    except (TypeError, ValueError):
        return translated
