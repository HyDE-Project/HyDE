#!/usr/bin/env lua

local root = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
package.path = package.path .. ";" .. root .. "?.lua;" .. root .. "?/init.lua;"

require("luautils.init")
local xdg = require("luautils.xdg")
local lfs = require("lfs")
local hyprctl = require("luautils.hypr.hyprctl")
local common = require("luautils.selector.common")
local argparse = require("argparse")

local state = require("luautils.global.state")
local socket = require("socket")
local JSON = require("dkjson")
local CACHE_DIR = xdg.state .. "/hyde/shaders"
local RUNTIME_DIR = (xdg.runtime or xdg.state) .. "/hyde/shaders"
local MENU_FILE = RUNTIME_DIR .. "/preview"
local INSTANCE = os.getenv("HYPRLAND_INSTANCE_SIGNATURE") or ""
local DEFAULT_SHADER_ICON = ""
local SHADER_DIRS = {
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

-- Each application gets its own file: previews must not overwrite saved shaders (#2076).
local function compile_shader(item)
    ensure_dir(CACHE_DIR)
    local src = item and item.path or ""
    if item and item.key == "disable" then
        return ""
    end
    if src == "" then
        return nil, "missing shader path"
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

    local contents = {(ver ~= "" and ver or "#version 300 es"), "\n\n"}
    for _, path in ipairs(files) do
        local f = io.open(path, "r")
        if not f then
            return nil, "include file not found: " .. path
        end
        for line in f:lines() do
            if not line:match("^%s*#version%s+") then
                contents[#contents + 1] = line .. "\n"
            end
        end
        f:close()
        contents[#contents + 1] = "\n"
    end
    local temp = os.tmpname()
    os.remove(temp)
    local compiled = CACHE_DIR .. "/" .. temp:match("[^/]+$") .. ".frag"
    local f, err = io.open(compiled, "w")
    if not f then return nil, err end
    local ok, write_err = f:write(table.concat(contents))
    local closed, close_err = f:close()
    if not ok or not closed then
        os.remove(compiled)
        return nil, write_err or close_err
    end
    return compiled
end

-- Shader name/icon end up inside a double-quoted shell string (rofi's
-- on_selection_changed {entry} substitution): strip what can break out of
-- that context so a crafted .frag file (or filename) can't run commands
-- just by being highlighted in the picker.
local function strip_shell_unsafe(s)
    return (s:gsub('[%c`$"\\]', ""))
end

-- A name that strips down to nothing (e.g. SHADER_NAME was only unsafe
-- characters) would break rofi's tab-separated row format and the
-- icon/name split on the way back out; fall back to the filename instead.
local function sanitize_name(raw, fallback)
    local safe = strip_shell_unsafe(raw)
    if safe ~= "" then
        return safe
    end
    -- The fallback (the filename) is just as untrusted as SHADER_NAME.
    return strip_shell_unsafe(fallback)
end

-- Read metadata from #define SHADER_* macros in a .frag file.
-- Stops scanning when actual GLSL declarations begin.
local function read_frag_meta(path)
    local meta = {}
    local f = io.open(path, "r")
    if not f then
        return meta
    end
    local declarations = { ["in"] = true, out = true, uniform = true, layout = true, void = true, precision = true }
    local in_comment = false
    for raw_line in f:lines() do
        local line = raw_line
        -- Ignore block comments as well as line comments when reading declarations.
        local clean = ""
        while line ~= "" do
            if in_comment then
                local finish = line:find("*/", 1, true)
                if not finish then break end
                line, in_comment = line:sub(finish + 2), false
            else
                local block = line:find("/*", 1, true)
                local comment = line:find("//", 1, true)
                if comment and (not block or comment < block) then
                    clean = clean .. line:sub(1, comment - 1)
                    break
                elseif block then
                    clean = clean .. line:sub(1, block - 1) .. " "
                    line, in_comment = line:sub(block + 2), true
                else
                    clean = clean .. line
                    break
                end
            end
        end
        line = clean
        local k, v = line:match("^%s*#define%s+SHADER_(%w+)%s*(.-)%s*$")
        if k then
            meta[k:lower()] = v
        end
        if line:match("^%s*#define%s+HYPRLAND_HOOK%f[%W]") then
            -- Shader files are data, not authority to execute arbitrary compositor commands.
            if line:match("^%s*#define%s+HYPRLAND_HOOK%s+debug:damage_tracking%s+false%s*$") and not meta.hook then
                meta.hook = "debug:damage_tracking"
            else
                meta.error = "unsupported or duplicate HYPRLAND_HOOK (only debug:damage_tracking false is supported)"
            end
        end
        if declarations[line:match("^%s*([%a_]+)")] then
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
                name = sanitize_name(meta.name or base, base),
                icon = strip_shell_unsafe(meta.icon or DEFAULT_SHADER_ICON),
                description = meta.description or ("Shader: " .. base),
                hook = meta.hook,
                error = meta.error
            }
        end,

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

-- Serialize only values; never turn shader metadata into Lua source or IPC keywords.
local function config_code(shader, damage)
    local code = "hl.config({ decoration = { screen_shader = " .. string.format("%q", shader) .. " } })"
    if damage ~= nil then
        code = "hl.config({ debug = { damage_tracking = " .. tostring(damage) .. " } }); " .. code
    end
    return code
end

local function runtime_state()
    local damage, err = hyprctl.get_option("debug:damage_tracking")
    local shader, shader_err = hyprctl.get_option("decoration:screen_shader")
    local value = damage and damage.int
    local path = shader and (shader.str or shader.string)
    if not (value == 0 or value == 1 or value == 2) or type(path) ~= "string" then
        return nil, err or shader_err or "cannot read current shader settings"
    end
    return {shader = path == "[[EMPTY]]" and "" or path, damage = value}
end

local function apply_config(shader, damage)
    local reply, err = hyprctl.exec("eval", config_code(shader, damage))
    if reply ~= "ok" then return nil, err or reply or "Hyprland rejected shader settings" end
    return true
end

local function read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local value = f:read("*a")
    f:close()
    return value
end

local function read_menu()
    local value = JSON.decode(read_file(MENU_FILE) or "")
    if type(value) == "table" and value.instance == INSTANCE and type(value.token) == "string" and type(value.shader) == "string"
        and (value.damage == 0 or value.damage == 1 or value.damage == 2) then
        return value
    end
end

local function atomic_write(path, contents)
    local f, err = io.open(path .. ".tmp", "w")
    if not f then return nil, err end
    local ok, write_err = f:write(contents)
    local closed, close_err = f:close()
    if ok and closed then
        local renamed, rename_err = os.rename(path .. ".tmp", path)
        if renamed then return true end
        err = rename_err
    end
    os.remove(path .. ".tmp")
    return nil, err or write_err or close_err
end

-- Rofi callbacks run in separate processes. Serialize them with commit/cancel and
-- reject callbacks from a menu that has already closed.
local function locked(fn)
    ensure_dir(RUNTIME_DIR)
    local f, err = io.open(RUNTIME_DIR .. "/lock", "a")
    if not f then return nil, err end
    for _ = 1, 100 do
        if lfs.lock(f, "w") then
            local result = table.pack(pcall(fn))
            lfs.unlock(f)
            f:close()
            if not result[1] then return nil, result[2] end
            return table.unpack(result, 2, result.n)
        end
        socket.sleep(0.05)
    end
    f:close()
    return nil, "shader selector is busy"
end

local function discard(path)
    -- Only remove files created by this loader, never a user's shader.
    if path and path:sub(1, #CACHE_DIR + 1) == CACHE_DIR .. "/" and path:match("/lua_[%w_]+%.frag$") then
        os.remove(path)
    end
end

local function approved(item, saved)
    return saved and saved.key == item.key and saved.path == item.path and saved.hook == item.hook
        and type(saved.previous_damage) == "number"
end

local function prepare(item)
    if item.key ~= "disable" then
        local meta = read_frag_meta(item.path)
        if meta.error then return nil, meta.error end
        item.hook = meta.hook
    else
        item.hook = nil
    end
    return compile_shader(item)
end

-- A complete snapshot is written only after the compositor accepts the settings.
-- The old cache stays intact so an IPC/state-write failure can roll back.
function M.set(name, allow_damage_tracking_off)
    return locked(function()
        local found = M.find(name)
        if not found then return nil, "unknown shader '" .. tostring(name) .. "'" end
        local item = {}
        for k, v in pairs(found) do item[k] = v end
        local compiled, err = prepare(item)
        if not compiled then return nil, err end
        local before, read_err = runtime_state()
        if not before then discard(compiled); return nil, read_err end
        local saved = state.read(M.state_file)
        local damage = before.damage
        local menu = read_menu()
        local original_shader = menu and menu.shader or before.shader
        if item.hook then
            if damage ~= 0 and not allow_damage_tracking_off and not approved(item, saved) then
                discard(compiled)
                return nil, "This shader requires disabling damage tracking, greatly increasing GPU usage. Confirm in --select or use --allow-damage-tracking-off."
            end
            item.previous_damage = damage
            if damage == 0 and saved and saved.hook and saved.compiled == original_shader then
                item.previous_damage = saved.previous_damage or damage
            end
            damage = 0
        elseif damage == 0 and saved and saved.hook and saved.compiled == original_shader then
            damage = saved.previous_damage or damage
        end
        item.compiled = compiled
        local fields = {}
        for _, k in ipairs({"path", "key", "name", "description", "icon", "hook", "compiled", "previous_damage"}) do
            if item[k] ~= nil then fields[#fields + 1] = k .. " = " .. string.format("%q", item[k]) end
        end
        local content = "local item = {" .. table.concat(fields, ", ") .. "}\n"
            .. 'if rawget(_G, "hl") then\n'
            .. '  local f = item.compiled ~= "" and io.open(item.compiled, "r")\n'
            .. '  if f then f:close() end\n'
            .. '  if item.compiled == "" or f then\n    '
            .. config_code(compiled, item.hook and 0 or nil) .. '\n'
            .. '  else\n    ' .. config_code("", item.previous_damage) .. '\n  end\nend\nreturn item\n'
        local ok, apply_err = apply_config(compiled, damage)
        if ok then
            ensure_dir(M.state_file:match("^(.*)/"))
            ok, apply_err = atomic_write(M.state_file, content)
        end
        if not ok then
            local restored, restore_err = apply_config(before.shader, before.damage)
            if restored then discard(compiled) end
            return nil, tostring(apply_err) .. (restored and "" or "; rollback failed: " .. tostring(restore_err))
        end
        -- lua_state is authoritative; retain the shell compatibility mirror.
        local mirrored, mirror_err = pcall(state.staterc_set, "HYPR_SHADER", item.key)
        if not mirrored then io.stderr:write("Warning: could not update staterc: " .. tostring(mirror_err) .. "\n") end
        os.remove(MENU_FILE) -- A committed selection invalidates outstanding menu callbacks.
        if saved then discard(saved.compiled) end
        if menu and before.shader ~= original_shader then discard(before.shader) end
        return item
    end)
end

function M.reload()
    local item = M.current()
    if not item then return nil, "no current shader" end
    return M.set(item.key)
end

function M.apply(item)
    if not item then return nil, "no shader supplied" end
    return M.set(item.key)
end

function M.preview(name, token)
    -- Rofi can emit repeated or rapidly changing selections. Only apply the
    -- latest settled entry, and never recompile the preview already on screen.
    local request, err = locked(function()
        local menu = read_menu()
        if not token or not menu or menu.token ~= token then return false end
        local item = M.find(name)
        if not item then return nil, "unknown shader" end
        local before, read_err = runtime_state()
        if not before then return nil, read_err end
        local saved = state.read(M.state_file)
        if (menu.preview_key == item.key and menu.preview_path == before.shader)
            or (saved and saved.key == item.key and saved.compiled == before.shader) then
            -- Also invalidate a pending callback for a different entry.
            menu.request = (menu.request or 0) + 1
            menu.request_key = nil
            local ok, failure = atomic_write(MENU_FILE, JSON.encode(menu))
            if not ok then return nil, failure end
            return false
        end
        if menu.request_key == item.key then return false end
        menu.request = (menu.request or 0) + 1
        menu.request_key = item.key
        local ok, failure = atomic_write(MENU_FILE, JSON.encode(menu))
        if not ok then return nil, failure end
        return menu.request
    end)
    if request == nil then return nil, err end
    if request == false then return true end
    socket.sleep(0.15)
    return locked(function()
        local menu = read_menu()
        if not menu or menu.token ~= token or menu.request ~= request then return true end
        menu.request_key = nil
        local recorded, record_err = atomic_write(MENU_FILE, JSON.encode(menu))
        if not recorded then return nil, record_err end
        local item = M.find(name)
        if not item then return nil, "unknown shader" end
        local before, read_err = runtime_state()
        if not before then return nil, read_err end
        local meta = item.key ~= "disable" and read_frag_meta(item.path) or {}
        if meta.error then return nil, meta.error end
        -- Hovering must never grant consent or change the user's damage tracking.
        if meta.hook and before.damage ~= 0 then return true end
        local compiled, compile_err = prepare(item)
        if not compiled then return nil, compile_err end
        local ok, apply_err = apply_config(compiled)
        if not ok then
            local restored = apply_config(before.shader)
            if restored then discard(compiled) end
            return nil, apply_err
        end
        menu.preview_key, menu.preview_path = item.key, compiled
        local recorded_preview, preview_err = atomic_write(MENU_FILE, JSON.encode(menu))
        if not recorded_preview then
            local restored = apply_config(before.shader)
            if restored then discard(compiled) end
            return nil, preview_err
        end
        -- The saved shader must survive every preview, including Disable.
        local saved = state.read(M.state_file)
        if before.shader ~= menu.shader and (not saved or before.shader ~= saved.compiled) then
            discard(before.shader)
        end
        return true
    end)
end

local _src = debug.getinfo(1, "S").source
local _script_path = _src:match("^@(.*)$") or _src
local function shell_quote(value)
    return "'" .. value:gsub("'", "'\\''") .. "'"
end

function M.select(opts)
    opts = opts or {}
    local before, token, err
    local ok
    ok, err = locked(function()
        before, err = runtime_state()
        if not before then return nil, err end
        -- A replacement menu (or a recovered crashed menu) retains the original snapshot.
        local previous = read_menu()
        if previous then before = {shader = previous.shader, damage = previous.damage} end
        token = os.tmpname()
        os.remove(token)
        return atomic_write(MENU_FILE, JSON.encode({token = token, shader = before.shader, damage = before.damage, instance = INSTANCE}))
    end)
    if not ok then return nil, err end
    opts.current_item = opts.current_item or M.current()
    opts.placeholder = opts.placeholder or "Animated shaders may require confirmation for higher GPU usage"
    opts.prioritize = opts.prioritize or {"disable", "00-disable"}
    opts.on_menu_canceled = nil
    opts.on_selection_changed = "lua " .. shell_quote(_script_path) .. " --preview-token " .. shell_quote(token) .. ' --test "{entry}"'
    local rofi = require("luautils.selector.rofi")
    local selected_ok, selected = pcall(rofi.select, M.list, opts)
    local restored, restore_err = locked(function()
        local menu = read_menu()
        if not menu or menu.token ~= token then return nil, "shader menu was replaced by another selection" end
        local preview = runtime_state()
        local result, failure = apply_config(before.shader, before.damage)
        if result then
            os.remove(MENU_FILE)
            if preview and preview.shader ~= before.shader then discard(preview.shader) end
        end
        return result, failure
    end)
    if not restored then return nil, restore_err end
    if not selected_ok then return nil, selected end
    if not selected or selected == "" then return nil end
    local item = M.find(selected)
    if not item then return nil, "unknown shader" end
    local meta = item.key ~= "disable" and read_frag_meta(item.path) or {}
    if meta.error then return nil, meta.error end
    local allow = false
    if meta.hook and before.damage ~= 0 and not approved(item, state.read(M.state_file)) then
        local answer = rofi.select({
            {name = "Cancel", icon = ""},
            {name = "Enable (higher GPU usage)", icon = ""}
        }, {prompt = "Disable damage tracking?", placeholder = "This shader greatly increases GPU usage", current_name = "Cancel"})
        if answer ~= "Enable (higher GPU usage)" then return nil end
        allow = true
    end
    return M.set(item.key, allow)
end

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
    parser:option("--preview-token", "Internal shader menu token"):hidden(true)
    parser:flag("--allow-damage-tracking-off", "Allow greatly increased GPU usage for shaders requiring it")

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
        local item, err = M.set(cli.set, cli.allow_damage_tracking_off)
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
        local ok, err = M.preview(shader_name, cli.preview_token)
        if not ok then io.stderr:write("Error: " .. tostring(err) .. "\n"); os.exit(1) end
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

        local item, err = M.select()
        if err then io.stderr:write("Error: " .. tostring(err) .. "\n"); os.exit(1) end
        if item then print_item(item) end
    elseif cli.waybar then
        M.waybar()
    else
        print(parser:get_help())
    end
end

return M
