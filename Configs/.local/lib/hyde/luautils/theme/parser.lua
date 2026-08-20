local xdg = require("luautils.xdg")

local function trim(value)
    if not value then
        return nil
    end
    return value:match("^%s*(.-)%s*$")
end

local function unquote(value)
    if not value then
        return nil
    end
    local s = trim(value)
    local quoted = s:match([[^"(.*)"$]]) or s:match([[^'(.*)'$]])
    return quoted or s
end

local function shell_quote(value)
    if not value then
        return "''"
    end
    return "'" .. value:gsub("'", "'\\''") .. "'"
end

local function file_exists(path)
    if not path then
        return false
    end
    local f = io.open(path, "r")
    if not f then
        return false
    end
    f:close()
    return true
end

local function run_command(cmd)
    local handle = io.popen(cmd)
    if not handle then
        return nil
    end
    local result = handle:read("*a")
    handle:close()
    return trim(result)
end

local function hyq_query(hyVar, hyType, path)
    local hyq_path = run_command("command -v hyq 2>/dev/null")
    if not hyq_path or hyq_path == "" then
        return nil
    end

    local query = "$" .. hyVar
    if hyType and hyType ~= "" then
        query = query .. "[" .. hyType .. "]"
    end
    local cmd =
        string.format("%s -s --query %s %s 2>/dev/null", shell_quote(hyq_path), shell_quote(query), shell_quote(path))
    local result = run_command(cmd)
    if result and result ~= "" then
        return result
    end

    cmd = string.format("%s --query %s %s 2>/dev/null", shell_quote(hyq_path), shell_quote(query), shell_quote(path))
    return run_command(cmd)
end

local function parse_theme_file(path, hyVar)
    if not file_exists(path) then
        return nil
    end

    local file = io.open(path, "r")
    if not file then
        return nil
    end

    local value
    for line in file:lines() do
        local matched = line:match("^%s*%$" .. hyVar .. "%s*=%s*(.*)$")
        if matched then
            value = unquote(matched)
            break
        end
    end
    file:close()
    return trim(value)
end

local gs_map = {
    GTK_THEME = "gtk-theme",
    ICON_THEME = "icon-theme",
    COLOR_SCHEME = "color-scheme",
    CURSOR_THEME = "cursor-theme",
    CURSOR_SIZE = "cursor-size",
    FONT = "font-name",
    DOCUMENT_FONT = "document-font-name",
    MONOSPACE_FONT = "monospace-font-name",
    FONT_SIZE = "font-size",
    DOCUMENT_FONT_SIZE = "document-font-size",
    MONOSPACE_FONT_SIZE = "monospace-font-size"
}

local function parse_gsettings_value(path, hyVar)
    if not file_exists(path) then
        return nil
    end

    local gsettings_key = gs_map[hyVar]
    if not gsettings_key then
        return nil
    end

    local file = io.open(path, "r")
    if not file then
        return nil
    end

    local last_value
    for line in file:lines() do
        local pattern =
            "^%s*exec%s*=%s*gsettings%s+set%s+org%.gnome%.desktop%.interface%s+" .. gsettings_key .. '%s+[\'"](.-)[\'"]'
        local matched = line:match(pattern)
        if matched then
            last_value = matched
        end
    end
    file:close()
    return trim(last_value)
end

local function parse_default_configs(hyVar)
    local default_paths = {
        xdg.data .. "/hyde/hyde.conf",
        xdg.data .. "/hyde/hyprland.conf",
        "/usr/local/share/hyde/hyde.conf",
        "/usr/local/share/hyde/hyprland.conf",
        "/usr/share/hyde/hyde.conf",
        "/usr/share/hyde/hyprland.conf"
    }

    for _, path in ipairs(default_paths) do
        if file_exists(path) then
            local file = io.open(path, "r")
            if file then
                for line in file:lines() do
                    local matched = line:match("^%s*%$default%." .. hyVar .. "%s*=%s*(.*)$")
                    if matched then
                        file:close()
                        return trim(unquote(matched))
                    end
                end
                file:close()
            end
        end
    end
    return nil
end

local function parse_hypr_conf(hyArg, path)
    if not hyArg or hyArg == "" then
        return nil
    end

    local hyVar, hyType = hyArg:match("^([^%[]+)%[([%w_]+)%]$")
    if not hyVar then
        hyVar = hyArg
    end
    hyVar = trim(hyVar)

    local theme_path = path
    if not theme_path or theme_path == "" then
        local theme_dir = os.getenv("HYDE_THEME_DIR")
        if theme_dir and theme_dir ~= "" then
            theme_path = theme_dir .. "/hypr.theme"
        end
    end

    local result = hyq_query(hyVar, hyType, theme_path)
    if result and result ~= "" then
        return result
    end

    local value = parse_theme_file(theme_path, hyVar)
    if value and value ~= "" and not value:match("^%$") then
        return value
    end

    local gs_val = parse_gsettings_value(theme_path, hyVar)
    if gs_val and gs_val ~= "" and not gs_val:match("^%$") then
        return gs_val
    end

    if hyVar == "CODE_THEME" then
        return "Wallbash"
    elseif hyVar == "SDDM_THEME" then
        return ""
    end

    return parse_default_configs(hyVar)
end

local M = {}
M.get_hyprConf = parse_hypr_conf
M.get = parse_hypr_conf
M.parse = parse_hypr_conf

return M
