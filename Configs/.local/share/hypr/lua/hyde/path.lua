-- hyde/path.lua
-- Provides global access to important XDG and HyDE paths

local P = {}

P.config = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
P.cache  = os.getenv("XDG_CACHE_HOME")  or (os.getenv("HOME") .. "/.cache")
P.state  = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state"))

-- XDG runtime directory
P.runtime = os.getenv("XDG_RUNTIME_DIR")

-- HyDE library directory resolution
local lib_paths = {
    os.getenv("HOME") .. "/.local/lib",
    "/usr/local/lib",
    "/usr/lib",
}
for _, p in ipairs(lib_paths) do
    local test = io.popen("[ -d '" .. p .. "' ] && echo 1 || echo 0"):read("*l")
    if test == "1" then
        P.lib = p
        break
    end
end

-- HyDE share directory: check user, then system
local share_paths = {
    (os.getenv("XDG_DATA_HOME") or (os.getenv("HOME") .. "/.local/share")) .. "",
    "/usr/local/share",
    "/usr/share",
}
for _, p in ipairs(share_paths) do
    local test = io.popen("[ -d '" .. p .. "' ] && echo 1 || echo 0"):read("*l")
    if test == "1" then
        P.share = p
        break
    end
end



-- Make globally accessible
_G.hyde = _G.hyde or {}
_G.hyde.path = P

return P
