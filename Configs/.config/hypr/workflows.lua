--[[
    █░█░█ █▀█ █▀█ █▄▀ █▀▀ █░░ █▀█ █░█░█ █▀
    ▀▄▀▄▀ █▄█ █▀▄ █░█ █▀░ █▄▄ █▄█ ▀▄▀▄▀ ▄█

    Workflow Loader
    https://wiki.hypr.land/Configuring/

    DOORwayDE managed — use 'doorwayde-shell animations --select' to change.
    Scripts update the workflow variable below.
--]]

local workflow = "default"  -- DOORwayDE scripts update this line
require("workflows/" .. workflow)
