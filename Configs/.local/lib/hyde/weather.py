#!/usr/bin/env python

import os
import sys
import json
from datetime import datetime
<<<<<<< HEAD
import requests

### Constants ###
# WMO Weather interpretation codes (Open-Meteo uses these)
# https://open-meteo.com/en/docs
WMO_WEATHER_CODES = {
    0: "☀️",   # Clear sky
    1: "🌤️",   # Mainly clear
    2: "⛅",   # Partly cloudy
    3: "☁️",   # Overcast
    45: "🌫️",  # Fog
    48: "🌫️",  # Depositing rime fog
    51: "🌧️",  # Light drizzle
    53: "🌧️",  # Moderate drizzle
    55: "🌧️",  # Dense drizzle
    61: "🌧️",  # Slight rain
    63: "🌧️",  # Moderate rain
    65: "🌧️",  # Heavy rain
    80: "🌦️",  # Slight rain showers
    81: "🌦️",  # Moderate rain showers
    82: "🌦️",  # Violent rain showers
    95: "⛈️",   # Thunderstorm
    96: "⛈️",   # Thunderstorm with slight hail
    99: "⛈️",   # Thunderstorm with heavy hail
}

=======
import locale

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
    **dict.fromkeys(["227", "230", "320", "323", "326", "374", "377", "386", "389"], "🌨️ "),
    **dict.fromkeys(["329", "332", "335", "338", "371", "395"], "❄️ "),
}


>>>>>>> master
### Functions ###
def load_env_file(filepath):
    try:
        with open(filepath, encoding="utf-8") as f:
            for line in f:
                if line.strip() and not line.startswith("#"):
                    if line.startswith("export "):
                        line = line[len("export ") :]
                    key, value = line.strip().split("=", 1)
                    os.environ[key] = value.strip('"')
    except Exception:
<<<<<<< HEAD
        pass

def get_weather_icon(weather_code):
    return WMO_WEATHER_CODES.get(weather_code, "❓")

def get_description(weather_code):
    descriptions = {
        0: "Clear sky",
        1: "Mainly clear",
        2: "Partly cloudy",
        3: "Overcast",
        45: "Fog",
        48: "Depositing rime fog",
        51: "Light drizzle",
        53: "Moderate drizzle",
        55: "Dense drizzle",
        61: "Slight rain",
        63: "Moderate rain",
        65: "Heavy rain",
        80: "Slight rain showers",
        81: "Moderate rain showers",
        82: "Violent rain showers",
        95: "Thunderstorm",
        96: "Thunderstorm with slight hail",
        99: "Thunderstorm with heavy hail"
    }
    return descriptions.get(weather_code, "Unknown")

def get_temperature(current_data):
    if temp_unit == "c":
        return f"{current_data['temperature_2m']}°C"
    else:
        temp_f = current_data['temperature_2m'] * 9/5 + 32
        return f"{temp_f:.1f}°F"

def get_feels_like(current_data):
    temp = current_data['temperature_2m']
    humidity = current_data['relative_humidity_2m']
    
    # Simple approximation: feels warmer when humidity is high
    if humidity > 70:
        feels_like = temp + 2
    else:
        feels_like = temp
        
    if temp_unit == "c":
        return f"{feels_like:.1f}°C"
    else:
        feels_like_f = feels_like * 9/5 + 32
        return f"{feels_like_f:.1f}°F"

def get_wind_speed(current_data):
    if windspeed_unit == "km/h":
        return f"{current_data['wind_speed_10m']} km/h"
    else:
        wind_mph = current_data['wind_speed_10m'] * 0.621371
        return f"{wind_mph:.1f} mph"

### Main Script ###
if __name__ == "__main__":
    # Load environment files first
    load_env_file(os.path.join(os.environ.get("HOME"), ".rlocal", "state", "hyde", "staterc"))
    load_env_file(os.path.join(os.environ.get("HOME"), ".local", "state", "hyde", "config"))

    # Set variables from environment with defaults
    temp_unit = os.getenv("WEATHER_TEMPERATURE_UNIT", "c").lower()
    time_format = os.getenv("WEATHER_TIME_FORMAT", "12h").lower()
    windspeed_unit = os.getenv("WEATHER_WINDSPEED_UNIT", "km/h").lower()
    show_icon = os.getenv("WEATHER_SHOW_ICON", "True").lower() in ("true", "1", "t", "y", "yes")
    show_location = os.getenv("WEATHER_SHOW_LOCATION", "True").lower() in ("true", "1", "t", "y", "yes")
    show_today_details = os.getenv("WEATHER_SHOW_TODAY_DETAILS", "True").lower() in ("true", "1", "t", "y", "yes")
    
    try:
        FORECAST_DAYS = int(os.getenv("WEATHER_FORECAST_DAYS", "3"))
    except ValueError:
        FORECAST_DAYS = 3
        
    get_location = os.getenv("WEATHER_LOCATION", "48.8566,2.3522")
    try:
        lat, lon = map(float, get_location.split(","))
    except Exception:
        lat, lon = 48.8566, 2.3522

    # Validate variables
    if temp_unit not in ("c", "f"):
        temp_unit = "c"
    if time_format not in ("12h", "24h"):
        time_format = "12h"
    if windspeed_unit not in ("km/h", "mph"):
        windspeed_unit = "km/h"
    if FORECAST_DAYS not in range(1, 4):
        FORECAST_DAYS = 3

    # Debug prints (to stderr so they don't interfere with JSON output)
    print("DEBUG: temp_unit:", temp_unit, file=sys.stderr)
    print("DEBUG: time_format:", time_format, file=sys.stderr)
    print("DEBUG: windspeed_unit:", windspeed_unit, file=sys.stderr)
    print("DEBUG: show_icon:", show_icon, file=sys.stderr)
    print("DEBUG: show_location:", show_location, file=sys.stderr)
    print("DEBUG: show_today_details:", show_today_details, file=sys.stderr)
    print("DEBUG: FORECAST_DAYS:", FORECAST_DAYS, file=sys.stderr)
    print("DEBUG: get_location:", get_location, file=sys.stderr)

    # Get weather data
    data = {}
    URL = (
            f"https://api.open-meteo.com/v1/forecast?"
            f"latitude={lat}&longitude={lon}&current=temperature_2m,weathercode,wind_speed_10m,relative_humidity_2m"
            f"&daily=weathercode,temperature_2m_max,temperature_2m_min,sunrise,sunset"
            f"&timezone=auto"
        )

    try:
        response = requests.get(URL, timeout=10)
        response.raise_for_status()
        weather = response.json()
    except Exception as e:
        data["text"] = "❓ Weather Error"
        data["tooltip"] = f"Failed to get weather data: {e}"
        print(json.dumps(data))
        sys.exit(1)

    try:
        current = weather["current"]
        daily = weather["daily"]

        # Text for Waybar
        data["text"] = get_temperature(current)
        if show_icon:
            icon = get_weather_icon(current["weathercode"])
            data["text"] = icon + " " + data["text"]
        if show_location:
            data["text"] += f" | Paris, FR"

        # Tooltip
        data["tooltip"] = f"<b>{get_description(current['weathercode'])} {get_temperature(current)}</b>\n"
        data["tooltip"] += f"Feels like: {get_feels_like(current)}\n"
        data["tooltip"] += f"Wind: {get_wind_speed(current)}\n"
        data["tooltip"] += f"Humidity: {current['relative_humidity_2m']}%\n"
        
        # Add forecast for the next few days
        for i in range(min(FORECAST_DAYS, len(daily["time"]))):
            date = daily["time"][i]
            weather_desc = get_description(daily["weathercode"][i])
            weather_icon = get_weather_icon(daily["weathercode"][i])
            
            if temp_unit == "c":
                max_temp = f"{daily['temperature_2m_max'][i]}°C"
                min_temp = f"{daily['temperature_2m_min'][i]}°C"
            else:
                max_temp = f"{daily['temperature_2m_max'][i] * 9/5 + 32:.1f}°F"
                min_temp = f"{daily['temperature_2m_min'][i] * 9/5 + 32:.1f}°F"
                
            # Format sunrise/sunset times
            sunrise = daily["sunrise"][i].split("T")[1][:5]
            sunset = daily["sunset"][i].split("T")[1][:5]
            
            day_label = "Today" if i == 0 else f"Day {i+1}"
            data["tooltip"] += f"\n<b>{day_label} ({date})</b>\n"
            data["tooltip"] += f"{weather_icon} {weather_desc}\n"
            data["tooltip"] += f"⬆️ {max_temp} ⬇️ {min_temp}\n"
            data["tooltip"] += f"🌅 {sunrise} 🌇 {sunset}\n"

    except Exception as e:
        import traceback
        print(f"ERROR: {traceback.format_exc()}", file=sys.stderr)
        data["text"] = "❓ Processing Error"
        data["tooltip"] = f"Failed to process weather data: {e}"

    print(json.dumps(data))
=======
        pass  # shhh


def get_weather_icon(weatherinstance):
    return WEATHER_CODES[weatherinstance["weatherCode"]]


def get_description(weatherinstance):
    lang_key = f"lang_{weather_lang}"
    if lang_key in weatherinstance:
        return weatherinstance[lang_key][0]["value"]
    
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
        f"{chances[event]} {hour[event]}%" for event in chances if int(hour.get(event, 0)) > 0
    ]
    return ", ".join(conditions)

def get_default_locale():
    lang, temp, time, wind = 'en', 'c', '24h', 'km/h'
    try:
        locale.setlocale(locale.LC_ALL, '')
        loc_info = locale.getlocale(locale.LC_CTYPE)
        if loc_info and loc_info[0]:
            # extract lang from user locale
            parts = loc_info[0].split('_')
            lang = parts[0].lower()
            # check country for other defaults
            country_code = loc_info[0].split('_')[-1].upper()
            if country_code in ['US', 'LR', 'MM']:
                temp, time, wind = 'f', '12h', 'mph'
    except Exception:
        pass
    return lang, temp, time, wind

### Variables ###
def_lang, def_temp, def_time, def_wind = get_default_locale() # default vals based on locale
load_env_file(os.path.join(os.environ.get("HOME"), ".local", "state", "hyde", "staterc"))
load_env_file(os.path.join(os.environ.get("HOME"), ".local", "state", "hyde", "config"))


weather_lang = os.getenv("WEATHER_LANG", def_lang).lower()  # default to 'en', based on user's locale
temp_unit = os.getenv("WEATHER_TEMPERATURE_UNIT", def_temp).lower()  # c or f
time_format = os.getenv("WEATHER_TIME_FORMAT", def_time).lower()  # 12h or 24h
windspeed_unit = os.getenv("WEATHER_WINDSPEED_UNIT", def_wind).lower()  # km/h or mph
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
URL = f"https://wttr.in/{get_location}?format=j1&lang={weather_lang}"

# Get the weather data
headers = {
    "User-Agent": "Mozilla/5.0",
    "Accept-Language": weather_lang
    }
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
    data["tooltip"] += f"Location: {get_city_name(weather)}, {get_country_name(weather)}\n"
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
>>>>>>> master
