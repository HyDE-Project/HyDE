--[[
    █▀ █▄░█ ▄▀█ █▀█ █▀█ █▄█
    ▄█ █░▀█ █▀█ █▀▀ █▀▀ ░█░

    Workflow: Snappy
    Snappy, tight desktop — no rounding, no gaps, no animations.

    Select with: doorwayde-shell workflows --select
--]]

hl.config({
    general = {
        gaps_in = 0,
        gaps_out = 0,
        border_size = 1,
    },
    decoration = {
        rounding = 0,
    },
    animations = { enabled = false },
})
