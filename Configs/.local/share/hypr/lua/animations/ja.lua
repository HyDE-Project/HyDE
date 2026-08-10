local animation = {
    name = "Smooth In/Out",
    icon = "",
    description = "Gentle in/out easing for calm motion by Ja."
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
hl.curve("overshot", {type = "bezier", points = {{0.05, 0.9}, {0.1, 1.05}}})
hl.curve("smoothOut", {type = "bezier", points = {{0.5, 0}, {0.99, 0.99}}})
hl.curve("smoothIn", {type = "bezier", points = {{0.5, -0.5}, {0.68, 1.5}}})

hl.animation({leaf = "windows", enabled = true, speed = prod(6), bezier = "wind", style = "slide"})
hl.animation({leaf = "windowsIn", enabled = true, speed = prod(5), bezier = "winIn", style = "slide"})
hl.animation({leaf = "windowsOut", enabled = true, speed = prod(3), bezier = "smoothOut", style = "slide"})
hl.animation({leaf = "windowsMove", enabled = true, speed = prod(5), bezier = "wind", style = "slide"})
hl.animation({leaf = "border", enabled = true, speed = prod(1), bezier = "liner"})
hl.animation({leaf = "fade", enabled = true, speed = prod(3), bezier = "smoothOut"})
hl.animation({leaf = "workspaces", enabled = true, speed = prod(5), bezier = "overshot"})
hl.animation({leaf = "workspacesIn", enabled = true, speed = prod(5), bezier = "winIn", style = "slide"})
hl.animation({leaf = "workspacesOut", enabled = true, speed = prod(5), bezier = "winOut", style = "slide"})

return animation
