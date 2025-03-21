#!/usr/bin/env python
# TODO: WIP


import sys
from dataclasses import dataclass
from signal import SIGINT, SIGTERM, signal
from threading import Event, Thread
import os
import argparse
import time

lib_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, lib_dir)

import pyutils.logger  # noqa: E402
import pyutils.pip_env as pip_env  # noqa: E402

pip_env.v_import("pywayland")  # noqa: E402
pip_env.v_import("pulsectl")  # noqa: E402
import pulsectl  # noqa: E402
from pywayland.client.display import Display  # noqa: E402
from pywayland.protocol.idle_inhibit_unstable_v1.zwp_idle_inhibit_manager_v1 import (  # noqa: E402
    ZwpIdleInhibitManagerV1,
)
from pywayland.protocol.wayland.wl_compositor import WlCompositor  # noqa: E402
from pywayland.protocol.wayland.wl_registry import WlRegistryProxy  # noqa: E402
from pywayland.protocol.wayland.wl_surface import WlSurface  # noqa: E402

logger = pyutils.logger.get_logger()  # Initialize logger


@dataclass
class GlobalRegistry:
    surface: WlSurface | None = None
    inhibit_manager: ZwpIdleInhibitManagerV1 | None = None


def handle_registry_global(
    wl_registry: WlRegistryProxy, id_num: int, iface_name: str, version: int
) -> None:
    global_registry: GlobalRegistry = wl_registry.user_data or GlobalRegistry()
    logger.debug(f"Handling registry global: {iface_name}")

    if iface_name == "wl_compositor":
        compositor = wl_registry.bind(id_num, WlCompositor, version)
        global_registry.surface = compositor.create_surface()  # type: ignore
        logger.debug("Compositor and surface created")
    elif iface_name == "zwp_idle_inhibit_manager_v1":
        global_registry.inhibit_manager = wl_registry.bind(
            id_num, ZwpIdleInhibitManagerV1, version
        )
        logger.debug("Idle inhibit manager created")


def is_audio_playing() -> bool:
    with pulsectl.Pulse("idle-inhibitor") as pulse:
        for sink_input in pulse.sink_input_list():
            if sink_input.volume.value_flat > 0:
                logger.debug(
                    f"Audio is playing: {sink_input.proplist.get('application.name', 'Unknown')}"
                )
                return True
    logger.debug("No audio playing")
    return False


def audio_listener(done: Event, audio_playing_signal: Event) -> None:
    while not done.is_set():
        logger.debug("Checking if audio is playing...")
        if is_audio_playing():
            logger.debug("Audio is playing")
            audio_playing_signal.set()
        else:
            logger.debug("No audio playing")
            audio_playing_signal.clear()
        time.sleep(3)


def main() -> None:
    parser = argparse.ArgumentParser(description="Idle inhibitor")
    parser.add_argument("--all", action="store_true", help="Inhibit idle for all cases")
    parser.add_argument(
        "--audio", action="store_true", help="Inhibit idle when there is audio"
    )
    args = parser.parse_args()

    done = Event()
    audio_playing_signal = Event()
    signal(SIGINT, lambda _, __: done.set())
    signal(SIGTERM, lambda _, __: done.set())

    global_registry = GlobalRegistry()

    display = Display()
    display.connect()
    logger.debug("Connected to display")

    registry = display.get_registry()  # type: ignore
    registry.user_data = global_registry
    registry.dispatcher["global"] = handle_registry_global

    def shutdown() -> None:
        display.dispatch()
        display.roundtrip()
        display.disconnect()
        logger.debug("Display disconnected")

    display.dispatch()
    display.roundtrip()

    if global_registry.surface is None or global_registry.inhibit_manager is None:
        logger.debug("Wayland does not support idle_inhibit_unstable_v1 protocol")
        print("Wayland seems not to support idle_inhibit_unstable_v1 protocol.")
        shutdown()
        sys.exit(1)

    global inhibitor
    inhibitor = None

    if args.all:
        inhibitor = global_registry.inhibit_manager.create_inhibitor(  # type: ignore
            global_registry.surface
        )
        logger.debug("Inhibiting idle for all cases")
        print("Inhibiting idle for all cases...")
    display.dispatch()
    display.roundtrip()

    if args.audio:
        logger.debug("Starting audio listener thread")
        audio_thread = Thread(target=audio_listener, args=(done, audio_playing_signal))
        audio_thread.start()
        logger.debug(f"Audio listener thread started: {audio_thread}")
        logger.debug(f"Initial inhibitor: {inhibitor}")
        while not done.is_set():
            if audio_playing_signal.is_set():
                if inhibitor is None:
                    logger.debug("Creating inhibitor due to audio")
                    inhibitor = global_registry.inhibit_manager.create_inhibitor(  # type: ignore
                        global_registry.surface
                    )
                    display.dispatch()
                    display.roundtrip()

                    if inhibitor:
                        logger.debug("Inhibiting idle due to audio")
                        print("Inhibiting idle due to audio...")
                    else:
                        logger.error("Failed to create inhibitor")

            else:
                if inhibitor is not None:
                    logger.debug("Destroying inhibitor due to no audio")
                    inhibitor.destroy()
                    inhibitor = None
                    logger.debug("Stopped inhibiting idle due to no audio")
                    print("Stopped inhibiting idle due to no audio")
                    shutdown()

            time.sleep(1)

    done.wait()
    logger.debug("Shutting down...")
    print("Shutting down...")

    if inhibitor:
        inhibitor.destroy()
        logger.debug("Inhibitor destroyed")

    shutdown()


if __name__ == "__main__":
    main()
