local animation = {
    name = "Moving",
    icon = "",
    description = "Moving animation profile for Hyprland"
}

if not hl then
    return animation
end
-- prod utilizes the stored hyde.config.anim.duration_scale to dynamically change anim speed!
local prod = function(ds)
    return ds * hyde.config.anim.duration_scale
end


hl.curve("overshot", {type = "bezier", points = {{0.05, 0.9}, {0.1, 1.05}}})
hl.curve("smoothOut", {type = "bezier", points = {{0.5, 0}, {0.99, 0.99}}})
hl.curve("smoothIn", {type = "bezier", points = {{0.5, -0.5}, {0.68, 1.5}}})

hl.animation({leaf = "fadeIn", enabled = true, speed = prod(5), bezier = "smoothIn"})
hl.animation({leaf = "fadeOut", enabled = true, speed = prod(5), bezier = "smoothIn"})
hl.animation({leaf = "fadeSwitch", enabled = true, speed = prod(5), bezier = "smoothIn"})
hl.animation({leaf = "fadeShadow", enabled = true, speed = prod(5), bezier = "smoothIn"})
hl.animation({leaf = "fadeLayers", enabled = true, speed = prod(5), bezier = "smoothIn"})
hl.animation({leaf = "fadePopups", enabled = true, speed = prod(5), bezier = "smoothIn"})
hl.animation({leaf = "fadeDpms", enabled = true, speed = prod(5), bezier = "smoothIn"})
hl.animation({leaf = "workspacesIn", enabled = true, speed = prod(6), bezier = "default"})
hl.animation({leaf = "workspacesOut", enabled = true, speed = prod(6), bezier = "default"})
hl.animation({leaf = "specialWorkspace", enabled = true, speed = prod(6), bezier = "default"})
hl.animation({leaf = "windows", enabled = true, speed = prod(5), bezier = "overshot", style = "slide"})
hl.animation({leaf = "windowsOut", enabled = true, speed = prod(3), bezier = "smoothOut"})
hl.animation({leaf = "windowsIn", enabled = true, speed = prod(3), bezier = "smoothOut"})
hl.animation({leaf = "windowsMove", enabled = true, speed = prod(4), bezier = "smoothIn", style = "slide"})
hl.animation({leaf = "border", enabled = true, speed = prod(5), bezier = "default"})
hl.animation({leaf = "fade", enabled = true, speed = prod(5), bezier = "smoothIn"})
hl.animation({leaf = "fadeDim", enabled = true, speed = prod(5), bezier = "smoothIn"})
hl.animation({leaf = "workspaces", enabled = true, speed = prod(6), bezier = "default"})
hl.animation({leaf = "fadeLayersIn", enabled = true, speed = prod(5), bezier = "smoothIn"})
hl.animation({leaf = "fadeLayersOut", enabled = true, speed = prod(5), bezier = "smoothIn"})
hl.animation({leaf = "fadePopupsIn", enabled = true, speed = prod(5), bezier = "smoothIn"})
hl.animation({leaf = "fadePopupsOut", enabled = true, speed = prod(5), bezier = "smoothIn"})
hl.animation({leaf = "specialWorkspaceIn", enabled = true, speed = prod(6), bezier = "default"})
hl.animation({leaf = "specialWorkspaceOut", enabled = true, speed = prod(6), bezier = "default"})
