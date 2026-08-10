local animation = {
    name = "Fast",
    icon = "",
    description = "Snappy, low-latency feel for quick transitions."
}

if not hl then
    return animation
end
-- prod utilizes the stored hyde.config.anim.duration_scale to dynamically change anim speed!
local prod = function(ds)
    return ds * hyde.config.anim.duration_scale
end


hl.curve("linear", {type = "bezier", points = {{0, 0}, {1, 1}}})
hl.curve("md3_standard", {type = "bezier", points = {{0.2, 0}, {0, 1}}})
hl.curve("md3_decel", {type = "bezier", points = {{0.05, 0.7}, {0.1, 1}}})
hl.curve("md3_accel", {type = "bezier", points = {{0.3, 0}, {0.8, 0.15}}})
hl.curve("overshot", {type = "bezier", points = {{0.05, 0.9}, {0.1, 1.1}}})
hl.curve("crazyshot", {type = "bezier", points = {{0.1, 1.5}, {0.76, 0.92}}})
hl.curve("hyprnostretch", {type = "bezier", points = {{0.05, 0.9}, {0.1, 1.0}}})
hl.curve("fluent_decel", {type = "bezier", points = {{0.1, 1}, {0, 1}}})
hl.curve("easeInOutCirc", {type = "bezier", points = {{0.85, 0}, {0.15, 1}}})
hl.curve("easeOutCirc", {type = "bezier", points = {{0, 0.55}, {0.45, 1}}})
hl.curve("easeOutExpo", {type = "bezier", points = {{0.16, 1}, {0.3, 1}}})

hl.animation({leaf = "windowsIn", enabled = true, speed = prod(3), bezier = "md3_decel", style = "popin 60%"})
hl.animation({leaf = "windowsOut", enabled = true, speed = prod(3), bezier = "md3_decel", style = "popin 60%"})
hl.animation({leaf = "windowsMove", enabled = true, speed = prod(3), bezier = "md3_decel", style = "popin 60%"})
hl.animation({leaf = "fadeIn", enabled = true, speed = prod(2.5), bezier = "md3_decel"})
hl.animation({leaf = "fadeOut", enabled = true, speed = prod(2.5), bezier = "md3_decel"})
hl.animation({leaf = "fadeSwitch", enabled = true, speed = prod(2.5), bezier = "md3_decel"})
hl.animation({leaf = "fadeShadow", enabled = true, speed = prod(2.5), bezier = "md3_decel"})
hl.animation({leaf = "fadeDim", enabled = true, speed = prod(2.5), bezier = "md3_decel"})
hl.animation({leaf = "fadeLayers", enabled = true, speed = prod(2.5), bezier = "md3_decel"})
hl.animation({leaf = "fadePopups", enabled = true, speed = prod(2.5), bezier = "md3_decel"})
hl.animation({leaf = "fadeDpms", enabled = true, speed = prod(2.5), bezier = "md3_decel"})
hl.animation({leaf = "workspacesIn", enabled = true, speed = prod(3.5), bezier = "easeOutExpo", style = "slide"})
hl.animation({leaf = "workspacesOut", enabled = true, speed = prod(3.5), bezier = "easeOutExpo", style = "slide"})
hl.animation({leaf = "specialWorkspaceIn", enabled = true, speed = prod(3), bezier = "md3_decel", style = "slidevert"})
hl.animation({leaf = "specialWorkspaceOut", enabled = true, speed = prod(3), bezier = "md3_decel", style = "slidevert"})
hl.animation({leaf = "windows", enabled = true, speed = prod(3), bezier = "md3_decel", style = "popin 60%"})
hl.animation({leaf = "border", enabled = true, speed = prod(10), bezier = "default"})
hl.animation({leaf = "fade", enabled = true, speed = prod(2.5), bezier = "md3_decel"})
hl.animation({leaf = "workspaces", enabled = true, speed = prod(3.5), bezier = "easeOutExpo", style = "slide"})
hl.animation({leaf = "specialWorkspace", enabled = true, speed = prod(3), bezier = "md3_decel", style = "slidevert"})
hl.animation({leaf = "fadeLayersIn", enabled = true, speed = prod(2.5), bezier = "md3_decel"})
hl.animation({leaf = "fadeLayersOut", enabled = true, speed = prod(2.5), bezier = "md3_decel"})
hl.animation({leaf = "fadePopupsIn", enabled = true, speed = prod(2.5), bezier = "md3_decel"})
hl.animation({leaf = "fadePopupsOut", enabled = true, speed = prod(2.5), bezier = "md3_decel"})
