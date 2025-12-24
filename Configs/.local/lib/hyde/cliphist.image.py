#!/usr/bin/env python3

import os
import subprocess
import re


tmp_dir = os.getenv("XDG_RUNTIME_DIR", "/tmp")
tmp_dir = os.path.join(tmp_dir, "cliphist")


def decode_and_save_image(grp):
    img_path = os.path.join(tmp_dir, f"{grp[0]}.{grp[2]}")
    if not os.path.exists(img_path):
        proc = subprocess.run(["cliphist", "decode", grp[0]], capture_output=True, check=True)
        with open(img_path, "wb") as img_file:
            img_file.write(proc.stdout)
    return img_path


def main():
    os.makedirs(tmp_dir, exist_ok=True)

    prog = re.compile(r"^([0-9]+)\s(\[\[\s)?binary.*(jpg|jpeg|png|bmp)")

    result = subprocess.run(["cliphist", "list"], capture_output=True, text=True, check=True)
    lines = result.stdout.splitlines()

    for line in lines:
        if re.match(r"^[0-9]+\s<meta http-equiv=", line):
            continue

        match = prog.match(line)
        if match:
            grp = match.groups()
            img_path = decode_and_save_image(grp)
            print(f"{line}\0icon\x1f{img_path}")
        elif os.getenv("HYDE_CLIPHIST_IMAGE_ONLY", "").lower() not in (
            "true",
            "1",
            "yes",
        ):
            # image path is ~/.cache/hyde/wallbash/pry1.svg but use xdg
            img_path = os.getenv("XDG_CACHE_HOME", os.path.expanduser("~/.cache"))
            img_path = os.path.join(img_path, "hyde", "wallbash", "pry1.svg")
            print(f"{line}\0icon\x1f{img_path}")


if __name__ == "__main__":
    import sys

    main()
