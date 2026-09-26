-- luautils/selector/rofi.lua
-- Generic rofi dmenu selector for Hyde.
--
-- Usage:
--   local rofi = require("luautils.selector.rofi")
--   local selected_name = rofi.select(items, opts)

local hyprctl = require("luautils.hypr.hyprctl")
local pos = require("luautils.rofi.pos") -- Corrected Path
local xdg = require("luautils.xdg")

local M = {}

local function shell_quote(s)
    return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

local function get_hypr_borders()
    local rounding = tonumber(hyprctl.get_option_value("decoration:rounding")) or 0
    local border_size = tonumber(hyprctl.get_option_value("general:border_size")) or 0
    return {
        border_size = border_size,
        win_border = math.floor(rounding * 3 / 2),
        elem_border = rounding == 0 and 5 or rounding
    }
end

local function getenv(prefix, key, fallback)
    local val
    if prefix and prefix ~= "" then
        val = os.getenv(prefix .. "_" .. key)
    end
    return val or os.getenv("ROFI_" .. key) or fallback
end

local function normalize_priority(value)
    if not value then
        return nil
    end

    if type(value) == "string" then
        return {value}
    end

    if type(value) == "table" then
        return value
    end

    return nil
end

--- Reads the `window { width: ...em; height: ...em; }` fields straight out of
-- the resolved theme's .rasi file, so the overflow-clamp estimate below tracks
-- whatever theme is actually rendered instead of assuming the "clipboard"
-- dropdown size. Returns nil, nil if the theme file can't be found or parsed.
local function theme_window_em(theme)
    if not theme or theme == "" then
        return nil, nil
    end
    local path = (theme:find("[/.]rasi$") or theme:find("/")) and theme or
        (xdg.data .. "/hyde/rofi/themes/" .. theme .. ".rasi")
    local f = io.open(path, "r")
    if not f then
        return nil, nil
    end
    local content = f:read("*a")
    f:close()
    local block = content:match("window%s*{([^}]*)}")
    if not block then
        return nil, nil
    end
    return tonumber(block:match("width:%s*([%d.]+)em")), tonumber(block:match("height:%s*([%d.]+)em"))
end

local function item_matches_priority(item, priorities)
    local ikey = (item.key or ""):lower()
    local iname = (item.name or ""):lower()
    for _, value in ipairs(priorities) do
        if type(value) == "string" then
            local v = value:lower()
            if ikey == v or iname == v then
                return true
            end
        end
    end
    return false
end

function M.select(items, opts)
    opts = opts or {}
    local current_item = opts.current_item
    local prefix = opts.env_prefix
    local selection_changed_cmd = opts.on_selection_changed
    local menu_canceled_cmd = opts.on_menu_canceled

    if current_item then
        opts.current_name = opts.current_name or current_item.name
        opts.current_icon = opts.current_icon or current_item.icon
    end

    local priorities = normalize_priority(opts.prioritize or opts.hoist)
    if opts.hoist_default then
        priorities = priorities or {}
        priorities[#priorities + 1] = "default"
    end

    if priorities and #priorities > 0 then
        local rest, hoisted = {}, {}
        for _, item in ipairs(items) do
            if item_matches_priority(item, priorities) then
                hoisted[#hoisted + 1] = item
            else
                rest[#rest + 1] = item
            end
        end

        for i = #hoisted, 1, -1 do
            table.insert(rest, 1, hoisted[i])
        end
        items = rest
    end

    local hypr = opts.hypr or get_hypr_borders()
    local font = opts.font or getenv(prefix, "FONT", "JetBrainsMono Nerd Font")
    local scale = tonumber(opts.scale or getenv(prefix, "SCALE", "10")) or 10
    local theme = opts.theme or getenv(prefix, "STYLE", "clipboard")

    -- Window size isn't known until rofi renders it, so the overflow clamp in
    -- pos.lua is fed an em->px estimate (1em ~= scale pt ~= scale*4/3 px) read
    -- from the resolved theme's own width/height (falling back to the shared
    -- dropdown themes' 23em x 30em when the theme file is missing or doesn't
    -- set them). Callers can still override via min_width_em/min_height_em;
    -- this remains an approximation, not an exact measurement of the rendered
    -- window.
    local pos_override = ""
    if opts.follow_cursor ~= false then
        local px_per_em = scale * (4 / 3)
        local theme_width_em, theme_height_em = theme_window_em(theme)
        local rofi_pos =
            pos.get_rofi_pos(
            {
                min_width = (opts.min_width_em or theme_width_em or 23) * px_per_em,
                min_height = (opts.min_height_em or theme_height_em or 30) * px_per_em
            }
        )
        if rofi_pos and rofi_pos.str ~= "" then
            pos_override = string.format("-theme-str %s", shell_quote(rofi_pos.str))
        end
    end
    local prompt = opts.prompt or getenv(prefix, "PROMPT", "Select")
    local placeholder = opts.placeholder or getenv(prefix, "PLACEHOLDER", "Type to filter...")

    local font_override = string.format([[ * { font: "%s %d"; } ]], (font:gsub('"', '\\"')), scale)
    local r_override =
        string.format(
        "window{border:%spx;border-radius:%spx;} wallbox{border-radius:%spx;} element{border-radius:%spx;}",
        hypr.border_size,
        hypr.win_border,
        hypr.elem_border,
        hypr.elem_border
    )
    local placeholder_theme = string.format('entry { placeholder: "%s"; }', (placeholder:gsub('"', '\\"')))

    local lines = {}
    for _, item in ipairs(items) do
        lines[#lines + 1] = (item.icon or "") .. "\t" .. (item.name or "")
    end
    local input = #lines > 0 and table.concat(lines, "\n") or ""

    local current_select = ""
    if opts.current_name then
        current_select = (opts.current_icon or "") .. "\t" .. opts.current_name
    end

    -- Recalculate selected_row against the (possibly reordered) items list
    local selected_row
    if opts.current_row ~= nil then
        local cur_key = opts.current_name and opts.current_name:lower()
        for i, item in ipairs(items) do
            if cur_key and ((item.name or ""):lower() == cur_key or (item.key or ""):lower() == cur_key) then
                selected_row = i - 1
                break
            end
        end
        -- fall back to original row if no match found
        if selected_row == nil then
            selected_row = opts.current_row
        end
    end

    -- Build callback options
    local callback_opts = ""
    if selection_changed_cmd then
        callback_opts = callback_opts .. " -on-selection-changed " .. shell_quote(selection_changed_cmd)
    end
    if menu_canceled_cmd then
        callback_opts = callback_opts .. " -on-menu-canceled " .. shell_quote(menu_canceled_cmd)
    end

    local rofi_cmd =
        string.format(
        [[printf %s | rofi -dmenu -i %s \
            %s%s \
            -p %s \
            -theme-str %s \
            -theme-str %s \
            -theme-str %s \
            %s \
            %s \
            -theme %s
        ]],
        shell_quote(input),
        selected_row and string.format("-selected-row %s", tostring(selected_row)) or "",
        selected_row and "" or string.format("-select %s", shell_quote(current_select)),
        selected_row and "" or "",
        shell_quote(prompt),
        shell_quote(placeholder_theme),
        shell_quote(font_override),
        shell_quote(r_override),
        pos_override,
        callback_opts,
        shell_quote(theme)
    )

    local handle = io.popen(rofi_cmd)
    if not handle then return nil end

    local result = handle:read("*a")
    local ok, _, code = handle:close()
    if not ok and code ~= 0 then return nil end

    if result then
        result = result:match("^%s*(.-)%s*$")
        result = result:match("\t%s*(.+)$") or result
    end

    return (result and result ~= "") and result or nil
end

return M
