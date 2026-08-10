local animation = {
    name = "Elastic Slide",
    icon = "",
    description = "Me-2 animation profile for Hyprland"
}

if not hl then
    return animation
end
-- prod utilizes the stored hyde.config.anim.duration_scale to dynamically change anim speed!
local prod = function(ds)
    return ds * hyde.config.anim.duration_scale
end


hl.curve("wind", {type = "bezier", points = {{0.05, 0.9}, {0.1, 1.05}}})
hl.curve("winIn", {type = "bezier", points = {{0.1, 1.1}, {0.1, 1.1}}})
hl.curve("winOut", {type = "bezier", points = {{0.3, -0.3}, {0, 1}}})
hl.curve("liner", {type = "bezier", points = {{1, 1}, {1, 1}}})
hl.curve("md3_standard", {type = "bezier", points = {{0.2, 0}, {0, 1}}})
hl.curve("md3_decel", {type = "bezier", points = {{0.05, 0.7}, {0.1, 1}}})
hl.curve("md3_accel", {type = "bezier", points = {{0.3, 0}, {0.8, 0.15}}})
hl.curve("overshot", {type = "bezier", points = {{0.05, 0.9}, {0.1, 1.1}}})
hl.curve("crazyshot", {type = "bezier", points = {{0.1, 1.5}, {0.76, 0.92}}})
hl.curve("hyprnostretch", {type = "bezier", points = {{0.05, 0.9}, {0.1, 1.0}}})
hl.curve("menu_decel", {type = "bezier", points = {{0.1, 1}, {0, 1}}})
hl.curve("menu_accel", {type = "bezier", points = {{0.38, 0.04}, {1, 0.07}}})
hl.curve("easeInOutCirc", {type = "bezier", points = {{0.85, 0}, {0.15, 1}}})
hl.curve("easeOutCirc", {type = "bezier", points = {{0, 0.55}, {0.45, 1}}})
hl.curve("easeOutExpo", {type = "bezier", points = {{0.16, 1}, {0.3, 1}}})
hl.curve("softAcDecel", {type = "bezier", points = {{0.26, 0.26}, {0.15, 1}}})
hl.curve("md2", {type = "bezier", points = {{0.4, 0}, {0.2, 1}}})
hl.curve("OutBack", {type = "bezier", points = {{0.34, 1.56}, {0.64, 1}}})

hl.animation({leaf = "fadeIn", enabled = true, speed = prod(3), bezier = "md3_decel"})
hl.animation({leaf = "fadeOut", enabled = true, speed = prod(3), bezier = "md3_decel"})
hl.animation({leaf = "fadeSwitch", enabled = true, speed = prod(3), bezier = "md3_decel"})
hl.animation({leaf = "fadeShadow", enabled = true, speed = prod(3), bezier = "md3_decel"})
hl.animation({leaf = "fadeDim", enabled = true, speed = prod(3), bezier = "md3_decel"})
hl.animation({leaf = "fadeLayers", enabled = true, speed = prod(3), bezier = "md3_decel"})
hl.animation({leaf = "fadePopups", enabled = true, speed = prod(3), bezier = "md3_decel"})
hl.animation({leaf = "fadeDpms", enabled = true, speed = prod(3), bezier = "md3_decel"})
hl.animation({leaf = "workspacesIn", enabled = true, speed = prod(5), bezier = "wind"})
hl.animation({leaf = "workspacesOut", enabled = true, speed = prod(5), bezier = "wind"})
hl.animation({leaf = "specialWorkspaceIn", enabled = true, speed = prod(3), bezier = "md3_decel", style = "slidevert"})
hl.animation({leaf = "specialWorkspaceOut", enabled = true, speed = prod(3), bezier = "md3_decel", style = "slidevert"})
hl.animation({leaf = "border", enabled = true, speed = prod(1), bezier = "liner"})
hl.animation({leaf = "borderangle", enabled = true, speed = prod(30), bezier = "liner", style = "loop"})
hl.animation({leaf = "windowsIn", enabled = true, speed = prod(6), bezier = "winIn", style = "slide"})
hl.animation({leaf = "windows", enabled = true, speed = prod(5), bezier = "easeInOutCirc"})
hl.animation({leaf = "windowsOut", enabled = true, speed = prod(5), bezier = "OutBack"})
hl.animation({leaf = "windowsMove", enabled = true, speed = prod(5), bezier = "wind", style = "slide"})
hl.animation({leaf = "fade", enabled = true, speed = prod(3), bezier = "md3_decel"})
hl.animation({leaf = "layersIn", enabled = true, speed = prod(3), bezier = "menu_decel", style = "slide"})
hl.animation({leaf = "layersOut", enabled = true, speed = prod(1.6), bezier = "menu_accel"})
hl.animation({leaf = "fadeLayersIn", enabled = true, speed = prod(2), bezier = "menu_decel"})
hl.animation({leaf = "fadeLayersOut", enabled = true, speed = prod(4.5), bezier = "menu_accel"})
hl.animation({leaf = "workspaces", enabled = true, speed = prod(5), bezier = "wind"})
hl.animation({leaf = "specialWorkspace", enabled = true, speed = prod(3), bezier = "md3_decel", style = "slidevert"})
hl.animation({leaf = "fadePopupsIn", enabled = true, speed = prod(3), bezier = "md3_decel"})
hl.animation({leaf = "fadePopupsOut", enabled = true, speed = prod(3), bezier = "md3_decel"})
