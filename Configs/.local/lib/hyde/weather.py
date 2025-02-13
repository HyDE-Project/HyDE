#!/usr/bin/env python

import json
import requests
from datetime import datetime
import os
import subprocess


# Constants
WEATHER_CODES = {
    **dict.fromkeys(['113'], '☀️ '),
    **dict.fromkeys(['116'], '⛅ '),
    **dict.fromkeys(['119', '122', '143', '248', '260'], '☁️ '),
    **dict.fromkeys(['176', '179', '182', '185', '263', '266', '281', '284', '293', '296', '299', '302', '305', '308', '311', '314', '317', '350', '353', '356', '359', '362', '365', '368', '392'], '🌧️ '),
    **dict.fromkeys(['200'], '⛈️ '),
    **dict.fromkeys(['227', '230', '320', '323', '326', '374', '377', '386', '389'], '🌨️ '),
    **dict.fromkeys(['329', '332', '335', '338', '371', '395'], '❄️ ')
}

# Functions
def load_env_file(filepath):
    with open(filepath) as f:
        for line in f:
            if line.strip() and not line.startswith('#'):
                if line.startswith('export '):
                    line = line[len('export '):]
                key, value = line.strip().split('=', 1)
                os.environ[key] = value.strip('"')

def get_weather_icon(weatherinstance):
    return WEATHER_CODES[weatherinstance['weatherCode']]

def get_description(weatherinstance):
    return weatherinstance['weatherDesc'][0]['value']

def get_temperature(weatherinstance):
    if temp_unit == 'C':
        return weatherinstance['temp_C'] + "°C"
    else:
        return weatherinstance['temp_F'] + "°F"
    
def get_temperature_hour(weatherinstance):
    if temp_unit == 'C':
        return weatherinstance['tempC'] + "°C"
    else:
        return weatherinstance['tempF'] + "°F"
    
def get_feels_like(weatherinstance):
    if temp_unit == 'C':
        return weatherinstance['FeelsLikeC'] + "°C"
    else:
        return weatherinstance['FeelsLikeF'] + "°F"

def get_max_temp(day):
    if temp_unit == 'C':
        return day['maxtempC'] + "°C"
    else:
        return day['maxtempF'] + "°F"

def get_min_temp(day):
    if temp_unit == 'C':
        return day['mintempC'] + "°C"
    else:
        return day['mintempF'] + "°F"
    
def get_city_name(weather):
    return weather['nearest_area'][0]['areaName'][0]['value']

def get_country_name(weather):
    return weather['nearest_area'][0]['country'][0]['value']

def format_time(time):
    return (time.replace("00", "")).ljust(3)

def format_temp(temp):
    if temp[0] != "-": temp += " "
    return temp.ljust(5)

def format_chances(hour):
    chances = {
        "chanceoffog": "Fog",
        "chanceoffrost": "Frost",
        "chanceofovercast": "Overcast",
        "chanceofrain": "Rain",
        "chanceofsnow": "Snow",
        "chanceofsunshine": "Sunshine",
        "chanceofthunder": "Thunder",
        "chanceofwindy": "Wind"
    }

    conditions = []
    for event in chances.keys():
        if int(hour[event]) > 0:
            conditions.append(chances[event]+" "+hour[event]+"%")
    return ", ".join(conditions)

# Variables
# Load environment variables from the specified files
load_env_file(os.path.expanduser('~/.local/state/hyde/staterc'))
load_env_file(os.path.expanduser('~/.local/state/hyde/config'))

temp_unit = os.getenv('TEMP_UNIT', 'C')                                                         # C or F            (default: C)
time_format = os.getenv('TIME_FORMAT', '24h')                                                   # 12h or 24h        (default: 24h)
show_location = os.getenv('SHOW_LOCATION', 'False').lower() in ('true', '1', 't', 'y', 'yes')   # True or False     (default: False)
get_location = os.getenv('WAYBAR_WEATHER_LOC', '')                                              # Name of the location to get the weather from (default: '')

# Check if the variables are set correctly
if temp_unit not in ('C', 'F'):
    subprocess.run(['notify-send', 'Weather Script Error', f"TEMP_UNIT in ~/.local/state/hyde/config must be 'C' or 'F'. {temp_unit} is not valid"])
    temp_unit = 'C'
if time_format not in ('12h', '24h'):
    subprocess.run(['notify-send', 'Weather Script Error', f"TIME_FORMAT in ~/.local/state/hyde/config must be '12h' or '24h'. {time_format} is not valid"])
    time_format = '24h'
if show_location not in (True, False):
    subprocess.run(['notify-send', 'Weather Script Error', f"SHOW_LOCATION in ~/.local/state/hyde/config must be 'True' or 'False'. {show_location} is not valid"])
    show_location = False

# Main Logic
data = {}
# Get the weather data
weather = requests.get(f"https://wttr.in/{get_location}?format=j1", timeout=10).json()
current_weather = weather['current_condition'][0]

# Get the data to display
# waybar text
data['text'] = get_weather_icon(current_weather) + get_temperature(current_weather)
if show_location:
    data['text'] += f" | {get_city_name(weather)}, {get_country_name(weather)}"

# waybar tooltip
data['tooltip'] = f"<b>{get_description(current_weather)} {get_temperature(current_weather)}</b>\n"
data['tooltip'] += f"Feels like: {get_feels_like(current_weather)}\n"
data['tooltip'] += f"Location: {get_city_name(weather)}, {get_country_name(weather)}\n"
data['tooltip'] += f"Wind: {current_weather['windspeedKmph']}Km/h\n"
data['tooltip'] += f"Humidity: {current_weather['humidity']}%\n"
# Get the weather forecast for the next 2 days
for i, day in enumerate(weather['weather']):
    data['tooltip'] += f"\n<b>"
    if i == 0:
        data['tooltip'] += "Today, "
    if i == 1:
        data['tooltip'] += "Tomorrow, "
    data['tooltip'] += f"{day['date']}</b>\n"
    data['tooltip'] += f"⬆️ {get_max_temp(day)} ⬇️ {get_min_temp(day)} "
    data['tooltip'] += f"🌅 {day['astronomy'][0]['sunrise']} 🌇 {day['astronomy'][0]['sunset']}\n"
    for hour in day['hourly']:
        if i == 0:
            if int(format_time(hour['time'])) < datetime.now().hour-2:
                continue
        data['tooltip'] += f"{format_time(hour['time'])} {get_weather_icon(hour)} {format_temp(get_temperature_hour(hour))} {get_description(hour)}, {format_chances(hour)}\n"


print(json.dumps(data))