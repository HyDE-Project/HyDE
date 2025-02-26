#!/usr/bin/env python

import json
import subprocess
import os

DEVICE_GLYPHS = {
    "iwlwifi": "",
    "nvme": "",
    "acpitz": "",
    "coretemp": "",
    "pch_cannonlake": "",
    "BAT": "",
    "acpi_fan": "",
    "default": "",
}


def get_device_glyph(device_name):
    return next(
        (glyph for key, glyph in DEVICE_GLYPHS.items() if key in device_name),
        DEVICE_GLYPHS["default"],
    )


def format_columns(data, max_entries_per_column=15):
    if not data:
        return []
    columns = []
    for i in range(0, len(data), max_entries_per_column):
        columns.append(data[i : i + max_entries_per_column])
    # Merge columns into rows
    rows = []
    max_rows = max(len(col) for col in columns)
    for i in range(max_rows):
        row = []
        for col in columns:
            if i < len(col):
                row.append(col[i])
            else:
                row.append("")
        rows.append("\t".join(row))
    return rows


PAGE_SIZE = 5
PAGE_FILE = "/tmp/sensorinfo_page"


def get_current_page(total_pages):
    if os.path.exists(PAGE_FILE):
        with open(PAGE_FILE, "r", encoding="utf-8") as f:
            page = int(f.read().strip())
            return page % total_pages
    return 0


def save_current_page(page):
    with open(PAGE_FILE, "w", encoding="utf-8") as f:
        f.write(str(page))


def get_temp_color(temp):
    temp_colors = {
        120: "#8b0000",  # Dark Red for 120 and above
        115: "#ad1f2f",  # Red for 115 to 119
        110: "#d22f2f",  # Light Red for 110 to 114
        105: "#ff471a",  # Orange-Red for 105 to 109
        100: "#ff6347",  # Tomato for 100 to 104
        95: "#ff8c00",  # Dark Orange for 95 to 99
        90: "#ffa500",  # Orange for 90 to 94
        85: "#ffd700",  # Gold for 85 to 89
        80: "#ffff00",  # Yellow for 80 to 84
        75: "#ffa07a",  # Light Salmon for 75 to 79
        70: "#ff7f50",  # Coral for 70 to 74
        65: "#ff4500",  # Orange Red for 65 to 69
        60: "#ff6347",  # Tomato for 60 to 64
        55: "#ff8c00",  # Dark Orange for 55 to 59
        45: "",  # No color for 45 to 54
        40: "#add8e6",  # Light Blue for 40 to 44
        35: "#87ceeb",  # Sky Blue for 35 to 39
        30: "#4682b4",  # Steel Blue for 30 to 34
        25: "#4169e1",  # Royal Blue for 25 to 29
        20: "#0000ff",  # Blue for 20 to 24
        0: "#00008b",  # Dark Blue for below 20
    }

    for threshold in sorted(temp_colors.keys(), reverse=True):
        if temp >= threshold:
            color = temp_colors[threshold]
            if color:
                return f"<span color='{color}'><b>{temp}°C</b></span>"
            else:
                return f"{temp}°C"
    return f"{temp}°C"


def get_sensor_data(result_sensors, page=0):
    try:
        sensors_data = json.loads(result_sensors.stdout)
    except json.JSONDecodeError:
        print("Error: Failed to decode JSON from sensors output")
        return {
            "text": " N/A",
            "tooltip": "Error: Failed to decode JSON from sensors output",
        }

    # Initialize variables
    device_data = {}

    # Extract top-level sensor data
    for device in sorted(sensors_data.keys()):
        data = sensors_data[device]
        device_data[device] = {
            "temperatures": [],
            "fan_speeds": [],
            "voltages": [],
            "currents": [],
            "powers": [],
        }
        for sensor, values in data.items():
            if isinstance(values, dict):
                for key, value in values.items():
                    if "temp" in key and "input" in key:
                        temp_color = get_temp_color(value)
                        device_data[device]["temperatures"].append(
                            f"{sensor}: {temp_color}"
                        )
                    elif "fan" in key and "input" in key:
                        device_data[device]["fan_speeds"].append(
                            f"{sensor}: {value} RPM"
                        )
                    elif "in" in key and "input" in key:
                        device_data[device]["voltages"].append(f"{sensor}: {value} V")
                    elif "curr" in key and "input" in key:
                        device_data[device]["currents"].append(f"{sensor}: {value} A")
                    elif "power" in key and "input" in key:
                        device_data[device]["powers"].append(f"{sensor}: {value} W")

    # Format the output
    text = " "
    tooltip_parts = []

    devices = list(device_data.keys())
    total_pages = (len(devices) + PAGE_SIZE - 1) // PAGE_SIZE
    page = max(0, min(page, total_pages - 1))
    save_current_page(page)

    start_index = page * PAGE_SIZE
    end_index = start_index + PAGE_SIZE
    devices = devices[start_index:end_index]

    for device in devices:
        data = device_data[device]
        device_glyph = get_device_glyph(device)
        device_parts = [f"  Device: {device}       "]
        has_data = False
        if data["temperatures"]:
            has_data = True
            temp_columns = format_columns(data["temperatures"])
            device_parts.append(
                "        Temperatures:\n        " + "\n        ".join(temp_columns)
            )
        if data["fan_speeds"]:
            has_data = True
            fan_columns = format_columns(data["fan_speeds"])
            device_parts.append(
                "        Fan Speeds:\n        " + "\n        ".join(fan_columns)
            )
        if data["voltages"]:
            has_data = True
            volt_columns = format_columns(data["voltages"])
            device_parts.append(
                "        Voltages:\n        " + "\n        ".join(volt_columns)
            )
        if data["currents"]:
            has_data = True
            curr_columns = format_columns(data["currents"])
            device_parts.append(
                "        Currents:\n        " + "\n        ".join(curr_columns)
            )
        if data["powers"]:
            has_data = True
            power_columns = format_columns(data["powers"])
            device_parts.append(
                "       臘 Powers:\n        " + "\n        ".join(power_columns)
            )
        if has_data:
            tooltip_parts.append("\n".join(device_parts))
            tooltip_parts.append("\n")  # Add a newline after each device's information

    # Add page indicator
    tooltip_parts.append(f"\nPage {page + 1}/{total_pages} ← →")

    tooltip = "\n".join(tooltip_parts)

    with open("/tmp/sensorinfo", "w", encoding="utf-8") as f:
        f.write(tooltip)

    return {"text": text, "tooltip": tooltip}


if __name__ == "__main__":
    import sys

    result_sensors = subprocess.run(
        ["sensors", "-j"],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        check=True,
    )
    sensors_data = json.loads(result_sensors.stdout)
    devices = list(sensors_data.keys())
    total_pages = (len(devices) + PAGE_SIZE - 1) // PAGE_SIZE

    page = get_current_page(total_pages)
    if "--next" in sys.argv:
        page = (page + 1) % total_pages
        subprocess.run(["pkill", "-RTMIN+19", "waybar"], check=False)
    elif "--prev" in sys.argv:
        page = (page - 1 + total_pages) % total_pages
        subprocess.run(["pkill", "-RTMIN+19", "waybar"], check=False)
    save_current_page(page)
    sensor_info = get_sensor_data(result_sensors, page)
    print(json.dumps(sensor_info, separators=(",", ":")))
