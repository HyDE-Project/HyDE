#!/usr/bin/env python

import os
import sys
import json
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
    **dict.fromkeys(["119", "122", "143", "248", "260"], "☁️ "),
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
    return WEATHER_CODES[weatherinstance["weatherCode"]]


def get_description(weatherinstance: CurrentCondition | HourlyPoint) -> str:
    """Returns the weather description in the specified language, or falls back to English if not available."""
    lang_key = f"lang_{weather_lang}"
    translated = cast(dict[str, object], weatherinstance).get(lang_key)
    if isinstance(translated, list) and translated and isinstance(translated[0], dict):
        value = translated[0].get("value")
        if isinstance(value, str):
            return value

    return weatherinstance["weatherDesc"][0]["value"]


def get_temperature(weatherinstance: CurrentCondition) -> str:
    """Returns the current temperature in the specified unit (C or F)."""
    if temp_unit == "c":
        return weatherinstance["temp_C"] + "°C"

    return weatherinstance["temp_F"] + "°F"


def get_temperature_hour(weatherinstance: HourlyPoint) -> str:
    """Returns the temperature for a specific hour in the specified unit (C or F)."""
    if temp_unit == "c":
        return weatherinstance["tempC"] + "°C"

    return weatherinstance["tempF"] + "°F"


def get_feels_like(weatherinstance: CurrentCondition) -> str:
    """Returns the "feels like" temperature in the specified unit (C or F)."""
    if temp_unit == "c":
        return weatherinstance["FeelsLikeC"] + "°C"

    return weatherinstance["FeelsLikeF"] + "°F"


def get_wind_speed(weatherinstance: CurrentCondition) -> str:
    """Returns the wind speed in the specified unit (km/h or mph)."""
    if windspeed_unit == "km/h":
        return weatherinstance["windspeedKmph"] + "Km/h"

    return weatherinstance["windspeedMiles"] + "Mph"


def get_max_temp(day: WeatherDay) -> str:
    """Returns the maximum temperature for the day in the specified unit (C or F)."""
    if temp_unit == "c":
        return day["maxtempC"] + "°C"

    return day["maxtempF"] + "°F"


def get_min_temp(day: WeatherDay) -> str:
    """Returns the minimum temperature for the day in the specified unit (C or F)."""
    if temp_unit == "c":
        return day["mintempC"] + "°C"

    return day["mintempF"] + "°F"


def get_sunrise(day: WeatherDay) -> str:
    """Returns the sunrise time for the day, formatted according to the specified time format (12h or 24h)."""
    return get_timestamp(day["astronomy"][0]["sunrise"])


def get_sunset(day: WeatherDay) -> str:
    """Returns the sunset time for the day, formatted according to the specified time format (12h or 24h)."""
    return get_timestamp(day["astronomy"][0]["sunset"])


def get_city_name(weather: WttrResponse) -> str:
    """Returns the city name from the weather data."""
    return weather["nearest_area"][0]["areaName"][0]["value"]


def get_country_name(weather: WttrResponse) -> str:
    """Returns the country name from the weather data."""
    return weather["nearest_area"][0]["country"][0]["value"]


def format_time(time: str) -> str:
    """Formats the time string according to the specified time format (12h or 24h)."""
    return (time.replace("00", "")).ljust(3)


def format_temp(temp: str) -> str:
    """Formats the temperature string, adding a leading space if it's positive for better alignment."""
    if temp[0] != "-":
        temp = " " + temp
    return temp.ljust(5)


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


def format_chances(hour: HourlyPoint) -> str:
    """Formats the chance of various weather events for a specific hour."""
    chances: dict[str, str] = {
        "chanceoffog": os.getenv("WEATHER_CHANCE_LABEL_FOG", "Fog"),
        "chanceoffrost": os.getenv("WEATHER_CHANCE_LABEL_FROST", "Frost"),
        "chanceofovercast": os.getenv("WEATHER_CHANCE_LABEL_OVERCAST", "Overcast"),
        "chanceofrain": os.getenv("WEATHER_CHANCE_LABEL_RAIN", "Rain"),
        "chanceofsnow": os.getenv("WEATHER_CHANCE_LABEL_SNOW", "Snow"),
        "chanceofsunshine": os.getenv("WEATHER_CHANCE_LABEL_SUNSHINE", "Sunshine"),
        "chanceofthunder": os.getenv("WEATHER_CHANCE_LABEL_THUNDER", "Thunder"),
        "chanceofwindy": os.getenv("WEATHER_CHANCE_LABEL_WIND", "Wind"),
    }

    conditions = [
        f"{chances[event]} {hour[event]}%"  # type: ignore[literal-required]
        for event in chances
        if int(hour.get(event, 0))  # type: ignore[call-overload]
        > 0
    ]
    return ", ".join(conditions)


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


def main() -> None:
    global weather_lang, temp_unit, time_format, windspeed_unit

    ### Variables ###
    def_lang, def_temp, def_time, def_wind = get_default_locale()  # default vals based on locale
    home = Path.home()
    load_env_file(home / ".local" / "state" / "doorwayde" / "staterc")
    load_env_file(home / ".local" / "state" / "doorwayde" / "config")

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
    response = requests.get(url, timeout=10, headers=headers)
    try:
        weather = cast(WttrResponse, response.json())
    except json.decoder.JSONDecodeError:
        sys.exit(1)
    current_weather = weather["current_condition"][0]

    # Get the data to display
    # waybar text
    data["text"] = get_temperature(current_weather)
    if show_icon:
        data["text"] = get_weather_icon(current_weather) + data["text"]
    if show_location:
        data["text"] += f" | {get_city_name(weather)}, {get_country_name(weather)}"

    # waybar tooltip
    data["tooltip"] = ""
    if show_today_details:
        data["tooltip"] += (
            f"<b>{get_description(current_weather)} {get_temperature(current_weather)}</b>\n"
        )
        data["tooltip"] += f"Feels like: {get_feels_like(current_weather)}\n"
        data["tooltip"] += f"Location: {get_city_name(weather)}, {get_country_name(weather)}\n"
        data["tooltip"] += f"Wind: {get_wind_speed(current_weather)}\n"
        data["tooltip"] += f"Humidity: {current_weather['humidity']}%\n"
    # Get the weather forecast for the next 2 days
    for i in range(forecast_days):
        day_instance = weather["weather"][i]
        data["tooltip"] += "\n<b>"
        if i == 0:
            data["tooltip"] += "Today, "
        if i == 1:
            data["tooltip"] += "Tomorrow, "
        data["tooltip"] += f"{day_instance['date']}</b>\n"
        data["tooltip"] += f"⬆️ {get_max_temp(day_instance)} ⬇️ {get_min_temp(day_instance)} "
        data["tooltip"] += f"🌅 {get_sunrise(day_instance)} 🌇 {get_sunset(day_instance)}\n"
        # Get the hourly forecast for the day
        for hour in day_instance["hourly"]:
            if i == 0:
                if int(format_time(hour["time"])) < datetime.now().hour - 2:
                    continue
            data["tooltip"] += (
                f"{format_time(hour['time'])} {get_weather_icon(hour)} {format_temp(get_temperature_hour(hour))} {get_description(hour)}, {format_chances(hour)}\n"
            )

    print(json.dumps(data))


if __name__ == "__main__":
    main()
