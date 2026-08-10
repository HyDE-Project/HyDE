local layout = {
    key = "monocle",
    name = "Monocle",
    icon = "",
    description = "Monocle layout // Best for maximizing space"
}
if not hl then
    return layout
end

hl.config({
    general = {
        layout = "monocle"
    },
    monocle = {
    }
})

-- Use 3-finger swipes to move between workspaces.
hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

hl.gesture({
    fingers = 3,
    direction = "vertical",
    action = "workspace"
})



-- Monocle keybinds
local _F = {description = "[Monocle] cycle next window"}
hl.bind("ALT + period", hl.dsp.layout("cyclenext"), _F)
_F = {description = "[Monocle] cycle previous window"}
hl.bind("ALT + comma", hl.dsp.layout("cycleprev"), _F)
