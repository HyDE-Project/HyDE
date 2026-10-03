#!/usr/bin/env python

import os
import sys
import json
import html
import math
import unicodedata
from datetime import datetime
from pathlib import Path
import locale
from typing import TypeAlias, TypedDict, Literal, cast

import requests


TempUnit: TypeAlias = Literal["c", "f"]
TimeFormat: TypeAlias = Literal["12h", "24h"]
WindUnit: TypeAlias = Literal["km/h", "mph"]


class TextValue(TypedDict):
    value: str


class AstronomyEntry(TypedDict):
    sunrise: str
    sunset: str


class CurrentCondition(TypedDict):
    weatherCode: str
    weatherDesc: list[TextValue]
    temp_C: str
    temp_F: str
    FeelsLikeC: str
    FeelsLikeF: str
    windspeedKmph: str
    windspeedMiles: str
    humidity: str
    localObsDateTime: str


class HourlyPoint(TypedDict):
    weatherCode: str
    weatherDesc: list[TextValue]
    tempC: str
    tempF: str
    FeelsLikeC: str
    FeelsLikeF: str
    windspeedKmph: str
    windspeedMiles: str
    time: str
    chanceoffog: str
    chanceoffrost: str
    chanceofovercast: str
    chanceofrain: str
    chanceofsnow: str
    chanceofsunshine: str
    chanceofthunder: str
    chanceofwindy: str


class WeatherDay(TypedDict):
    date: str
    maxtempC: str
    maxtempF: str
    mintempC: str
    mintempF: str
    astronomy: list[AstronomyEntry]
    hourly: list[HourlyPoint]


class NearestArea(TypedDict):
    areaName: list[TextValue]
    country: list[TextValue]


class WttrResponse(TypedDict):
    current_condition: list[CurrentCondition]
    weather: list[WeatherDay]
    nearest_area: list[NearestArea]


### Constants ###
WEATHER_CODES = {
    **dict.fromkeys(["113"], "☀️ "),
    **dict.fromkeys(["116"], "⛅ "),
    **dict.fromkeys(["119", "122", "143", "149", "248", "260"], "☁️ "),
    **dict.fromkeys(
        [
            "176",
            "179",
            "182",
            "185",
            "263",
            "266",
            "281",
            "284",
            "293",
            "296",
            "299",
            "302",
            "305",
            "308",
            "311",
            "314",
            "317",
            "350",
            "353",
            "356",
            "359",
            "362",
            "365",
            "368",
            "392",
        ],
        "🌧️ ",
    ),
    **dict.fromkeys(["200"], "⛈️ "),
    **dict.fromkeys(["227", "230", "320", "323", "326", "374", "377", "386", "389"], "🌨️ "),
    **dict.fromkeys(["329", "332", "335", "338", "371", "395"], "❄️ "),
}


### Functions ###
def load_env_file(filepath: Path) -> None:
    """Loads environment variables from a file, ignoring any lines that are empty or start with #."""
    try:
        with open(filepath, encoding="utf-8") as f:
            for line in f:
                if line.strip() and not line.startswith("#"):
                    if line.startswith("export "):
                        line = line[len("export ") :]
                    key, value = line.strip().split("=", 1)
                    os.environ[key] = value.strip('"')
    except Exception:
        pass


def get_weather_icon(weatherinstance: CurrentCondition | HourlyPoint) -> str:
    """Returns the appropriate weather icon based on the weather code."""
    return WEATHER_CODES.get(weatherinstance["weatherCode"], "☁️ ")


def get_temperature(weatherinstance: CurrentCondition) -> str:
    """Returns the current temperature in the specified unit (C or F)."""
    return _temp(cast(dict[str, str], weatherinstance), "temp_C", "temp_F")


def get_feels_like(weatherinstance: CurrentCondition) -> str:
    """Returns the "feels like" temperature in the specified unit (C or F)."""
    return _temp(cast(dict[str, str], weatherinstance), "FeelsLikeC", "FeelsLikeF")


def get_wind_speed(weatherinstance: CurrentCondition) -> str:
    """Returns the wind speed in the specified unit (km/h or mph)."""
    if windspeed_unit == "km/h":
        return _clamped(weatherinstance.get("windspeedKmph"), 0, 999, " km/h")
    return _clamped(weatherinstance.get("windspeedMiles"), 0, 999, " mph")


def get_city_name(weather: WttrResponse) -> str:
    """Returns the city name from the weather data."""
    return weather["nearest_area"][0]["areaName"][0]["value"]


def get_country_name(weather: WttrResponse) -> str:
    """Returns the country name from the weather data."""
    return weather["nearest_area"][0]["country"][0]["value"]


def get_timestamp(time_str: str) -> str:
    """Formats the time string according to the specified time format (12h or 24h)."""
    # wttr.in always returns "HH:MM AM/PM" (English, locale-independent) — never use %p with strptime
    try:
        parts = time_str.strip().split()
        h, m = map(int, parts[0].split(":"))
        suffix = parts[1].upper() if len(parts) > 1 else ""
        if suffix == "PM" and h != 12:
            h += 12
        elif suffix == "AM" and h == 12:
            h = 0
        if time_format == "24h":
            return f"{h:02d}:{m:02d}"
        return f"{(h % 12) or 12:02d}:{m:02d} {'AM' if h < 12 else 'PM'}"
    except Exception:
        return time_str


def get_location_hour(weather: WttrResponse, fallback: int) -> int:
    """Current hour (0-23) at the weather location, from `localObsDateTime`
    ("2026-09-30 08:15 PM", always 12-hour English). wttr.in's hourly slots use
    that clock, so the first-day cutoff must too, not the host's (#2159).
    Returns `fallback` (the host hour) when the field is missing or malformed."""
    try:
        _, clock, suffix = weather["current_condition"][0]["localObsDateTime"].split()
        h, m = (int(x) for x in clock.split(":"))
        suffix = suffix.upper()
        if suffix not in ("AM", "PM") or not 1 <= h <= 12 or not 0 <= m < 60:
            return fallback
        return h % 12 + (12 if suffix == "PM" else 0)
    except (KeyError, IndexError, TypeError, ValueError, AttributeError):
        return fallback


DASH = "–"
# Range shown in the forecast table: a junk or absurd reading must not widen a column.
# Fahrenheit needs more headroom than Celsius (a 100 °F day is ordinary).
TEMP_RANGE = {"c": (-99, 99), "f": (-99, 199)}


def _number(value: object) -> float | None:
    """Reads a number from a number or numeric string; None for anything else (incl. NaN/inf)."""
    if isinstance(value, bool):
        return None
    try:
        n = float(str(value).strip())
    except ValueError:
        return None
    return n if math.isfinite(n) else None


def _clamped(value: object, low: int, high: int, suffix: str) -> str:
    """Rounds into [low, high] and appends the suffix; DASH when the input is not a number."""
    n = _number(value)
    if n is None:
        return DASH
    return f"{max(low, min(high, round(n)))}{suffix}"


def _temp(entry: dict[str, str], key_c: str, key_f: str) -> str:
    """Temperature in the chosen unit, taken from the Celsius or Fahrenheit key and clamped."""
    low, high = TEMP_RANGE[temp_unit]
    if temp_unit == "c":
        return _clamped(entry.get(key_c), low, high, "°C")
    return _clamped(entry.get(key_f), low, high, "°F")


def _hour_of(time_value: object) -> int | None:
    """wttr.in reports slot times as 0, 300 ... 2100; None when it is anything else."""
    n = _number(time_value)
    if n is None or not 0 <= n < 2400:
        return None
    return int(n) // 100


def _width(text: str) -> int:
    """Terminal cells a string occupies: wide (CJK) characters count twice, combining marks none."""
    return sum(
        0 if unicodedata.combining(c) else 2 if unicodedata.east_asian_width(c) in "WF" else 1
        for c in text
    )


def _pad(text: str, width: int, right: bool) -> str:
    """Pads to a width in terminal cells, on the left for right-aligned columns."""
    gap = " " * max(0, width - _width(text))
    return gap + text if right else text + gap


def _esc(text: object) -> str:
    """wttr.in text goes into Pango markup; an & or < in a description would break the tooltip."""
    return html.escape(str(text), quote=False)


def _icon(entry: dict[str, str]) -> str:
    """Icon without the trailing space WEATHER_CODES carries; the table sets its own gaps."""
    return WEATHER_CODES.get(str(entry.get("weatherCode")), "☁️ ").strip()


def get_description(entry: dict[str, str]) -> str:
    """Description in WEATHER_LANG if wttr.in sent one, else the English text; empty if neither."""
    lang = cast(dict[str, object], entry).get(f"lang_{weather_lang}")
    if isinstance(lang, list) and lang and isinstance(lang[0], dict):
        value = lang[0].get("value")
        if isinstance(value, str):
            return value.strip()
    desc = entry.get("weatherDesc")
    if isinstance(desc, list) and desc and isinstance(desc[0], dict):  # type: ignore[index]
        return str(desc[0].get("value", "")).strip()  # type: ignore[index]
    return ""


def _astronomy(day: dict[str, object], key: str) -> str:
    """Sunrise or sunset as text for the tooltip (escaped, since an unparsable value passes through)."""
    astro = day.get("astronomy")
    if isinstance(astro, list) and astro and isinstance(astro[0], dict) and key in astro[0]:
        return _esc(get_timestamp(str(astro[0][key])))
    return DASH


def _rare_events(hour: dict[str, str]) -> str:
    """Events without a column of their own, only when above 0, separated by spacing (no commas)."""
    events = {
        "chanceoffog": os.getenv("WEATHER_CHANCE_LABEL_FOG", "Fog"),
        "chanceoffrost": os.getenv("WEATHER_CHANCE_LABEL_FROST", "Frost"),
        "chanceofsnow": os.getenv("WEATHER_CHANCE_LABEL_SNOW", "Snow"),
        "chanceofthunder": os.getenv("WEATHER_CHANCE_LABEL_THUNDER", "Thunder"),
    }
    found = []
    for key, label in events.items():
        n = _number(hour.get(key))
        if n is not None and n > 0:
            found.append(f"{label} {_clamped(n, 0, 100, '%')}")
    return "   ".join(found)


# One column per chance that matters in daily life; the rest goes into the last column.
_PERCENT_KEYS = ("chanceofovercast", "chanceofrain", "chanceofsunshine", "chanceofwindy")


def _slot_row(hour: dict[str, str]) -> list[str]:
    """One table row as raw cell texts: hour, icon, temperature, sky, four chances, rare events."""
    h = _hour_of(hour.get("time"))
    return [
        DASH if h is None else str(h),
        _icon(hour),
        _temp(hour, "tempC", "tempF"),
        get_description(hour),
        *(_clamped(hour.get(k), 0, 100, "%") for k in _PERCENT_KEYS),
        _rare_events(hour),
    ]


def build_forecast(weather: WttrResponse, now_hour: int, forecast_days: int) -> str:
    """The forecast as Pango markup with aligned columns (hour, icon, temperature, sky, four
    chances, rare events). Every day shares one set of column widths so rows line up across days.
    Numbers are right-aligned, headings follow their column. Needs a monospace tooltip font."""
    days = [d for d in weather.get("weather", [])[:forecast_days] if isinstance(d, dict)]
    rows_per_day = []
    for i, day in enumerate(days):
        rows = []
        for hour in day.get("hourly") or []:
            if not isinstance(hour, dict):
                continue
            h = _hour_of(hour.get("time"))
            # today: drop slots that are more than two hours past
            if i == 0 and h is not None and h < now_hour - 2:
                continue
            rows.append(_slot_row(hour))
        rows_per_day.append(rows)

    heads = [
        "Hour", "", "Temp", "Sky",
        os.getenv("WEATHER_CHANCE_LABEL_OVERCAST", "Clouds"),
        os.getenv("WEATHER_CHANCE_LABEL_RAIN", "Rain"),
        os.getenv("WEATHER_CHANCE_LABEL_SUNSHINE", "Sun"),
        os.getenv("WEATHER_CHANCE_LABEL_WIND", "Wind"),
        "",
    ]
    right = [True, False, True, False, True, True, True, True, False]
    icon_col = 1
    widths = [_width(h) for h in heads]
    widths[icon_col] = 2  # an emoji takes two cells, whatever its code points
    for rows in rows_per_day:
        for row in rows:
            for c, cell in enumerate(row):
                if c != icon_col:
                    widths[c] = max(widths[c], _width(cell))

    def line(cells: list[str]) -> str:
        """Joins cells into one row. Pad first, escape after: an entity such as &amp; is longer
        than the one cell Pango draws for it, so padding the escaped text would skew the row."""
        parts = [
            (cells[c] or " " * widths[c]) if c == icon_col else _esc(_pad(cells[c], widths[c], right[c]))
            for c in range(len(cells))
        ]
        return "  ".join(parts).rstrip()

    out = []
    for i, day in enumerate(days):
        if i:
            out.append("")
        title = ("Today, ", "Tomorrow, ")[i] if i < 2 else ""
        out.append(f"<b>{title}{_esc(day.get('date', DASH))}</b>")
        out.append(
            f"⬆️ <b>{_temp(day, 'maxtempC', 'maxtempF')}</b> "
            f"⬇️ <b>{_temp(day, 'mintempC', 'mintempF')}</b> "
            f"🌅 <b>{_astronomy(day, 'sunrise')}</b> "
            f"🌇 <b>{_astronomy(day, 'sunset')}</b>"
        )
        out.append(line(heads))
        out.extend(line(row) for row in rows_per_day[i])
    return "\n".join(out)


def build_facts(weather: WttrResponse) -> str:
    """Current conditions: bold headline, then label/value pairs with aligned values."""
    current = weather["current_condition"][0]
    pairs = [
        ("Feels like", get_feels_like(current)),
        ("Location", f"{get_city_name(weather)}, {get_country_name(weather)}"),
        ("Wind", get_wind_speed(current)),
        ("Humidity", _clamped(current.get("humidity"), 0, 100, "%")),
    ]
    width = max(len(label) for label, _ in pairs)
    lines = [f"<b>{_esc(get_description(current))} {get_temperature(current)}</b>"]
    lines += [f"{label.ljust(width)}   {_esc(value)}" for label, value in pairs]
    return "\n".join(lines)


def _parse_lang_code(raw: str) -> str:
    """Parses a locale code to extract the language code (e.g., "en" from "en_US.UTF-8").
    Returns an empty string if the code is not valid or indicates a C/POSIX locale."""
    if not raw:
        return ""
    code = raw.split(".")[0].split("@")[0].split("_")[0].lower()
    return "" if code in ("c", "posix") else code


def get_default_locale() -> tuple[str, TempUnit, TimeFormat, WindUnit]:
    """Determines the default locale settings for language, temperature unit, time format,
    and windspeed unit based on the system's locale configuration."""
    lang: str = "en"
    temp: TempUnit = "c"
    time: TimeFormat = "24h"
    wind: WindUnit = "km/h"
    try:
        lc_messages = getattr(locale, "LC_MESSAGES", None)
        if lc_messages is not None:
            locale.setlocale(lc_messages, "")
            loc_info = locale.getlocale(lc_messages)
            code = _parse_lang_code(loc_info[0] if loc_info else "")
            if code:
                lang = code
        else:
            code = _parse_lang_code(os.getenv("LANG", ""))
            if code:
                lang = code
    except Exception:
        # LC_MESSAGES failed, fall back to $LANG
        code = _parse_lang_code(os.getenv("LANG", ""))
        if code:
            lang = code
    try:
        # LC_TIME for 12h/24h and country-based unit defaults
        locale.setlocale(locale.LC_TIME, "")
        if "%p" in locale.nl_langinfo(locale.D_T_FMT):
            time = "12h"
        loc_info = locale.getlocale(locale.LC_TIME)
        if loc_info and loc_info[0]:
            country_code = loc_info[0].split("_")[-1].split(".")[0].upper()
            if country_code in ("US", "LR", "MM"):
                temp, wind = "f", "mph"
    except Exception:
        pass
    return lang, temp, time, wind


weather_lang: str = "en"
temp_unit: TempUnit = "c"
time_format: TimeFormat = "24h"
windspeed_unit: WindUnit = "km/h"


def get_weather_data(url: str, headers: dict[str, str]) -> WttrResponse | None:
    try:
        response = requests.get(url, timeout=10, headers=headers)
        response.raise_for_status()
        weather = response.json()
    except (requests.exceptions.RequestException, json.decoder.JSONDecodeError):
        return None

    if not isinstance(weather, dict):
        return None

    current_condition = weather.get("current_condition")
    forecast = weather.get("weather")
    nearest_area = weather.get("nearest_area")
    if not (
        isinstance(current_condition, list)
        and len(current_condition) > 0
        and isinstance(forecast, list)
        and len(forecast) > 0
        and isinstance(nearest_area, list)
        and len(nearest_area) > 0
    ):
        return None

    return cast(WttrResponse, weather)


def print_weather_unavailable() -> None:
    print(json.dumps({"text": "Weather --", "tooltip": "Weather unavailable: wttr.in did not return usable data", "class": "error"}))


def main() -> None:
    """Prints the Waybar JSON (text and tooltip) for the current weather."""
    global weather_lang, temp_unit, time_format, windspeed_unit

    ### Variables ###
    def_lang, def_temp, def_time, def_wind = get_default_locale()  # default vals based on locale
    home = Path.home()
    load_env_file(home / ".local" / "state" / "hyde" / "staterc")
    load_env_file(home / ".local" / "state" / "hyde" / "config")

    user_lang = os.getenv("WEATHER_LANG")
    weather_lang = user_lang.lower() if user_lang else def_lang
    user_temp = os.getenv("WEATHER_TEMPERATURE_UNIT")
    if user_temp and user_temp.lower() in ("c", "f"):
        temp_unit = cast(TempUnit, user_temp.lower())
    else:
        temp_unit = def_temp
    user_time = os.getenv("WEATHER_TIME_FORMAT")
    if user_time and user_time.lower() in ("12h", "24h"):
        time_format = cast(TimeFormat, user_time.lower())
    else:
        time_format = def_time
    user_wind = os.getenv("WEATHER_WINDSPEED_UNIT")
    if user_wind and user_wind.lower() in ("km/h", "mph"):
        windspeed_unit = cast(WindUnit, user_wind.lower())
    else:
        windspeed_unit = def_wind
    show_icon = os.getenv("WEATHER_SHOW_ICON", "True").lower() in (
        "true",
        "1",
        "t",
        "y",
        "yes",
    )  # True or False     (default: True)
    show_location = os.getenv("WEATHER_SHOW_LOCATION", "True").lower() in (
        "true",
        "1",
        "t",
        "y",
        "yes",
    )  # True or False     (default: False)
    show_today_details = os.getenv("WEATHER_SHOW_TODAY_DETAILS", "True").lower() in (
        "true",
        "1",
        "t",
        "y",
        "yes",
    )  # True or False     (default: True)
    try:
        forecast_days = int(os.getenv("WEATHER_FORECAST_DAYS", "3"))
        if forecast_days not in range(1, 4):
            forecast_days = 3
    except ValueError:
        forecast_days = 3  # Number of days to show the forecast for (default: 3)
    get_location = os.getenv("WEATHER_LOCATION", "").replace(
        " ", "_"
    )  # Name of the location to get the weather from (default: '')
    # Parse the location to wttr.in format (snake_case)

    ### Main Logic ###
    data: dict[str, str] = {}
    url = f"https://wttr.in/{get_location}?format=j1"
    if user_lang and weather_lang:
        url += f"&lang={weather_lang}"

    # Get the weather data
    headers = {"User-Agent": "Mozilla/5.0"}
    weather = get_weather_data(url, headers)
    if weather is None:
        print_weather_unavailable()
        sys.exit(0)
    current_conditions = weather.get("current_condition")
    if not current_conditions:
        print_weather_unavailable()
        sys.exit(0)
    current_weather = current_conditions[0]

    # Get the data to display
    # waybar text
    data["text"] = get_temperature(current_weather)
    if show_icon:
        data["text"] = get_weather_icon(current_weather) + data["text"]
    if show_location:
        data["text"] += f" | {get_city_name(weather)}, {get_country_name(weather)}"

    # waybar tooltip
    parts = []
    if show_today_details:
        parts.append(build_facts(weather))
    parts.append(build_forecast(weather, get_location_hour(weather, datetime.now().hour), forecast_days))
    data["tooltip"] = "\n\n".join(p for p in parts if p)

    print(json.dumps(data))


if __name__ == "__main__":
    main()
