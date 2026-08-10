#!/usr/bin/env lua
local json = require("json")
local toml = require("toml")
local xdg = require("xdg")

local theme_name = arg[1] or "Catppuccin Mocha"
local theme_dir = xdg.config .. "/hyde/themes/" .. theme_name
local theme_config = theme_dir .. "/hypr.theme"
local toml_config = theme_dir .. "/config.toml"
local schema_path = xdg.data .. "/hypr/schema/hyprland-lua.json"

-- Helper to check if a file exists
local function file_exists(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

-- 1. Ensure the source hypr.theme actually exists
if not file_exists(theme_config) then
    print("Error: Source theme config not found at " .. theme_config)
    os.exit(1)
end

-- 2. Check if config.toml already exists. If NOT, create it.
if not file_exists(toml_config) then
    -- Run the hyq parser command with fully resolved XDG arguments
    local cmd = string.format('hyq --dump "%s" --schema "%s" --export nested-json', theme_config, schema_path)
    local f = io.popen(cmd)
    local raw = f:read("*a")
    f:close()

    -- Convert JSON string to TOML string
    local data = json.decode(raw)
    local toml_output = toml.encode(data)

    -- Write the output directly to config.toml
    local out_file = io.open(toml_config, "w")
    if out_file then
        out_file:write(toml_output)
        out_file:close()
        print("Created: " .. toml_config)
    else
        print("Error: Could not write to " .. toml_config)
    end
else
    print("Skipped: " .. toml_config .. " already exists.")
end
