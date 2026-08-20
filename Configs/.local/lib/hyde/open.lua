#!/usr/bin/env lua

local root = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
package.path = package.path .. ";" .. root .. "?.lua;" .. root .. "?/init.lua;"
local ok_luautils, _ = pcall(require, "luautils.init")

local lgi = require "lgi"
local Gio = lgi.Gio
local GLib = lgi.GLib

local M = {}

M.dict = {
    ["file-manager"] = "inode/directory",
    ["text-editor"] = "text/plain",
    ["web-browser"] = "text/html",
    ["image-viewer"] = "image/webp",
    ["video-player"] = "video/mp4",
    ["pdf-viewer"] = "application/pdf",
    ["archive-manager"] = "application/x-compressed-tar",
    ["word-processor"] = "application/msword",
    ["font-manager"] = "font/ttf",
    ["code-editor"] = "text/x-csrc",
    ["log-viewer"] = "text/x-log"
}

local LOG_LEVELS = {error = 1, warn = 2, info = 3, debug = 4}
local current_log_level = LOG_LEVELS.info

local function set_log_level_by_name(name)
    if not name then
        return
    end
    name = name:lower()
    if LOG_LEVELS[name] then
        current_log_level = LOG_LEVELS[name]
    end
end

local function log(level, ...)
    local lvl = LOG_LEVELS[level] or LOG_LEVELS.info
    if lvl <= current_log_level then
        local prefix = ("[%s] "):format(level:upper())
        io.stderr:write(prefix, table.concat({...}, " "), "\n")
    end
end

local function format_error(err)
    if not err then
        return "<no error>"
    end
    if type(err) == "userdata" then
        if err.message then
            return tostring(err.message)
        end
        return tostring(err)
    end
    return tostring(err)
end

local function safe_call(fn, ...)
    local ok, res_or_err = pcall(fn, ...)
    if ok then
        return res_or_err, nil
    end
    return nil, format_error(res_or_err)
end

local function is_uri(s)
    return type(s) == "string" and s:match("^%a+://")
end

local function to_gio_file(path_or_uri)
    if is_uri(path_or_uri) then
        return Gio.File.new_for_uri(path_or_uri)
    else
        return Gio.File.new_for_path(path_or_uri)
    end
end

local function file_exists(path)
    if not path then
        return false
    end
    if is_uri(path) then
        local f, ferr = safe_call(Gio.File.new_for_uri, path)
        if not f then
            return false
        end
        local info, ierr =
            safe_call(
            function()
                return f:query_info("standard::type", Gio.FileQueryInfoFlags.NONE, nil)
            end
        )
        return info ~= nil
    end
    local fh = io.open(path, "r")
    if fh then
        fh:close()
        return true
    end
    return false
end

function M.resolve_mime(input)
    if not input or input == "" then
        return nil, "no input"
    end

    if M.dict[input] then
        log("debug", "Resolved via dict:", input, "->", M.dict[input])
        return M.dict[input]
    end

    if file_exists(input) then
        local file = to_gio_file(input)
        local info, ierr =
            safe_call(
            function()
                return file:query_info("standard::content-type", Gio.FileQueryInfoFlags.NONE, nil)
            end
        )
        if info then
            local ct = info:get_attribute_as_string("standard::content-type")
            if ct and ct ~= "" then
                log("debug", "Resolved MIME from file:", input, "->", ct)
                return ct
            end
        else
            log("debug", "query_info failed for", input, ":", ierr)
        end
        local guessed, uncertain = safe_call(Gio.content_type_guess, input, nil)
        if guessed and guessed ~= "" then
            log("debug", "Guessed MIME for", input, "->", guessed)
            return guessed
        end
    end

    if input:match(".+/.+") then
        log("debug", "Input appears to be a MIME type:", input)
        return input
    end

    local home = os.getenv("HOME") or ""
    local mimeapps = home .. "/.config/mimeapps.list"
    if file_exists(mimeapps) then
        for line in io.lines(mimeapps) do
            local k, v = line:match("^%s*([^=]+)=([^=]+)%s*$")
            if k and v and k:lower():find(input:lower(), 1, true) then
                log("debug", "Found mimeapps.list entry matching", input, "->", k)
                return k
            end
        end
    end

    return nil, "could not resolve mime for input: " .. tostring(input)
end

function M.appinfo_from_desktop(desktop_name)
    if not desktop_name or desktop_name == "" then
        return nil, "no desktop name"
    end

    local desktop_info = Gio.DesktopAppInfo
    if desktop_info then
        if desktop_name:match("/") then
            local info, ierr = safe_call(desktop_info.new_from_filename, desktop_name)
            if info then
                log("debug", "Created DesktopAppInfo from filename:", desktop_name)
                return info
            else
                log("debug", "DesktopAppInfo.new_from_filename failed:", ierr)
            end
        end

        local info, ierr = safe_call(desktop_info.new, desktop_name)
        if info then
            log("debug", "Created DesktopAppInfo by id:", desktop_name)
            return info
        end
    else
        log("debug", "Gio.DesktopAppInfo unavailable; falling back to AppInfo scanning")
    end

    local apps = Gio.AppInfo.get_all()
    local lower_target = desktop_name:lower()
    for _, app in ipairs(apps) do
        local id = app:get_id() or ""
        local name = app:get_name() or ""
        if id == desktop_name or name == desktop_name then
            log("debug", "Found exact match by id/name:", desktop_name)
            return app
        end
    end
    for _, app in ipairs(apps) do
        local id = (app:get_id() or ""):lower()
        local name = (app:get_name() or ""):lower()
        if id:find(lower_target, 1, true) or name:find(lower_target, 1, true) then
            log("debug", "Found fuzzy match for", desktop_name, "->", app:get_id() or app:get_name())
            return app
        end
    end

    return nil, "could not create AppInfo for " .. desktop_name
end

function M.find_default_app_for_mime(mime)
    if not mime then
        return nil, "no mime provided"
    end
    local app = Gio.AppInfo.get_default_for_type(mime, false)
    if app then
        log("debug", "Default app for", mime, "is", app:get_id() or app:get_name())
        return app
    end
    return nil, "no default app for mime: " .. mime
end

function M.set_default_app_for_mime(appinfo, mime, dry_run)
    if not appinfo or not mime then
        return nil, "missing args"
    end
    if dry_run then
        log("info", "Dry-run: would set", appinfo:get_id() or appinfo:get_name(), "as default for", mime)
        return true
    end
    local ok, err =
        safe_call(
        function()
            appinfo:set_as_default_for_type(mime)
        end
    )
    if err then
        return nil, "failed to set default: " .. tostring(err)
    end
    log("info", "Set default app", appinfo:get_id() or appinfo:get_name(), "for", mime)
    return true
end

function M.launch_app_for_files(appinfo, paths, std_only, dry_run)
    if not appinfo then
        return nil, "no appinfo"
    end
    paths = paths or {}
    local gio_files = {}
    for _, p in ipairs(paths) do
        table.insert(gio_files, to_gio_file(p))
    end
    if std_only then
        local id = appinfo:get_id() or appinfo:get_name() or "<unknown>"
        print(id)
        return true
    end
    if dry_run then
        log("info", "Dry-run: would launch", appinfo:get_id() or appinfo:get_name(), "with", table.concat(paths, ", "))
        return true
    end
    local ok, err =
        safe_call(
        function()
            appinfo:launch(gio_files, nil)
        end
    )
    if err then
        return nil, "failed to launch: " .. tostring(err)
    end
    log("info", "Launched", appinfo:get_id() or appinfo:get_name())
    return true
end

function M.run_fallback(cmd, dry_run)
    if not cmd or cmd == "" then
        return nil, "no fallback command"
    end
    if dry_run then
        log("info", "Dry-run: would run fallback command:", cmd)
        return true
    end
    local res = os.execute(cmd)
    return res == 0 or res == true
end

local function build_option_context_with_detection()
    local holders = {
        with = {value = nil},
        set_default = {value = false},
        std = {value = false},
        mime_search = {value = nil},
        fallback = {value = nil},
        help = {value = false},
        verbose = {value = 0},
        log_level = {value = nil},
        dry_run = {value = false},
        set_only = {value = false}
    }

    local function try_new_option_context(summary)
        if not GLib.OptionContext then
            return nil
        end
        local ctx = nil
        local ok =
            pcall(
            function()
                if type(GLib.OptionContext.new) == "function" then
                    ctx = GLib.OptionContext.new(summary)
                else
                    ctx = GLib.OptionContext(summary)
                end
            end
        )
        return ok and ctx or nil
    end

    local function try_new_option_entry()
        if not GLib.OptionEntry then
            return nil
        end
        local entry = nil
        local ok =
            pcall(
            function()
                if type(GLib.OptionEntry.new) == "function" then
                    entry = GLib.OptionEntry.new()
                else
                    entry = GLib.OptionEntry()
                end
            end
        )
        return ok and entry or nil
    end

    local ctx = try_new_option_context("open [files|mime|keyword] [OPTIONS]")
    if not ctx then
        return nil, holders, false
    end
    ctx:set_summary("Open files, MIME types, or keywords with desktop applications using GIO.")
    ctx:set_description(
        [[
hyde-shell: open files, MIME types, or keywords with desktop applications.

Examples:
  hyde-shell open example.pdf
  hyde-shell open text-editor
  hyde-shell open example.pdf --with evince.desktop --set-default
]]
    )

    local can_option_entry = false
    if try_new_option_entry() then
        can_option_entry = true
    end

    if not can_option_entry then
        return ctx, holders, false
    end

    local function new_entry(tbl)
        local e = try_new_option_entry()
        if not e then
            return nil
        end
        if tbl.long_name then
            e.long_name = tbl.long_name
        end
        if tbl.short_name then
            e.short_name = tbl.short_name
        end
        if tbl.arg then
            e.arg = tbl.arg
        end
        if tbl.arg_data then
            e.arg_data = tbl.arg_data
        end
        if tbl.description then
            e.description = tbl.description
        end
        return e
    end

    local entries = {
        new_entry {
            long_name = "with",
            arg = GLib.OptionArg.STRING,
            arg_data = holders.with,
            description = "Use this .desktop app instead of default"
        },
        new_entry {
            long_name = "set-default",
            arg = GLib.OptionArg.NONE,
            arg_data = holders.set_default,
            description = "Set the chosen app as default for the mime"
        },
        new_entry {
            long_name = "set-only",
            arg = GLib.OptionArg.NONE,
            arg_data = holders.set_only,
            description = "Set default but do not launch the app"
        },
        new_entry {
            long_name = "std",
            arg = GLib.OptionArg.NONE,
            arg_data = holders.std,
            description = "Only print the desktop id/name (do not launch)"
        },
        new_entry {
            long_name = "mime",
            arg = GLib.OptionArg.STRING,
            arg_data = holders.mime_search,
            description = "Search mimeapps.list and /usr/share/mime/types for pattern"
        },
        new_entry {
            long_name = "fall",
            arg = GLib.OptionArg.STRING,
            arg_data = holders.fallback,
            description = "Fallback shell command to run if no app found"
        },
        new_entry {
            long_name = "verbose",
            short_name = 0,
            arg = GLib.OptionArg.NONE,
            arg_data = holders.verbose,
            description = "Increase verbosity (can be repeated)"
        },
        new_entry {
            long_name = "log-level",
            arg = GLib.OptionArg.STRING,
            arg_data = holders.log_level,
            description = "Set log level: error,warn,info,debug"
        },
        new_entry {
            long_name = "dry-run",
            arg = GLib.OptionArg.NONE,
            arg_data = holders.dry_run,
            description = "Do not launch or set defaults; only print actions"
        },
        new_entry {long_name = "help", arg = GLib.OptionArg.NONE, arg_data = holders.help, description = "Show help"}
    }

    ctx:add_main_entries(entries, "hyde-shell")
    return ctx, holders, true
end

local function manual_parse(argv)
    local opts = {
        cmd = nil,
        inputs = {},
        with = nil,
        set_default = false,
        set_only = false,
        std = false,
        mime_search = nil,
        fallback = nil,
        verbose = 0,
        log_level = nil,
        dry_run = false,
        help = false
    }

    local i = 1
    while i <= #argv do
        local a = argv[i]
        if a == "open" and not opts.cmd then
            opts.cmd = "open"
            i = i + 1
        elseif a == "--with" then
            opts.with = argv[i + 1]
            i = i + 2
        elseif a == "--set-default" then
            opts.set_default = true
            i = i + 1
        elseif a == "--set-only" then
            opts.set_only = true
            i = i + 1
        elseif a == "--std" then
            opts.std = true
            i = i + 1
        elseif a == "--mime" then
            opts.mime_search = argv[i + 1]
            i = i + 2
        elseif a == "--fall" then
            opts.fallback = argv[i + 1]
            i = i + 2
        elseif a == "--verbose" then
            opts.verbose = opts.verbose + 1
            i = i + 1
        elseif a == "--log-level" then
            opts.log_level = argv[i + 1]
            i = i + 2
        elseif a == "--dry-run" then
            opts.dry_run = true
            i = i + 1
        elseif a == "--help" or a == "-h" then
            opts.help = true
            i = i + 1
        else
            table.insert(opts.inputs, a)
            i = i + 1
        end
    end

    return opts
end

local function print_usage(prog)
    prog = prog or arg[0] or "hyde-shell"
    io.write(("Usage: %s open <file|mime|keyword> [options]\n"):format(prog))
    io.write("Use --help for detailed options.\n")
end

function M.cli_main(argv)
    argv = argv or arg

    local ctx, holders, have_option_entries = build_option_context_with_detection()

    local parsed = nil
    if have_option_entries then
        io.stderr:write("debug: using GLib option entries\n")
        local ok, parse_err =
            pcall(
            function()
                ctx:parse(argv)
            end
        )
        if not ok then
            io.stderr:write("Error parsing options: " .. tostring(parse_err) .. "\n")
            return 2
        end
        parsed = {
            cmd = nil,
            inputs = ctx:get_remaining_args() or {},
            with = holders.with.value,
            set_default = holders.set_default.value,
            set_only = holders.set_only.value,
            std = holders.std.value,
            mime_search = holders.mime_search.value,
            fallback = holders.fallback.value,
            verbose = holders.verbose.value,
            log_level = holders.log_level.value,
            dry_run = holders.dry_run.value,
            help = holders.help.value
        }
        if #parsed.inputs > 0 then
            parsed.cmd = parsed.inputs[1]
            local real_inputs = {}
            for i = 2, #parsed.inputs do
                table.insert(real_inputs, parsed.inputs[i])
            end
            parsed.inputs = real_inputs
        end

        if not parsed.cmd and #parsed.inputs > 0 then
            parsed.cmd = "open"
        end
    else
        log("debug", "GLib.OptionEntry not usable; using manual parser")
        local m = manual_parse(argv)
        parsed = {
            cmd = m.cmd,
            inputs = m.inputs,
            with = m.with,
            set_default = m.set_default,
            set_only = m.set_only,
            std = m.std,
            mime_search = m.mime_search,
            fallback = m.fallback,
            verbose = m.verbose,
            log_level = m.log_level,
            dry_run = m.dry_run,
            help = m.help
        }

        if not parsed.cmd and #parsed.inputs > 0 then
            parsed.cmd = "open"
        end
    end

    if parsed.log_level then
        set_log_level_by_name(parsed.log_level)
    end
    if parsed.verbose and parsed.verbose > 0 then
        current_log_level = LOG_LEVELS.debug
    end

    if parsed.help then
        if have_option_entries then
            print(ctx:get_help())
        else
            print_usage(argv[0])
            io.write("\nOptions:\n")
            io.write(
                "  --with <app.desktop>\n  --set-default\n  --set-only\n  --std\n  --mime <pattern>\n  --fall <command>\n  --verbose\n  --log-level <error|warn|info|debug>\n  --dry-run\n"
            )
        end
        return 0
    end

    if parsed.mime_search then
        local pattern = parsed.mime_search
        local home = os.getenv("HOME") or ""
        local mimeapps = home .. "/.config/mimeapps.list"
        if file_exists(mimeapps) then
            for line in io.lines(mimeapps) do
                if line:lower():find(pattern:lower(), 1, true) then
                    print(line)
                end
            end
        end
        if file_exists("/usr/share/mime/types") then
            for line in io.lines("/usr/share/mime/types") do
                if line:lower():find(pattern:lower(), 1, true) then
                    print(line)
                end
            end
        end
        return 0
    end

    if not parsed.cmd then
        print_usage(argv[0])
        return 1
    end

    if parsed.cmd ~= "open" then
        io.stderr:write("Unknown command: " .. tostring(parsed.cmd) .. "\n")
        print_usage(argv[0])
        return 1
    end

    if #parsed.inputs == 0 then
        io.stderr:write("Error: no input provided\n")
        print_usage(argv[0])
        return 1
    end

    local dry_run = parsed.dry_run
    local set_only = parsed.set_only
    local fallback_cmd = parsed.fallback
    local chosen_appinfo = nil
    local chosen_mime = nil

    if parsed.with then
        local appinfo, aerr = M.appinfo_from_desktop(parsed.with)
        if not appinfo then
            io.stderr:write("Error resolving --with app: " .. tostring(aerr) .. "\n")
            if fallback_cmd then
                M.run_fallback(fallback_cmd, dry_run)
            end
            return 3
        end
        chosen_appinfo = appinfo
    end

    local file_group = {}
    local non_file_inputs = {}
    for _, inp in ipairs(parsed.inputs) do
        if file_exists(inp) or is_uri(inp) then
            table.insert(file_group, inp)
        else
            table.insert(non_file_inputs, inp)
        end
    end

    if #file_group > 0 then
        local mime, merr = M.resolve_mime(file_group[1])
        if not mime then
            io.stderr:write("Error resolving mime for file: " .. tostring(merr) .. "\n")
            if fallback_cmd then
                M.run_fallback(fallback_cmd, dry_run)
            end
        else
            chosen_mime = mime
            if not chosen_appinfo then
                local appinfo, aerr = M.find_default_app_for_mime(mime)
                if not appinfo then
                    io.stderr:write("No default app for mime " .. mime .. ": " .. tostring(aerr) .. "\n")
                    if fallback_cmd then
                        M.run_fallback(fallback_cmd, dry_run)
                    end
                else
                    chosen_appinfo = appinfo
                end
            end

            if chosen_appinfo then
                if parsed.set_default then
                    local ok, serr = M.set_default_app_for_mime(chosen_appinfo, mime, dry_run)
                    if not ok then
                        io.stderr:write("Warning: could not set default: " .. tostring(serr) .. "\n")
                    end
                end

                if set_only then
                    log("info", "--set-only specified; skipping launch")
                else
                    local ok, lerr = M.launch_app_for_files(chosen_appinfo, file_group, parsed.std, dry_run)
                    if not ok then
                        io.stderr:write("Error launching app for files: " .. tostring(lerr) .. "\n")
                        if fallback_cmd then
                            M.run_fallback(fallback_cmd, dry_run)
                        end
                    end
                end
            end
        end
    end

    for _, inp in ipairs(non_file_inputs) do
        local mime, merr = M.resolve_mime(inp)
        if not mime then
            io.stderr:write("Error resolving mime for input '" .. tostring(inp) .. "': " .. tostring(merr) .. "\n")
            if fallback_cmd then
                M.run_fallback(fallback_cmd, dry_run)
            end
        else
            local appinfo = chosen_appinfo
            if not appinfo then
                local a, aerr = M.find_default_app_for_mime(mime)
                if not a then
                    io.stderr:write("No default app for mime " .. mime .. ": " .. tostring(aerr) .. "\n")
                    if fallback_cmd then
                        M.run_fallback(fallback_cmd, dry_run)
                    end
                    goto continue_nonfile
                end
                appinfo = a
            end

            if parsed.set_default then
                local ok, serr = M.set_default_app_for_mime(appinfo, mime, dry_run)
                if not ok then
                    io.stderr:write("Warning: could not set default: " .. tostring(serr) .. "\n")
                end
            end

            if set_only then
                log("info", "--set-only specified; skipping launch for input", inp)
            else
                local ok, lerr = M.launch_app_for_files(appinfo, {}, parsed.std, dry_run)
                if not ok then
                    io.stderr:write(
                        "Error launching app for input '" .. tostring(inp) .. "': " .. tostring(lerr) .. "\n"
                    )
                    if fallback_cmd then
                        M.run_fallback(fallback_cmd, dry_run)
                    end
                end
            end

            ::continue_nonfile::
        end
    end

    return 0
end

local arg_count = #arg
local vararg_count = select("#", ...)
if arg_count == vararg_count and (vararg_count == 0 or select(1, ...) == arg[1]) then
    os.exit(M.cli_main(arg))
end

return M
