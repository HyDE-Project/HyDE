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

def format_time(time):
    return time.replace("00", "").zfill(2)

def format_temp(temp):
    return (hour['FeelsLikeC']+"°").ljust(3)

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

temp_unit = os.getenv('TEMP_UNIT', 'C')                                                         # C or F
time_format = os.getenv('TIME_FORMAT', '24h')                                                   # 12h or 24h
show_location = os.getenv('SHOW_LOCATION', 'False').lower() in ('true', '1', 't', 'y', 'yes')   # True or False
get_location = os.getenv('WAYBAR_WEATHER_LOC', 'True')                                          # Name of the location to get the weather from

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
if get_location.lower() in ('false', '0', 'f', 'n', 'no', 'true', '1', 't', 'y', 'yes'):
    # If get_location is a boolean value (default) then request the weather without a location (IP based location)
    set_location = False
    weather = requests.get("https://wttr.in/?format=j1", timeout=10).json()
else:
    set_location = True
    weather = requests.get(f"https://wttr.in/{get_location}?format=j1", timeout=10).json()

tempint = int(weather['current_condition'][0]['FeelsLikeC'])
extrachar = ''
if tempint > 0 and tempint < 10:
    extrachar = '+'


if set_location is True :
    data['text'] = ' '+WEATHER_CODES[weather['current_condition'][0]['weatherCode']] + \
        " "+extrachar+weather['current_condition'][0]['FeelsLikeC']+"°" +" | "+ weather['nearest_area'][0]['areaName'][0]['value']+\
        ", "  + weather['nearest_area'][0]['country'][0]['value']

if set_location is False:
    data['text'] = ' '+WEATHER_CODES[weather['current_condition'][0]['weatherCode']] + \
        " "+extrachar+weather['current_condition'][0]['FeelsLikeC']+"°" 


data['tooltip'] = f"<b>{weather['current_condition'][0]['weatherDesc'][0]['value']} {weather['current_condition'][0]['temp_C']}°</b>\n"
data['tooltip'] += f"Feels like: {weather['current_condition'][0]['FeelsLikeC']}°\n"
data['tooltip'] += f"Location: {weather['nearest_area'][0]['areaName'][0]['value']}\n"
data['tooltip'] += f"Wind: {weather['current_condition'][0]['windspeedKmph']}Km/h\n"
data['tooltip'] += f"Humidity: {weather['current_condition'][0]['humidity']}%\n"
for i, day in enumerate(weather['weather']):
    data['tooltip'] += f"\n<b>"
    if i == 0:
        data['tooltip'] += "Today, "
    if i == 1:
        data['tooltip'] += "Tomorrow, "
    data['tooltip'] += f"{day['date']}</b>\n"
    data['tooltip'] += f"⬆️ {day['maxtempC']}° ⬇️ {day['mintempC']}° "
    data['tooltip'] += f"🌅 {day['astronomy'][0]['sunrise']} 🌇 {day['astronomy'][0]['sunset']}\n"
    for hour in day['hourly']:
        if i == 0:
            if int(format_time(hour['time'])) < datetime.now().hour-2:
                continue
        data['tooltip'] += f"{format_time(hour['time'])} {WEATHER_CODES[hour['weatherCode']]} {format_temp(hour['FeelsLikeC'])} {hour['weatherDesc'][0]['value']}, {format_chances(hour)}\n"


print(json.dumps(data))