---@diagnostic disable: undefined-field
_G.hyde = _G.hyde or {}
hyde.handle = hyde.handle or {}

--- Normalizes monitor data, accounting for rotation (transforms) and scaling.
-- @param mon table: The raw monitor object from hl.get_active_monitor().
-- @return table|nil: A normalized monitor object with logical dimensions.
hyde.get_logical_monitor = function()
    local mon = assert(hl.get_active_monitor(), "No active monitor found")
    local scale = mon.scale or 1
    local transform = mon.transform or 0
    local w, h = mon.width, mon.height

    -- Swap dimensions for portrait/flipped-portrait transforms (1, 3, 5, 7)
    if transform == 1 or transform == 3 or transform == 5 or transform == 7 then
        w, h = h, w
    end

    local res = mon.reserved or {}

    local cfg_m = hyde.config.monitor and hyde.config.monitor.edge_margin or {0}
    local u, r, d, l = 0, 0, 0, 0

    if #cfg_m == 1 then
        u, r, d, l = cfg_m[1], cfg_m[1], cfg_m[1], cfg_m[1]
    elseif #cfg_m == 2 then
        u, d = cfg_m[1], cfg_m[1]
        l, r = cfg_m[2], cfg_m[2]
    elseif #cfg_m == 3 then
        u, l, r, d = cfg_m[1], cfg_m[2], cfg_m[2], cfg_m[3]
    elseif #cfg_m >= 4 then
        u, r, d, l = cfg_m[1], cfg_m[2], cfg_m[3], cfg_m[4]
    end

    return {
        x = mon.x or 0,
        y = mon.y or 0,
        w = w,
        h = h,
        inv_scale = 1 / scale,
        -- 2. Combined reserved space + user margins
        -- Multiplies the float directly with the dimension
        res = {
            top = (res.top or 0) + (u * h),
            bottom = (res.bottom or 0) + (d * h),
            left = (res.left or 0) + (l * w),
            right = (res.right or 0) + (r * w)
        }
    }
end

local function in_table(list, title)
    for _, v in ipairs(list) do
        if v == title then
            return true
        end
    end
    return false
end

--- Sets the maximum boundary for floating windows based on the usable monitor area.
-- @param win table: The window object provided by the Hyprland event.
hyde.handle.float_size_bounds = function(win)
    if not win or not win.floating then
        return
    end
    local cfg = hyde.config.window and hyde.config.window.float_size_bounds
    if not cfg or not cfg.enabled then
        return
    end
    local no_bounds = hyde.config.window.float.no_bounds or {}
    for _, field in ipairs({"initial_title", "title", "class", "initial_class"}) do
        if in_table(no_bounds[field] or {}, win[field]) then
            return
        end
    end

    local l_mon = hyde.get_logical_monitor()
    if not l_mon then
        return
    end

    -- Calculate usable area
    local usable_w = l_mon.w - (l_mon.res.left + l_mon.res.right)
    local usable_h = l_mon.h - (l_mon.res.top + l_mon.res.bottom)

    -- SANITY GUARD: Ensure we always have at least 100px usable space
    -- This prevents the "Invalid size" crash if margins are too large
    usable_w = math.max(100, usable_w)
    usable_h = math.max(100, usable_h)

    local max_w = math.floor((usable_w * (cfg.scale or 1)) * l_mon.inv_scale)
    local max_h = math.floor((usable_h * (cfg.scale or 1)) * l_mon.inv_scale)

    -- Resize if the window exceeds the safe bounds
    if win.size.x > max_w or win.size.y > max_h then
        local new_w = math.max(1, math.min(win.size.x, max_w))
        local new_h = math.max(1, math.min(win.size.y, max_h))

        hl.dispatch(
            hl.dsp.window.resize(
                {
                    window = win,
                    x = new_w,
                    y = new_h,
                    exact = true
                }
            )
        )

        if cfg.force_center then
            local cx = l_mon.x + (l_mon.res.left * l_mon.inv_scale) + (max_w / 2) - (new_w / 2)
            local cy = l_mon.y + (l_mon.res.top * l_mon.inv_scale) + (max_h / 2) - (new_h / 2)
            hl.dispatch(hl.dsp.window.move({window = win, x = cx, y = cy, exact = true}))
        end
    end
end

--- Moves a newly opened floating window to the cursor with CSS-style percentage margins.
-- Always centers the floating window on the cursor.
-- @param win table: The window object from Hyprland.
hyde.handle.float_follow_cursor = function(win)
    if not win or not win.floating then
        return
    end
    local cfg = hyde.config.window and hyde.config.window.float_follow_cursor
    if not cfg or not cfg.enabled then
        return
    end

    local l_mon = hyde.get_logical_monitor()
    if not l_mon then
        return
    end

    local cursor = hl.get_cursor_pos()
    if not cursor then
        return
    end

    local min_x = l_mon.x + (l_mon.res.left * l_mon.inv_scale)
    local max_x = l_mon.x + (l_mon.w - l_mon.res.right) * l_mon.inv_scale - win.size.x
    local min_y = l_mon.y + (l_mon.res.top * l_mon.inv_scale)
    local max_y = l_mon.y + (l_mon.h - l_mon.res.bottom) * l_mon.inv_scale - win.size.y

    local tx = cursor.x - (win.size.x / 2)
    local ty = cursor.y - (win.size.y / 2)

    tx = math.max(min_x, math.min(tx, max_x))
    ty = math.max(min_y, math.min(ty, max_y))

    hl.dispatch(hl.dsp.window.move({window = win, x = math.floor(tx), y = math.floor(ty), exact = true}))
end

--- Places a floating window in an opposite quadrant around the cursor.
-- Uses padding and monitor usable area to avoid reserved edges.
-- @param win table: The Hyprland window object.
-- @param opts table|nil: Optional settings, e.g. { padding = 20 }.
hyde.handle.follow_cursor_quadrant = function(win, opts)
    if not win or not win.floating then
        return
    end

    local l_mon = hyde.get_logical_monitor()
    if not l_mon then
        return
    end

    local cursor = hl.get_cursor_pos()
    if not cursor then
        return
    end

    local padding = (opts and tonumber(opts.padding)) or 24
    local min_x = l_mon.x + (l_mon.res.left * l_mon.inv_scale)
    local max_x = l_mon.x + (l_mon.w - l_mon.res.right) * l_mon.inv_scale - win.size.x
    local min_y = l_mon.y + (l_mon.res.top * l_mon.inv_scale)
    local max_y = l_mon.y + (l_mon.h - l_mon.res.bottom) * l_mon.inv_scale - win.size.y

    local usable_x = min_x
    local usable_y = min_y
    local usable_w = max_x - min_x + win.size.x
    local usable_h = max_y - min_y + win.size.y
    local center_x = usable_x + (usable_w / 2)
    local center_y = usable_y + (usable_h / 2)

    local on_right = cursor.x >= center_x
    local on_bottom = cursor.y >= center_y

    local tx = on_right and (cursor.x - win.size.x - padding) or (cursor.x + padding)
    local ty = on_bottom and (cursor.y - win.size.y - padding) or (cursor.y + padding)

    tx = math.max(min_x, math.min(tx, max_x))
    ty = math.max(min_y, math.min(ty, max_y))

    hl.dispatch(hl.dsp.window.move({window = win, x = math.floor(tx), y = math.floor(ty), exact = true}))
end
