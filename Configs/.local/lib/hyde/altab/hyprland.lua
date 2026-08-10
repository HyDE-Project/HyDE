local socket = require("socket.unix")
local json = require("luautils.json")

--[[
Hypr backend adapter for hyde-shell altab.

This module implements the backend interface expected by altab.lua.
Other compositor backends should expose the same API surface and data shape.

Exported functions:
  build_clients_once(DEBUG)
      returns ids, id_to_info, addr_to_id, stableId_to_id, current_id
      ids: array of focusHistoryID values
      id_to_info: map focusHistoryID -> { address, stableId, title, class, workspace }
      addr_to_id: map address -> focusHistoryID (optional)
      stableId_to_id: map stableId -> focusHistoryID
      current_id: currently focused focusHistoryID or nil

  focus_by_id(id, DEBUG)
      Focuses the client identified by the compositor-specific index (Hypr focusHistoryID).
      The adapter should resolve the actual compositor target internally using address or stableId.
      Returns true on success, false otherwise.

  focus_by_stableId(stableId, DEBUG)
      Focuses the client by Wayland stableId. This is the preferred Wayland-level identifier.

  focus_addr(addr, DEBUG)
      Optional fallback focus by address if the compositor supports it.

The adapter may also provide hyprctl_json(cmd, DEBUG) for backend queries.
]]
local xdg_runtime = os.getenv("XDG_RUNTIME_DIR") or "/tmp"
local his = os.getenv("HYPRLAND_INSTANCE_SIGNATURE") or ""
local socket_path = xdg_runtime .. "/hypr/" .. his .. "/.socket.sock"

local hypr = {}

local function log(msg, DEBUG)
    if DEBUG then
        io.stderr:write("[hypr-altab] " .. msg .. "\n")
    end
end

local function is_available()
    return his ~= ""
end

local function hyprctl_raw(cmd, DEBUG)
    if not is_available() then
        log("HYPRLAND_INSTANCE_SIGNATURE not set", DEBUG)
        return ""
    end

    local ok, s = pcall(socket)
    if not ok or not s then
        log("socket init failed", DEBUG)
        return ""
    end
    local connected, err = s:connect(socket_path)
    if not connected then
        log("socket connect failed: " .. tostring(err), DEBUG)
        s:close()
        return ""
    end
    local sent, send_err = s:send(cmd)
    if not sent then
        log("socket send failed: " .. tostring(send_err), DEBUG)
        s:close()
        return ""
    end
    s:shutdown("send")
    local data, recv_err, partial = s:receive("*a")
    s:close()
    return data or partial or ""
end

-- hyprctl_json(cmd, DEBUG)
-- Perform a raw backend query and decode JSON output.
-- Returns nil on failure or a decoded Lua object.
function hypr.hyprctl_json(cmd, DEBUG)
    local raw = hyprctl_raw(cmd, DEBUG)
    if raw == "" then
        return nil
    end
    local obj, _, err = json.decode(raw)
    if not obj and err then
        log("json decode failed: " .. tostring(err), DEBUG)
    end
    return obj
end

-- build_clients_once(DEBUG)
-- Query the backend for current clients and return the normalized index map.
-- Returns: ids, id_to_info, addr_to_id, stableId_to_id, current_id
-- where id_to_info maps focusHistoryID -> { address, stableId, title, class, workspace }
function hypr.build_clients_once(DEBUG)
    local clients_raw = hypr.hyprctl_json("j/clients", DEBUG)
    if type(clients_raw) ~= "table" then
        return {}, {}, {}, {}, -1
    end

    local active_window = hypr.hyprctl_json("j/activewindow", DEBUG)
    local current_id = nil
    if type(active_window) == "table" and type(active_window.focusHistoryID) == "number" then
        current_id = active_window.focusHistoryID
    end

    local ids = {}
    local id_to_info = {}
    local addr_to_id = {}
    local stableId_to_id = {}

    for _, c in ipairs(clients_raw) do
        if c.mapped and (c.hidden == false or (c.grouped and #c.grouped > 0)) and type(c.focusHistoryID) == "number" and
            type(c.stableId) == "string" and c.stableId ~= "" then
            ids[#ids + 1] = c.focusHistoryID
            id_to_info[c.focusHistoryID] = {
                address = c.address or "",
                stableId = c.stableId,
                title = c.title or "(untitled)",
                class = c.class or "unknown",
                workspace = (c.workspace and c.workspace.name) or "?"
            }
            if c.address and c.address ~= "" then
                addr_to_id[c.address] = c.focusHistoryID
            end
            stableId_to_id[c.stableId] = c.focusHistoryID
        end
        ::continue::
    end

    table.sort(ids)
    return ids, id_to_info, addr_to_id, stableId_to_id, current_id
end

-- find_client_by_stableId(stableId, DEBUG)
-- Returns client info for a given Wayland stableId.
-- This is useful when saved state contains stableId but the numeric index may have changed.
function hypr.find_client_by_stableId(stableId, DEBUG)
    if type(stableId) ~= "string" or stableId == "" then
        return nil
    end

    local clients_raw = hypr.hyprctl_json("j/clients", DEBUG)
    if type(clients_raw) ~= "table" then
        return nil
    end

    for _, c in ipairs(clients_raw) do
        if c.mapped and (c.hidden == false or (c.grouped and #c.grouped > 0)) and c.stableId == stableId then
            return {
                focusHistoryID = c.focusHistoryID,
                address = c.address or "",
                stableId = c.stableId,
                title = c.title or "(untitled)",
                class = c.class or "unknown",
                workspace = (c.workspace and c.workspace.name) or "?"
            }
        end
    end
    return nil
end

-- find_client_by_id(id, DEBUG)
-- Returns client info for a given backend-specific index/id.
-- In Hyprland this is focusHistoryID. Other compositors should map their index
-- to the same return shape when adapting this module.
function hypr.find_client_by_id(id, DEBUG)
    if type(id) ~= "number" then
        return nil
    end

    local clients_raw = hypr.hyprctl_json("j/clients", DEBUG)
    if type(clients_raw) ~= "table" then
        return nil
    end

    for _, c in ipairs(clients_raw) do
        if
            c.mapped and (c.hidden == false or (c.grouped and #c.grouped > 0)) and type(c.focusHistoryID) == "number" and
                c.focusHistoryID == id
         then
            return {
                focusHistoryID = c.focusHistoryID,
                address = c.address or "",
                stableId = c.stableId or "",
                title = c.title or "(untitled)",
                class = c.class or "unknown",
                workspace = (c.workspace and c.workspace.name) or "?"
            }
        end
    end
    return nil
end

function hypr.focus_addr(addr, DEBUG)
    if addr and addr ~= "" then
        hyprctl_raw('dispatch hl.dsp.focus({ window = "address:' .. addr .. '" })', DEBUG)
        hyprctl_raw('dispatch hl.dsp.window.alter_zorder({ mode = "top", window = "address:' .. addr .. '" })', DEBUG)
        return true
    end
    return false
end

function hypr.focus_by_stableId(stableId, DEBUG)
    if type(stableId) ~= "string" or stableId == "" then
        return false
    end
    local client = hypr.find_client_by_stableId(stableId, DEBUG)
    if not client or not client.address or client.address == "" then
        return false
    end
    return hypr.focus_addr(client.address, DEBUG)
end

-- focus_by_id(id, DEBUG)
-- Focus the client matching the backend-specific index.
-- Hyprland prefers address-based targeting for window focus.
function hypr.focus_by_id(id, DEBUG)
    local client = hypr.find_client_by_id(id, DEBUG)
    if not client then
        return false
    end
    if client.address and client.address ~= "" then
        return hypr.focus_addr(client.address, DEBUG)
    end
    return false
end

function hypr.is_available()
    return is_available()
end

return hypr
