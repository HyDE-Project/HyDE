local animation = {
    name = "Optimized",
    icon = "",
    description = "Optimized animation profile for Hyprland"
}

if not hl then
    return animation
end
-- prod utilizes the stored hyde.config.anim.duration_scale to dynamically change anim speed!
local prod = function(ds)
    return ds * hyde.config.anim.duration_scale
end


hl.curve("wind", {type = "bezier", points = {{0.05, 0.85}, {0.03, 0.97}}})
hl.curve("winIn", {type = "bezier", points = {{0.07, 0.88}, {0.04, 0.99}}})
hl.curve("winOut", {type = "bezier", points = {{0.20, -0.15}, {0, 1}}})
hl.curve("liner", {type = "bezier", points = {{1, 1}, {1, 1}}})
hl.curve("md3_standard", {type = "bezier", points = {{0.12, 0}, {0, 1}}})
hl.curve("md3_decel", {type = "bezier", points = {{0.05, 0.80}, {0.10, 0.97}}})
hl.curve("md3_accel", {type = "bezier", points = {{0.20, 0}, {0.80, 0.08}}})
hl.curve("overshot", {type = "bezier", points = {{0.05, 0.85}, {0.07, 1.04}}})
hl.curve("crazyshot", {type = "bezier", points = {{0.1, 1.22}, {0.68, 0.98}}})
hl.curve("hyprnostretch", {type = "bezier", points = {{0.05, 0.82}, {0.03, 0.94}}})
hl.curve("menu_decel", {type = "bezier", points = {{0.05, 0.82}, {0, 1}}})
hl.curve("menu_accel", {type = "bezier", points = {{0.20, 0}, {0.82, 0.10}}})
hl.curve("easeInOutCirc", {type = "bezier", points = {{0.75, 0}, {0.15, 1}}})
hl.curve("easeOutCirc", {type = "bezier", points = {{0, 0.48}, {0.38, 1}}})
hl.curve("easeOutExpo", {type = "bezier", points = {{0.10, 0.94}, {0.23, 0.98}}})
hl.curve("softAcDecel", {type = "bezier", points = {{0.20, 0.20}, {0.15, 1}}})
hl.curve("md2", {type = "bezier", points = {{0.30, 0}, {0.15, 1}}})
hl.curve("OutBack", {type = "bezier", points = {{0.28, 1.40}, {0.58, 1}}})
hl.animation({leaf = "fadeIn", enabled = true, speed = prod(1.8), bezier = "md3_decel"})
hl.animation({leaf = "fadeOut", enabled = true, speed = prod(1.8), bezier = "md3_decel"})
hl.animation({leaf = "fadeSwitch", enabled = true, speed = prod(1.8), bezier = "md3_decel"})
hl.animation({leaf = "fadeShadow", enabled = true, speed = prod(1.8), bezier = "md3_decel"})
hl.animation({leaf = "fadeDim", enabled = true, speed = prod(1.8), bezier = "md3_decel"})
hl.animation({leaf = "fadeLayers", enabled = true, speed = prod(1.8), bezier = "md3_decel"})
hl.animation({leaf = "fadePopups", enabled = true, speed = prod(1.8), bezier = "md3_decel"})
hl.animation({leaf = "fadeDpms", enabled = true, speed = prod(1.8), bezier = "md3_decel"})
hl.animation({leaf = "workspacesIn", enabled = true, speed = prod(4.0), bezier = "menu_decel", style = "slide"})
hl.animation({leaf = "workspacesOut", enabled = true, speed = prod(4.0), bezier = "menu_decel", style = "slide"})
hl.animation(
    {leaf = "specialWorkspaceIn", enabled = true, speed = prod(2.3), bezier = "md3_decel", style = "slidefadevert 15%"}
)
hl.animation(
    {leaf = "specialWorkspaceOut", enabled = true, speed = prod(2.3), bezier = "md3_decel", style = "slidefadevert 15%"}
)
hl.animation({leaf = "border", enabled = true, speed = prod(1.6), bezier = "liner"})
hl.animation({leaf = "borderangle", enabled = true, speed = prod(82), bezier = "liner", style = "loop"})
hl.animation({leaf = "windowsIn", enabled = true, speed = prod(3.2), bezier = "winIn", style = "slide"})
hl.animation({leaf = "windowsOut", enabled = true, speed = prod(2.8), bezier = "easeOutCirc"})
hl.animation({leaf = "windowsMove", enabled = true, speed = prod(3.0), bezier = "wind", style = "slide"})
hl.animation({leaf = "fade", enabled = true, speed = prod(1.8), bezier = "md3_decel"})
hl.animation({leaf = "layersIn", enabled = true, speed = prod(1.8), bezier = "menu_decel", style = "slide"})
hl.animation({leaf = "layersOut", enabled = true, speed = prod(1.5), bezier = "menu_accel"})
hl.animation({leaf = "fadeLayersIn", enabled = true, speed = prod(1.6), bezier = "menu_decel"})
hl.animation({leaf = "fadeLayersOut", enabled = true, speed = prod(1.8), bezier = "menu_accel"})
hl.animation({leaf = "workspaces", enabled = true, speed = prod(4.0), bezier = "menu_decel", style = "slide"})
hl.animation({leaf = "specialWorkspace", enabled = true, speed = prod(4.0), bezier = "menu_decel", style = "slide"})
hl.animation(
    {leaf = "specialWorkspace", enabled = true, speed = prod(2.3), bezier = "md3_decel", style = "slidefadevert 15%"}
)
hl.animation({leaf = "fadePopupsIn", enabled = true, speed = prod(1.8), bezier = "md3_decel"})
hl.animation({leaf = "fadePopupsOut", enabled = true, speed = prod(1.8), bezier = "md3_decel"})
