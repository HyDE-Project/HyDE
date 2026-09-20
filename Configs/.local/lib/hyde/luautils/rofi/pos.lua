local M = {}

-- Anchors the window at the cursor and grows it away from the nearest edge, then
-- pulls the anchor back so the window's far edge never crosses the opposite safe
-- boundary (e.g. a tall menu opened near the top no longer grows off the bottom).
-- required may be 0/nil when the caller doesn't know the window size.
local function resolve_axis(rel, dim, safe_start, safe_end, required)
    required = required or 0
    local at_end = rel >= (dim / 2)
    local dir_is_end, offset

    if at_end then
        local far_edge = rel
        local near_edge = far_edge - required
        if near_edge < safe_start then
            near_edge = safe_start
            far_edge = math.max(near_edge, safe_start + required)
        end
        dir_is_end = true
        offset = far_edge - (dim - safe_end)
    else
        local near_edge = rel
        local far_edge = near_edge + required
        if far_edge > dim - safe_end then
            far_edge = dim - safe_end
            near_edge = math.min(far_edge, dim - safe_end - required)
        end
        dir_is_end = false
        offset = near_edge - safe_start
    end

    return dir_is_end, offset
end

function M.get_rofi_pos(opts)
    opts = opts or {}
    local hyprctl = require("luautils.hypr.hyprctl")
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

    local x_is_east, x_off = resolve_axis(rel_x, l_w, safe_lft, safe_rgt, opts.min_width)
    local y_is_south, y_off = resolve_axis(rel_y, l_h, safe_top, safe_bot, opts.min_height)
    local x_dir = x_is_east and "east" or "west"
    local y_dir = y_is_south and "south" or "north"

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

local function self_test()
    local function eq(got, want, msg)
        assert(math.abs(got - want) < 1e-6, msg .. ": got " .. tostring(got) .. " want " .. tostring(want))
    end

    -- Window fits in the available space: behaves like the pre-clamp math.
    local is_end, off = resolve_axis(100, 1000, 0, 0, 200)
    assert(not is_end, "cursor in first half anchors at the start edge")
    eq(off, 100, "unclamped offset should equal the cursor position")

    -- Regression: cursor near the top, but the window is taller than the room
    -- left below it -> must pull back instead of growing off the far edge.
    is_end, off = resolve_axis(100, 1000, 0, 0, 950)
    assert(not is_end, "still start-anchored")
    eq(off, 50, "offset should shrink so the window's far edge stays on-screen")

    -- Same overflow, mirrored: cursor near the bottom/right.
    is_end, off = resolve_axis(900, 1000, 0, 0, 950)
    assert(is_end, "cursor in second half anchors at the end edge")
    eq(off, -50, "offset should shrink so the window's near edge stays on-screen")

    -- Window bigger than the whole safe area: best-effort, pinned to the start.
    is_end, off = resolve_axis(100, 1000, 0, 0, 1200)
    assert(not is_end)
    eq(off, -200, "oversized window is pinned at the start edge, ceiling case")

    print("pos.lua self-test OK")
end

local _src = debug.getinfo(1, "S").source
if arg and arg[0] and _src:sub(2):match("[^/]+$") == arg[0]:match("[^/]+$") then
    self_test()
end

return M
