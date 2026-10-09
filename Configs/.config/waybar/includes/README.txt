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

- includes.json
  - Lists the modules your bar can use. HyDE rewrites its module list and
    the bar position, so don't edit it by hand.

ADDING YOUR OWN:
----------------
1. Modules: save them as `.jsonc` files in `~/.config/waybar/modules/`, then
   run `hyde-shell waybar --update` and add them to your layout.
   (Use `.json` only for strict JSON, as some of HyDE's own modules need.)
2. Styles: put your CSS in `~/.config/waybar/user-style.css`. It is loaded
   last, so it overrides the theme. The CSS files in this directory follow
   your theme, so edits to them may be lost.
