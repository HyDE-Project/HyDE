-- # -----------------------------------------------------
-- # macOS-like animation profile for Hyprland
-- # -----------------------------------------------------

local animation = {
    name = "MacOS",
    icon = "",
    description = "macOS-like springy popin and smooth fades."
}

if not hl then
    return animation
end
-- prod utilizes the stored hyde.config.anim.duration_scale to dynamically change anim speed!
local prod = function(ds)
    return ds * hyde.config.anim.duration_scale
end


hl.curve("macOpen", {type = "spring", mass = 1, stiffness = 110, dampening = 16})
hl.curve("macBounce", {type = "spring", mass = 1, stiffness = 80, dampening = 10})
hl.curve("macSmooth", {type = "bezier", points = {{0.25, 0.1}, {0.25, 1.0}}})
hl.animation({leaf = "fadeIn", enabled = true, speed = prod(8), bezier = "default"})
hl.animation({leaf = "fadeOut", enabled = true, speed = prod(8), bezier = "default"})
hl.animation({leaf = "fadeSwitch", enabled = true, speed = prod(8), bezier = "default"})
hl.animation({leaf = "fadeShadow", enabled = true, speed = prod(8), bezier = "default"})
hl.animation({leaf = "fadeDim", enabled = true, speed = prod(8), bezier = "default"})
hl.animation({leaf = "fadeLayers", enabled = true, speed = prod(8), bezier = "default"})
hl.animation({leaf = "fadeLayersIn", enabled = true, speed = prod(8), bezier = "default"})
hl.animation({leaf = "fadeLayersOut", enabled = true, speed = prod(8), bezier = "default"})
hl.animation({leaf = "fadePopups", enabled = true, speed = prod(8), bezier = "default"})
hl.animation({leaf = "fadePopupsIn", enabled = true, speed = prod(8), bezier = "default"})
hl.animation({leaf = "fadePopupsOut", enabled = true, speed = prod(8), bezier = "default"})
hl.animation({leaf = "fadeDpms", enabled = true, speed = prod(8), bezier = "default"})
hl.animation({leaf = "windows", enabled = true, speed = prod(8), spring = "macOpen", style = "popin 90%"})
hl.animation({leaf = "windowsIn", enabled = true, speed = prod(8), spring = "macOpen", style = "popin 90%"})
hl.animation({leaf = "windowsOut", enabled = true, speed = prod(7), spring = "macBounce", style = "popin 90%"})
hl.animation({leaf = "windowsMove", enabled = true, speed = prod(5), bezier = "macSmooth", style = "slide"})
hl.animation({leaf = "border", enabled = true, speed = prod(1), bezier = "default"})
hl.animation({leaf = "borderangle", enabled = true, speed = prod(30), bezier = "default", style = "once"})
hl.animation({leaf = "fade", enabled = true, speed = prod(8), bezier = "default"})
hl.animation({leaf = "workspaces", enabled = true, speed = prod(6), bezier = "macSmooth", style = "slidefade 20%"})
hl.animation({leaf = "workspacesIn", enabled = true, speed = prod(6), bezier = "macSmooth", style = "slidefade 20%"})
hl.animation({leaf = "workspacesOut", enabled = true, speed = prod(6), bezier = "macSmooth", style = "slidefade 20%"})
hl.animation({leaf = "specialWorkspace", enabled = true, speed = prod(6), bezier = "macSmooth", style = "slidefade 20%"})
hl.animation({leaf = "specialWorkspaceIn", enabled = true, speed = prod(6), bezier = "macSmooth", style = "slidefade 20%"})
hl.animation({leaf = "specialWorkspaceOut", enabled = true, speed = prod(6), bezier = "macSmooth", style = "slidefade 20%"})
hl.animation({leaf = "zoomFactor", enabled = true, speed = prod(7), bezier = "default"})
hl.animation({leaf = "monitorAdded", enabled = true, speed = prod(7), bezier = "default"})
