--- @module hyde.path
--- Resolves the XDG and HyDE directories the Hyprland Lua configuration reads
--- from, and exposes them globally as `hyde.path`.
---
--- This module is loaded before any other part of the configuration, so it has
--- to survive an environment it does not like. A session started outside uwsm
--- — from a TTY, or through a display manager that exports little — can reach
--- it with `HOME` absent and the XDG variables unset or empty. A field that
--- cannot be resolved is left `nil` for the caller to skip; raising here would
--- take the whole configuration down before Hyprland has a window on screen.
---
--- Usage:
---   local config_file = hyde.path.config and (hyde.path.config .. "/hyde/config.toml")

local P = {}

local HOME = os.getenv("HOME")

--- Reads an XDG base directory from the environment.
---
--- Per the specification a variable that is set but empty counts as unset, and
--- the fallback is derived from `HOME`.
---
--- @param name string Environment variable holding the directory.
--- @param fallback string|nil Path appended to `HOME` when the variable is
--- unset. Omit it for a directory that has no meaningful default.
--- @return string|nil path The directory, or nil when there is no fallback to
--- derive.
---
--- Example:
---   env("XDG_CONFIG_HOME", "/.config") --> "/home/user/.config"
---   env("XDG_RUNTIME_DIR")             --> nil when the session set nothing
local function env(name, fallback)
    local value = os.getenv(name)
    if value == nil or value == "" then
        return fallback and HOME and HOME .. fallback
    end

    return value
end

--- @field config string|nil User configuration directory.
P.config = env("XDG_CONFIG_HOME", "/.config")

--- @field cache string|nil User cache directory.
P.cache = env("XDG_CACHE_HOME", "/.cache")

--- @field state string|nil User state directory.
P.state = env("XDG_STATE_HOME", "/.local/state")

--- @field data string|nil User data directory.
P.data = env("XDG_DATA_HOME", "/.local/share")

--- @field runtime string|nil Runtime directory. It has no fallback: the spec
--- requires the session to provide one, and inventing a path would put runtime
--- state somewhere that outlives the session. An empty value is still unset,
--- so it reads as nil rather than as the working directory.
P.runtime = env("XDG_RUNTIME_DIR")

--- Errno the open reports when the path exists but may not be read.
local EACCES = 13

--- Reports whether a path is a directory.
---
--- Plain Lua cannot stat, so this asks the path itself, and asks for the entry
--- inside it that only a directory has: `dir/.` opens, while `file/.` and
--- `fifo/.` fail with ENOTDIR before anything is opened. Probing the bare path
--- instead would hand the resolver a way to hang — opening a FIFO with no
--- writer blocks until one arrives, and this runs before Hyprland has a window
--- on screen. The handle is closed on every outcome; leaving it open leaks one
--- per probe, and this module runs on every configuration reload.
---
--- Asking the shell instead, as this used to, costs a fork per probe. Hyprland
--- gives the whole configuration a single 1500 ms budget and its watchdog
--- counts VM instructions, so time spent waiting on a subprocess is time no
--- part of the configuration can account for.
---
--- A refusal on permission grounds counts as a directory. A directory that
--- grants search but not read cannot be listed and cannot be opened this way,
--- yet a file inside it still loads by name — which is all `package.path` ever
--- does with it, and what `test -d` reported here before.
---
--- @param path string Absolute path to test.
--- @return boolean exists True when the path is a directory.
local function is_directory(path)
    local handle, _, code = io.open(path .. "/.", "r")
    if not handle then
        return code == EACCES
    end

    handle:close()

    return true
end

--- Returns the first candidate that exists, preferring the user's own.
---
--- @param user_path string|nil User candidate, nil when it cannot be resolved.
--- @param system_paths table Ordered system candidates to fall back on.
--- @return string|nil path The first existing directory, or nil when none do.
local function first_directory(user_path, system_paths)
    if user_path and is_directory(user_path) then
        return user_path
    end

    for _, path in ipairs(system_paths) do
        if is_directory(path) then
            return path
        end
    end
end

--- @field lib string|nil Directory holding the HyDE Lua and shell libraries.
P.lib = first_directory(HOME and HOME .. "/.local/lib", {"/usr/local/lib", "/usr/lib"})

--- @field share string|nil Directory holding the shipped HyDE data files.
P.share = first_directory(P.data, {"/usr/local/share", "/usr/share"})

_G.hyde = _G.hyde or {}
_G.hyde.path = P

return P
