-- # // █▀ █▄░█ ▄▀█ █▀█ █▀█ █▄█
-- # // ▄█ █░▀█ █▀█ █▀▀ █▀▀ ░█░

-- $WORKFLOW_ICON=󰓅 # this is an indicator that can be parsed by waybar or other status guis
-- $WORKFLOW_DESCRIPTION = Snappy desktop

-- decoration {
-- rounding = 0
-- }

-- general {
--     gaps_in = 0
--     gaps_out = 0
--     border_size = 1
-- }

-- animations:enabled = 0

local workflow = {
    name = "Snappy",
    icon = "󰓅",
    description = "A snappy desktop with no animations and effects, but preserving readability"
}

if not hl then
    return workflow
end

hl.config({
    decoration = {
        rounding = 0,
    },
    general = {
        gaps_in = 0,
        gaps_out = 0,
        border_size = 1
    }
})

check_require("animations.00-disable")
