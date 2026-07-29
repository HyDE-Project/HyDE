--- @module luautils.xdg
-- XDG Base Directory Specification https://specifications.freedesktop.org/basedir-spec/latest/
local HOME = os.getenv("HOME")
--- Per the spec, a variable that is set but empty is treated as unset.
local function env(var, fallback)
   local value = os.getenv(var)
   if value == nil or value == "" then
      return HOME and HOME .. fallback
   end
   return value
end
local function dirs(var, default, home)
   local t = {}
   local value = os.getenv(var)
   if value == nil or value == "" then
      value = default
   end
   for e in value:gmatch("([^:]+)") do
      t[#t + 1] = e
   end
   if home then
      table.insert(t, 1, home)
   end
   return t
end

local xdg = {
   data = env("XDG_DATA_HOME", "/.local/share"),
   config = env("XDG_CONFIG_HOME", "/.config"),
   cache = env("XDG_CACHE_HOME", "/.cache"),
   state = env("XDG_STATE_HOME", "/.local/state"),
   runtime = os.getenv("XDG_RUNTIME_DIR")
}

xdg.dirs = {
   data = dirs("XDG_DATA_DIRS", "/usr/local/share:/usr/share", xdg.data),
   config = dirs("XDG_CONFIG_DIRS", "/etc/xdg", xdg.config),
   cache = dirs("XDG_CACHE_DIRS", "", xdg.cache)
}

return xdg
