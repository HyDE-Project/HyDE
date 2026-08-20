local animation = {
    name = "Minimal-2",
    icon = "",
    description = "Minimal-2 animation profile for Hyprland"
}

if not hl then
    return animation
end
-- prod utilizes the stored hyde.config.anim.duration_scale to dynamically change anim speed!
local prod = function(ds)
    return ds * hyde.config.anim.duration_scale
end


hl.curve("quart", {type = "bezier", points = {{0.25, 1}, {0.5, 1}}})

hl.animation({leaf = "windowsIn", enabled = true, speed = prod(6), bezier = "quart", style = "slide"})
hl.animation({leaf = "windowsOut", enabled = true, speed = prod(6), bezier = "quart", style = "slide"})
hl.animation({leaf = "windowsMove", enabled = true, speed = prod(6), bezier = "quart", style = "slide"})
hl.animation({leaf = "fadeIn", enabled = true, speed = prod(6), bezier = "quart"})
hl.animation({leaf = "fadeOut", enabled = true, speed = prod(6), bezier = "quart"})
hl.animation({leaf = "fadeSwitch", enabled = true, speed = prod(6), bezier = "quart"})
hl.animation({leaf = "fadeShadow", enabled = true, speed = prod(6), bezier = "quart"})
hl.animation({leaf = "fadeDim", enabled = true, speed = prod(6), bezier = "quart"})
hl.animation({leaf = "fadeLayers", enabled = true, speed = prod(6), bezier = "quart"})
hl.animation({leaf = "fadePopups", enabled = true, speed = prod(6), bezier = "quart"})
hl.animation({leaf = "fadeDpms", enabled = true, speed = prod(6), bezier = "quart"})
hl.animation({leaf = "workspacesIn", enabled = true, speed = prod(6), bezier = "quart"})
hl.animation({leaf = "workspacesOut", enabled = true, speed = prod(6), bezier = "quart"})
hl.animation({leaf = "specialWorkspace", enabled = true, speed = prod(6), bezier = "quart"})
hl.animation({leaf = "windows", enabled = true, speed = prod(6), bezier = "quart", style = "slide"})
hl.animation({leaf = "border", enabled = true, speed = prod(6), bezier = "quart"})
hl.animation({leaf = "borderangle", enabled = true, speed = prod(6), bezier = "quart"})
hl.animation({leaf = "fade", enabled = true, speed = prod(6), bezier = "quart"})
hl.animation({leaf = "workspaces", enabled = true, speed = prod(6), bezier = "quart"})
hl.animation({leaf = "fadeLayersIn", enabled = true, speed = prod(6), bezier = "quart"})
hl.animation({leaf = "fadeLayersOut", enabled = true, speed = prod(6), bezier = "quart"})
hl.animation({leaf = "fadePopupsIn", enabled = true, speed = prod(6), bezier = "quart"})
hl.animation({leaf = "fadePopupsOut", enabled = true, speed = prod(6), bezier = "quart"})
hl.animation({leaf = "specialWorkspaceIn", enabled = true, speed = prod(6), bezier = "quart"})
hl.animation({leaf = "specialWorkspaceOut", enabled = true, speed = prod(6), bezier = "quart"})
