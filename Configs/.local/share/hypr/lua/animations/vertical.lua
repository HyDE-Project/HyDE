local animation = {
    name = "Vertical",
    icon = "",
    description = "Vertical animation profile for Hyprland"
}

if not hl then
    return animation
end
-- prod utilizes the stored hyde.config.anim.duration_scale to dynamically change anim speed!
local prod = function(ds)
    return ds * hyde.config.anim.duration_scale
end


hl.curve("fluent_decel", {type = "bezier", points = {{0, 0.2}, {0.4, 1}}})
hl.curve("easeOutCirc", {type = "bezier", points = {{0, 0.55}, {0.45, 1}}})
hl.curve("easeOutCubic", {type = "bezier", points = {{0.33, 1}, {0.68, 1}}})
hl.curve("easeinoutsine", {type = "bezier", points = {{0.37, 0}, {0.63, 1}}})

hl.animation({leaf = "layersIn", enabled = true, speed = prod(1.5), bezier = "easeinoutsine", style = "popin"})
hl.animation({leaf = "layersOut", enabled = true, speed = prod(1.5), bezier = "easeinoutsine", style = "popin"})
hl.animation({leaf = "fadeIn", enabled = true, speed = prod(2.5), bezier = "fluent_decel"})
hl.animation({leaf = "fadeOut", enabled = true, speed = prod(2.5), bezier = "fluent_decel"})
hl.animation({leaf = "fadeSwitch", enabled = true, speed = prod(2.5), bezier = "fluent_decel"})
hl.animation({leaf = "fadeShadow", enabled = true, speed = prod(2.5), bezier = "fluent_decel"})
hl.animation({leaf = "fadeDim", enabled = true, speed = prod(2.5), bezier = "fluent_decel"})
hl.animation({leaf = "fadeLayers", enabled = true, speed = prod(2.5), bezier = "fluent_decel"})
hl.animation({leaf = "fadePopups", enabled = true, speed = prod(2.5), bezier = "fluent_decel"})
hl.animation({leaf = "fadeDpms", enabled = true, speed = prod(2.5), bezier = "fluent_decel"})
hl.animation({leaf = "workspacesIn", enabled = true, speed = prod(3), bezier = "fluent_decel", style = "slidefadevert 30%"})
hl.animation({leaf = "workspacesOut", enabled = true, speed = prod(3), bezier = "fluent_decel", style = "slidefadevert 30%"})
hl.animation({leaf = "specialWorkspaceIn", enabled = true, speed = prod(2), bezier = "fluent_decel", style = "slidefade 10%"})
hl.animation(
    {leaf = "specialWorkspaceOut", enabled = true, speed = prod(2), bezier = "fluent_decel", style = "slidefade 10%"}
)
hl.animation({leaf = "windowsIn", enabled = true, speed = prod(1.5), bezier = "easeinoutsine", style = "popin 60%"})
hl.animation({leaf = "windowsOut", enabled = true, speed = prod(1.5), bezier = "easeOutCubic", style = "popin 60%"})
hl.animation({leaf = "windowsMove", enabled = true, speed = prod(1.5), bezier = "easeinoutsine", style = "slide"})
hl.animation({leaf = "fade", enabled = true, speed = prod(2.5), bezier = "fluent_decel"})
hl.animation({leaf = "fadeLayersIn", enabled = false})
hl.animation({leaf = "border", enabled = false})
hl.animation({leaf = "layers", enabled = true, speed = prod(1.5), bezier = "easeinoutsine", style = "popin"})
hl.animation({leaf = "workspaces", enabled = true, speed = prod(3), bezier = "fluent_decel", style = "slidefadevert 30%"})
hl.animation({leaf = "specialWorkspace", enabled = true, speed = prod(2), bezier = "fluent_decel", style = "slidefade 10%"})
hl.animation({leaf = "fadeLayersOut", enabled = true, speed = prod(2.5), bezier = "fluent_decel"})
hl.animation({leaf = "fadePopupsIn", enabled = true, speed = prod(2.5), bezier = "fluent_decel"})
hl.animation({leaf = "fadePopupsOut", enabled = true, speed = prod(2.5), bezier = "fluent_decel"})
