local animation = {
    name = "Popin Soft",
    icon = "",
    description = "Soft popin with md3 easing by End4."
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
hl.curve("menu_decel", {type = "bezier", points = {{0.1, 1}, {0, 1}}})
hl.curve("menu_accel", {type = "bezier", points = {{0.38, 0.04}, {1, 0.07}}})
hl.curve("easeInOutCirc", {type = "bezier", points = {{0.85, 0}, {0.15, 1}}})
hl.curve("easeOutCirc", {type = "bezier", points = {{0, 0.55}, {0.45, 1}}})
hl.curve("easeOutExpo", {type = "bezier", points = {{0.16, 1}, {0.3, 1}}})
hl.curve("softAcDecel", {type = "bezier", points = {{0.26, 0.26}, {0.15, 1}}})
hl.curve("md2", {type = "bezier", points = {{0.4, 0}, {0.2, 1}}})

hl.animation({leaf = "windows", enabled = true, speed = prod(3), bezier = "md3_decel", style = "popin 60%"})
hl.animation({leaf = "windowsIn", enabled = true, speed = prod(3), bezier = "md3_decel", style = "popin 60%"})
hl.animation({leaf = "windowsOut", enabled = true, speed = prod(3), bezier = "md3_accel", style = "popin 60%"})
hl.animation({leaf = "border", enabled = true, speed = prod(10), bezier = "default"})
hl.animation({leaf = "fade", enabled = true, speed = prod(3), bezier = "md3_decel"})
hl.animation({leaf = "layersIn", enabled = true, speed = prod(3), bezier = "menu_decel", style = "slide"})
hl.animation({leaf = "layersOut", enabled = true, speed = prod(1.6), bezier = "menu_accel"})
hl.animation({leaf = "fadeLayersIn", enabled = true, speed = prod(2), bezier = "menu_decel"})
hl.animation({leaf = "fadeLayersOut", enabled = true, speed = prod(4.5), bezier = "menu_accel"})
hl.animation({leaf = "workspaces", enabled = true, speed = prod(7), bezier = "menu_decel", style = "slide"})
hl.animation({leaf = "specialWorkspace", enabled = true, speed = prod(3), bezier = "md3_decel", style = "slidevert"})

return animation
