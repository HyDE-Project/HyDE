-- # -----------------------------------------------------
-- # ▄▀█ █▄░█ █ █▀▄▀█ ▄▀█ ▀█▀ █ █▀█ █▄░█
-- # █▀█ █░▀█ █ █░▀░█ █▀█ ░█░ █ █▄█ █░▀█
-- #
-- # name "Classic"
-- # credit https://github.com/mylinuxforwork/dotfiles
-- # -----------------------------------------------------

-- animations {
--     enabled = true
--     bezier = myBezier, 0.05, 0.9, 0.1, 1.05
--     animation = windows, 1, 7, myBezier
--     animation = windowsOut, 1, 7, default, popin 80%
--     animation = border, 1, 10, default
--     animation = borderangle, 1, 8, default
--     animation = fade, 1, 7, default
--     animation = workspaces, 1, 6, default
-- }

local animation = {
    name = "Classic",
    icon = "",
    description = "Classic animation configuration from Hyde"
}

if not hl then
    return animation
end

-- prod utilizes the stored hyde.config.anim.duration_scale to dynamically change anim speed!
local prod = function(ds)
    return ds * hyde.config.anim.duration_scale
end

hl.curve("myBezier", {type = "bezier", points = {{0.05, 0.9}, {0.1, 1.05}}})
hl.animation({leaf = "windows", enabled = true, speed = prod(7), bezier = "myBezier"})
hl.animation({leaf = "windowsOut", enabled = true, speed = prod(7), bezier = "default", style = "popin 80%"})
hl.animation({leaf = "border", enabled = true, speed = prod(10), bezier = "default"})
hl.animation({leaf = "borderangle", enabled = true, speed = prod(8), bezier = "default"})
hl.animation({leaf = "fade", enabled = true, speed = prod(7), bezier = "default"})
hl.animation({leaf = "workspaces", enabled = true, speed = prod(6), bezier = "default"})
hl.animation({leaf = "windowsIn", enabled = true, speed = prod(7), bezier = "myBezier"})
hl.animation({leaf = "windowsMove", enabled = true, speed = prod(7), bezier = "myBezier"})
hl.animation({leaf = "fadeIn", enabled = true, speed = prod(7), bezier = "default"})
hl.animation({leaf = "fadeOut", enabled = true, speed = prod(7), bezier = "default"})
hl.animation({leaf = "fadeSwitch", enabled = true, speed = prod(7), bezier = "default"})
hl.animation({leaf = "fadeShadow", enabled = true, speed = prod(7), bezier = "default"})
hl.animation({leaf = "fadeDim", enabled = true, speed = prod(7), bezier = "default"})
hl.animation({leaf = "fadeLayers", enabled = true, speed = prod(7), bezier = "default"})
hl.animation({leaf = "fadeLayersIn", enabled = true, speed = prod(7), bezier = "default"})
hl.animation({leaf = "fadeLayersOut", enabled = true, speed = prod(7), bezier = "default"})
hl.animation({leaf = "fadePopups", enabled = true, speed = prod(7), bezier = "default"})
hl.animation({leaf = "fadePopupsIn", enabled = true, speed = prod(7), bezier = "default"})
hl.animation({leaf = "fadePopupsOut", enabled = true, speed = prod(7), bezier = "default"})
hl.animation({leaf = "fadeDpms", enabled = true, speed = prod(7), bezier = "default"})
hl.animation({leaf = "workspacesIn", enabled = true, speed = prod(6), bezier = "default"})
hl.animation({leaf = "workspacesOut", enabled = true, speed = prod(6), bezier = "default"})
hl.animation({leaf = "specialWorkspace", enabled = true, speed = prod(6), bezier = "default"})
hl.animation({leaf = "specialWorkspaceIn", enabled = true, speed = prod(6), bezier = "default"})
hl.animation({leaf = "specialWorkspaceOut", enabled = true, speed = prod(6), bezier = "default"})
