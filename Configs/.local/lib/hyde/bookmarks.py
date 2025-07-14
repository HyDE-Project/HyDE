from pathlib import Path
import argparse

class XDGPaths:
    def __init__(self):
        import os
        self.HOME = str(Path.home())
        self.xdg_cache = os.environ.get("XDG_CACHE_HOME", os.path.join(self.HOME, ".cache"))
        self.xdg_config = os.environ.get("XDG_CONFIG_HOME", os.path.join(self.HOME, ".config"))
        self.xdg_runtime = os.environ.get("XDG_RUNTIME_DIR", os.path.join(self.HOME, ".local/share"))
        self.xdg_data = os.environ.get("XDG_DATA_HOME", os.path.join(self.HOME, ".local/share"))
        self.CACHE_DIR = os.path.join(self.xdg_cache, "hyde")
        self.CONFIG_DIR = os.path.join(self.xdg_config, "hyde")
        self.RUNTIME_DIR = os.path.join(self.xdg_runtime, "hyde")
        self.DATA_DIR = os.path.join(self.xdg_data, "hyde")
        self.RECENT_FILE = os.path.join(self.CACHE_DIR, "landing/show_bookmarks.recent")
        self.RECENT_NUMBER = 5

class BookmarkManager:
    def __init__(self, xdg: XDGPaths):
        self.xdg = xdg

    def find_bookmark_files(self):
        import os
        files = []
        # Firefox
        for root, dirs, filelist in os.walk(os.path.join(self.xdg.HOME, ".mozilla/firefox")):
            for file in filelist:
                if file == "places.sqlite":
                    files.append(os.path.join(root, file))
        # Chromium/Brave/Chrome
        for path in [
            os.path.join(self.xdg.xdg_config, "BraveSoftware/Brave-Browser/Default/Bookmarks"),
            os.path.join(self.xdg.xdg_config, "chromium/Default/Bookmarks"),
            os.path.join(self.xdg.xdg_config, "google-chrome/Default/Bookmarks"),
        ]:
            if os.path.exists(path):
                files.append(path)
        # Custom .lst files
        for path in [
            os.path.join(self.xdg.xdg_config, "hyde/bookmarks.lst"),
        ]:
            if os.path.exists(path):
                files.append(path)
        return files

    def read_firefox_bookmarks(self, places_file):
        import sqlite3
        import sys
        query = """
        SELECT b.title, p.url
        FROM moz_bookmarks AS b
        LEFT JOIN moz_places AS p ON b.fk = p.id
        WHERE b.type = 1 AND p.hidden = 0 AND b.title IS NOT NULL
        """
        bookmarks = []
        try:
            conn = sqlite3.connect(places_file)
            for title, url in conn.execute(query):
                if not title:
                    title = url
                bookmarks.append({"title": title, "url": url})
            conn.close()
        except Exception as e:
            print(f"Error reading Firefox bookmarks: {e}", file=sys.stderr)
        return bookmarks

    def read_chromium_bookmarks(self, bookmarks_file):
        import json
        import sys
        bookmarks = []
        try:
            with open(bookmarks_file, "r") as f:
                data = json.load(f)
            for item in data.get("roots", {}).get("bookmark_bar", {}).get("children", []):
                if "url" in item:
                    bookmarks.append({"title": item.get("name", item["url"]), "url": item["url"]})
            for item in data.get("roots", {}).get("other", {}).get("children", []):
                if "url" in item:
                    bookmarks.append({"title": item.get("name", item["url"]), "url": item["url"]})
        except Exception as e:
            print(f"Error reading Chromium bookmarks: {e}", file=sys.stderr)
        return bookmarks

    def read_custom_lst(self, lst_file):
        import sys
        bookmarks = []
        try:
            with open(lst_file, "r") as f:
                for line in f:
                    line = line.strip()
                    if not line or "|" not in line:
                        continue
                    title, url = [x.strip() for x in line.split("|", 1)]
                    bookmarks.append({"title": title, "url": url})
        except Exception as e:
            print(f"Error reading custom bookmarks: {e}", file=sys.stderr)
        return bookmarks

    def read_recent(self):
        import os
        import sys
        bookmarks = []
        if not os.path.exists(self.xdg.RECENT_FILE):
            return bookmarks
        try:
            with open(self.xdg.RECENT_FILE, "r") as f:
                for line in f:
                    line = line.strip()
                    if "|" in line:
                        title, url = [x.strip() for x in line.split("|", 1)]
                        bookmarks.append({"title": title, "url": url})
        except Exception as e:
            print(f"Error reading recent bookmarks: {e}", file=sys.stderr)
        return bookmarks

    def save_recent(self, title, url):
        import os
        lines = [f"{title} | {url}"]
        if os.path.exists(self.xdg.RECENT_FILE):
            with open(self.xdg.RECENT_FILE, "r") as f:
                for line in f:
                    line = line.strip()
                    if line and line != lines[0]:
                        lines.append(line)
        seen = set()
        unique_lines = []
        for line in lines:
            if line not in seen and line:
                unique_lines.append(line)
                seen.add(line)
            if len(unique_lines) >= self.xdg.RECENT_NUMBER:
                break
        os.makedirs(os.path.dirname(self.xdg.RECENT_FILE), exist_ok=True)
        with open(self.xdg.RECENT_FILE, "w") as f:
            for line in unique_lines:
                f.write(line + "\n")

    def get_all_bookmarks(self, isCustom=True):
        files = self.find_bookmark_files()
        all_bookmarks = []
        for file in files:
            if file.endswith(".sqlite"):
                all_bookmarks.extend(self.read_firefox_bookmarks(file))
            elif file.endswith(".lst"):
                if isCustom:
                    all_bookmarks.extend(self.read_custom_lst(file))
            else:
                all_bookmarks.extend(self.read_chromium_bookmarks(file))
        all_bookmarks.extend(self.read_recent())
        # Deduplicate by title and url, sort by title
        seen = set()
        unique_bookmarks = []
        for bm in all_bookmarks:
            key = (bm["title"], bm["url"])
            if key not in seen:
                unique_bookmarks.append(bm)
                seen.add(key)
        unique_bookmarks.sort(key=lambda x: x["title"].lower())
        return unique_bookmarks

    def list_bookmarks(self, bookmarks):
        for idx, bm in enumerate(bookmarks, 1):
            print(f"{idx}) {bm['title']}")

    def open_bookmark(self, url, browser=None):
        import subprocess
        if browser:
            subprocess.run([browser, url])
        else:
            subprocess.run(["xdg-open", url])

    def open_by_selection(self, selection, bookmarks, browser=None):
        import sys
        # Parse index from selection string like '1) Title'
        try:
            index = int(selection.split(')', 1)[0].strip())
            bm = bookmarks[index - 1]
            self.save_recent(bm['title'], bm['url'])
            self.open_bookmark(bm['url'], browser)
            sys.exit()
        except Exception as e:
            print(f"Error: {e}", file=sys.stderr)

def main():
    parser = argparse.ArgumentParser(description="Bookmarks manager (feature parity with bookmarks.sh)")
    parser.add_argument('--browser', '-b', type=str, help='Set browser command (default: $BROWSER env or xdg-open)')
    parser.add_argument('--no-custom', action='store_true', help='Run without custom .lst bookmark files')
    parser.add_argument('--list', action='store_true', help='List bookmarks and exit')
    parser.add_argument('selection', nargs='?', type=str, help='Selected bookmark string from rofi (e.g. "1) Title")')
    args = parser.parse_args()

    xdg = XDGPaths()
    manager = BookmarkManager(xdg)
    bookmarks = manager.get_all_bookmarks(isCustom=not args.no_custom)
    if args.selection:
        manager.open_by_selection(args.selection, bookmarks, args.browser)
        return
    manager.list_bookmarks(bookmarks)
    if args.list:
        import sys
        sys.exit(0)

if __name__ == "__main__":
    main()
