# Dcol and Wallbash

## Overview

This document provides an explanation of the color configuration used for theming HyDE. It covers primary colors, text colors, and accent colors. Each color can be specified in either hexadecimal or RGBA format.

## Color Identifiers 

By default, while  **wallpaper caching**, it will produce 4 primary colors, 4 text colors, and 9 accent colors for each primary color.

- **`dcol_mode`**: This identifier determines whether the theme is in dark or light mode. 
- **`dcol_pryX`**: These are the primary colors, with `X` ranging from 1 to 4.
- **`dcol_txtX`**: These are the inverted primary colors used for text, with `X` ranging from 1 to 4.
- **`dcol_XaxY`**: These are the accent colors for each primary color, with `X` ranging from 1 to 4 and `Y` ranging from 1 to 9.
- **`_rgba`**: This suffix indicates that the color is in RGBA format. If the suffix is not present, the color is in hexadecimal format.
## Usage

To use the cache color configuration:

1. Replace the prefix `dcol_` with `wallbash_` to allow the Wallbash script to parse and change values.
2. Consider the `wallbash_` prefix as a placeholder for the dominant color value.
3. Wrap the color identifier with angle brackets (`<...>`) to indicate replacement with the corresponding value, e.g., `<wallbash_pry1>`.
4. Use this [example](https://github.com/hyde-project/hyde/tree/master/Configs/.config/hyde/wallbash) as a template.

This allows you to create a template for configurations, using the dominant color or wallpaper, and let the Wallbash script convert it for you.

### Creating a `*.dcol` Template

A template requires three parts:
- Target file
- Script/command (optional)
- Contents

The basic format:
---
| target | command |
|--------|---------|
| **contents** |


---




> **Note:** **target**|**command** should always be on line 1 of every template file. We will call it `header line`.

#### Target File

Structure your template and determine the target configuration location. This can be:
- `${cacheDir}/wallbash` with post-processing using a script.
- An expected path, e.g., beside `kitty.conf` for Kitty, sourced by `include theme.conf`.

Use environment variables to handle directories dynamically:
- `${confDir}` = `$XDG_CONFIG_HOME` or `$HOME/.config/`
- `${cacheDir}/wallbash` = `HYDE_CACHE_DIR/wallbash` = `$HOME/.cache/hyde`

#### Optional Script/Command

After filling the target file with contents, you can run arbitrary commands/scripts for post-processing. Use the `WALLBASH_SCRIPTS` variable to navigate to Wallbash's script directory, e.g., `WALLBASH_SCRIPTS/your_script.sh`.

> **Caution:** Only add templates from trusted authors to avoid executing bad code.

#### Contents

These are the contents of the file, containing Wallbash placeholders, e.g., `<wallbash_pry1>`.

---

The `~/.config/hyde/wallbash/*` directory contains three main directories:

### always

Templates in `./wallbash/always/` are executed during:
- Theme switch
- Wallpaper switch
- Mode switch

More information [here](./always/README).

### theme

Templates in `./wallbash/theme/` are executed during:
- Theme switch
- Mode switch

More information [here](./theme/README).

### scripts

For customization, store your scripts in `./wallbash/scripts`. Use the `$WALLBASH_SCRIPTS` variable to navigate this directory.