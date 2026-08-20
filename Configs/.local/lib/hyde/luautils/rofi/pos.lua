local hyprctl = require("luautils.hypr.hyprctl")

local M = {}

function M.get_rofi_pos()
    local cursor = hyprctl.cursorpos()
    local mon = hyprctl.get_active_monitor()

    if not cursor or not mon then
        return {x = 0, y = 0, str = ""}
    end

    local scale = mon.scale or 1
    local inv_scale = 1 / scale
    local w, h = mon.width, mon.height

    if (mon.transform or 0) % 2 ~= 0 then
        w, h = h, w
    end

    local rel_x = cursor.x - (mon.x or 0)
    local rel_y = cursor.y - (mon.y or 0)

    local cfg_m = (hyde and hyde.config and hyde.config.monitor and hyde.config.monitor.edge_margin) or {0}
    local u, r, d, l = 0, 0, 0, 0
    local n = #cfg_m
    if n == 1 then
        u, r, d, l = cfg_m[1], cfg_m[1], cfg_m[1], cfg_m[1]
    elseif n == 2 then
        u, d = cfg_m[1], cfg_m[1]
        r, l = cfg_m[2], cfg_m[2]
    elseif n >= 4 then
        u, r, d, l = cfg_m[1], cfg_m[2], cfg_m[3], cfg_m[4]
    end

    local res = mon.reserved or {0, 0, 0, 0}
    local safe_top = ((res[2] or res.top or 0) + (u * h)) * inv_scale
    local safe_bot = ((res[4] or res.bottom or 0) + (d * h)) * inv_scale
    local safe_lft = ((res[1] or res.left or 0) + (l * w)) * inv_scale
    local safe_rgt = ((res[3] or res.right or 0) + (r * w)) * inv_scale

    local l_w, l_h = w * inv_scale, h * inv_scale

    local x_dir = (rel_x >= (l_w / 2)) and "east" or "west"
    local y_dir = (rel_y >= (l_h / 2)) and "south" or "north"

    local x_off = (x_dir == "east") and -(l_w - rel_x - safe_rgt) or (rel_x - safe_lft)
    local y_off = (y_dir == "south") and -(l_h - rel_y - safe_bot) or (rel_y - safe_top)

    local pos_str =
        string.format(
        "window{location:%s %s;anchor:%s %s;x-offset:%dpx;y-offset:%dpx;}",
        x_dir,
        y_dir,
        x_dir,
        y_dir,
        math.floor(x_off),
        math.floor(y_off)
    )

    return {x = x_off, y = y_off, str = pos_str}
end

return M
