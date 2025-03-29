#!/usr/bin/env python3
import gi

gi.require_version("Playerctl", "2.0")
from gi.repository import Playerctl, GLib
import argparse
import logging
import sys
import signal
import json

logger = logging.getLogger(__name__)
quote_timer_id = None  # Global variable to keep track of the quote timer

# Default variables (can be overridden by command-line arguments)
prefix_playing = ""
prefix_paused = "  "
max_length_module = 70  # Maximum combined length of track + artist
standby_text = "  Music"


def write_output(track, artist, playing, player):
    logger.info("Writing output")

    # Use the appropriate prefix based on playback status
    output = prefix_playing if playing else prefix_paused
    max_length = max_length_module

    # Calculate the total length and truncate track if necessary
    total_length = len(track) + len(artist)
    if total_length > max_length:
        available_length = max(0, max_length - len(artist))
        track = (
            f"{track[:available_length]}..." if len(track) > available_length else track
        )

    # Generate the output based on the presence of track and artist
    if track and not artist:
        output = f"{output}  <b>{track}</b>"
    elif track and artist:
        output = f"{output}  <i>{artist}</i> ~ <b>{track}</b>"
    else:
        output = "<b>Nothing playing</b>"

    output = {
        "text": output,
        "class": "custom-" + player.props.player_name,
        "alt": player.props.player_name,
    }

    sys.stdout.write(json.dumps(output) + "\n")
    sys.stdout.flush()


def on_play(player, status, manager):
    logger.info("Received new playback status")
    on_metadata(player, player.props.metadata, manager)


def on_metadata(player, metadata, manager):
    logger.info("Received new metadata")
    track = ""
    artist = ""
    playing = False

    if player.get_artist() != "" and player.get_title() != "":
        track = f"{player.get_title()}"
        artist = f"{player.get_artist()}"
    else:
        track = player.get_title()

    if track and player.props.status == "Playing":
        playing = True

    write_output(track, artist, playing, player)


def on_player_appeared(manager, player, selected_player=None):
    global quote_timer_id
    if player is not None and (
        selected_player is None or player.name == selected_player
    ):
        init_player(manager, player)
    else:
        logger.debug("New player appeared, but it's not the selected player, skipping")


def on_player_vanished(manager, player, loop):
    logger.info("Player has vanished")
    output = {
        "text": standby_text,
        "class": "custom-nothing-playing",
        "alt": "player-closed",
    }

    sys.stdout.write(json.dumps(output) + "\n")
    sys.stdout.flush()


def init_player(manager, name):
    logger.debug("Initialize player: {player}".format(player=name.name))
    player = Playerctl.Player.new_from_name(name)
    player.connect("playback-status", on_play, manager)
    player.connect("metadata", on_metadata, manager)
    manager.manage_player(player)
    on_metadata(player, player.props.metadata, manager)


def signal_handler(sig, frame):
    logger.debug("Received signal to stop, exiting")
    sys.stdout.write("\n")
    sys.stdout.flush()
    sys.exit(0)


def parse_arguments():
    parser = argparse.ArgumentParser(
        description="A media player status tool with customizable display options."
    )

    # Increase verbosity with every occurrence of -v
    parser.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        help="Increase output verbosity (e.g. -v, -vv)",
    )

    # Define for which player we're listening
    parser.add_argument("--player", help="Specify the player to listen to.")

    # Customizable display options
    parser.add_argument(
        "--prefix-playing",
        type=str,
        default=prefix_playing,
        help="Prefix displayed when media is playing (default: '%s')" % prefix_playing,
    )
    parser.add_argument(
        "--prefix-paused",
        type=str,
        default=prefix_paused,
        help="Prefix displayed when media is paused (default: '%s')" % prefix_paused,
    )
    parser.add_argument(
        "--max-length",
        type=int,
        default=max_length_module,
        help="Maximum combined length of track and artist (default: %d)"
        % max_length_module,
    )
    parser.add_argument(
        "--standby-text",
        type=str,
        default=standby_text,
        help="Text to display when no player is active (default: '%s')" % standby_text,
    )

    return parser.parse_args()


def main():
    global prefix_playing, prefix_paused, max_length_module, standby_text

    arguments = parse_arguments()
    player_found = False

    # Override defaults with command-line arguments if provided
    prefix_playing = arguments.prefix_playing
    prefix_paused = arguments.prefix_paused
    max_length_module = arguments.max_length
    standby_text = arguments.standby_text

    # Initialize logging
    logging.basicConfig(
        stream=sys.stdout,
        level=logging.DEBUG,
        format="%(name)s %(levelname)s %(message)s",
    )

    # Set logging level based on verbosity
    logger.setLevel(max((3 - arguments.verbose) * 10, 0))

    logger.debug("Arguments received {}".format(vars(arguments)))

    manager = Playerctl.PlayerManager()
    loop = GLib.MainLoop()

    manager.connect(
        "name-appeared", lambda *args: on_player_appeared(*args, arguments.player)
    )
    manager.connect("player-vanished", lambda *args: on_player_vanished(*args, loop))

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)

    for player in manager.props.player_names:
        if arguments.player is not None and arguments.player != player.name:
            logger.debug(
                "{player} is not the filtered player, skipping it".format(
                    player=player.name
                )
            )
            continue

        init_player(manager, player)
        player_found = True

    # If no player is found, generate the standby output
    if not player_found:
        output = {
            "text": standby_text,
            "class": "custom-nothing-playing",
            "alt": "player-closed",
        }

        sys.stdout.write(json.dumps(output) + "\n")
        sys.stdout.flush()

    loop.run()


if __name__ == "__main__":
    main()
