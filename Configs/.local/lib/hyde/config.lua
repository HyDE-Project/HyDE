#!/usr/bin/env lua

local root = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
package.path = package.path .. ";" .. root .. "?.lua;" .. root .. "?/init.lua;"
require("luautils.init")

local argparse = require("luautils.argparse")
local notify = require("luautils.global.notify")

local ok_lfs, lfs = pcall(require, "lfs")
if not ok_lfs then
    io.stderr:write("Missing dependency: luafilesystem (luarocks install luafilesystem)\n")
    os.exit(1)
end

local ok_toml, toml = pcall(require, "luautils.toml")
if not ok_toml then
    io.stderr:write("Missing dependency: luautils.toml\n")
    os.exit(1)
end

local has_inotify, inotify = pcall(require, "inotify")
local has_socket, socket = false, nil

-- Secure same-directory temporary filename generator.
math.randomseed((os.time() % 2 ^ 31) + tonumber(tostring({}):sub(-6), 36) % 1000)
local function make_temp_filename(filename)
    local token = tostring(os.time()) .. "-" .. tostring(math.random(1000000000, 9999999999))
    return string.format("%s.tmp.%s", filename, token)
end

-- Helpers
local function getenv_or(def, name)
    local v = os.getenv(name)
    if v and v ~= "" then
        return v
    end
    return def
end

local xdg_config_home = getenv_or(os.getenv("HOME") .. "/.config", "XDG_CONFIG_HOME")
local xdg_state_home = getenv_or(os.getenv("HOME") .. "/.local/state", "XDG_STATE_HOME")

local config = {
    ConfigFile = xdg_config_home .. "/hyde/config.toml",
    EnvFile = xdg_state_home .. "/hyde/config",
    HyprFile = xdg_state_home .. "/hyde/hyprland.conf",
    HyprEnvFile = xdg_state_home .. "/hyde/hypr.conf",
    NoDaemon = false,
    NoExport = false,
    Verbose = false,
    Debug = false
}

local noStartup = false
local hydeConfigNotificationID = 19
local isInitialStartup = true

-- CLI parsing
local function parse_args(argv)
    local parser = argparse("hyde-shell config", "Parse HyDE config.toml and generate HyDE/Hyprland output files.")
    parser:option("--input", "Path to the input TOML config file."):argname("PATH")
    parser:option("--env", "Path to the generated shell env file."):argname("PATH")
    parser:option("--hypr", "Path to the generated Hyprland config file."):argname("PATH")
    parser:option("--hypr-env", "Path to the generated Hyprland env file."):argname("PATH")
    parser:flag("--no-daemon", "Run once and exit without watching for changes.")
    parser:flag("--no-export", "Write shell variables without export prefixes.")
    parser:flag("--verbose", "Enable verbose logging.")
    parser:flag("--debug", "Enable debug logging.")
    parser:flag("--no-startup", "Only validate TOML on startup without writing output files.")

    local args = parser:parse(argv)
    config.ConfigFile = args.input or config.ConfigFile
    config.EnvFile = args.env or config.EnvFile
    config.HyprFile = args.hypr or config.HyprFile
    config.HyprEnvFile = args["hypr_env"] or config.HyprEnvFile
    config.NoDaemon = args.no_daemon or false
    config.NoExport = args.no_export or false
    config.Verbose = args.verbose or false
    config.Debug = args.debug or false
    noStartup = args.no_startup or false
end

parse_args(arg)

-- Logging
local function logInfo(fmt, ...)
    if config.Verbose or config.Debug then
        io.write(string.format(fmt .. "\n", ...))
    end
end
local function logDebug(fmt, ...)
    if config.Debug then
        io.write("DEBUG: " .. string.format(fmt .. "\n", ...))
    end
end
local function logError(fmt, ...)
    io.write("ERROR: " .. string.format(fmt .. "\n", ...))
end

logInfo("Using config file: %s", config.ConfigFile)
logInfo("Using env output file: %s", config.EnvFile)
logInfo("Using hypr output file: %s", config.HyprFile)
logInfo("Using hypr env output file: %s", config.HyprEnvFile)
logInfo("Export mode: %s", tostring(not config.NoExport))
logInfo("Daemon mode: %s", tostring(not config.NoDaemon))
logInfo("Debug mode: %s", tostring(config.Debug))

-- Ensure parent directories exist
local function ensure_parent_dirs(file)
    local dir = file:match("^(.*)/[^/]+$")
    if not dir then
        return
    end
    local cur = ""
    for part in dir:gmatch("[^/]+") do
        cur = cur .. "/" .. part
        local ok, err = lfs.mkdir(cur)
        if not ok and err and not string.find(err, "File exists") then
            logError("Failed to create directory %s: %s", cur, tostring(err))
            os.exit(1)
        end
    end
end

ensure_parent_dirs(config.EnvFile)
ensure_parent_dirs(config.HyprFile)
ensure_parent_dirs(config.HyprEnvFile)

local function sendSuccessNotification(title, message)
    if config.NoDaemon then
        return
    end
    notify.send(title, message, {urgency = "normal"})
end

-- TOML loader with error notification
local function load_toml_file(path)
    local attr = lfs.attributes(path)
    if not attr then
        return nil, "failed to access TOML file"
    end
    if attr.size == 0 then
        return nil, "TOML file is empty"
    end
    local ok, parsed = pcall(toml.parse, path)
    if not ok then
        logError("TOML parse error: %s", tostring(parsed))
        if not config.NoDaemon then
            local msg = tostring(parsed)
            if #msg > 250 then
                msg = msg:sub(1, 250) .. "..."
            end
            notify.send(
                "Hyde Config: TOML Syntax Error",
                msg,
                {urgency = "normal", replace_id = hydeConfigNotificationID}
            )
        end
        return nil, "failed to parse TOML"
    end
    return parsed, nil
end

-- Flattening helpers (mirror Go logic)
local function to_upper(s)
    return string.upper(s)
end

local function is_ignored_key(k, parentKey)
    local ignored = {
        ["$schema"] = true,
        ["$SCHEMA"] = true,
        ["hyprland"] = true,
        ["hyprland-ipc"] = true,
        ["hyprland-env"] = true,
        ["hyprland-start"] = true
    }
    if ignored[k] then
        return true
    end
    if parentKey ~= "" and parentKey:sub(1, 8) == "hyprland" then
        return true
    end
    return false
end

local function flatten_dict(data, parentKey, result, exportMode)
    for k, v in pairs(data) do
        if is_ignored_key(k, parentKey) then
            logDebug("Skipping ignored key: %s", k)
            goto continue
        end
        if k:sub(1, 1) == "$" then
            goto continue
        end

        local newKey
        if parentKey ~= "" then
            newKey = string.format("%s_%s", parentKey, to_upper(k))
        else
            newKey = to_upper(k)
        end

        local t = type(v)
        if t == "table" then
            local is_array = true
            local n = 0
            for kk, _ in pairs(v) do
                if type(kk) ~= "number" then
                    is_array = false
                    break
                end
                n = math.max(n, kk)
            end
            if is_array then
                local items = {}
                for i = 1, n do
                    table.insert(items, string.format('"%s"', tostring(v[i])))
                end
                local value = "(" .. table.concat(items, " ") .. ")"
                if exportMode then
                    table.insert(result, string.format("export %s=%s", newKey, value))
                else
                    table.insert(result, string.format("%s=%s", newKey, value))
                end
            else
                flatten_dict(v, newKey, result, exportMode)
            end
        elseif t == "boolean" then
            local value = tostring(v)
            if exportMode then
                table.insert(result, string.format("export %s=%s", newKey, value))
            else
                table.insert(result, string.format("%s=%s", newKey, value))
            end
        elseif t == "number" then
            if exportMode then
                table.insert(result, string.format("export %s=%s", newKey, tostring(v)))
            else
                table.insert(result, string.format("%s=%s", newKey, tostring(v)))
            end
        else
            if exportMode then
                table.insert(result, string.format('export %s="%s"', newKey, tostring(v)))
            else
                table.insert(result, string.format('%s="%s"', newKey, tostring(v)))
            end
        end

        ::continue::
    end
end

local function flatten_hypr_dict(data, parentKey, result)
    for k, v in pairs(data) do
        local isHyprlandSection = (k:sub(1, 8) == "hyprland") or (parentKey:sub(1, 8) == "hyprland")
        if isHyprlandSection then
            logDebug("Found hyprland key: %s", k)
            local newKey = k
            if newKey:sub(1, 9) == "hyprland_" then
                newKey = newKey:gsub("^hyprland_", "", 1)
            end

            if parentKey ~= "" and parentKey:sub(1, 8) ~= "hyprland" then
                newKey = string.format("%s_%s", parentKey, newKey)
            elseif parentKey:sub(1, 8) == "hyprland" then
                if #parentKey > 9 then
                    newKey = string.format("$%s.%s", parentKey:sub(10), to_upper(newKey))
                else
                    newKey = string.format("$%s", to_upper(newKey))
                end
            end

            local t = type(v)
            if t == "table" then
                local is_array = true
                local n = 0
                for kk, _ in pairs(v) do
                    if type(kk) ~= "number" then
                        is_array = false
                        break
                    end
                    n = math.max(n, kk)
                end
                if is_array then
                    local items = {}
                    for i = 1, n do
                        table.insert(items, tostring(v[i]))
                    end
                    local value = table.concat(items, ", ")
                    table.insert(result, string.format("%s=%s", newKey, value))
                else
                    flatten_hypr_dict(v, newKey, result)
                end
            elseif t == "boolean" then
                table.insert(result, string.format("%s=%s", newKey, tostring(v)))
            elseif t == "number" then
                table.insert(result, string.format("%s=%s", newKey, tostring(v)))
            else
                table.insert(result, string.format("%s=%s", newKey, tostring(v)))
            end
        else
            logDebug("Skipping key: %s", k)
        end
    end
end

local function flatten_to_hypr_vars(data, parentKey, result)
    local ignored = {
        ["$schema"] = true,
        ["$SCHEMA"] = true,
        ["hyprland"] = true,
        ["hyprland-ipc"] = true,
        ["hyprland-env"] = true,
        ["hyprland-start"] = true
    }
    for k, v in pairs(data) do
        if ignored[k] or k:sub(1, 8) == "hyprland" or parentKey:sub(1, 8) == "hyprland" then
            logDebug("Skipping key for hypr-env: %s", k)
            goto continue
        end
        if k:sub(1, 1) == "$" then
            goto continue
        end

        local newKey
        if parentKey ~= "" then
            newKey = string.format("%s_%s", parentKey, to_upper(k))
        else
            newKey = to_upper(k)
        end

        local t = type(v)
        if t == "table" then
            local is_array = true
            local n = 0
            for kk, _ in pairs(v) do
                if type(kk) ~= "number" then
                    is_array = false
                    break
                end
                n = math.max(n, kk)
            end
            if is_array then
                local items = {}
                for i = 1, n do
                    table.insert(items, tostring(v[i]))
                end
                table.insert(result, string.format("$%s = %s", newKey, table.concat(items, ", ")))
            else
                flatten_to_hypr_vars(v, newKey, result)
            end
        elseif t == "boolean" then
            table.insert(result, string.format("$%s = %s", newKey, tostring(v)))
        elseif t == "number" then
            table.insert(result, string.format("$%s = %s", newKey, tostring(v)))
        else
            table.insert(result, string.format("$%s = %s", newKey, tostring(v)))
        end

        ::continue::
    end
end

local function write_lines_to_file(filename, lines)
    if #lines == 0 then
        return nil, "no lines to write"
    end
    ensure_parent_dirs(filename)
    local tmp = make_temp_filename(filename)
    local f, err = io.open(tmp, "w")
    if not f then
        return nil, "failed to create temp file: " .. tostring(err)
    end
    for _, line in ipairs(lines) do
        f:write(line .. "\n")
    end
    f:close()
    local ok, renerr = os.rename(tmp, filename)
    if not ok then
        os.remove(tmp)
        return nil, "failed to replace file: " .. tostring(renerr)
    end
    return true, nil
end

local function run_hyprctl_reload()
    local ok, exit_type, exit_code = os.execute("hyprctl reload")
    if not ok then
        logError("hyprctl reload failed: %s %s", tostring(exit_type), tostring(exit_code))
        return false
    end
    logInfo("hyprctl reload executed successfully")
    return true
end

-- parse_config_files
local function parse_config_files(tomlFile, envFile, hyprFile, hyprEnvFile, exportMode)
    local attr = lfs.attributes(tomlFile)
    if not attr then
        logError("Failed to stat config file: %s", tostring(tomlFile))
        return false
    end
    if attr.size == 0 then
        logError("Config file is empty, skipping parse")
        return false
    end

    local tomlContent, err = load_toml_file(tomlFile)
    if not tomlContent then
        return false
    end

    local success1, success2, success3 = false, false, false

    -- env
    do
        local envVars = {}
        flatten_dict(tomlContent, "", envVars, exportMode)
        if #envVars == 0 then
            logError("No environment variables generated, skipping file write")
            success1 = false
        else
            if envFile ~= "" then
                local ok, werr = write_lines_to_file(envFile, envVars)
                if not ok then
                    logError("Failed to write environment variables: %s", tostring(werr))
                    success1 = false
                else
                    logInfo("Environment variables have been written to %s", envFile)
                    success1 = true
                end
            else
                for _, line in ipairs(envVars) do
                    logInfo("%s", line)
                end
                success1 = true
            end
        end
    end

    -- hypr
    do
        local hyprVars = {}
        flatten_hypr_dict(tomlContent, "", hyprVars)
        if #hyprVars == 0 then
            logError("No Hyprland variables generated, skipping file write")
            success2 = false
        else
            if hyprFile ~= "" then
                local ok, werr = write_lines_to_file(hyprFile, hyprVars)
                if not ok then
                    logError("Failed to write Hyprland variables: %s", tostring(werr))
                    success2 = false
                else
                    logInfo("Hyprland variables have been written to %s", hyprFile)
                    success2 = true
                end
            else
                logInfo("No hypr file specified.")
                for _, line in ipairs(hyprVars) do
                    logInfo("%s", line)
                end
                success2 = true
            end
        end
    end

    -- hypr-env
    do
        local hyprEnvVars = {}
        table.insert(hyprEnvVars, "# hyprlang noerror true")
        flatten_to_hypr_vars(tomlContent, "", hyprEnvVars)
        table.insert(hyprEnvVars, "# hyprlang noerror false")
        if #hyprEnvVars <= 2 then
            logError("No Hyprland env variables generated, skipping file write")
            success3 = false
        else
            if hyprEnvFile ~= "" then
                local ok, werr = write_lines_to_file(hyprEnvFile, hyprEnvVars)
                if not ok then
                    logError("Failed to write Hyprland env variables: %s", tostring(werr))
                    success3 = false
                else
                    logInfo("Hyprland env variables have been written to %s", hyprEnvFile)
                    success3 = true
                end
            else
                logInfo("No hypr-env file specified.")
                for _, line in ipairs(hyprEnvVars) do
                    logInfo("%s", line)
                end
                success3 = true
            end
        end
    end

    local success = success1 and success2 and success3
    if success and not config.NoDaemon and not isInitialStartup then
        sendSuccessNotification("Hyde Config", "Configuration reloaded successfully")
    end
    if isInitialStartup then
        isInitialStartup = false
    end
    return success
end

-- Watcher with debounce; prefer inotify if available
local last_mod = os.time()
local debounce_interval = 0.3

local function file_mod_time(path)
    local a = lfs.attributes(path)
    if not a then
        return nil
    end
    return a.modification
end

local function sleep(sec)
    if not socket then
        local ok, s = pcall(require, "socket")
        if ok then
            has_socket = true
            socket = s
        end
    end
    if has_socket and socket.sleep then
        socket.sleep(sec)
    else
        os.execute("sleep " .. tostring(sec))
    end
end

local function watch_file(tomlFile, envFile, hyprFile, hyprEnvFile, exportMode)
    local configDir = tomlFile:match("^(.*)/[^/]+$") or "."
    logInfo("Watching directory %s for changes to %s", configDir, tomlFile:match("[^/]+$"))

    last_mod = file_mod_time(tomlFile) or os.time()

    if has_inotify then
        logDebug("Using inotify watcher")
        local fd = inotify.init()
        fd:addwatch(configDir, inotify.IN_MODIFY + inotify.IN_CREATE)
        while true do
            local events, err, errno = fd:read()
            if not events then
                logError("inotify read failed: %s (%s)", tostring(err), tostring(errno))
                break
            end
            for _, ev in ipairs(events) do
                if ev.name == tomlFile:match("[^/]+$") then
                    local mod = file_mod_time(tomlFile)
                    if mod and (mod - last_mod) > debounce_interval then
                        last_mod = mod
                        logInfo("Config file changed (reprocessing)")
                        sleep(0.05)
                        if parse_config_files(tomlFile, envFile, hyprFile, hyprEnvFile, exportMode) then
                            run_hyprctl_reload()
                        end
                    else
                        logDebug("Skipping event, within debounce interval")
                    end
                end
            end
        end
    else
        logDebug("Inotify not available; using polling watcher")
        while true do
            local mod = file_mod_time(tomlFile)
            if mod and (mod - last_mod) > debounce_interval then
                last_mod = mod
                logInfo("Config file changed (reprocessing)")
                sleep(0.05)
                parse_config_files(tomlFile, envFile, hyprFile, hyprEnvFile, exportMode)
            end
            sleep(0.3)
        end
    end
end

-- Main flow
if noStartup then
    logInfo("--no-startup: Only parsing config and reporting errors, not populating configs on startup")
    local tomlContent, err = load_toml_file(config.ConfigFile)
    if not tomlContent then
        logError("Startup parse error: %s", tostring(err))
        os.exit(1)
    end
    local count = 0
    for _ in pairs(tomlContent) do
        count = count + 1
    end
    if count == 0 then
        logError("Startup TOML content is empty")
        os.exit(1)
    end
    logInfo("Config parsed successfully on startup (no configs written)")
end

if not config.NoDaemon then
    logInfo("Starting daemon mode, watching %s for changes", config.ConfigFile)
    if not noStartup then
        parse_config_files(config.ConfigFile, config.EnvFile, config.HyprFile, config.HyprEnvFile, not config.NoExport)
    end
    watch_file(config.ConfigFile, config.EnvFile, config.HyprFile, config.HyprEnvFile, not config.NoExport)
else
    if not noStartup then
        parse_config_files(config.ConfigFile, config.EnvFile, config.HyprFile, config.HyprEnvFile, not config.NoExport)
        logInfo("Running in one-off mode (no watching for changes)")
    end
end
