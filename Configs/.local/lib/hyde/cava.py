#!/usr/bin/env python3
"""
#TODO: I am trying to learn a good way to use sockets.
#? This implementation is a POC for other rewrites to avoid multiple IO and System calls.
Cava Manager and Client using Unix Sockets
This script can act as both a manager (server) and client (reader)
- Manager: Runs a single cava instance and broadcasts to multiple clients via socket
- Client: Connects to the socket and reads cava data with formatting
"""

import socket
import subprocess
import os
import sys
import threading
import time
import argparse
import signal
import atexit
import json
import shlex
from pathlib import Path


class HydeConfig:
    """Handle Hyde configuration loading and parsing"""

    def __init__(self):
        self.config = self._load_config()

    def _load_config(self):
        """Load Hyde configuration from $XDG_STATE_HOME/hyde/config"""
        state_dir = os.path.expanduser(os.getenv("XDG_STATE_HOME", "~/.local/state"))
        config_file = os.path.join(state_dir, "hyde", "config")

        if not os.path.exists(config_file):
            return {}

        config = {}
        try:
            with open(config_file, "r") as f:
                for line in f:
                    line = line.strip()
                    if line.startswith("export ") and "=" in line:
                        line = line[7:]
                        if "=" in line:
                            key, value = line.split("=", 1)
                            value = value.strip()
                            if value.startswith("(") and value.endswith(")"):
                                # Remove parentheses and split using shlex to respect quotes
                                value = value[1:-1].strip()
                                value = shlex.split(value)
                            else:
                                value = value.strip("\"'")
                            config[key] = value
        except Exception as e:
            print(f"Warning: Could not load Hyde config: {e}", file=sys.stderr)

        return config

    def get_value(self, key, default=None):
        """Get value from Hyde config, falling back to environment, then default"""
        return self.config.get(key, os.getenv(key, default))


class CavaDataParser:
    """Handle cava data parsing and formatting"""

    @staticmethod
    def format_data(line, bar_chars="▁▂▃▄▅▆▇█", width=None, standby_mode=""):
        """Format cava data with custom bar characters (list or string)"""
        line = line.strip()
        if not line:
            return CavaDataParser._handle_standby_mode(standby_mode, bar_chars, width)

        try:
            values = [int(x) for x in line.split(";") if x.isdigit()]
        except ValueError:
            return CavaDataParser._handle_standby_mode(standby_mode, bar_chars, width)

        if not values or all(v == 0 for v in values):
            return CavaDataParser._handle_standby_mode(standby_mode, bar_chars, width)

        if not width:
            width = len(values)

        if len(values) != width:
            expanded_values = []
            for i in range(width):
                original_pos = (i * (len(values) - 1)) / (width - 1) if width > 1 else 0

                left_idx = int(original_pos)
                right_idx = min(left_idx + 1, len(values) - 1)

                if left_idx == right_idx:
                    expanded_values.append(values[left_idx])
                else:
                    fraction = original_pos - left_idx
                    interpolated = (
                        values[left_idx] + (values[right_idx] - values[left_idx]) * fraction
                    )
                    expanded_values.append(int(round(interpolated)))

            values = expanded_values

        bar_length = len(bar_chars)
        result = ""

        for value in values:
            if value >= bar_length:
                char_index = bar_length - 1
            else:
                char_index = value
            # bar_chars can be a list or string
            result += bar_chars[char_index]

        return result

    @staticmethod
    def _handle_standby_mode(standby_mode, bar_chars, width):
        """Handle standby mode when no audio activity - matches bash script logic"""
        if isinstance(standby_mode, str):
            return standby_mode
        elif standby_mode == 0:
            return ""
        elif standby_mode == 1:
            return "‎ "
        elif standby_mode == 2:
            full_char = bar_chars[-1]
            return full_char * (width or len(bar_chars))
        elif standby_mode == 3:
            low_char = bar_chars[0]
            return low_char * (width or len(bar_chars))
        else:
            return str(standby_mode)


class CavaServer:
    """Cava server that manages the cava process and broadcasts to clients"""

    def __init__(self):
        self.runtime_dir = os.getenv("XDG_RUNTIME_DIR", os.path.join("/run/user", str(os.getuid())))
        self.socket_file = os.path.join(self.runtime_dir, "hyde", "cava.sock")
        self.pid_file = os.path.join(self.runtime_dir, "hyde", "cava.pid")
        self.temp_dir = Path(os.path.join(self.runtime_dir, "hyde"))
        self.config_file = self.temp_dir / "cava.manager.conf"

        self.clients = []
        self.clients_lock = threading.Lock()
        self.cava_process = None
        self.server_socket = None
        self.cleanup_registered = False
        self.successfully_started = False
        self.consecutive_zero_count = 0
        self.zero_threshold = 50
        self.last_client_time = time.time()
        self.should_shutdown = False

    def _signal_handler(self, signum, frame):
        """Handle signals gracefully"""
        self.cleanup()
        sys.exit(0)

    def cleanup(self):
        """Cleanup function called on exit"""
        if not (self.successfully_started and (self.server_socket or self.cava_process)):
            return

        print(f"Shutting down cava manager (PID: {os.getpid()})...")

        if self.cava_process and self.cava_process.poll() is None:
            self.cava_process.terminate()
            try:
                self.cava_process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                self.cava_process.kill()

        with self.clients_lock:
            for client_socket in self.clients[:]:
                try:
                    client_socket.close()
                except Exception:
                    pass
            self.clients.clear()

        if self.server_socket:
            self.server_socket.close()

        if self.server_socket and os.path.exists(self.socket_file):
            owns_pid_file = False
            if os.path.exists(self.pid_file):
                try:
                    with open(self.pid_file, "r") as f:
                        pid = int(f.read().strip())
                    owns_pid_file = pid == os.getpid()
                except (ValueError, IOError, FileNotFoundError):
                    pass

            if owns_pid_file or not os.path.exists(self.pid_file):
                os.remove(self.socket_file)
                print(f"Removed socket file: {self.socket_file}")

        if self.server_socket and os.path.exists(self.pid_file):
            try:
                with open(self.pid_file, "r") as f:
                    pid = int(f.read().strip())
                if pid == os.getpid():
                    os.remove(self.pid_file)
                    print(f"Removed PID file: {self.pid_file}")
            except (ValueError, IOError, FileNotFoundError):
                pass

        print("Cleanup complete.")

    def _write_pid_file(self):
        """Write PID file to prevent multiple managers"""
        self.temp_dir.mkdir(parents=True, exist_ok=True)
        with open(self.pid_file, "w") as f:
            f.write(str(os.getpid()))

    def _quick_check_running(self):
        """Quick check if manager is running without acquiring locks"""
        if os.path.exists(self.socket_file):
            try:
                with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as test_socket:
                    test_socket.settimeout(0.5)
                    test_socket.connect(self.socket_file)
                return True
            except (ConnectionRefusedError, FileNotFoundError, OSError, socket.timeout):
                try:
                    os.remove(self.socket_file)
                except FileNotFoundError:
                    pass

        if os.path.exists(self.pid_file):
            try:
                with open(self.pid_file, "r") as f:
                    pid = int(f.read().strip())

                try:
                    os.kill(pid, 0)
                    return True
                except OSError:
                    try:
                        os.remove(self.pid_file)
                    except FileNotFoundError:
                        pass
            except (ValueError, IOError):
                try:
                    os.remove(self.pid_file)
                except FileNotFoundError:
                    pass

        return False

    def _check_auto_shutdown(self):
        """Check if manager should auto-shutdown when no clients are connected"""
        while not self.should_shutdown:
            time.sleep(1)
            with self.clients_lock:
                if not self.clients and time.time() - self.last_client_time > 1:
                    print("No clients connected for 5 seconds, shutting down...")
                    self.should_shutdown = True
                    break

    def _broadcast_data(self, data):
        """Broadcast data to all connected clients"""
        with self.clients_lock:
            disconnected_clients = []
            for client_socket in self.clients:
                try:
                    client_socket.sendall(data)
                except (BrokenPipeError, ConnectionResetError, OSError):
                    disconnected_clients.append(client_socket)

            for client in disconnected_clients:
                try:
                    client.close()
                except Exception:
                    pass
                if client in self.clients:
                    self.clients.remove(client)

            # If no clients remain, trigger shutdown immediately
            if not self.clients and not self.should_shutdown:
                print("All clients disconnected, shutting down cava manager.")
                self.should_shutdown = True
                # Terminate cava process to unblock main loop
                if self.cava_process and self.cava_process.poll() is None:
                    try:
                        self.cava_process.terminate()
                    except Exception:
                        pass

    def _handle_client_connections(self):
        """Handle incoming client connections and listen for reload command"""
        while not self.should_shutdown:
            try:
                conn, addr = self.server_socket.accept()
                print("New client connected")
                threading.Thread(
                    target=self._client_command_listener, args=(conn,), daemon=True
                ).start()
                with self.clients_lock:
                    self.clients.append(conn)
                    self.last_client_time = time.time()
            except OSError:
                break

    def _client_command_listener(self, conn):
        """Listen for special commands from a client (e.g., reload)"""
        try:
            conn.settimeout(0.1)
            data = b""
            while True:
                try:
                    chunk = conn.recv(1024)
                    if not chunk:
                        break
                    data += chunk
                    if b"\n" in data:
                        line, data = data.split(b"\n", 1)
                        if line.strip() == b"CMD:RELOAD":
                            print("Received reload command from client.")
                            self._reload_cava_process()
                except socket.timeout:
                    break
        except Exception:
            pass

    def _reload_cava_process(self):
        """Restart cava process and reload config with latest values"""
        print("Reloading cava process...")
        if self.cava_process and self.cava_process.poll() is None:
            self.cava_process.terminate()
            try:
                self.cava_process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                self.cava_process.kill()
        # Always use latest config values
        hyde_config = HydeConfig()
        bars = int(hyde_config.get_value("CAVA_BARS", 16))
        range_val = int(hyde_config.get_value("CAVA_RANGE", 15))
        channels = hyde_config.get_value("CAVA_CHANNELS", "stereo")
        reverse = hyde_config.get_value("CAVA_REVERSE", 0)
        try:
            reverse = int(reverse)
        except Exception:
            reverse = 1 if str(reverse).lower() in ("true", "yes", "on") else 0
        self._create_cava_config(bars, range_val, channels, reverse)
        try:
            self.cava_process = subprocess.Popen(
                ["cava", "-p", str(self.config_file)],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )
            print("Cava process restarted.")
        except FileNotFoundError:
            print("Error: cava not found. Please install cava.")

    def _create_cava_config(self, bars=16, range_val=15, channels="stereo", reverse=0, prefix=""):
        """Create cava configuration file with channels and reverse support, using HydeConfig with or without prefix as appropriate"""
        hyde_config = HydeConfig()

        if prefix:
            config_channels = hyde_config.get_value(f"CAVA_{prefix}_CHANNELS")
            config_reverse = hyde_config.get_value(f"CAVA_{prefix}_REVERSE")
        else:
            config_channels = hyde_config.get_value("CAVA_CHANNELS")
            config_reverse = hyde_config.get_value("CAVA_REVERSE")
        if config_channels in ("mono", "stereo"):
            channels = config_channels
        if config_reverse is not None:
            try:
                reverse = int(config_reverse)
            except ValueError:
                reverse = 1 if str(config_reverse).lower() in ("true", "yes", "on") else 0

        self.temp_dir.mkdir(parents=True, exist_ok=True)

        config_content = f"""[general]
bars = {bars}
sleep_timer = 1

[input]
method = pulse
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = {range_val}
channels = {channels}
reverse = {reverse}
"""

        with open(self.config_file, "w") as f:
            f.write(config_content)

    def start(self, bars=16, range_val=15, channels="stereo", reverse=0):
        """Start the cava server"""
        self.shutdown_event = threading.Event()
        threads = []
        try:
            self.temp_dir.mkdir(parents=True, exist_ok=True)
            self.server_socket = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            try:
                self.server_socket.bind(self.socket_file)
                self.server_socket.listen(10)
            except OSError as e:
                error_msg = {
                    98: "Error: Cava manager is already running",
                    2: None,  # Handle directory creation separately
                }.get(e.errno, f"Error: Could not bind to socket: {e}")

                if e.errno == 2:
                    os.makedirs(os.path.dirname(self.socket_file), exist_ok=True)
                    try:
                        self.server_socket.bind(self.socket_file)
                        self.server_socket.listen(10)
                    except OSError as e2:
                        error_msg = (
                            "Error: Cava manager is already running"
                            if e2.errno == 98
                            else f"Error: Could not bind to socket: {e2}"
                        )
                        print(error_msg)
                        self.server_socket.close()
                        self.server_socket = None
                        sys.exit(1)
                else:
                    print(error_msg)
                    self.server_socket.close()
                    self.server_socket = None
                    sys.exit(1)

            print(f"Cava manager started. Socket: {self.socket_file}")

            if not self.cleanup_registered:
                atexit.register(self.cleanup)
                self.cleanup_registered = True
                self.successfully_started = True

            self._write_pid_file()
            self._create_cava_config(bars, range_val, channels, reverse)

            print(f"Starting cava with config: {self.config_file}")
            try:
                self.cava_process = subprocess.Popen(
                    ["cava", "-p", str(self.config_file)],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                )
            except FileNotFoundError:
                print("Error: cava not found. Please install cava.")
                sys.exit(1)

            def read_cava_output():
                import select

                while not self.shutdown_event.is_set():
                    if self.cava_process.stdout:
                        rlist, _, _ = select.select([self.cava_process.stdout], [], [], 0.2)
                        if rlist:
                            line = self.cava_process.stdout.readline()
                            if not line or self.shutdown_event.is_set():
                                break
                            line_stripped = line.strip()
                            if line_stripped:
                                values = [x for x in line_stripped.split(";") if x.isdigit()]
                                if values and all(int(v) == 0 for v in values):
                                    self.consecutive_zero_count += 1
                                    if self.consecutive_zero_count <= self.zero_threshold:
                                        self._broadcast_data(line.encode("utf-8"))
                                else:
                                    self.consecutive_zero_count = 0
                                    if values:
                                        self._broadcast_data(line.encode("utf-8"))
                        else:
                            continue
                    else:
                        break

            def handle_client_connections():
                while not self.shutdown_event.is_set():
                    try:
                        self.server_socket.settimeout(0.2)
                        conn, addr = self.server_socket.accept()
                        print("New client connected")
                        threading.Thread(
                            target=self._client_command_listener,
                            args=(conn,),
                            daemon=True,
                        ).start()
                        with self.clients_lock:
                            self.clients.append(conn)
                            self.last_client_time = time.time()
                    except socket.timeout:
                        continue
                    except OSError:
                        break

            def check_auto_shutdown():
                while not self.shutdown_event.is_set():
                    time.sleep(1)
                    with self.clients_lock:
                        if not self.clients and time.time() - self.last_client_time > 1:
                            print("No clients connected for 5 seconds, shutting down...")
                            self.shutdown_event.set()
                            break

            threads.append(threading.Thread(target=handle_client_connections, daemon=True))
            threads.append(threading.Thread(target=check_auto_shutdown, daemon=True))
            threads.append(threading.Thread(target=read_cava_output, daemon=True))
            for t in threads:
                t.start()

            def shutdown_handler(signum=None, frame=None):
                self.shutdown_event.set()
                for t in threads:
                    t.join(timeout=2)
                if self.cava_process and self.cava_process.poll() is None:
                    try:
                        self.cava_process.terminate()
                        self.cava_process.wait(timeout=2)
                    except Exception:
                        try:
                            self.cava_process.kill()
                        except Exception:
                            pass
                self.cleanup()
                os._exit(0)

            signal.signal(signal.SIGTERM, shutdown_handler)
            signal.signal(signal.SIGINT, shutdown_handler)
            try:
                while not self.shutdown_event.is_set():
                    time.sleep(0.2)
            except KeyboardInterrupt:
                shutdown_handler()

        except Exception as e:
            print(f"Error starting manager: {e}")
            sys.exit(1)
        finally:
            self.cleanup()
            os._exit(0)

    def is_running(self):
        """Check if the server is running"""
        return self._quick_check_running()

    def start_in_background(self, bars=16, range_val=15):
        """Start the manager in background and return immediately"""
        if self.is_running():
            return True

        script_path = os.path.abspath(__file__)
        try:
            process = subprocess.Popen(
                [
                    sys.executable,
                    script_path,
                    "manager",
                    "--bars",
                    str(bars),
                    "--range",
                    str(range_val),
                ],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
            )

            max_wait = 5
            start_time = time.time()
            while time.time() - start_time < max_wait:
                if self.is_running():
                    return True
                time.sleep(0.1)

            if process.poll() is None:
                time.sleep(0.5)
                if self.is_running():
                    return True

            return False
        except Exception as e:
            print(f"Failed to start manager in background: {e}", file=sys.stderr)
            return False


class CavaClient:
    """Cava client that connects to the server and formats output"""

    def __init__(self):
        self.runtime_dir = os.getenv("XDG_RUNTIME_DIR", os.path.join("/run/user", str(os.getuid())))
        self.socket_file = os.path.join(self.runtime_dir, "hyde", "cava.sock")
        self.parser = CavaDataParser()

    def _auto_start_manager_if_needed(self, bars=16, range_val=15):
        """Automatically start manager if not running"""
        server = CavaServer()
        if not server.is_running():
            print("Manager not running, starting automatically...", file=sys.stderr)
            if server.start_in_background(bars, range_val):
                print("Manager started successfully", file=sys.stderr)
                return True
            else:
                print("Failed to start manager automatically", file=sys.stderr)
                return False
        return True

    def start(
        self,
        bar_chars="▁▂▃▄▅▆▇█",
        width=None,
        standby_mode=0,
        timeout=10,
        bars=16,
        range_val=15,
        json_output=False,
    ):
        """Start the cava client"""
        if not self._auto_start_manager_if_needed(bars, range_val):
            print("Error: Could not start cava manager", file=sys.stderr)
            sys.exit(1)

        start_time = time.time()
        while not os.path.exists(self.socket_file):
            if time.time() - start_time > timeout:
                print("Error: Cava manager not accessible after timeout", file=sys.stderr)
                sys.exit(1)
            time.sleep(0.1)

        try:
            client_socket = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            client_socket.connect(self.socket_file)

            standby_output = self.parser._handle_standby_mode(standby_mode, bar_chars, width)
            if not (
                (standby_mode == 0 and standby_output == "")
                or (standby_mode == "" and standby_output == "")
            ):
                if json_output:
                    output = {
                        "text": standby_output,
                        "tooltip": "Cava audio visualizer - standby mode",
                    }
                    print(json.dumps(output), flush=True)
                else:
                    print(standby_output, flush=True)

            buffer = ""
            while True:
                data = client_socket.recv(1024)
                if not data:
                    break

                decoded_data = data.decode("utf-8")
                if decoded_data.strip():
                    buffer += decoded_data

                    while "\n" in buffer:
                        line, buffer = buffer.split("\n", 1)
                        if line.strip():
                            formatted = self.parser.format_data(
                                line, bar_chars, width, standby_mode
                            )
                            should_suppress = (standby_mode == 0 and formatted == "") or (
                                standby_mode == "" and formatted == ""
                            )
                            if not should_suppress:
                                if json_output:
                                    output = {
                                        "text": formatted,
                                        "tooltip": "Cava audio visualizer - active",
                                    }
                                    print(json.dumps(output), flush=True)
                                else:
                                    print(formatted, flush=True)

        except (ConnectionRefusedError, FileNotFoundError):
            print("Error: Cannot connect to cava manager", file=sys.stderr)
            sys.exit(1)
        except KeyboardInterrupt:
            pass
        finally:
            try:
                client_socket.close()
            except Exception:
                pass

    @staticmethod
    def parse_command_config(hyde_config, command, args):
        """Parse configuration for a specific command type"""
        prefix = f"CAVA_{command.upper()}"

        # Prefer --bar-array if present
        if hasattr(args, "bar_array") and args.bar_array:
            bar_chars = args.bar_array
        else:
            # Prefer BAR_ARRAY from config if present and is a list
            bar_array = hyde_config.get_value(f"{prefix}_BAR_ARRAY")
            if bar_array and isinstance(bar_array, list):
                bar_chars = bar_array
            else:
                bar_chars = args.bar or hyde_config.get_value(f"{prefix}_BAR", "▁▂▃▄▅▆▇█")
                if isinstance(bar_chars, str):
                    bar_chars = list(bar_chars)

        width = (
            args.width
            if args.width is not None
            else int(hyde_config.get_value(f"{prefix}_WIDTH", "0") or 0)
        )
        if not width:
            width = len(bar_chars) if bar_chars else 8

        if args.stb is not None:
            standby_mode = args.stb
            if isinstance(standby_mode, str) and standby_mode.isdigit():
                standby_mode = int(standby_mode)
        else:
            standby_mode = hyde_config.get_value(f"{prefix}_STANDBY", "0")
            if standby_mode is None or standby_mode == "":
                standby_mode = "\n"
            elif isinstance(standby_mode, str) and standby_mode.isdigit():
                standby_mode = int(standby_mode)

        return bar_chars, width, standby_mode


class CavaReloadClient:
    """Minimal client to send reload command to the server"""

    def __init__(self):
        self.runtime_dir = os.getenv("XDG_RUNTIME_DIR", os.path.join("/run/user", str(os.getuid())))
        self.socket_file = os.path.join(self.runtime_dir, "hyde", "cava.sock")

    def reload(self):
        if not os.path.exists(self.socket_file):
            print("Cava manager is not running.")
            sys.exit(1)
        try:
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.connect(self.socket_file)
            s.sendall(b"CMD:RELOAD\n")
            s.close()
            print("Reload command sent.")
        except Exception as e:
            print(f"Failed to send reload command: {e}")
            sys.exit(1)


def create_client_parser(subparsers, name, help_text):
    """Create a client parser with common arguments"""
    parser = subparsers.add_parser(name, help=help_text)
    parser.add_argument("--bar", default=None, help="Bar characters")
    parser.add_argument(
        "--bar-array",
        nargs="+",
        help="Bar characters as an array (e.g. --bar-array '<span color=red>#</span>' '<span color=green>#</span>')",
    )
    parser.add_argument("--width", type=int, help="Bar width")
    parser.add_argument(
        "--stb",
        default=None,
        help='Standby mode (0-3 or string): 0=clean (totally hides the module), 1=blank (makes module expand as spaces), 2=full (occupies the module with full bar), 3=low (makes the module display the lowest set bar), ""=displays nothing and compresses the module, string=displays the custom string',
    )
    if name == "waybar":
        parser.add_argument(
            "--json", action="store_true", help="Output JSON format for waybar tooltips"
        )
    return parser


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="Cava Manager and Client")
    subparsers = parser.add_subparsers(dest="command", help="Commands")

    manager_parser = subparsers.add_parser("manager", help="Start cava manager")
    manager_parser.add_argument("--bars", type=int, default=16, help="Number of bars")
    manager_parser.add_argument("--range", type=int, default=15, help="ASCII range")
    manager_parser.add_argument(
        "--channels",
        choices=["mono", "stereo"],
        default="stereo",
        help="Audio channels: mono or stereo",
    )
    manager_parser.add_argument(
        "--reverse",
        type=int,
        choices=[0, 1],
        default=0,
        help="Reverse frequency order: 0=normal, 1=reverse",
    )

    create_client_parser(subparsers, "waybar", "Waybar client")
    create_client_parser(subparsers, "stdout", "Stdout client")
    create_client_parser(subparsers, "hyprlock", "Hyprlock client")

    subparsers.add_parser("status", help="Check manager status")
    subparsers.add_parser("reload", help="Reload cava manager (restart cava process)")

    args = parser.parse_args()

    if args.command == "manager":
        server = CavaServer()
        if server.is_running():
            print("Cava manager is already running")
            sys.exit(0)

        server.start(args.bars, args.range, args.channels, args.reverse)

    elif args.command in ["waybar", "stdout", "hyprlock"]:
        hyde_config = HydeConfig()

        bar_chars, width, standby_mode = CavaClient.parse_command_config(
            hyde_config, args.command, args
        )

        bars = width
        range_val = int(hyde_config.get_value("CAVA_RANGE", "15"))

        json_output = args.command == "waybar" and hasattr(args, "json") and args.json

        client = CavaClient()
        client.start(
            bar_chars,
            width,
            standby_mode,
            bars=bars,
            range_val=range_val,
            json_output=json_output,
        )

    elif args.command == "status":
        server = CavaServer()
        if server.is_running():
            print("Cava manager is running")
            sys.exit(0)
        else:
            print("Cava manager is not running")
            sys.exit(1)

    elif args.command == "reload":
        CavaReloadClient().reload()

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
