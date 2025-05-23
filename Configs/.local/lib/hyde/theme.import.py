#!/usr/bin/env python
import subprocess
import os
import json
import argparse
import sys
import pyutils.wrapper.fzf as fzf
import pyutils.logger as logger
import random

logger = logger.get_logger()

REPO_URL = "https://github.com/HyDE-Project/hyde-gallery.git"
CLONE_DIR = os.path.join(
    os.getenv("XDG_CACHE_HOME", os.path.expanduser("~/.cache")),
    "hyde/gallery-database",
)
JSON_DATA = None


def fetch_theme_preview_path(theme):
    theme_dir = os.path.join(CLONE_DIR, theme)
    if os.path.exists(theme_dir):
        images = []
        for root, dirs, files in os.walk(theme_dir):
            for file in files:
                if file.lower().endswith((".png", ".jpg", ".jpeg", ".gif")):
                    images.append(os.path.join(root, file))
        if images:
            return images


def fetch_data():
    global JSON_DATA
    json_file_path = os.path.join(CLONE_DIR, "hyde-themes.json")
    if os.path.exists(json_file_path):
        with open(json_file_path, "r") as json_file:
            JSON_DATA = json.load(json_file)
            for theme in JSON_DATA:
                theme["PREVIEW"] = fetch_theme_preview_path(theme["THEME"])
    else:
        logger.debug(f"JSON file not found: {json_file_path}")


def clone_repo():
    if os.path.exists(CLONE_DIR):
        try:
            logger.debug(f"Resetting and cleaning repository in {CLONE_DIR}")
            subprocess.run(
                ["git", "-C", CLONE_DIR, "reset", "--hard"],
                check=True,
                capture_output=True,
                text=True,
            )
            logger.debug("Reset successful")

            subprocess.run(
                ["git", "-C", CLONE_DIR, "clean", "-fdx"],
                check=True,
                capture_output=True,
                text=True,
            )
            logger.debug("Clean successful")
            result = subprocess.run(
                ["git", "-C", CLONE_DIR, "pull", "origin", "master"],
                check=True,
                capture_output=True,
                text=True,
            )
            logger.debug(result.stdout)
            logger.debug(f"Repository updated successfully in {CLONE_DIR}")
        except subprocess.CalledProcessError as e:
            logger.debug(f"Failed to update repository: {e}")
            logger.debug(e.stderr)
    else:
        try:
            logger.debug(f"Cloning repository into {CLONE_DIR}")
            result = subprocess.run(
                ["git", "clone", "--depth", "1", REPO_URL, CLONE_DIR],
                check=True,
                capture_output=True,
                text=True,
            )
            logger.debug(result.stdout)
            logger.debug(f"Repository cloned successfully into {CLONE_DIR}")
        except subprocess.CalledProcessError as e:
            logger.debug(f"Failed to clone repository: {e}")
            logger.debug(e.stderr)


def get_theme_preview(theme):
    fetch_data()
    color1 = "#39b1d6"
    color2 = "#c79bf0"
    color3 = "#ebbcba"
    color4 = "#a9b1d6"

    if theme == "[CONFIRM]":
        # Calculate opposite colors for text
        def get_opposite_color(hex_color):
            r = 255 - int(hex_color[1:3], 16)
            g = 255 - int(hex_color[3:5], 16)
            b = 255 - int(hex_color[5:7], 16)
            return f"#{r:02x}{g:02x}{b:02x}"

        text_color1 = get_opposite_color(color1)
        text_color2 = get_opposite_color(color2)

        # Create decorative border
        bar_width = 256
        bar_top = ""
        for i in range(bar_width):
            color = [color1, color2, color3, color4][i % 4]
            bar_top += f"\033[48;2;{int(color[1:3], 16)};{int(color[3:5], 16)};{int(color[5:7], 16)}m▀\033[0m"
        bar_bottom = bar_top.replace("▀", "▄")

        preview_text = bar_top + "\n\n"

        preview_text += (
            "👋 Let's HyDErate your system with more cool themes!\n\n"
            "  [TAB] to mark a theme\n"
            "  [Enter] or choose [CONFIRM] to confirm selected themes\n"
            "  [Esc] to exit/cancel\n\n"
            "Some helpful shortcuts:\n"
            "   CTRL A : mark all\n"
            "   CTRL D : un-mark all\n"
            "\n"
            "Stay HyDErated! 🌊"
            "\n\n"
        )

        preview_text += bar_bottom + "\n"
        image = CLONE_DIR + "/preview.png"
    else:
        theme_data = next((t for t in JSON_DATA if t["THEME"] == theme), None)
        if theme_data and theme_data.get("PREVIEW"):
            image = random.choice(theme_data["PREVIEW"])
        else:
            image = None
        theme_name = theme_data.get("THEME")
        theme_link = theme_data.get("LINK")
        theme_author = theme_data.get("OWNER")
        theme_description = theme_data.get("DESCRIPTION")
        color1 = (
            theme_data.get("COLORSCHEME", [])[0]
            if theme_data.get("COLORSCHEME")
            else "#000000"
        )
        color2 = (
            theme_data.get("COLORSCHEME", [])[1]
            if theme_data.get("COLORSCHEME")
            else "#000000"
        )

        # Calculate opposite colors for text
        def get_opposite_color(hex_color):
            r = 255 - int(hex_color[1:3], 16)
            g = 255 - int(hex_color[3:5], 16)
            b = 255 - int(hex_color[5:7], 16)
            return f"#{r:02x}{g:02x}{b:02x}"

        text_color1 = get_opposite_color(color1)
        text_color2 = get_opposite_color(color2)

        # Add a colorful division line using the theme colors
        bar_width = 256  # Adjust width as needed
        bar_top = ""
        for i in range(bar_width):
            # Alternate between color1 and color2
            color = color1 if i % 2 == 0 else color2
            bar_top += f"\033[48;2;{int(color[1:3], 16)};{int(color[3:5], 16)};{int(color[5:7], 16)}m▀\033[0m"
            bar_bottom = bar_top.replace("▀", "▄")

        preview_text = bar_top + "\n\n"

        preview_text += (
            f"\033[48;2;{int(color1[1:3], 16)};{int(color1[3:5], 16)};{int(color1[5:7], 16)}m"
            f"\033[38;2;{int(text_color1[1:3], 16)};{int(text_color1[3:5], 16)};{int(text_color1[5:7], 16)}mTheme:\033[0m {theme_name}\n"
            f"\033[48;2;{int(color2[1:3], 16)};{int(color2[3:5], 16)};{int(color2[5:7], 16)}m"
            f"\033[38;2;{int(text_color2[1:3], 16)};{int(text_color2[3:5], 16)};{int(text_color2[5:7], 16)}mAuthor:\033[0m {theme_author}\n"
            f"\033[48;2;{int(color1[1:3], 16)};{int(color1[3:5], 16)};{int(color1[5:7], 16)}m"
            f"\033[38;2;{int(text_color1[1:3], 16)};{int(text_color1[3:5], 16)};{int(text_color1[5:7], 16)}mLink:\033[0m {theme_link}\n"
            f"\033[48;2;{int(color2[1:3], 16)};{int(color2[3:5], 16)};{int(color2[5:7], 16)}m"
            f"\033[38;2;{int(text_color2[1:3], 16)};{int(text_color2[3:5], 16)};{int(text_color2[5:7], 16)}mDescription:\033[0m {theme_description}"
            "\n\n"
        )

        preview_text += bar_bottom + "\n"

        # print(echo_command)
        logger.debug(f"Theme: {theme_name}")
        logger.debug(f"Author: {theme_author}")
        logger.debug(f"Link: {theme_link}")
        logger.debug(f"Description: {theme_description}")
    if image:
        logger.debug(f"Image preview: {image}")
        try:
            subprocess.run(
                ["fzf_preview.sh", image, preview_text],
                check=True,
            )
            return f"Image preview: {image}"
        except (subprocess.CalledProcessError, FileNotFoundError):
            logger.debug("Failed to display image preview")
            return f"Image preview: {image}"
    else:
        logger.debug("Image preview not found")
        return f"Image preview not found for {theme}"


def patch_single_theme(theme):
    url = [
        theme_data["LINK"] for theme_data in JSON_DATA if theme_data["THEME"] == theme
    ]
    print(f"📦 Fetching {theme}...")
    try:
        result = subprocess.run(
            ["theme.patch.sh", theme, url[0], "--skipcaching"],
            check=False,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            print(f"❌ Failed to patch {theme}")
            logger.error(f"Error output: {result.stderr}")
        else:
            print(f"✅ Successfully patched {theme}")
            logger.debug(f"Installation output: {result.stdout}")
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to patch {theme}: {e.stderr}")


def patch_themes(selected_themes):
    try:
        for theme in selected_themes:
            patch_single_theme(theme)
    except KeyboardInterrupt:
        print("\n❌ Operation cancelled by user.\n")
        sys.exit(0)


def fzf_menu():
    try:
        fetch_data()
        if JSON_DATA:
            themes = [theme["THEME"] for theme in JSON_DATA]
            themes.sort(reverse=True)
            themes = ["[CONFIRM]"] + themes
            fzf_options = [
                "--input-label-pos=center",
                "--cycle",
                "-m",
                "--marker=✅",
                "--pointer=",
                "--prompt=Choose themes: ",
                "--bind=ctrl-a:select-all,ctrl-d:deselect-all",
                "--preview-window=right:60%,border-rounded",
                "--preview= theme.import.py --skip-clone --preview {}",
                "--preview-window=right::70%",
            ]
            SELECTED_THEMES = fzf.prompt(themes, fzf_options)
            logger.debug(f"Selected themes: {SELECTED_THEMES}")
        else:
            logger.debug("No JSON data available to display themes.")
        if SELECTED_THEMES and "[CONFIRM]" in SELECTED_THEMES:
            SELECTED_THEMES.remove("[CONFIRM]")
        logger.debug(f"Selected themes: {SELECTED_THEMES}")
        if not SELECTED_THEMES:
            print("\n❌ No themes selected. Exiting...\n")
            return
        print("\n" + "━" * 50)
        print("🎨 Selected Themes:")
        print("─" * 50)
        for theme in SELECTED_THEMES:
            print(f"  • {theme}")
        print("━" * 50 + "\n")
        response = input("✨ Do you want to continue? [y/N]: ").lower().strip()
        if response != "y":
            print("\n❌ Operation cancelled.\n")
            return
        print("\n🚀 Proceeding with theme installation...\n")
        patch_themes(SELECTED_THEMES)
        subprocess.run(["hyde-shell", "reload"], check=True)

    except KeyboardInterrupt:
        print("\n❌ Operation cancelled by user.\n")
        sys.exit(1)


def fetch_all_themes():
    config_home = os.getenv("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
    themes_dir = os.path.join(config_home, "hyde/themes")
    if os.path.exists(themes_dir):
        theme_dirs = [
            d
            for d in os.listdir(themes_dir)
            if os.path.isdir(os.path.join(themes_dir, d))
        ]
        for theme_name in theme_dirs:
            theme_data = next((t for t in JSON_DATA if t["THEME"] == theme_name), None)
            if theme_data:
                patch_themes([theme_name])
            else:
                print(f"⚠️  Theme '{theme_name}' not found in the JSON data.")
                logger.debug(f"Theme '{theme_name}' not found in the JSON data.")
        subprocess.run(["hyde-shell", "reload"], check=True)
    else:
        print(f"❌ Themes directory '{themes_dir}' not found.")
        logger.debug(f"Themes directory '{themes_dir}' not found.")


def fetch_theme(theme_name):
    fetch_data()
    if theme_name.lower() == "all":
        fetch_all_themes()
    else:
        theme_data = next((t for t in JSON_DATA if t["THEME"] == theme_name), None)
        if theme_data:
            patch_themes([theme_name])
            subprocess.run(["hyde-shell", "reload"], check=True)
        else:
            print(f"❌ Theme '{theme_name}' not found in the JSON data.")
            logger.debug(f"Theme '{theme_name}' not found in the JSON data.")


def main():
    parser = argparse.ArgumentParser(
        description="Imports themes from hyde-gallery repository",
        epilog="Env:\n"
        "'export FULL_THEME_UPDATE=true' Overwrites the archived files (useful for updates and changes in archives)",
    )
    parser.add_argument(
        "--json", "-j", action="store_true", help="Fetch JSON data after cloning"
    )
    parser.add_argument(
        "--select", "-S", action="store_true", help="Select themes using fzf"
    )
    parser.add_argument(
        "--preview", "-p", type=str, metavar="THEME", help="Get theme preview"
    )

    parser.add_argument(
        "--preview-text", "-t", type=str, metavar="TEXT", help="Preview text to display"
    )
    parser.add_argument(
        "--skip-clone", action="store_true", help="Skip cloning repository"
    )
    parser.add_argument(
        "--fetch",
        "-f",
        type=str,
        metavar="THEME",
        help="Fetch and update a specific theme by name (`all` to fetch all themes located in 'xdg_config/hyde/themes')",
    )

    args = parser.parse_args()

    try:
        if not args.skip_clone:
            clone_repo()
        if args.json:
            fetch_data()
            json.dump(JSON_DATA, sys.stdout, indent=4, ensure_ascii=False)
            return 0
        if args.select:
            fzf_menu()
        if args.preview:
            if args.preview_text:
                logger.debug("LoadedPreview text: " + args.preview)
                preview_text = args.preview_text
                print(preview_text)
            get_theme_preview(args.preview)
        if args.fetch:
            fetch_theme(args.fetch)
    except KeyboardInterrupt:
        print("\n❌ Operation cancelled by user.\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
