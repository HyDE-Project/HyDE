local lib_dir = os.getenv("LIB_DIR") or "."
local v_require = dofile(lib_dir .. "/hyde/luautils/require.lua")

local socket = require("socket.unix")
local json = require("dkjson")
local argparse = require "argparse"

local parser = argparse("hyde-shell hypr.altab", "Hyprland Alt-Tab Switcher")
parser:flag("--prev", "Switch to previous window in history")
parser:flag("--notify", "Enable notifications (default)")
parser:flag("--no-notify", "Disable notifications")
parser:flag("--debug", "Enable debug logging")
parser:flag("--clear", "Clear saved state")
parser:flag("--apply", "Apply last selection")

local args = parser:parse()

local DEBUG = args["debug"] or false
local NOTIFY = args["notify"] or (not args["no-notify"])
local PREV = args["prev"] or false

local PREVIEW_NEXT = tonumber(os.getenv("HYPR_ALTAB_PREVIEW_NEXT")) or -1
local _capture_env = os.getenv("HYPR_ALTAB_CAPTURE")
local CAPTURE = (_capture_env == nil) or _capture_env == "1" or _capture_env == "true"

local xdg_runtime = os.getenv("XDG_RUNTIME_DIR") or "/tmp"
local his = os.getenv("HYPRLAND_INSTANCE_SIGNATURE") or ""
local socket_path = xdg_runtime .. "/hypr/" .. his .. "/.socket.sock"

local state_dir = xdg_runtime .. "/hypr-altab"
local state_file = state_dir .. "/state"
local preview_dir = state_dir .. "/previews"
local function log(msg)
    if DEBUG then
        io.stderr:write("[hypr-altab] " .. msg .. "\n")
    end
end
local function file_exists(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

local function which(cmd)
    local h = io.popen("command -v '" .. cmd .. "' 2>/dev/null")
    local r = h:read("*a")
    h:close()
    return r and r:match("%S")
end
local function shell_escape(s)
    return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end
local function preview_path(addr)
    local safe = addr:gsub("0x", ""):gsub(":", "")
    return preview_dir .. "/" .. safe .. ".png"
end

local hyprctl_json

local function capture_preview(addr)
    if not CAPTURE then
        return
    end
    if not addr or addr == "" then
        return
    end
    if not which("grim") then
        return
    end
    os.execute("mkdir -p '" .. preview_dir .. "'")
    local path = preview_path(addr)

    local clients = hyprctl_json("j/clients")
    local match
    if type(clients) == "table" then
        for _, c in ipairs(clients) do
            if c.address == addr then
                match = c
                break
            end
        end
    end

    if match and type(match.at) == "table" and type(match.size) == "table" then
        local x = tonumber(match.at[1])
        local y = tonumber(match.at[2])
        local w = tonumber(match.size[1])
        local h = tonumber(match.size[2])
        if x and y and w and h and w > 1 and h > 1 then
            local geom = string.format("%d,%d %dx%d", x, y, w, h)
            os.execute("grim -g " .. shell_escape(geom) .. " " .. shell_escape(path) .. " >/dev/null 2>&1 &")
        end
    end
end
local function hyprctl_raw(cmd)
    if his == "" then
        log("HYPRLAND_INSTANCE_SIGNATURE not set")
        return ""
    end
    local ok, s = pcall(socket)
    if not ok or not s then
        log("socket init failed")
        return ""
    end
    local connected, err = s:connect(socket_path)
    if not connected then
        log("socket connect failed: " .. tostring(err))
        s:close()
        return ""
    end
    local sent, send_err = s:send(cmd)
    if not sent then
        log("socket send failed: " .. tostring(send_err))
        s:close()
        return ""
    end
    s:shutdown("send")
    local data, recv_err, partial = s:receive("*a")
    s:close()
    if not data then
        if recv_err and recv_err ~= "closed" then
            log("socket receive failed: " .. tostring(recv_err))
        end
        data = partial or ""
    end
    return data
end

hyprctl_json = function(cmd)
    local raw = hyprctl_raw(cmd)
    if not raw or raw == "" then
        return nil
    end
    local obj, _, err = json.decode(raw)
    return obj
end

local function contains_addr(list, addr)
    if type(list) ~= "table" or not addr then
        return false
    end
    for _, v in ipairs(list) do
        if v == addr then
            return true
        end
    end
    return false
end

local function build_notify(addr)
    local clients = hyprctl_json("j/clients")
    if type(clients) ~= "table" then
        return nil, nil, nil
    end
    local match
    for _, c in ipairs(clients) do
        if c.address == addr then
            match = c
            break
        end
    end
    if not match then
        return nil, nil, nil
    end
    local title = match.title or "(untitled)"
    local klass = match.class or "unknown"
    local ws = (match.workspace and match.workspace.name) or "?"
    local body = title .. "\n" .. klass .. "  •  " .. ws
    local icon = preview_path(addr)
    if file_exists(icon) then
        return klass, body, icon
    else
        return klass, body, nil
    end
end
local function notify_preview_pair(current_addr, next_addrs)
    if not which("notify-send") then
        return
    end
    local title, body, icon = build_notify(current_addr)
    if title then
        local cmd = "notify-send " .. shell_escape(title) .. " " .. shell_escape(body) .. " -t 2000 -r 6"
        if icon then
            cmd = cmd .. " -i " .. shell_escape(icon)
        end
        os.execute(cmd .. " &")
    end
end

local function read_state()
    local f = io.open(state_file, "r")
    if not f then
        return {}
    end
    local content = f:read("*a")
    f:close()
    local obj, _, err = json.decode(content)
    return obj or {}
end

local function write_state(tbl)
    os.execute("mkdir -p " .. state_dir)
    local f = io.open(state_file, "w")
    if not f then
        return
    end
    f:write(json.encode(tbl))
    f:close()
end

local function focus_addr(addr)
    if addr and addr ~= "" then
        hyprctl_raw("dispatch focuswindow address:" .. addr)
    end
end

local function build_history()
    local clients = hyprctl_json("j/clients")
    if type(clients) ~= "table" then
        return {}
    end
    local filtered = {}
    for _, c in ipairs(clients) do
        if c.mapped and (c.hidden == false or (c.grouped and #c.grouped > 0)) and type(c.focusHistoryID) == "number" then
            table.insert(filtered, c)
        end
    end
    table.sort(filtered, function(a, b)
        return a.focusHistoryID < b.focusHistoryID
    end)
    local addrs = {}
    for _, c in ipairs(filtered) do
        if c.address then
            table.insert(addrs, c.address)
        end
    end
    return addrs
end

local function main()
    local args = {}
    for i = 1, #arg do
        local flag = arg[i]:match("^%-%-(.+)$") or arg[i]
        args[flag] = true
    end
    if args["clear"] then
        os.remove(state_file)
        return
    end
    if args["apply"] then
        local state = read_state()
        local addr = state.addr
        log("apply: target=" .. tostring(addr))
        if addr then
            if not state.applied then
                focus_addr(addr)
                if CAPTURE then
                    capture_preview(addr)
                end
            end
        end
        os.remove(state_file)
        return
    end

    local state = read_state()
    local current_history = build_history()
    if #current_history < 2 then
        log("not enough windows in focus history")
        return
    end

    local history = current_history
    local state_age_ok = type(state.ts) == "number" and (os.time() - state.ts) <= 2
    if type(state.list) == "table" and #state.list > 1 and state_age_ok then
        local all_present = true
        for _, addr in ipairs(state.list) do
            if not contains_addr(current_history, addr) then
                all_present = false
                break
            end
        end
        if all_present then
            history = state.list
        end
    end

    local idx = tonumber(state.idx or 0)
    if PREV then
        idx = idx - 1
        if idx <= 0 then
            idx = #history - 1
        end
    else
        idx = idx + 1
        if idx >= #history then
            idx = 1
        end
    end

    local target = history[idx + 1]
    if not target then
        log("target missing after idx calc, rebuilding")
        history = current_history
        idx = PREV and (#history - 1) or 1
        target = history[idx + 1]
    end
    if not target then
        log("unable to resolve target window")
        return
    end

    local next_targets = {}
    local preview_count = (PREVIEW_NEXT > 0) and PREVIEW_NEXT or math.max(1, #history - 1)
    if #history > 1 and preview_count > 0 then
        for step = 1, preview_count do
            local next_idx
            if PREV then
                next_idx = idx - step
                if next_idx <= 0 then
                    next_idx = #history - 1 - ((step - idx) % math.max(1, #history - 1))
                end
            else
                next_idx = idx + step
                if next_idx >= #history then
                    next_idx = 1 + ((next_idx - #history) % math.max(1, #history - 1))
                end
            end
            table.insert(next_targets, history[next_idx + 1])
        end
    end
    log("preview: idx=" .. idx .. " target=" .. tostring(target) .. " count=" .. #history)
    write_state {
        idx = idx,
        addr = target,
        list = history,
        ts = os.time(),
        applied = true
    }
    focus_addr(target)
    if CAPTURE then
        capture_preview(target)
    end
    if NOTIFY then
        notify_preview_pair(target, next_targets)
    end
end

main()
