--[[
    DOORwayDE core window and layer rules.

    Originally `windowrules.conf` (hyprlang). Hyprland 0.55+ lua migration.

    This is the SHARED core rule set (~/.local/share/hypr/windowrules.lua),
    not the user-editable file in ~/.config/hypr/windowrules.lua.

    The `# hyprlang if HYPRLAND_V_0_53` guard and the !0_53 fallback that
    sourced `migration/hypr/0.52_windowrules.conf` are dropped — DOORwayDE
    is pinned to Hyprland 0.55+.

    See https://wiki.hypr.land/Configuring/Window-Rules/
--]]

-- // █░█░█ █ █▄░█ █▀▄ █▀█ █░█░█   █▀█ █░█ █░░ █▀▀ █▀
-- // ▀▄▀▄▀ █ █░▀█ █▄▀ █▄█ ▀▄▀▄▀   █▀▄ █▄█ █▄▄ ██▄ ▄█

-- Fix file chooser dialogs opening off-screen
hl.window_rule({
    float = true,
    match = { tag = "portal-dialogs" },
})

hl.window_rule({
    center = true,
    match  = { tag = "portal-dialogs" },
})

-- Core floating apps: settings panels, applets, file utilities.
hl.window_rule({
    name  = "doorwayde_floating_apps",
    tag   = "+doorwayde_floating_apps",
    match = { class = "^(blueman-manager|pavucontrol-qt|com\\.gabm\\.satty|vlc|kvantummanager|qt[56]ct|nwg-(look|displays)|org\\.kde\\.ark|org\\.pulseaudio\\.pavucontrol|blueman-manager|nm-(applet|connection-editor)|hyprpolkitagent|console-dropdown)$" },
})

-- Dolphin transient progress windows
hl.window_rule({
    name  = "doorwayde_dolphin_popups",
    tag   = "+doorwayde_floating_apps",
    match = {
        class = "^(org\\.kde\\.dolphin)$",
        title = "^(Progress Dialog — Dolphin|Copying — Dolphin)$",
    },
})

-- Common popups (open/save dialogs, auth prompts, etc.)
hl.window_rule({
    name  = "doorwayde_common_popups",
    tag   = "+doorwayde_common_popups",
    match = { title = "^(Choose Files|Save As|Confirm to replace files|File Operation Progress|Open|Authentication Required|Add Folder to Workspace|File Upload.*|Choose wallpaper.*|Library.*|.*dialog.*)$" },
})

hl.window_rule({
    tag   = "+doorwayde_common_popups",
    match = { initial_title = "^(Open File|Volume Control|Save As.*)$" },
})

hl.window_rule({
    tag   = "+doorwayde_common_popups",
    match = { class = "^(.*dialog.*|[Xx]dg-desktop-portal-gtk)$" },
})

-- XDG desktop portal dialogs
hl.window_rule({
    name  = "doorwayde_portal_dialogs",
    tag   = "+doorwayde_portal_dialogs",
    match = { class = "^(org\\.freedesktop\\.impl\\.portal\\.desktop\\.(hyprland|gtk)|[Xx]dg-desktop-portal-gtk)$" },
})

-- Picture-in-Picture: floating, pinned, aspect-locked, anchored bottom-right.
local pip_match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }

hl.window_rule({
    name  = "doorwayde_picture_in_picture",
    match = pip_match,
    tag   = "+picture-in-picture",
    float = true,
    keep_aspect_ratio = true,
    move  = "(monitor_w*0.73) (monitor_h*0.72)",
    size  = "(monitor_w*0.25) (monitor_h*0.25)",
    pin   = true,
})
hl.window_rule({
    match = pip_match,
    tag   = "+doorwayde_picture_in_picture",
})

-- Apply float/center based on the tags above.
hl.window_rule({
    float = true,
    match = { tag = "doorwayde_floating_apps" },
})

hl.window_rule({
    float  = true,
    center = true,
    match  = { tag = "doorwayde_common_popups" },
})

hl.window_rule({
    float  = true,
    center = true,
    match  = { tag = "doorwayde_portal_dialogs" },
})

-- Re-tag already-floating windows of the floating-apps class set.
hl.window_rule({
    match = { float = true, class = "doorwayde_floating_apps" },
})

-- // █░░ ▄▀█ █▄█ █▀▀ █▀█   █▀█ █░█ █░░ █▀▀ █▀
-- // █▄▄ █▀█ ░█░ ██▄ █▀▄   █▀▄ █▄█ █▄▄ ██▄ ▄█

hl.layer_rule({
    name  = "doorwayde_layer_blur",
    match = { namespace = "^(rofi|quickshell:notificationPopups|swaync-(notification-window|control-center)|quickshell:bar|quickshell:session)$" },
    blur  = true,
})

hl.layer_rule({
    name  = "doorwayde_layer_ignore_alpha",
    match = { namespace = "^(rofi|quickshell:notificationPopups|swaync-(notification-window|control-center)|quickshell:session|quickshell:bar|selection)$" },
    ignore_alpha = true,
})

hl.layer_rule({
    match = { namespace = "selection" },
    no_anim = true,
})
