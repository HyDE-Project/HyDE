#!/usr/bin/env python3
"""Read every GPU's normalized metrics from the LACT daemon socket.

Only Python stdlib -- no HyDE-managed venv needed, unlike amdgpu.py.
"""

import json
import socket
import sys


SOCKET = "/run/lactd.sock"
TIMEOUT_SECONDS = 2.0


def request(payload):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
        sock.settimeout(TIMEOUT_SECONDS)
        sock.connect(SOCKET)
        sock.sendall((json.dumps(payload) + "\n").encode())
        sock.shutdown(socket.SHUT_WR)
        data = b""
        while chunk := sock.recv(65536):
            data += chunk
    response = json.loads(data)
    if response.get("status") != "ok":
        raise RuntimeError(response.get("error", "LACT request failed"))
    return response.get("data")


def optional_request(payload):
    try:
        result = request(payload)
    except (OSError, RuntimeError, ValueError):
        return {}
    return result if isinstance(result, dict) else {}


def first_value(mapping, *keys):
    for key in keys:
        value = mapping.get(key)
        if value is not None:
            return value
    return None


# LACT reports the raw pci.ids vendor string ("Advanced Micro Devices, Inc.
# [AMD/ATI]", "NVIDIA Corporation"), which is accurate but too long for a
# Waybar tooltip line already carrying the model name too.
VENDOR_SHORT_NAMES = (
    ("nvidia", "NVIDIA"),
    ("advanced micro devices", "AMD"),
    ("intel", "Intel"),
)


def short_vendor_name(vendor):
    if not vendor:
        return vendor
    lowered = vendor.lower()
    for needle, short in VENDOR_SHORT_NAMES:
        if needle in lowered:
            return short
    return vendor


# ponytail: one device_info/device_stats/device_clocks_info round trip per
# GPU, sequentially, each with its own 2s socket timeout -- fine for the
# handful of GPUs a desktop/laptop actually has, but a machine with many
# GPUs would see this poll take proportionally longer. Upgrade path if that
# ever matters: fire the per-device requests concurrently (asyncio, or a
# thread pool) instead of one after another.
def device_fields(device_id, fallback_name):
    info = optional_request({"command": "device_info", "args": {"id": device_id}})
    stats = optional_request({"command": "device_stats", "args": {"id": device_id}})
    clocks = optional_request({"command": "device_clocks_info", "args": {"id": device_id}})

    pci = info.get("pci_info", {})
    pci = pci.get("device_pci_info", {}) if isinstance(pci, dict) else {}
    drm = info.get("drm_info", {})
    drm = drm if isinstance(drm, dict) else {}

    temps = stats.get("temps", {})
    temps = temps if isinstance(temps, dict) else {}
    primary_temp = next(
        (v.get("current") for v in temps.values() if isinstance(v, dict) and v.get("primary")),
        None,
    )

    power = stats.get("power", {})
    power = power if isinstance(power, dict) else {}
    clock = stats.get("clockspeed", {})
    clock = clock if isinstance(clock, dict) else {}
    fan = stats.get("fan", {})
    fan = fan if isinstance(fan, dict) else {}

    clock_table = clocks.get("table", {})
    clock_data = clock_table.get("value", {}) if isinstance(clock_table, dict) else {}
    clock_range = clock_data.get("gpu_clock_range", []) if isinstance(clock_data, dict) else []
    clock_range = clock_range if isinstance(clock_range, list) else []

    return {
        "primary_gpu": pci.get("model") or fallback_name,
        "vendor": short_vendor_name(pci.get("vendor")),
        "family": drm.get("family_name"),
        "temperature": primary_temp,
        "utilization": stats.get("busy_percent"),
        "current_clock_speed": clock.get("gpu_clockspeed"),
        "max_clock_speed": clock_range[-1] if clock_range else None,
        "power_usage": power.get("current"),
        "power_limit": first_value(power, "cap_current", "cap_max"),
        "fan_speed": fan.get("speed_current"),
    }


def main():
    try:
        devices = request({"command": "list_devices"})
    except (OSError, RuntimeError, ValueError) as exc:
        # lactd not running, socket missing, or a malformed/unreachable
        # response: report zero devices rather than raising, so this always
        # produces one valid JSON line on stdout for lact.lua to read.
        print(json.dumps({"devices": [], "error": str(exc)}, ensure_ascii=False))
        return

    if not isinstance(devices, list):
        devices = []

    results = []
    for device in devices:
        if not isinstance(device, dict):
            continue
        device_id = device.get("id")
        if not device_id:
            continue
        try:
            results.append(device_fields(device_id, device.get("name")))
        except Exception:
            # One broken device (partial/garbled daemon response) must not
            # take the rest of a multi-GPU poll down with it.
            continue

    print(json.dumps({"devices": results}, ensure_ascii=False))


if __name__ == "__main__":
    main()
