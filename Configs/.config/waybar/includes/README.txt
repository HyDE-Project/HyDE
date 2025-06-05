WAYBAR INCLUDES
===============

WHAT IS THIS DIRECTORY?
-----------------------
This directory contains additional configuration files and styles for Waybar, enhancing its customization and dynamic features. This setup is specific to HyDE.

WHAT ARE THE FILES?
-------------------
- border-radius.css
  - Provides dynamic border radius for the [groups](#groups).

- global.css
  - Includes dynamic font-size and font-family.
  - This is dynamic so that themes can override these values via the `hypr.theme` >> `$WAYBAR_FONT`.

HOW TO USE INCLUDES:
--------------------
1. Place your custom CSS or JSONC files in this directory.
2. Reference these files in your main Waybar configuration to apply their styles or settings.
3. Files in this directory are recursively added as entries in `includes/includes.json`.