local animation = {
    name = "Disabled (No Animations)",
    icon = "󰇄",
    description = "Disable all animations"
}

if not hl then
    return animation
end

-- Note: We are required to disbale them explicitly.
hl.animation({leaf = "global", enabled = false})
hl.animation({leaf = "windows", enabled = false})
hl.animation({leaf = "windowsIn", enabled = false})
hl.animation({leaf = "windowsOut", enabled = false})
hl.animation({leaf = "windowsMove", enabled = false})
hl.animation({leaf = "layers", enabled = false})
hl.animation({leaf = "layersIn", enabled = false})
hl.animation({leaf = "layersOut", enabled = false})
hl.animation({leaf = "fade", enabled = false})
hl.animation({leaf = "fadeIn", enabled = false})
hl.animation({leaf = "fadeOut", enabled = false})
hl.animation({leaf = "fadeSwitch", enabled = false})
hl.animation({leaf = "fadeShadow", enabled = false})
hl.animation({leaf = "fadeGlow", enabled = false})
hl.animation({leaf = "fadeDim", enabled = false})
hl.animation({leaf = "fadeLayers", enabled = false})
hl.animation({leaf = "fadeLayersIn", enabled = false})
hl.animation({leaf = "fadeLayersOut", enabled = false})
hl.animation({leaf = "fadePopups", enabled = false})
hl.animation({leaf = "fadePopupsIn", enabled = false})
hl.animation({leaf = "fadePopupsOut", enabled = false})
hl.animation({leaf = "fadeDpms", enabled = false})
hl.animation({leaf = "border", enabled = false})
hl.animation({leaf = "borderangle", enabled = false})
hl.animation({leaf = "shadowangle", enabled = false})
hl.animation({leaf = "glowangle", enabled = false})
hl.animation({leaf = "workspaces", enabled = false})
hl.animation({leaf = "workspacesIn", enabled = false})
hl.animation({leaf = "workspacesOut", enabled = false})
hl.animation({leaf = "specialWorkspace", enabled = false})
hl.animation({leaf = "specialWorkspaceIn", enabled = false})
hl.animation({leaf = "specialWorkspaceOut", enabled = false})
hl.animation({leaf = "zoomFactor", enabled = false})
hl.animation({leaf = "monitorAdded", enabled = false})
