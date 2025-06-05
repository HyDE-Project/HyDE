WAYBAR MODULES
=============

WHAT IS THIS DIRECTORY?
-----------------------
This directory contains module configuration files for Waybar, a customizable status bar for Wayland compositors.

WHAT ARE MODULES?
----------------
Modules are individual components of Waybar that display specific information, such as:
* System stats (CPU, memory, disk usage)
* Network status
* Media controls
* Custom scripts

HOW TO USE MODULES:
------------------
1. Module configurations are defined in JSONC format and should be placed in this directory.
2. Reference these modules in your main Waybar configuration file (config.jsonc) under the "modules" section.
3. Each module should follow the Waybar module configuration format.

Example:
##########
#
{
  "modules-left": ["cpu", "memory"],
  "modules-center": ["clock"],
  "modules-right": ["network", "battery"]
}
#
##########

GETTING STARTED WITH MODULES:
----------------------------
* View sample modules in: ~/.local/share/waybar/modules/
* Copy a sample to this directory and customize it to your needs
* For detailed configuration options, see: https://man.archlinux.org/man/waybar