local socket = require("socket.unix")
local json = require("dkjson")
local xdg = require("luautils.xdg")

local M = {}

local function trim(s)
    if not s then
        return nil
    end
    return s:match("^%s*(.-)%s*$")
end

local function get_runtime_dir()
    return os.getenv("XDG_RUNTIME_DIR") or "/tmp"
end

local function get_instance_signature()
    return os.getenv("HYPRLAND_INSTANCE_SIGNATURE") or ""
end

local function get_socket_path()
    local his = get_instance_signature()
    if his == "" then
        return nil
    end
    return get_runtime_dir() .. "/hypr/" .. his .. "/.socket.sock"
end

local function hyprctl_raw(cmd)
    if type(cmd) ~= "string" then
        return nil, "command must be a string"
    end

    local path = get_socket_path()
    if not path then
        return nil, "HYPRLAND_INSTANCE_SIGNATURE is not set"
    end

    local ok, s = pcall(socket)
    if not ok or not s then
        return nil, "failed to initialize unix socket"
    end

    local connected, err = s:connect(path)
    if not connected then
        s:close()
        return nil, err or "failed to connect"
    end

    local sent, send_err = s:send(cmd)
    if not sent then
        s:close()
        return nil, send_err or "failed to send command"
    end

    s:shutdown("send")
    local data, recv_err, partial = s:receive("*a")
    s:close()

    if not data then
        if recv_err and recv_err ~= "closed" then
            return nil, recv_err
        end
        data = partial or ""
    end

    return trim(data)
end

local function hyprctl_json(cmd)
    local raw, err = hyprctl_raw(cmd)
    if not raw then
        return nil, err
    end
    if raw == "" then
        return nil, "empty response"
    end
    local ok, decoded = pcall(json.decode, raw)
    if not ok then
        return nil, tostring(decoded)
    end
    return decoded
end

local function hyprctl(cmd, ...)
    local args = {...}
    local request = cmd
    for _, v in ipairs(args) do
        request = request .. " " .. tostring(v)
    end
    return hyprctl_raw(request)
end

local function hyprctl_json_cmd(cmd, ...)
    local args = {...}
    local request = cmd
    for _, v in ipairs(args) do
        request = request .. " " .. tostring(v)
    end
    return hyprctl_json(request)
end

local function wrap_json(fn_name, cmd)
    return function(...)
        return hyprctl_json_cmd(cmd, ...)
    end
end

M.get_runtime_dir = get_runtime_dir
M.get_instance_signature = get_instance_signature
M.get_socket_path = get_socket_path
M.raw = hyprctl_raw
M.request = hyprctl
M.exec = hyprctl
M.json = hyprctl_json
M.command = hyprctl
M.json_command = hyprctl_json_cmd
M.reload = function(config_only)
    if config_only then
        return hyprctl("reload", config_only)
    end
    return hyprctl("reload")
end
M.seterror = function(color, ...)
    if not color or color == "" then
        return nil, "color required"
    end
    local args = {...}
    local request = "seterror " .. tostring(color)
    for _, v in ipairs(args) do
        request = request .. " " .. tostring(v)
    end
    return hyprctl_raw(request)
end
M.get_option = function(option)
    if not option or option == "" then
        return nil, "option name required"
    end
    return hyprctl_json_cmd("j/getoption", option)
end

M.get_option_value = function(option)
    local result, err = M.get_option(option)
    if not result then
        return nil, err
    end
    if type(result) == "table" then
        if result.int ~= nil then
            return result.int
        end
        if result.string ~= nil then
            return result.string
        end
        if result.value ~= nil then
            return result.value
        end
        local first_key = next(result)
        return result[first_key]
    end
    return result
end

M.get_active_monitor = function()
    local monitors = M.monitors()
    if not monitors then return nil end
    for _, mon in ipairs(monitors) do
        if mon.focused == true then
            return mon
        end
    end
    return monitors[1] -- Fallback to first monitor
end

M.cursorpos = wrap_json("cursorpos", "j/cursorpos")
M.clients = wrap_json("clients", "j/clients")
M.active_window = wrap_json("active_window", "j/activewindow")
M.active_workspace = wrap_json("active_workspace", "j/activeworkspace")
M.workspaces = wrap_json("workspaces", "j/workspaces")
M.monitors = wrap_json("monitors", "j/monitors")
M.layers = wrap_json("layers", "j/layers")
M.status = wrap_json("status", "j/status")
M.config_errors = wrap_json("config_errors", "j/configerrors")
M.instances = wrap_json("instances", "j/instances")
M.system_info = wrap_json("system_info", "j/systeminfo")
M.dispatch = function(dispatcher, ...)
    if not dispatcher or dispatcher == "" then
        return nil, "dispatcher name required"
    end
    return hyprctl("dispatch", dispatcher, ...)
end

return M
