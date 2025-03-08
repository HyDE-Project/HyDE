import os
import json
import subprocess
from typing import Union, Any


class HyprctlWrapper:
    @staticmethod
    def _execute_command(cmd: list) -> str:
        """Execute hyprctl command and return output"""
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return result.stdout
        except subprocess.CalledProcessError as e:
            raise RuntimeError(f"hyprctl command failed: {e}")

    @staticmethod
    def getoption(option: str, get_set: bool = False) -> Union[int, str, bool, Any]:
        """
        Get hyprctl option value

        Args:
            option: Option name (e.g., 'decoration:rounding')
            get_set: If True, returns the 'set' value instead of the actual value

        Returns:
            The option value or set status depending on get_set parameter
        """
        if not os.getenv("HYPRLAND_INSTANCE_SIGNATURE"):
            raise EnvironmentError(
                "HYPRLAND_INSTANCE_SIGNATURE is not set. Cannot run hyprctl command."
            )

        cmd = ["hyprctl", "getoption", option, "-j"]
        output = HyprctlWrapper._execute_command(cmd)

        try:
            data = json.loads(output)
            if get_set:
                return data.get("set", False)

            # Try to get the value in order of preference
            for key in ["int", "float", "str", "bool"]:
                if key in data:
                    return data[key]

            return None

        except json.JSONDecodeError:
            raise ValueError(f"Failed to parse hyprctl output: {output}")

    @staticmethod
    def get_rofi_override_string() -> str:
        """
        Generate the rofi override string based on hyprctl options and environment variables.

        Returns:
            The formatted rofi override string.
        """
        font_scale = os.getenv("ROFI_CLIPHIST_SCALE", os.getenv("ROFI_SCALE", "10"))
        font_name = os.getenv("ROFI_CLIPHIST_FONT", os.getenv("ROFI_FONT"))
        # if not font_name:
        #     font_name = HyprctlWrapper.getoption("general:font_name")
        font_name = font_name or "JetBrainsMono Nerd Font"

        hypr_border = HyprctlWrapper.getoption("decoration:rounding")
        wind_border = hypr_border * 3 // 2 if hypr_border else 5
        elem_border = hypr_border if hypr_border else 5

        hypr_width = HyprctlWrapper.getoption("general:border_size")

        font_override = f'* {{font: "{font_name} {font_scale}";}}'
        r_override = (
            f"window{{border:{hypr_width}px;border-radius:{wind_border}px;}}"
            f"wallbox{{border-radius:{elem_border}px;}}"
            f"element{{border-radius:{elem_border}px;}}"
        )

        return f"{font_override} {r_override}"

    @staticmethod
    def get_rofi_pos() -> str:
        """
        Get the rofi position based on the cursor position and monitor configuration.

        Returns:
            The formatted rofi position string.
        """
        cursor_pos = json.loads(
            HyprctlWrapper._execute_command(["hyprctl", "cursorpos", "-j"])
        )
        monitors = json.loads(
            HyprctlWrapper._execute_command(["hyprctl", "monitors", "-j"])
        )

        focused_monitor = next(
            (monitor for monitor in monitors if monitor["focused"]), None
        )
        if not focused_monitor:
            raise RuntimeError("No focused monitor found.")

        mon_res = [
            focused_monitor["width"],
            focused_monitor["height"],
            int(focused_monitor["scale"] * 100),
            focused_monitor["x"],
            focused_monitor["y"],
        ]
        off_res = focused_monitor["reserved"]

        mon_res[0] = mon_res[0] * 100 // mon_res[2]
        mon_res[1] = mon_res[1] * 100 // mon_res[2]
        cur_pos = [cursor_pos["x"] - mon_res[3], cursor_pos["y"] - mon_res[4]]

        if cur_pos[0] >= mon_res[0] // 2:
            x_pos = "east"
            x_off = -(mon_res[0] - cur_pos[0] - off_res[2])
        else:
            x_pos = "west"
            x_off = cur_pos[0] - off_res[0]

        if cur_pos[1] >= mon_res[1] // 2:
            y_pos = "south"
            y_off = -(mon_res[1] - cur_pos[1] - off_res[3])
        else:
            y_pos = "north"
            y_off = cur_pos[1] - off_res[1]

        coordinates = (
            f"window{{location:{x_pos} {y_pos};"
            f"anchor:{x_pos} {y_pos};"
            f"x-offset:{x_off}px;"
            f"y-offset:{y_off}px;}}"
        )
        return coordinates

    @staticmethod
    def is_hovered() -> bool:
        """
        Check if the cursor is hovered on a window.

        Returns:
            True if the cursor is hovered on a window, False otherwise.
        """
        data = json.loads(
            HyprctlWrapper._execute_command(
                ["hyprctl", "--batch", "-j", "cursorpos;activewindow"]
            )
        )

        cursor_x = data.get("x", 0)
        cursor_y = data.get("y", 0)
        window_x = data.get("at", [0, 0])[0]
        window_y = data.get("at", [0, 0])[1]
        window_size_x = data.get("size", [0, 0])[0]
        window_size_y = data.get("size", [0, 0])[1]

        if (
            window_x <= cursor_x <= window_x + window_size_x
            and window_y <= cursor_y <= window_y + window_size_y
        ):
            return True
        return False
