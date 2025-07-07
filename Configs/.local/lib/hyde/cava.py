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
                            value = value.strip("\"'")
                            if value.startswith("(") and value.endswith(")"):
                                value = value[1:-1].strip("\"'")
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
        """Format cava data with custom bar characters"""
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
                        values[left_idx]
                        + (values[right_idx] - values[left_idx]) * fraction
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
        self.runtime_dir = os.getenv(
            "XDG_RUNTIME_DIR", os.path.join("/run/user", str(os.getuid()))
        )
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
        if not (
            self.successfully_started and (self.server_socket or self.cava_process)
        ):
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
                if not self.clients and time.time() - self.last_client_time > 5:
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
            
            if not self.clients and disconnected_clients:
                self.last_client_time = time.time()

    def _handle_client_connections(self):
        """Handle incoming client connections"""
        while True:
            try:
                conn, addr = self.server_socket.accept()
                print("New client connected")
                with self.clients_lock:
                    self.clients.append(conn)
                    self.last_client_time = time.time()
            except OSError:
                break

    def _create_cava_config(self, bars=16, range_val=15):
        """Create cava configuration file"""
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
"""

        with open(self.config_file, "w") as f:
            f.write(config_content)

    def start(self, bars=16, range_val=15):
        """Start the cava server"""
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
                signal.signal(signal.SIGTERM, self._signal_handler)
                signal.signal(signal.SIGINT, self._signal_handler)
                self.cleanup_registered = True
                self.successfully_started = True

            self._write_pid_file()

            self._create_cava_config(bars, range_val)

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

            client_thread = threading.Thread(
                target=self._handle_client_connections, daemon=True
            )
            client_thread.start()

            auto_shutdown_thread = threading.Thread(
                target=self._check_auto_shutdown, daemon=True
            )
            auto_shutdown_thread.start()

            try:
                while not self.should_shutdown:
                    line = self.cava_process.stdout.readline()
                    if not line:
                        print("Cava process ended unexpectedly")
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

            except KeyboardInterrupt:
                print("Received interrupt signal")
                self.should_shutdown = True
                
        except Exception as e:
            print(f"Error starting manager: {e}")
            sys.exit(1)
        finally:
            self.cleanup()
            sys.exit(0)

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
        self.runtime_dir = os.getenv(
            "XDG_RUNTIME_DIR", os.path.join("/run/user", str(os.getuid()))
        )
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
                print(
                    "Error: Cava manager not accessible after timeout", file=sys.stderr
                )
                sys.exit(1)
            time.sleep(0.1)

        try:
            client_socket = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            client_socket.connect(self.socket_file)

            standby_output = self.parser._handle_standby_mode(standby_mode, bar_chars, width)
            if not ((standby_mode == 0 and standby_output == "") or (standby_mode == "" and standby_output == "")):
                if json_output:
                    output = {"text": standby_output, "tooltip": "Cava audio visualizer - standby mode"}
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
                            should_suppress = (
                                standby_mode == 0 and formatted == ""
                            ) or (standby_mode == "" and formatted == "")
                            if not should_suppress:
                                if json_output:
                                    output = {"text": formatted, "tooltip": "Cava audio visualizer - active"}
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

        bar_chars = args.bar or hyde_config.get_value(f"{prefix}_BAR", "▁▂▃▄▅▆▇█")
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
            elif standby_mode.isdigit():
                standby_mode = int(standby_mode)

        return bar_chars, width, standby_mode


def create_client_parser(subparsers, name, help_text):
    """Create a client parser with common arguments"""
    parser = subparsers.add_parser(name, help=help_text)
    parser.add_argument("--bar", default=None, help="Bar characters")
    parser.add_argument("--width", type=int, help="Bar width")
    parser.add_argument(
        "--stb",
        default=None,
        help='Standby mode (0-3 or string): 0=clean (totally hides the module), 1=blank (makes module expand as spaces), 2=full (occupies the module with full bar), 3=low (makes the module display the lowest set bar), ""=displays nothing and compresses the module, string=displays the custom string',
    )
    
    if name == "waybar":
        parser.add_argument("--json", action="store_true", help="Output JSON format for waybar tooltips")
    
    return parser


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="Cava Manager and Client")
    subparsers = parser.add_subparsers(dest="command", help="Commands")

    manager_parser = subparsers.add_parser("manager", help="Start cava manager")
    manager_parser.add_argument("--bars", type=int, default=16, help="Number of bars")
    manager_parser.add_argument("--range", type=int, default=15, help="ASCII range")

    create_client_parser(subparsers, "waybar", "Waybar client")
    create_client_parser(subparsers, "stdout", "Stdout client")
    create_client_parser(subparsers, "hyprlock", "Hyprlock client")

    subparsers.add_parser("status", help="Check manager status")

    args = parser.parse_args()

    if args.command == "manager":
        server = CavaServer()
        if server.is_running():
            print("Cava manager is already running")
            sys.exit(0)

        server.start(args.bars, args.range)

    elif args.command in ["waybar", "stdout", "hyprlock"]:
        hyde_config = HydeConfig()

        bar_chars, width, standby_mode = CavaClient.parse_command_config(
            hyde_config, args.command, args
        )

        bars = width
        range_val = int(hyde_config.get_value("CAVA_RANGE", "15"))

        json_output = args.command == "waybar" and hasattr(args, 'json') and args.json

        client = CavaClient()
        client.start(bar_chars, width, standby_mode, bars=bars, range_val=range_val, json_output=json_output)

    elif args.command == "status":
        server = CavaServer()
        if server.is_running():
            print("Cava manager is running")
            sys.exit(0)
        else:
            print("Cava manager is not running")
            sys.exit(1)

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
