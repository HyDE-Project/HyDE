#!/usr/bin/env python3
# coding: utf-8

from subprocess import run, CalledProcessError
from typing import Optional

DEFAULT_APP_NAME = "HyDE"
DEFAULT_URGENCY = "normal"


def send(
    summary: str,
    body: Optional[str] = None,
    urgency: Optional[str] = DEFAULT_URGENCY,
    expire_time: Optional[int] = None,
    icon: Optional[str] = None,
    category: Optional[str] = None,
    app_name: Optional[str] = DEFAULT_APP_NAME,
    replace_id: Optional[int] = None,
):
    """Send a notification using notify-send.

    Parameters
    ----------
    summary : str
        The summary of the notification.
    body : Optional[str]
        The body of the notification.
    urgency : Optional[str]
        The urgency level (low, normal, critical).
    expire_time : Optional[int]
        The timeout in milliseconds at which to expire the notification.
    icon : Optional[str]
        The icon filename or stock icon to display.
    category : Optional[str]
        The notification category.
    app_name : Optional[str]
        The app name for the notification.
    replace_id : Optional[int]
        The ID of the notification to replace.
    """
    command = ["notify-send"]

    if urgency:
        command.extend(["-u", urgency])
    if expire_time:
        command.extend(["-t", str(expire_time)])
    if icon:
        command.extend(["-i", icon])
    if category:
        command.extend(["-c", category])
    if app_name:
        command.extend(["-a", app_name])
    if replace_id:
        command.extend(["-r", str(replace_id)])

    command.append(summary)
    if body:
        command.append(body)

    try:
        run(command, check=True)
    except CalledProcessError as e:
        print(f"Failed to send notification: {e}")


# Example usage
if __name__ == "__main__":
    send("Test Notification", "This is a test notification body.", urgency="normal")
