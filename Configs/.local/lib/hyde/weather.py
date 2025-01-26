#!/usr/bin/env python

import json
import requests
from datetime import datetime
import os


def load_env_file(filepath):
    with open(filepath) as f:
        for line in f:
            if line.strip() and not line.startswith('#'):
                if line.startswith('export '):
                    line = line[len('export '):]
                key, value = line.strip().split('=', 1)
                os.environ[key] = value.strip('"')

# Load environment variables from the specified files
load_env_file(os.path.expanduser('~/.local/state/hyde/staterc'))
load_env_file(os.path.expanduser('~/.local/state/hyde/config'))


WEATHER_CODES = {
    **dict.fromkeys(['113'], '☀️ '),
    **dict.fromkeys(['116'], '⛅ '),
    **dict.fromkeys(['119', '122', '143', '248', '260'], '☁️ '),
    **dict.fromkeys(['176', '179', '182', '185', '263', '266', '281', '284', '293', '296', '299', '302', '305', '308', '311', '314', '317', '350', '353', '356', '359', '362', '365', '368', '392'], '🌧️'),
    **dict.fromkeys(['200'], '⛈️ '),
    **dict.fromkeys(['227', '230', '320', '323', '326', '374', '377', '386', '389'], '🌨️'),
    **dict.fromkeys(['329', '332', '335', '338', '371', '395'], '❄️ ')
}
data = {}


get_location = os.getenv('WAYBAR_WEATHER_LOC', 'True')

if get_location.lower() in ('false', '0', 'f', 'n', 'no'):
    set_location = False
    weather = requests.get("https://wttr.in/?format=j1").json()
else:
    set_location = True
    if get_location == 'True':
        get_location = ''
    weather = requests.get(f"https://wttr.in/{get_location}?format=j1", timeout=10).json() # timeout is 10 seconds

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