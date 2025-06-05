#!/usr/bin/env python

import os
import sys
import json
from datetime import datetime


import pyutils.pip_env as pip_env

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
pip_env.v_import(
    "requests"
)  # fetches the module by name // does `pip install --update requests` under the hood
import requests  # noqa: E402


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
    **dict.fromkeys(
        ["227", "230", "320", "323", "326", "374", "377", "386", "389"], "🌨️ "
    ),
    **dict.fromkeys(["329", "332", "335", "338", "371", "395"], "❄️ "),
}


### Functions ###
def load_env_file(filepath):
    with open(filepath, encoding="utf-8") as f:
        for line in f:
            if line.strip() and not line.startswith("#"):
                if line.startswith("export "):
                    line = line[len("export ") :]
                key, value = line.strip().split("=", 1)
                os.environ[key] = value.strip('"')


def get_weather_icon(weatherinstance):
    return WEATHER_CODES[weatherinstance["weatherCode"]]


def get_description(weatherinstance):
    return weatherinstance["weatherDesc"][0]["value"]


def get_temperature(weatherinstance):
    if temp_unit == "c":
        return weatherinstance["temp_C"] + "°C"

    return weatherinstance["temp_F"] + "°F"


def get_temperature_hour(weatherinstance):
    if temp_unit == "c":
        return weatherinstance["tempC"] + "°C"

    return weatherinstance["tempF"] + "°F"


def get_feels_like(weatherinstance):
    if temp_unit == "c":
        return weatherinstance["FeelsLikeC"] + "°C"

    return weatherinstance["FeelsLikeF"] + "°F"


def get_wind_speed(weatherinstance):
    if windspeed_unit == "km/h":
        return weatherinstance["windspeedKmph"] + "Km/h"

    return weatherinstance["windspeedMiles"] + "Mph"


def get_max_temp(day):
    if temp_unit == "c":
        return day["maxtempC"] + "°C"

    return day["maxtempF"] + "°F"


def get_min_temp(day):
    if temp_unit == "c":
        return day["mintempC"] + "°C"

    return day["mintempF"] + "°F"


def get_sunrise(day):
    return get_timestamp(day["astronomy"][0]["sunrise"])


def get_sunset(day):
    return get_timestamp(day["astronomy"][0]["sunset"])


def get_city_name(weather):
    return weather["nearest_area"][0]["areaName"][0]["value"]


def get_country_name(weather):
    return weather["nearest_area"][0]["country"][0]["value"]


def format_time(time):
    return (time.replace("00", "")).ljust(3)


def format_temp(temp):
    if temp[0] != "-":
        temp = " " + temp
    return temp.ljust(5)


def get_timestamp(time_str):
    if time_format == "24h":
        return datetime.strptime(time_str, "%I:%M %p").strftime("%H:%M")

    return time_str


def format_chances(hour):
    chances = {
        "chanceoffog": "Fog",
        "chanceoffrost": "Frost",
        "chanceofovercast": "Overcast",
        "chanceofrain": "Rain",
        "chanceofsnow": "Snow",
        "chanceofsunshine": "Sunshine",
        "chanceofthunder": "Thunder",
        "chanceofwindy": "Wind",
    }

    conditions = [
        f"{chances[event]} {hour[event]}%"
        for event in chances
        if int(hour.get(event, 0)) > 0
    ]
    return ", ".join(conditions)


### Variables ###
# Load environment variables from the specified files
load_env_file(os.path.expanduser("~/.local/state/hyde/staterc"))
load_env_file(os.path.expanduser("~/.local/state/hyde/config"))

temp_unit = os.getenv(
    "WEATHER_TEMPERATURE_UNIT", "c"
).lower()  # c or f            (default: c)
time_format = os.getenv(
    "WEATHER_TIME_FORMAT", "12h"
).lower()  # 12h or 24h        (default: 12h)
windspeed_unit = os.getenv(
    "WEATHER_WINDSPEED_UNIT", "km/h"
).lower()  # km/h or mph       (default: Km/h)
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
    FORECAST_DAYS = int(
        os.getenv("WEATHER_FORECAST_DAYS", "3")
    )  # Number of days to show the forecast for (default: 3)
except ValueError:
    FORECAST_DAYS = 3
get_location = os.getenv("WEATHER_LOCATION", "").replace(
    " ", "_"
)  # Name of the location to get the weather from (default: '')
# Parse the location to wttr.in format (snake_case)

# Check if the variables are set correctly
if temp_unit not in ("c", "f"):
    TEMP_UNIT = "c"
if time_format not in ("12h", "24h"):
    TIME_FORMAT = "12h"
if windspeed_unit not in ("km/h", "mph"):
    WINDSPEED_UINT = "km/h"
if FORECAST_DAYS not in range(4):
    FORECAST_DAYS = 3

### Main Logic ###
data = {}
URL = f"https://wttr.in/{get_location}?format=j1"

# Get the weather data
headers = {"User-Agent": "Mozilla/5.0"}
response = requests.get(URL, timeout=10, headers=headers)
try:
    weather = response.json()
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
    data["tooltip"] += (
        f"Location: {get_city_name(weather)}, {get_country_name(weather)}\n"
    )
    data["tooltip"] += f"Wind: {get_wind_speed(current_weather)}\n"
    data["tooltip"] += f"Humidity: {current_weather['humidity']}%\n"
# Get the weather forecast for the next 2 days
for i in range(FORECAST_DAYS):
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
