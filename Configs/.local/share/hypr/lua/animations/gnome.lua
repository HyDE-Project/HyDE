local animation = {
    name = "GNOME Spring",
    icon = "",
    description = "Spring-based, GNOME-like behavior using the native gnomed style."
}

if not hl then
    return animation
end

-- prod utilizes the stored hyde.config.anim.duration_scale to dynamically change anim speed!
local prod = function(ds)
    return ds * hyde.config.anim.duration_scale
end

hl.curve("gnomeOpen", {type = "spring", mass = 1, stiffness = 100, dampening = 14})
hl.curve("gnomeClose", {type = "spring", mass = 1, stiffness = 90, dampening = 16})
hl.curve("gnomeFade", {type = "bezier", points = {{0.25, 0.1}, {0.25, 1.0}}})

hl.animation({leaf = "windowsIn", enabled = true, speed = prod(7), spring = "gnomeOpen", style = "gnomed"})
hl.animation({leaf = "windowsOut", enabled = true, speed = prod(6), spring = "gnomeClose", style = "gnomed"})

hl.animation({leaf = "windowsMove", enabled = true, speed = prod(5), bezier = "gnomeFade", style = "slide"})
hl.animation({leaf = "border", enabled = true, speed = prod(1), bezier = "default"})
hl.animation({leaf = "borderangle", enabled = true, speed = prod(30), bezier = "default", style = "once"})
hl.animation({leaf = "fade", enabled = true, speed = prod(9), bezier = "default"})
hl.animation({leaf = "workspaces", enabled = true, speed = prod(6), bezier = "gnomeFade", style = "slidefade 20%"})
hl.animation({leaf = "workspacesIn", enabled = true, speed = prod(6), bezier = "gnomeFade", style = "slidefade 20%"})
hl.animation({leaf = "workspacesOut", enabled = true, speed = prod(6), bezier = "gnomeFade", style = "slidefade 20%"})
hl.animation(
    {leaf = "specialWorkspace", enabled = true, speed = prod(6), bezier = "gnomeFade", style = "slidefade 20%"}
)
hl.animation(
    {leaf = "specialWorkspaceIn", enabled = true, speed = prod(6), bezier = "gnomeFade", style = "slidefade 20%"}
)
hl.animation(
    {leaf = "specialWorkspaceOut", enabled = true, speed = prod(6), bezier = "gnomeFade", style = "slidefade 20%"}
)
hl.animation({leaf = "zoomFactor", enabled = true, speed = prod(7), bezier = "default"})
hl.animation({leaf = "monitorAdded", enabled = true, speed = prod(7), bezier = "default"})

return animation
