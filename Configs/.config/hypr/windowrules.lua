--[[
    █░█░█ █ █▄░█ █▀▄ █▀█ █░█░█   █▀█ █░█ █░░ █▀▀ █▀
    ▀▄▀▄▀ █ █░▀█ █▄▀ █▄█ ▀▄▀▄▀   █▀▄ █▄█ █▄▄ ██▄ ▄█

    Window Rules
    https://wiki.hypr.land/Configuring/Window-Rules/

    Custom window rules for your applications.
--]]

--------------------------------------------------------------------------------
-- Idle Inhibit Rules
-- Prevent screen from sleeping when these apps are fullscreen
--------------------------------------------------------------------------------

-- Media players
hl.window_rule({
    match = { class = "^(.*celluloid.*)$|^(.*mpv.*)$|^(.*vlc.*)$" },
    idle_inhibit = "fullscreen",
})

-- Spotify
hl.window_rule({
    match = { class = "^(.*[Ss]potify.*)$" },
    idle_inhibit = "fullscreen",
})

-- Browsers
hl.window_rule({
    match = { class = "^(.*LibreWolf.*)$|^(.*floorp.*)$|^(.*brave-browser.*)$|^(.*firefox.*)$|^(.*chromium.*)$|^(.*zen.*)$|^(.*vivaldi.*)$" },
    idle_inhibit = "fullscreen",
})

--------------------------------------------------------------------------------
-- Picture-in-Picture
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- Opacity Rules
-- Format: "active inactive fullscreen" (space-separated string, parsed by Hyprland)
--------------------------------------------------------------------------------

-- Browsers (90% opacity)
local browser_opacity = "0.90 0.90 1.0"
for _, class in ipairs({ "firefox", "zen", "brave-browser" }) do
    hl.window_rule({
        match = { class = "^(" .. class .. ")$" },
        opacity = browser_opacity,
    })
end

-- Code editors (80% opacity)
local editor_opacity = "0.80 0.80 1.0"
for _, class in ipairs({ "code-oss", "[Cc]ode", "code-url-handler", "code-insiders-url-handler" }) do
    hl.window_rule({
        match = { class = "^(" .. class .. ")$" },
        opacity = editor_opacity,
    })
end

-- Terminals and file managers (80% opacity)
for _, class in ipairs({ "kitty", "org.kde.dolphin", "org.kde.ark" }) do
    hl.window_rule({
        match = { class = "^(" .. class .. ")$" },
        opacity = editor_opacity,
    })
end

-- Settings apps (80% opacity)
for _, class in ipairs({ "nwg-look", "qt5ct", "qt6ct", "kvantummanager" }) do
    hl.window_rule({
        match = { class = "^(" .. class .. ")$" },
        opacity = editor_opacity,
    })
end

-- System utilities (80% active, 70% inactive)
local util_opacity = "0.80 0.70 1.0"
for _, class in ipairs({
    "org.pulseaudio.pavucontrol", "blueman-manager", "nm-applet",
    "nm-connection-editor", "hyprpolkitagent",
    "org.freedesktop.impl.portal.desktop.gtk",
    "org.freedesktop.impl.portal.desktop.hyprland"
}) do
    hl.window_rule({
        match = { class = "^(" .. class .. ")$" },
        opacity = util_opacity,
    })
end

-- Steam and Spotify (70% opacity)
local media_opacity = "0.70 0.70 1.0"
for _, class in ipairs({ "[Ss]team", "steamwebhelper", "[Ss]potify" }) do
    hl.window_rule({
        match = { class = "^(" .. class .. ")$" },
        opacity = media_opacity,
    })
end

hl.window_rule({
    match = { initial_title = "^(Spotify Free)$" },
    opacity = media_opacity,
})

hl.window_rule({
    match = { initial_title = "^(Spotify Premium)$" },
    opacity = media_opacity,
})

-- Blender (full opacity)
hl.window_rule({
    match = { class = "^(blender)$" },
    opacity = "1.0 1.0 1.0",
})

-- Various GTK/Qt apps (80% opacity)
local app_opacity_80 = "0.80 0.80 1.0"
local apps_80 = {
    "com.github.rafostar.Clapper", "com.github.tchx84.Flatseal",
    "hu.kramo.Cartridges", "com.obsproject.Studio", "gnome-boxes",
    "vesktop", "discord", "WebCord", "ArmCord", "app.drey.Warp",
    "net.davidotek.pupgui2", "yad", "Signal", "io.github.alainm23.planify",
    "io.gitlab.theevilskeleton.Upscaler", "com.github.unrud.VideoDownloader",
    "io.gitlab.adhami3310.Impression", "io.missioncenter.MissionCenter",
    "io.github.flattool.Warehouse"
}
for _, class in ipairs(apps_80) do
    hl.window_rule({
        match = { class = "^(" .. class .. ")$" },
        opacity = app_opacity_80,
    })
end

--------------------------------------------------------------------------------
-- Floating Windows
--------------------------------------------------------------------------------

local float_apps = {
    "Signal", "com.github.rafostar.Clapper", "app.drey.Warp",
    "net.davidotek.pupgui2", "yad", "eog", "io.github.alainm23.planify",
    "io.gitlab.theevilskeleton.Upscaler", "com.github.unrud.VideoDownloader",
    "io.gitlab.adhami3310.Impression", "io.missioncenter.MissionCenter"
}
for _, class in ipairs(float_apps) do
    hl.window_rule({
        match = { class = "^(" .. class .. ")$" },
        float = true,
    })
end

-- Steam dialogs
hl.window_rule({
    match = { title = "^(Friends List)$" },
    float = true,
})

hl.window_rule({
    match = { title = "^(Steam Settings)$" },
    float = true,
})

-- Blender render window
hl.window_rule({
    match = { initial_title = "^(Image Editor)$", class = "^(blender)$" },
    float = true,
    size  = "(monitor_w*0.5) (monitor_h*0.5)",
})

--------------------------------------------------------------------------------
-- JetBrains IDE Workaround
-- Prevent flickering on dropdowns/popups
--------------------------------------------------------------------------------

hl.window_rule({
    match = { class = "^(.*jetbrains.*)$", title = "^(win[0-9]+)$" },
    no_initial_focus = true,
})

--------------------------------------------------------------------------------
-- Layer Rules
-- For rofi, notifications, etc.
--------------------------------------------------------------------------------

hl.layer_rule({
    match = { namespace = "rofi" },
    blur = true,
    ignore_alpha = 0,
})

hl.layer_rule({
    match = { namespace = "notifications" },
    blur = true,
    ignore_alpha = 0,
})

hl.layer_rule({
    match = { namespace = "swaync-notification-window" },
    blur = true,
    ignore_alpha = 0,
})

hl.layer_rule({
    match = { namespace = "swaync-control-center" },
    blur = true,
    ignore_alpha = 0,
})

hl.layer_rule({
    match = { namespace = "logout_dialog" },
    blur = true,
})

-- QuickShell sidebars
hl.layer_rule({
    match = { namespace = "^quickshell:sidebarRight$" },
    blur = true,
    ignore_alpha = 0,
})
hl.layer_rule({
    match = { namespace = "^quickshell:sidebarLeft$" },
    blur = true,
    ignore_alpha = 0,
})

-- QuickShell OSD + notification popups (overlay layer, transparent areas pass input through)
hl.layer_rule({
    match = { namespace = "^quickshell:osd$" },
    blur = true,
    ignore_alpha = 0,
})
hl.layer_rule({
    match = { namespace = "^quickshell:notificationPopups$" },
    blur = true,
    ignore_alpha = 0,
})

-- QuickShell session screen (fullscreen overlay; blur enhances the scrim frosted look)
hl.layer_rule({
    match = { namespace = "^quickshell:session$" },
    blur = true,
    ignore_alpha = 0,
})
