local layout = {
    name = "Master",
    icon = "",
    description = "Master layout // Best for maximizing space"
}
if not hl then
    return layout
end

hl.config(
    {
        general = {
            layout = "master"
        },
        master = {
            new_on_top = 1,
            new_status = "slave",
            allow_small_split = true
        }
    }
)

local _F = {description = "[Master] swap current window with master"}
hl.bind("ALT + M", hl.dsp.layout("swapwithmaster auto"), _F)

-- _F = {description = "[Master] swap master with first child"}
-- hl.bind("ALT + SHIFT + M", hl.dsp.layout("swapwithmaster child"), _F)

_F = {description = "[Master] focus master"}
hl.bind("ALT + F", hl.dsp.layout("focusmaster auto"), _F)

-- _F = {description = "[Master] focus previous window when on master"}
-- hl.bind("ALT + SHIFT + F", hl.dsp.layout("focusmaster previous"), _F)

_F = {description = "[Master] focus next window"}
hl.bind("ALT + period", hl.dsp.layout("cyclenext"), _F)

_F = {description = "[Master] focus previous window"}
hl.bind("ALT + comma", hl.dsp.layout("cycleprev"), _F)

_F = {description = "[Master] swap focused window with next window"}
hl.bind("ALT + K", hl.dsp.layout("swapnext"), _F)

_F = {description = "[Master] swap focused window with previous window"}
hl.bind("ALT + J", hl.dsp.layout("swapprev"), _F)

_F = {description = "[Master] add current window to master area"}
hl.bind("ALT + A", hl.dsp.layout("addmaster"), _F)

_F = {description = "[Master] remove current master window"}
hl.bind("ALT + SHIFT + A", hl.dsp.layout("removemaster"), _F)

_F = {description = "[Master] set orientation to left"}
hl.bind("ALT + LEFT", hl.dsp.layout("orientationleft"), _F)

_F = {description = "[Master] set orientation to right"}
hl.bind("ALT + RIGHT", hl.dsp.layout("orientationright"), _F)

_F = {description = "[Master] set orientation to top"}
hl.bind("ALT + UP", hl.dsp.layout("orientationtop"), _F)

_F = {description = "[Master] set orientation to bottom"}
hl.bind("ALT + DOWN", hl.dsp.layout("orientationbottom"), _F)

_F = {description = "[Master] set orientation to center"}
hl.bind("ALT + C", hl.dsp.layout("orientationcenter"), _F)

_F = {description = "[Master] cycle orientation clockwise"}
hl.bind("ALT + N", hl.dsp.layout("orientationnext"), _F)

_F = {description = "[Master] cycle orientation counter-clockwise"}
hl.bind("ALT + SHIFT + N", hl.dsp.layout("orientationprev"), _F)

_F = {description = "[Master] cycle orientation through all modes"}
hl.bind("ALT + T", hl.dsp.layout("orientationcycle left top right bottom center"), _F)

_F = {description = "[Master] increase master area ratio"}
hl.bind("ALT + EQUAL", hl.dsp.layout("mfact +0.05"), _F)

_F = {description = "[Master] decrease master area ratio"}
hl.bind("ALT + MINUS", hl.dsp.layout("mfact -0.05"), _F)

_F = {description = "[Master] rotate next stack window into master"}
hl.bind("ALT + U", hl.dsp.layout("rollnext"), _F)

_F = {description = "[Master] rotate previous stack window into master"}
hl.bind("ALT + I", hl.dsp.layout("rollprev"), _F)

hl.gesture(
    {
        fingers = 4,
        direction = "horizontal",
        action = "workspace"
    }
)

hl.gesture(
    {
        fingers = 4,
        direction = "vertical",
        action = "workspace"
    }
)

for _, dir in ipairs({"up", "down", "left", "right"}) do
    hl.gesture(
        {
            fingers = 3,
            direction = dir,
            action = function()
                hl.dispatch(hl.dsp.focus({direction = dir}))
            end
        }
    )
end
