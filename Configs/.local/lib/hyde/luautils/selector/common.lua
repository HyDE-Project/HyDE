-- luautils/selector/common.lua
-- Generic selector factory + CLI runner for Hyde.
--
-- FACTORY — builds a full module from a config table:
--
--   local common = require("luautils.selector.common")
--   local M = common.new({
--       dirs                   = { "/path/a", "/path/b" },  -- dirs scanned for item files
--       state_name             = "mymodule",                -- state file base name
--       waybar_class           = "custom-mymodule",         -- class field in waybar JSON output
--       state_dir              = "/optional/override",      -- default: $XDG_STATE_HOME/hyde/lua_state
--       item_ext               = ".lua",                    -- extension stripped for item names
--       file_pattern           = "%.lua$",                  -- file pattern matched in directories
--       load_item              = function(path, base) return { ... } end,
--       static_items           = { ... },                    -- extra items to inject
--       static_items_position  = "prepend",                -- or "append"
--       on_set                 = function(item) end,
--       state_writer           = function(state_dir, state_file, item) end,
--   })
--   -- M exposes: .dirs .list .names .all .find(n) .current() .set(n) .waybar()
--
-- CLI RUNNER — delegates argparse to the returned module:
--
--   common.run(M, { name = "prog-name", description = "desc" })
--   -- handles --list / --set NAME / --current / --waybar

local argparse = require("argparse")
local JSON = require("dkjson")
local lfs = require("lfs")
local xdg = require("luautils.xdg")
local state = require("luautils.global.state")
local rofi = require("luautils.selector.rofi")

local M = {}

-- ── internal helpers ─────────────────────────────────────────────────────────

local function normalize(name)
    return (name or ""):match("^%s*(.-)%s*$"):lower()
end

local function dir_exists(path)
    return path and lfs.attributes(path, "mode") == "directory"
end

local function filter_dirs(dirs)
    local result = {}
    for _, d in ipairs(dirs or {}) do
        if dir_exists(d) then
            result[#result + 1] = d
        end
    end
    return result
end

local function read_item_file(path)
    local ok, result = pcall(dofile, path)
    return (ok and type(result) == "table") and result or {}
end

local function default_load_item(path, base)
    local item = read_item_file(path)
    item.path = path
    item.key = item.key or base
    item.name = item.name or base
    item.description = item.description or "No description available"
    item.icon = item.icon or ""
    return item
end

local function scan_dirs(dirs, opts)
    local by_key, ordered, names = {}, {}, {}
    local load_item = opts.load_item or default_load_item
    local item_ext = opts.item_ext or ".lua"
    local pattern = opts.file_pattern or item_ext:gsub("%.", "%%.") .. "$"

    local function add(item)
        item.key = item.key or item.name
        item.name = item.name or item.key or ""
        item.description = item.description or "No description available"
        item.icon = item.icon or ""

        local bk = normalize(item.key)
        local nk = normalize(item.name)
        if not by_key[bk] then
            table.insert(names, item.name)
            table.insert(ordered, item)
        end
        by_key[bk] = item
        by_key[nk] = item
    end

    local function add_static(item)
        item.key = item.key or item.name
        item.name = item.name or item.key
        item.description = item.description or "No description available"
        item.icon = item.icon or ""
        add(item)
    end

    if opts.static_items and opts.static_items_position == "prepend" then
        for _, item in ipairs(opts.static_items) do
            add_static(item)
        end
    end

    local files = {}
    for dir_index, dir in ipairs(dirs) do
        for file in lfs.dir(dir) do
            if file:match(pattern) then
                files[#files + 1] = {
                    file = file,
                    path = dir .. "/" .. file,
                    base = file:sub(1, #file - #item_ext),
                    dir_index = dir_index
                }
            end
        end
    end
    table.sort(
        files,
        function(a, b)
            if a.file ~= b.file then
                return a.file < b.file
            end
            return a.dir_index < b.dir_index
        end
    )
    for _, entry in ipairs(files) do
        local item = load_item(entry.path, entry.base)
        if item then
            item.path = item.path or entry.path
            add(item)
        end
    end

    if opts.static_items and opts.static_items_position ~= "prepend" then
        for _, item in ipairs(opts.static_items) do
            add_static(item)
        end
    end

    return by_key, ordered, names
end

-- ── factory ──────────────────────────────────────────────────────────────────

-- common.new(opts) → module table ready for use or require()
function M.new(opts)
    opts = opts or {}

    local sd = opts.state_dir or (xdg.state .. "/hyde/lua_state")
    local sf = sd .. "/" .. (opts.state_name or "selector") .. ".lua"
    local wbcl = opts.waybar_class or "custom-module"
    local dirs = filter_dirs(opts.dirs)

    local by_key, ordered, names = scan_dirs(dirs, opts)

    local function find(name)
        return by_key[normalize(name)]
    end

    local function write_state(state_dir, state_file, item)
        if opts.state_writer then
            return opts.state_writer(state_dir, state_file, item)
        end
        return state.write(state_dir, state_file, item)
    end

    local function set_item(name)
        local item = find(name)
        if not item then
            return nil, "unknown item '" .. tostring(name) .. "'"
        end
        write_state(sd, sf, item)
        if opts.staterc_key then
            state.staterc_set(opts.staterc_key, item.key)
        end
        if opts.on_set then
            opts.on_set(item)
        end
        return item
    end

    local function current()
        local cur = state.read(sf)
        if cur then
            return cur
        end
        -- fall back to staterc (set by shell/Python)
        if opts.staterc_key then
            local v = state.staterc_get(opts.staterc_key)
            if v then
                local item = find(v)
                if item then
                    state.write(sd, sf, item) -- sync lua_state so next read is fast
                    return item
                end
            end
        end
        return find("default") or ordered[1]
    end

    local function reload()
        local item = current()
        if not item then
            return nil, "no current item"
        end
        return set_item(item.key)
    end

    local function waybar()
        local cur = state.read(sf)
        if not cur then
            local fallback = find("default") or ordered[1]
            if fallback then
                state.write(sd, sf, fallback)
                cur = state.read(sf) or fallback
            else
                cur = {icon = "", name = "unknown", description = "No items found"}
            end
        end
        local icon = cur.icon or ""
        local name = cur.name or "unknown"
        print(
            JSON.encode(
                {
                    text = icon,
                    tooltip = "Mode: " .. icon .. " " .. name .. " \n" .. (cur.description or ""),
                    class = wbcl
                }
            )
        )
    end

    return {
        dirs = dirs,
        all = by_key,
        list = ordered,
        names = names,
        find = find,
        current = current,
        set = set_item,
        reload = reload,
        waybar = waybar,
        rofi_opts = opts.rofi_opts or {}
    }
end

-- ── CLI runner ───────────────────────────────────────────────────────────────

-- common.run(module, opts)
-- opts.name        program name shown in help
-- opts.description description shown in help
function M.run(module, opts)
    opts = opts or {}
    local parser = argparse(opts.name or "hyde-shell", opts.description or "HyDE Selector")
    parser:flag("--list", "List available items")
    parser:option("--set", "Set the given item"):argname("NAME")
    parser:flag("--select", "Select an item with rofi (runs rofi.*command)")
    parser:flag("--reload", "Reload the current item and re-apply its configuration")
    parser:flag("--current", "Show the current item")
    parser:flag("--waybar", "Get item info for Waybar")

    local cli = parser:parse(arg or {})

    local function print_item(item)
        print((item.icon or "") .. " " .. (item.name or "?") .. ": " .. (item.description or ""))
    end

    if cli.list then
        if not module.list or #module.list == 0 then
            print("No items found")
            return
        end
        for _, item in ipairs(module.list) do
            print((item.icon or "") .. " " .. (item.name or "?") .. " :: " .. (item.description or ""))
            if item.path then
                print("  " .. item.path)
            end
        end
    elseif cli.set then
        local item, err = module.set(cli.set)
        if not item then
            io.stderr:write("Error: " .. tostring(err) .. "\n")
            if module.names then
                io.stderr:write("Available: " .. table.concat(module.names, ", ") .. "\n")
            end
            os.exit(1)
        end
        print_item(item)
    elseif cli.current then
        local item = module.current and module.current()
        if not item then
            print("No current item")
        else
            print_item(item)
        end
    elseif cli.reload then
        local item, err = module.reload and module.reload()
        if not item then
            io.stderr:write("Error: " .. tostring(err) .. "\n")
            os.exit(1)
        end
        os.execute("hyprctl reload >/dev/null 2>&1")
        print_item(item)
    elseif cli.select then
        if not module.list or #module.list == 0 then
            print("No items found")
            return
        end

        local current_item = module.current and module.current()
        local rofi_opts = opts.rofi or {}
        -- merge module-level rofi_opts (e.g. prioritize) without overriding caller opts
        if module.rofi_opts then
            for k, v in pairs(module.rofi_opts) do
                if rofi_opts[k] == nil then
                    rofi_opts[k] = v
                end
            end
        end
        rofi_opts.current_item = current_item

        local selected = rofi.select(module.list, rofi_opts)
        if not selected or selected == "" then
            return
        end

        local item, err = module.set(selected)
        if not item then
            io.stderr:write("Error: " .. tostring(err) .. "\n")
            if module.names then
                io.stderr:write("Available: " .. table.concat(module.names, ", ") .. "\n")
            end
            os.exit(1)
        end
        print_item(item)
    elseif cli.waybar then
        module.waybar()
    else
        print(parser:get_help())
    end
end

return M
