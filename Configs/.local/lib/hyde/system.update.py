import curses
import subprocess
import threading

def curses_interactive(records: list[UpdateRecord]) -> int:
    def run_raw_output(raw_win, cmd):
        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        for line in proc.stdout:
            raw_win.addstr(line.decode())
            raw_win.refresh()

    def main(stdscr):
        curses.curs_set(0)
        stdscr.clear()
        height, width = stdscr.getmaxyx()

        # Split screen: top half summary, bottom half raw output
        summary_win = curses.newwin(height // 2, width, 0, 0)
        raw_win = curses.newwin(height // 2, width, height // 2, 0)

        # Draw summary
        summary_win.addstr(0, 0, "System Update Summary\n")
        summary_win.addstr(1, 0, "=" * (width - 1))
        for idx, record in enumerate(records, start=2):
            state = "pending" if record.count else "up to date"
            summary_win.addstr(idx, 0, f"{record.name:<16}{record.count:>8}  {state}")
        summary_win.refresh()

        # Example: stream raw output from one manager
        if records:
            cmd = ["echo", f"Simulated raw output for {records[0].name}..."]
            threading.Thread(target=run_raw_output, args=(raw_win, cmd), daemon=True).start()

        # Wait for user input
        summary_win.addstr(height // 2 - 2, 0, "Press 'q' to quit.")
        summary_win.refresh()
        while True:
            ch = stdscr.getch()
            if ch == ord('q'):
                break

    curses.wrapper(main)
    return 0
