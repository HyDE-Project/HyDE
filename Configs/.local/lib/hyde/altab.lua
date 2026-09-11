#!/usr/bin/env lua
local root = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
package.path = package.path .. ";" .. root .. "?.lua;" .. root .. "?/init.lua;"
require("luautils.init")

--[[
altab.lua
Entry point and state management for Hyprland Alt-Tab integration.

This script is compositor-agnostic at the frontend level. It only saves and
loads state in the form of:
    { id = <focusHistoryID>, stableId = <stableId>, ts = <timestamp> }

Compositor-specific lookup and focus logic must live in the backend adapter
module loaded via require("altab.hyprland").
]]
local json = require("luautils.json")
local argparse = require("luautils.argparse")
local logger = require("luautils.global.log")

local parser = argparse("hyde-shell altab", "Window Alt-Tab Switcher (index-based, optimized)")
parser:flag("--next", "Select next window index (save only)")
parser:flag("--prev", "Select previous window index (save only)")
parser:flag("--apply", "Apply saved window index (focus and clear state)")
parser:flag("--no-notify", "Disable notifications")
parser:flag("--no-capture", "Disable screenshot capture")
parser:flag("--debug", "Enable debug logging")
parser:flag("--log", "Enable file logging to XDG_RUNTIME_DIR/hyde-altab/log.txt")
parser:flag("--clear", "Clear saved state")
local args = parser:parse()

local DEBUG = args["debug"] or false
local PREV = args["prev"] or false
local NEXT = args["next"] or false
local APPLY = args["apply"] or false
local LOG = args["log"] or false
local function shell_escape(s)
    return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

local append_log_file

if DEBUG then
    logger.level = "debug"
    logger.debug("[hyde-altab] debug mode enabled")
end

local action_count = (NEXT and 1 or 0) + (PREV and 1 or 0) + (APPLY and 1 or 0) + (args["clear"] and 1 or 0)
if action_count == 0 then
    io.stderr:write(parser:get_help() .. "\n")
    os.exit(0)
end
if action_count > 1 then
    parser:error("only one of --next, --prev, --apply, or --clear may be used")
end

local env_notify = os.getenv("ALTAB_NOTIFY")
local DEFAULT_NOTIFY = (env_notify == nil) or env_notify == "1" or env_notify == "true"
local NO_NOTIFY = args["no_notify"] or args["no-notify"]
local NOTIFY = DEFAULT_NOTIFY and not NO_NOTIFY

local env_capture = os.getenv("ALTAB_CAPTURE")
local DEFAULT_CAPTURE = (env_capture == nil) or env_capture == "1" or env_capture == "true"
local NO_CAPTURE = args["no_capture"] or args["no-capture"]
local CAPTURE = DEFAULT_CAPTURE and not NO_CAPTURE

local xdg_runtime = os.getenv("XDG_RUNTIME_DIR") or "/tmp"
local state_dir = xdg_runtime .. "/hyde-altab"
local state_file = state_dir .. "/state"
local preview_dir = state_dir .. "/previews"
local log_file_path = state_dir .. "/log.txt"

local api_mod = nil
local function load_api_module()
    if api_mod ~= nil then
        return api_mod
    end
    local ok, mod = pcall(require, "altab.hyprland")
    if ok and type(mod) == "table" then
        api_mod = mod
    else
        api_mod = false
    end
    return api_mod
end

append_log_file = function(level, msg)
    if not LOG then
        return
    end
    os.execute("mkdir -p " .. shell_escape(state_dir))
    local f = io.open(log_file_path, "a")
    if not f then
        return
    end
    local entry = string.format("%s [%s] %s\n", os.date("%Y-%m-%d %H:%M:%S"), level, tostring(msg))
    f:write(entry)
    f:close()
end

if DEBUG and LOG then
    append_log_file("DEBUG", "[hyde-altab] debug mode enabled")
end

local function log(msg)
    local formatted = string.format("[hyde-altab] %s", tostring(msg))
    logger.info("%s", formatted)
    append_log_file("INFO", formatted)
end

local function debug(msg)
    local formatted = string.format("[hyde-altab] %s", tostring(msg))
    logger.debug("%s", formatted)
    append_log_file("DEBUG", formatted)
end

local function module_required()
    local mod = load_api_module()
    if not mod then
        log("could not load altab.{compositor} module")
        return nil
    end
    return mod
end

local function file_exists(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

-- Quoting alone isn't escaping: a cmd containing a single quote still closes
-- this early and reaches the shell (#1901's path.lua had the same class of
-- bug via HOME; only hardcoded callers exist here today, but the next one
-- might not be).
local function shell_quote(arg)
    arg = tostring(arg)
    arg = arg:gsub("'", "'\\''")
    return "'" .. arg .. "'"
end

local function which(cmd)
    local h = io.popen("command -v " .. shell_quote(cmd) .. " 2>/dev/null")
    local r = h:read("*a")
    h:close()
    return r and r:match("%S")
end

local function shell_escape(s)
    return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

local function preview_path(stableId, addr)
    local safe = tostring(stableId ~= nil and stableId ~= "" and stableId or addr):gsub("0x", ""):gsub(":", "")
    return preview_dir .. "/" .. safe .. ".png"
end

local function build_clients_once()
    local mod = module_required()
    if not mod then
        return {}, {}, {}, {}, -1
    end
    if type(mod.build_clients_once) ~= "function" then
        log("API module missing build_clients_once")
        return {}, {}, {}, {}, -1
    end
    return mod.build_clients_once(DEBUG)
end

local function write_state(tbl)
    os.execute("mkdir -p " .. shell_escape(state_dir))
    local tmp = state_file .. ".tmp"
    local f = io.open(tmp, "w")
    if not f then
        return
    end
    f:write(json.encode(tbl))
    f:close()
    os.rename(tmp, state_file)
end

local function write_state_entry(id, stableId)
    write_state({id = id, stableId = stableId or "", ts = os.time()})
end

local function read_state()
    local f = io.open(state_file, "r")
    if not f then
        return nil
    end
    local content = f:read("*a")
    f:close()
    local ok, obj = pcall(json.decode, content)
    if not ok then
        log("state decode failed: " .. tostring(obj))
        return nil
    end
    return obj
end

local function state_matches_client(saved, id_to_info, stableId_to_id)
    if type(saved) ~= "table" then
        return nil
    end
    if type(saved.stableId) == "string" and saved.stableId ~= "" and stableId_to_id then
        local stable_id = stableId_to_id[saved.stableId]
        if stable_id then
            return stable_id
        end
    end
    if type(saved.id) == "number" and id_to_info[saved.id] then
        return saved.id
    end
    return nil
end

local function index_of(tbl, val)
    for i, v in ipairs(tbl) do
        if v == val then
            return i
        end
    end
    return nil
end

local function capture_toplevel(id, id_to_info)
    if not CAPTURE then
        return
    end
    local info = id_to_info and id_to_info[id]
    if not info or info.stableId == "" then
        return
    end
    os.execute("mkdir -p " .. shell_escape(preview_dir))
    local path = preview_path(info.stableId, info.address)
    local cmd = "grim -T " .. shell_escape(info.stableId) .. " " .. shell_escape(path) .. " >/dev/null 2>&1 &"
    os.execute(cmd)
end

local function notify_for_id_with_info(id, id_to_info)
    if not NOTIFY or not which("notify-send") then
        return
    end
    local info = id_to_info and id_to_info[id]
    if not info then
        return
    end
    local title = info.title or "(untitled)"
    local klass = info.class or "unknown"
    local ws = info.workspace or "?"
    local body = title .. "\n" .. klass .. "  •  " .. ws
    local icon =
        file_exists(preview_path(info.stableId, info.address)) and preview_path(info.stableId, info.address) or nil
    local cmd = "notify-send " .. shell_escape(klass) .. " " .. shell_escape(body) .. " -t 2000 -r 6"
    if icon then
        cmd = cmd .. " -i " .. shell_escape(icon)
    end
    os.execute(cmd .. " &")
end

local function focus_window(id, info)
    if type(id) ~= "number" then
        return false
    end
    local mod = module_required()
    if not mod then
        return false
    end

    if mod.focus_by_id then
        return mod.focus_by_id(id, DEBUG)
    end

    if mod.focus_by_stableId and info and info.stableId and info.stableId ~= "" then
        return mod.focus_by_stableId(info.stableId, DEBUG)
    end

    if mod.focus_addr and info and info.address and info.address ~= "" then
        return mod.focus_addr(info.address, DEBUG)
    end

    return false
end

local function cleanup_orphan_previews_with_info(id_to_info)
    if not id_to_info then
        return
    end
    local valid_paths = {}
    for _, info in pairs(id_to_info) do
        if info then
            valid_paths[preview_path(info.stableId, info.address)] = true
        end
    end
    local find_cmd = "find " .. shell_escape(preview_dir) .. " -maxdepth 1 -type f -name '*.png' -print 2>/dev/null"
    local h = io.popen(find_cmd)
    if not h then
        return
    end
    for line in h:lines() do
        local path = line:match("^%s*(.-)%s*$")
        if path and path ~= "" and not valid_paths[path] then
            os.remove(path)
            log("removed orphan preview: " .. tostring(path))
        end
    end
    h:close()
end

local function remove_state()
    os.remove(state_file)
end

local function main()
    if args["clear"] then
        remove_state()
        return
    end

    local ids, id_to_info, _, stableId_to_id, current_id = build_clients_once()
    if #ids == 0 then
        log("no windows in history")
        return
    end

    if APPLY then
        local saved = read_state()
        log("apply: saved_state=" .. tostring(saved and json.encode(saved) or "nil"))
        if not saved then
            log("apply: no saved state")
            return
        end

        local focus_id = state_matches_client(saved, id_to_info, stableId_to_id)
        local info = focus_id and id_to_info[focus_id]
        if not info then
            log("apply: saved state is stale; clearing state")
            cleanup_orphan_previews_with_info(id_to_info)
            remove_state()
            return
        end

        focus_window(focus_id, info)

        if CAPTURE then
            capture_toplevel(focus_id, id_to_info)
        end

        write_state_entry(0, info.stableId)
        log("apply: preserved state with stableId=" .. tostring(info.stableId))

        cleanup_orphan_previews_with_info(id_to_info)
        remove_state()
        return
    end

    local saved = read_state()
    local start_id = current_id or ids[1]
    local valid_saved_id = nil
    if saved then
        valid_saved_id = state_matches_client(saved, id_to_info, stableId_to_id)
        if valid_saved_id then
            start_id = valid_saved_id
        else
            log("saved state invalid or stale; reset to current active focusHistoryID")
            remove_state()
            start_id = current_id or ids[1]
        end
    end

    if DEBUG then
        logger.debug(
            "altab: current_id=%s saved_id=%s saved_stableId=%s valid_saved_id=%s start_id=%s",
            tostring(current_id),
            tostring(saved and saved.id),
            tostring(saved and saved.stableId),
            tostring(valid_saved_id),
            tostring(start_id)
        )
    end

    local start_idx = index_of(ids, start_id) or 1
    local idx
    if NEXT then
        idx = (start_idx % #ids) + 1
    elseif PREV then
        idx = ((start_idx - 2) % #ids) + 1
    else
        idx = (start_idx % #ids) + 1
    end

    local target_id = ids[idx]
    local info = id_to_info[target_id]
    if not target_id or not info then
        log("no target client computed")
        return
    end

    write_state_entry(target_id, info.stableId)
    log("saved id=" .. tostring(target_id) .. " stableId=" .. tostring(info.stableId))

    if info and not file_exists(preview_path(info.stableId, info.address)) then
        capture_toplevel(target_id, id_to_info)
    end

    if NOTIFY then
        notify_for_id_with_info(target_id, id_to_info)
    end
end

main()
