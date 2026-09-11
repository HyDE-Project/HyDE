#!/usr/bin/env lua

local root = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
package.path = package.path .. ";" .. root .. "?.lua;" .. root .. "?/init.lua;"

require("luautils.init")
local xdg = require("luautils.xdg")
local lfs = require("lfs")
local hyprctl = require("luautils.hypr.hyprctl")
local common = require("luautils.selector.common")
local argparse = require("argparse")

local COMPILED = xdg.state .. "/hyde/compiled.cache.glsl"
local DEFAULT_SHADER_ICON = ""local SHADER_DIRS = {
    xdg.config .. "/hypr/shaders",
    xdg.data .. "/hypr/shaders",
    "/usr/local/share/hypr/shaders",
    "/usr/share/hypr/shaders"
}
local function ensure_dir(path)
    local cur = ""
    for p in path:gmatch("[^/]+") do
        cur = cur .. "/" .. p
        lfs.mkdir(cur)
    end
end

local function find_include(base)
    for _, dir in ipairs(SHADER_DIRS) do
        local path = dir .. "/" .. base .. ".inc"
        if lfs.attributes(path, "mode") == "file" then
            return path
        end
    end
    return nil
end

-- Falls back to the XDG defaults when a variable is not exported, so a shader
-- referencing "$XDG_CACHE_HOME" still resolves outside of a HyDE session.
local ENV_FALLBACK = {
    XDG_DATA_HOME = xdg.data,
    XDG_CONFIG_HOME = xdg.config,
    XDG_CACHE_HOME = xdg.cache,
    XDG_STATE_HOME = xdg.state,
    XDG_RUNTIME_DIR = xdg.runtime,
    HOME = os.getenv("HOME")
}

-- Expands "$VAR" and "${VAR}" occurrences in a path. A variable that is set but
-- empty counts as unset, so the fallback still applies.
local function expand_env(str)
    local function lookup(name)
        local value = os.getenv(name)
        if value == nil or value == "" then
            value = ENV_FALLBACK[name]
        end
        return value or ""
    end
    str = str:gsub("%${([%w_]+)}", lookup)
    str = str:gsub("%$([%w_]+)", lookup)
    return str
end

local function parse_source_include(path)
    local source_include
    local shader_dir = path:match("^(.*)/") or "."
    local f = io.open(path, "r")
    if not f then
        return nil
    end
    for line in f:lines() do
        local source = line:match("^%s*//%s*!source%s*=%s*(.-)%s*$")
        if source and source ~= "" then
            source = expand_env(source)
            if source:sub(1, 1) ~= "/" then
                source = shader_dir .. "/" .. source
            end
            source_include = source
            break
        end
    end
    f:close()
    return source_include
end

-- Compile item's .frag into COMPILED (strips duplicate #version lines).
-- Includes a matching same-name .inc file from any known shader dir.
-- Returns COMPILED on success, or nil + error string on failure.
local function compile_shader(item)
    ensure_dir(xdg.state .. "/hyde/shaders")
    local src = item and item.path or ""
    if item == nil or item.key == "disable" or src == "" then
        local f = io.open(COMPILED, "w")
        if f then
            f:write("\n")
            f:close()
        end
        return COMPILED
    end

    local in_f = io.open(src, "r")
    if not in_f then
        return nil, "shader not found: " .. src
    end

    local ver = ""
    for line in in_f:lines() do
        if ver == "" then
            ver = line:match("^%s*#version%s+.+$") or ""
        end
    end
    in_f:close()

    local base = src:match("([^/]+)%.frag$") or item.key or ""
    local inc_path = find_include(base)
    local source_include = parse_source_include(src)

    local files = {}
    if source_include then
        if lfs.attributes(source_include, "mode") ~= "file" then
            return nil, "source include not found: " .. source_include
        end
        files[#files + 1] = source_include
    end
    if inc_path then
        files[#files + 1] = inc_path
    end
    files[#files + 1] = src

    local out_f = assert(io.open(COMPILED, "w"))
    out_f:write((ver ~= "" and ver or "#version 300 es"), "\n\n")
    for _, path in ipairs(files) do
        local f = io.open(path, "r")
        if not f then
            return nil, "include file not found: " .. path
        end
        for line in f:lines() do
            if not line:match("^%s*#version%s+") then
                out_f:write(line, "\n")
            end
        end
        f:close()
        out_f:write("\n")
    end
    out_f:close()
    return COMPILED
end

-- Write the shader runtime state file consumed by Hyprland.
local function write_state(state_dir, state_file, item)
    ensure_dir(state_dir)
    local shader = item and item.key ~= "disable" and COMPILED or ""
    local f = assert(io.open(state_file, "w"))
    f:write("local shader = ", string.format("%q", shader), "\n")
    f:write('if rawget(_G, "hl") then hl.config({ decoration = { screen_shader = shader } }) end\n\n')
    f:write("return {\n")
    for _, k in ipairs({"path", "key", "name", "description", "icon"}) do
        if item and item[k] then
            f:write("  ", k, " = ", string.format("%q", item[k]), ",\n")
        end
    end
    f:write("}\n")
    f:close()
end

local function apply_shader(item)
    local shader = ""
    if item and item.key ~= "disable" then
        local compiled, err = compile_shader(item)
        if not compiled then
            error("compile shader: " .. tostring(err))
        end
        shader = compiled
    end
    hyprctl.exec("keyword", "decoration:screen_shader", shader)
end

-- Read metadata from #define SHADER_* macros in a .frag file.
-- Stops scanning when actual GLSL declarations begin.
local function read_frag_meta(path)
    local meta = {}
    local f = io.open(path, "r")
    if not f then
        return meta
    end
    local function is_glsl_decl(line)
        return line:match("^%s*(in|out|uniform|layout|void|precision)%s")
    end
    for line in f:lines() do
        local k, v = line:match("^%s*#define%s+SHADER_(%w+)%s*(.-)%s*$")
        if k then
            meta[k:lower()] = v
        end
        if is_glsl_decl(line) then
            break
        end
    end
    f:close()
    return meta
end

local M =
    common.new(
    {
        dirs = {
            xdg.config .. "/hypr/shaders",
            xdg.data .. "/hypr/shaders",
            "/usr/local/share/hypr/shaders",
            "/usr/share/hypr/shaders"
        },
        state_name = "shaders",
        waybar_class = "custom-shaders",
        staterc_key = "HYPR_SHADER",
        -- Without this a fresh install starts on the blue light filter.
        default_key = "disable",
        item_ext = ".frag",
        file_pattern = "%.frag$",
        load_item = function(path, base)
            local meta = read_frag_meta(path)
            return {
                path = path,
                key = base,
                name = meta.name or base,
                icon = meta.icon or DEFAULT_SHADER_ICON,
                description = meta.description or ("Shader: " .. base)
            }
        end,

        state_writer = write_state,
        on_set = apply_shader,
        rofi_opts = {
            prioritize = {"00-disable", "disable"}
        }
    }
)

local _base_current = M.current
M.current = function()
    local env = os.getenv("HYPR_SHADER")
    local item = env and M.find(env)
    return item or _base_current()
end

M.apply = apply_shader
if rawget(_G, "hl") then
    apply_shader(M.current())
end

local _src = debug.getinfo(1, "S").source
local _script_path = _src:match("^@(.*)$") or _src
if _script_path:sub(1, 1) ~= "/" then
    _script_path = arg[0] or _script_path
end

M.rofi_opts.on_selection_changed = string.format(
    [[lua "%s" --test "{entry}"]],
    _script_path
)
M.rofi_opts.on_menu_canceled = "hyprctl reload"

local function normalize_rofi_entry(value)
    value = tostring(value or "")
    value = value:match("^%s*(.-)%s*$")
    return value:match("[^	]+$") or value
end

local _is_main = arg and arg[0] and (_src == "@" .. arg[0] or _src:sub(2):match("[^/]+$") == arg[0]:match("[^/]+$"))
if _is_main then
    -- Custom CLI parser with test flags
    local parser = argparse("hyde-shell shaders", "HyDE Shader Selector")
    parser:flag("--list", "List available items")
    parser:option("--set", "Set the given item"):argname("NAME")
    parser:flag("--select", "Select an item with rofi")
    parser:flag("--reload", "Reload the current item and re-apply its configuration")
    parser:flag("--current", "Show the current item")
    parser:flag("--waybar", "Get item info for Waybar")
    parser:option("--test", "Transiently preview shader (for rofi on-selection-changed)"):argname("NAME")

    local cli = parser:parse(arg or {})

    local function print_item(item)
        print((item.icon or "") .. " " .. (item.name or "?") .. ": " .. (item.description or ""))
    end

    if cli.list then
        if not M.list or #M.list == 0 then
            print("No items found")
            return
        end
        for _, item in ipairs(M.list) do
            print((item.icon or "") .. " " .. (item.name or "?") .. " :: " .. (item.description or ""))
            if item.path then
                print("  " .. item.path)
            end
        end
    elseif cli.set then
        local item, err = M.set(cli.set)
        if not item then
            io.stderr:write("Error: " .. tostring(err) .. "\n")
            if M.names then
                io.stderr:write("Available: " .. table.concat(M.names, ", ") .. "\n")
            end
            os.exit(1)
        end
        print_item(item)
    elseif cli.test then
        local shader_name = normalize_rofi_entry(cli.test)
        local item = M.find(shader_name)
        if not item then
            io.stderr:write("Error: unknown shader '" .. tostring(shader_name) .. "'\n")
            if M.names then
                io.stderr:write("Available: " .. table.concat(M.names, ", ") .. "\n")
            end
            os.exit(1)
        end
        local compiled, err = compile_shader(item)
        if not compiled then
            io.stderr:write("Error: " .. tostring(err) .. "\n")
            os.exit(1)
        end
        local shader = item.key ~= "disable" and compiled or ""
        local lua_cmd = string.format(
            "hl.config({ debug = { damage_tracking = false }, decoration = { screen_shader = %s } })",
            string.format("%q", shader)
        )
        hyprctl.exec("eval", lua_cmd)
    elseif cli.current then
        local item = M.current and M.current()
        if not item then
            print("No current item")
        else
            print_item(item)
        end
    elseif cli.reload then
        local item = M.reload and M.reload()
        if not item then
            io.stderr:write("Error: reload failed\n")
            os.exit(1)
        end
        print_item(item)
    elseif cli.select then
        if not M.list or #M.list == 0 then
            print("No items found")
            return
        end

        local current_item = M.current and M.current()
        local rofi_opts = {}
        -- merge module-level rofi_opts (e.g. prioritize) without overriding caller opts
        if M.rofi_opts then
            for k, v in pairs(M.rofi_opts) do
                if rofi_opts[k] == nil then
                    rofi_opts[k] = v
                end
            end
        end
        rofi_opts.current_item = current_item

        local rofi = require("luautils.selector.rofi")
        local selected = rofi.select(M.list, rofi_opts)
        if not selected or selected == "" then
            return
        end

        local item, err = M.set(selected)
        if not item then
            io.stderr:write("Error: " .. tostring(err) .. "\n")
            if M.names then
                io.stderr:write("Available: " .. table.concat(M.names, ", ") .. "\n")
            end
            os.exit(1)
        end
        print_item(item)
    elseif cli.waybar then
        M.waybar()
    else
        print(parser:get_help())
    end
end

return M
