-- Just for optimization, I decided to compile all known regexes into a single table
-- compile them into single string patterns
-- and have lesser hl.windowrule calls.
-- Then identify key desktop features:
-- 1. Floating windows (dialogs, popups, portal dialogs, etc)
-- 2. Pinned windows (picture-in-picture, etc)
-- 3. And common modals that are floating anyway but should be centered (file choosers, etc)

local util = _G.hyde.utils

local floating =
  util.regex_compile(
  {
    class = {
      "Bitwarden",
      "org.keepassxc.KeePassXC",
      "hyprland-share-picker",
      "blueman-manager",
      "pavucontrol-qt",
      "com\\.gabm\\.satty",
      "vlc",
      "kvantummanager",
      "qt6ct",
      "qt[56]ct",
      "nwg-(look|displays)",
      "org\\.kde\\.ark",
      "org\\.pulseaudio\\.pavucontrol",
      "nm-(applet|connection-editor)",
      "hyprpolkitagent",
      "console-dropdown",
      "org\\.kde\\.dolphin",
      ".*dialog.*",
      "[Xx]dg-desktop-portal-gtk",
      "org\\.freedesktop\\.impl\\.portal\\.desktop\\.(hyprland|gtk)"
    },
    title = {
      "Progress Dialog — Dolphin",
      "Copying — Dolphin",
      "Choose Files",
      "Save As",
      "Confirm to replace files",
      "File Operation Progress",
      "Open",
      "Authentication Required",
      "Add Folder to Workspace",
      "File Upload.*",
      "Choose wallpaper.*",
      "Library.*",
      ".*dialog.*",
      "Open File",
      "Volume Control",
      "Save As.*"
    }
  }
)

local pinned =
  util.regex_compile(
  {
    title = {
      "[Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture(.*)"
    }
  },
  true
)

local modals =
  util.regex_compile(
  {
    class = {
      "pinentry-.*"
    },
    title = {
      "Choose Files",
      "Open File",
      "Save As.*",
      "File Operation Progress",
      "Authentication Required",
      "File Upload.*"
    },
    initial_title = {
      "Open File",
      "Save As.*"
    }
  }
)

-- Consolidated floating rules (includes dialogs, portal dialogs, popups, dolphin dialogs)
hl.window_rule(
  {
    name = "hyde_floating_class",
    tag = "+hyde_floating",
    match = {
      class = floating.class
    },
    float = true
  }
)

hl.window_rule(
  {
    name = "hyde_floating_title",
    tag = "+hyde_floating",
    match = {
      title = floating.title
    },
    float = true
  }
)

-- Pinned windows
hl.window_rule(
  {
    name = "hyde_pin",
    tag = "+hyde_pin",
    match = {
      title = pinned.title
    },
    float = true,
    move = "(monitor_w*0.73) (monitor_h*0.72)",
    size = "(monitor_w*0.25) (monitor_h*0.25)",
    pin = true
  }
)

-- Modals that strictly pinned,floats and centered for the best user experience (file choosers, etc)

hl.window_rule(
  {
    name = "hyde_modals",
    tag = "+hyde_modals",
    match = {
      class = modals.class,
      title = modals.title,
      initial_title = modals.initial_title,
      modal = true
    },
    float = true,
    center = true,
    pin = true
  }
)

hl.window_rule(
  {
    name = "xwayland_video_bridge_fixes",
    match = {
      class = "xwaylandvideobridge"
    },
    no_initial_focus = true,
    no_focus = true,
    no_anim = true,
    no_blur = true,
    no_follow_mouse = true,
    max_size = {1, 1},
    opacity = 0.0,
    float = true,
    workspace = "special:xwayland_video_bridge silent"
  }
)
