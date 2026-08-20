local animation = {
    name = "Lime Frenzy",
    icon = "",
    description = "Playful popin with slight overshoot by LimeFrenzy"
}

if not hl then
    return animation
end
-- prod utilizes the stored hyde.config.anim.duration_scale to dynamically change anim speed!
local prod = function(ds)
    return ds * hyde.config.anim.duration_scale
end


hl.curve("default", {type = "bezier", points = {{0.12, 0.92}, {0.08, 1.0}}})
hl.curve("wind", {type = "bezier", points = {{0.12, 0.92}, {0.08, 1.0}}})
hl.curve("overshot", {type = "bezier", points = {{0.18, 0.95}, {0.22, 1.03}}})
hl.curve("liner", {type = "bezier", points = {{1, 1}, {1, 1}}})

hl.animation({leaf = "layersIn", enabled = true, speed = prod(4), bezier = "default", style = "popin"})
hl.animation({leaf = "layersOut", enabled = true, speed = prod(4), bezier = "default", style = "popin"})
hl.animation({leaf = "fadeLayersIn", enabled = true, speed = prod(7), bezier = "default"})
hl.animation({leaf = "fadeLayersOut", enabled = true, speed = prod(7), bezier = "default"})
hl.animation({leaf = "workspacesIn", enabled = true, speed = prod(5), bezier = "overshot", style = "slidevert"})
hl.animation({leaf = "workspacesOut", enabled = true, speed = prod(5), bezier = "overshot", style = "slidevert"})
hl.animation({leaf = "specialWorkspace", enabled = true, speed = prod(5), bezier = "overshot", style = "slidevert"})
hl.animation({leaf = "windows", enabled = true, speed = prod(5), bezier = "wind", style = "popin 60%"})
hl.animation({leaf = "windowsIn", enabled = true, speed = prod(6), bezier = "overshot", style = "popin 60%"})
hl.animation({leaf = "windowsOut", enabled = true, speed = prod(4), bezier = "overshot", style = "popin 60%"})
hl.animation({leaf = "windowsMove", enabled = true, speed = prod(4), bezier = "overshot", style = "slide"})
hl.animation({leaf = "layers", enabled = true, speed = prod(4), bezier = "default", style = "popin"})
hl.animation({leaf = "fadeIn", enabled = true, speed = prod(7), bezier = "default"})
hl.animation({leaf = "fadeOut", enabled = true, speed = prod(7), bezier = "default"})
hl.animation({leaf = "fadeSwitch", enabled = true, speed = prod(7), bezier = "default"})
hl.animation({leaf = "fadeShadow", enabled = true, speed = prod(7), bezier = "default"})
hl.animation({leaf = "fadeDim", enabled = true, speed = prod(7), bezier = "default"})
hl.animation({leaf = "fadeLayers", enabled = true, speed = prod(7), bezier = "default"})
hl.animation({leaf = "workspaces", enabled = true, speed = prod(5), bezier = "overshot", style = "slidevert"})
hl.animation({leaf = "border", enabled = true, speed = prod(1), bezier = "liner"})
hl.animation({leaf = "borderangle", enabled = true, speed = prod(24), bezier = "liner", style = "loop"})
hl.animation({leaf = "specialWorkspaceIn", enabled = true, speed = prod(5), bezier = "overshot", style = "slidevert"})
hl.animation({leaf = "specialWorkspaceOut", enabled = true, speed = prod(5), bezier = "overshot", style = "slidevert"})
