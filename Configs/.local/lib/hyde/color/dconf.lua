#!/usr/bin/env lua

local root = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
package.path = package.path .. ";" .. root .. "../?.lua;" .. root .. "../?/init.lua;"
require("luautils.init")

local xdg = require("luautils.xdg")
local lgi = require("lgi")
local Gio = lgi.Gio

local function _s(v)
    if v == nil or v == "" then return nil end
    return tostring(v)
end

local function _f(font, size)
    local f = _s(font)
    if not f then return nil end
    local s = _s(size)
    if not s then return f end
    return f .. " " .. s
end

local lua_u = {}
local ok, ui = pcall(dofile, xdg.state .. "/hyde/lua_state/ui.lua")
if ok and ui then lua_u = ui.ui end

local function _r(key)
    return _s(lua_u[key])
        or _s(os.getenv("__" .. key:upper()))
        or _s(os.getenv(key:upper()))
end

local GTK_THEME         = _r("gtk_theme")         or "Wallbash-Gtk"
local ICON_THEME        = _r("icon_theme")
local COLOR_SCHEME      = _r("color_scheme")       or "prefer-dark"
local CURSOR_THEME      = _r("cursor_theme")
local CURSOR_SIZE       = tonumber(_r("cursor_size")) or 24
local FONT_NAME         = _f(_r("font"), _r("font_size"))
local DOC_FONT_NAME     = _f(_r("document_font"), _r("document_font_size"))
local MONO_FONT_NAME    = _f(_r("monospace_font"), _r("monospace_font_size"))
local FONT_ANTIALIASING = _r("font_antialiasing")  or "rgba"
local FONT_HINTING      = _r("font_hinting")       or "slight"
local BUTTON_LAYOUT     = _r("button_layout")      or ""
local TERMINAL          = _r("terminal")            or "kitty"

local iface = Gio.Settings.new("org.gnome.desktop.interface")
if GTK_THEME         then iface:set_string("gtk-theme",           GTK_THEME)         end
if ICON_THEME        then iface:set_string("icon-theme",          ICON_THEME)        end
if COLOR_SCHEME      then iface:set_string("color-scheme",        COLOR_SCHEME)      end
if CURSOR_THEME      then iface:set_string("cursor-theme",        CURSOR_THEME)      end
iface:set_int("cursor-size", CURSOR_SIZE)
if FONT_NAME         then iface:set_string("font-name",           FONT_NAME)         end
if DOC_FONT_NAME     then iface:set_string("document-font-name",  DOC_FONT_NAME)     end
if MONO_FONT_NAME    then iface:set_string("monospace-font-name", MONO_FONT_NAME)    end
if FONT_ANTIALIASING then iface:set_string("font-antialiasing",   FONT_ANTIALIASING) end
if FONT_HINTING      then iface:set_string("font-hinting",        FONT_HINTING)      end
Gio.Settings.sync()

local wm = Gio.Settings.new("org.gnome.desktop.wm.preferences")
if BUTTON_LAYOUT then wm:set_string("button-layout", BUTTON_LAYOUT) end
Gio.Settings.sync()

local ok_term, term = pcall(Gio.Settings.new, "org.gnome.desktop.default-applications.terminal")
if ok_term and term then
    local handle = io.popen("command -v " .. TERMINAL .. " 2>/dev/null")
    local bin = handle and handle:read("*l") or TERMINAL
    if handle then handle:close() end
    if bin and bin ~= "" then
        term:set_string("exec", bin)
        Gio.Settings.sync()
    end
end

if os.getenv("HYPRLAND_INSTANCE_SIGNATURE") then
    os.execute(string.format("hyprctl setcursor '%s' %d", CURSOR_THEME, CURSOR_SIZE))
end
