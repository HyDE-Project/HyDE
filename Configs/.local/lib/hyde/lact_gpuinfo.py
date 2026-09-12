#!/usr/bin/env python3
"""Read one GPU's normalized metrics from the LACT daemon socket."""

import json
import socket
import sys


SOCKET = "/run/lactd.sock"


def request(payload):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
        sock.settimeout(2.0)
        sock.connect(SOCKET)
        sock.sendall((json.dumps(payload) + "\n").encode())
        sock.shutdown(socket.SHUT_WR)
        data = b""
        while chunk := sock.recv(65536):
            data += chunk
    response = json.loads(data)
    if response.get("status") != "ok":
        raise RuntimeError(response.get("error", "LACT request failed"))
    return response.get("data") or {}


def first_value(mapping, *keys):
    for key in keys:
        value = mapping.get(key)
        if value is not None:
            return value
    return None


def optional_request(payload):
    try:
        return request(payload)
    except (OSError, RuntimeError, json.JSONDecodeError):
        return {}


def main():
    devices = request({"command": "list_devices"})
    if not devices:
        raise RuntimeError("no GPU reported by LACT")
    wanted_vendor = sys.argv[1].lower() if len(sys.argv) > 1 else None
    vendor_prefix = {"nvidia": "10de:", "amd": "1002:", "intel": "8086:"}
    if wanted_vendor in vendor_prefix:
        devices = [d for d in devices if d.get("id", "").lower().startswith(vendor_prefix[wanted_vendor])]
        if not devices:
            raise RuntimeError(f"no {wanted_vendor} GPU reported by LACT")
    device = devices[0]
    device_id = device["id"]
    info = request({"command": "device_info", "args": {"id": device_id}})
    stats = request({"command": "device_stats", "args": {"id": device_id}})
    clocks = optional_request({"command": "device_clocks_info", "args": {"id": device_id}})

    pci = info.get("pci_info", {}).get("device_pci_info", {})
    drm = info.get("drm_info", {})
    temps = stats.get("temps", {})
    primary_temp = next((v.get("current") for v in temps.values() if v.get("primary")), None)
    power = stats.get("power", {})
    clock = stats.get("clockspeed", {})
    clock_data = clocks.get("table", {}).get("value", {})
    clock_range = clock_data.get("gpu_clock_range", [])

    print(json.dumps({
        "primary_gpu": pci.get("model") or device.get("name"),
        "vendor": pci.get("vendor"),
        "family": drm.get("family_name"),
        "temperature": primary_temp,
        "utilization": stats.get("busy_percent"),
        "current_clock_speed": clock.get("gpu_clockspeed"),
        "max_clock_speed": clock_range[-1] if clock_range else None,
        "power_usage": power.get("current"),
        "power_limit": first_value(power, "cap_current", "cap_max"),
    }, ensure_ascii=False))


try:
    main()
except Exception as exc:
    print(json.dumps({"error": str(exc)}))
    sys.exit(1)
