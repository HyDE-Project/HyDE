-- hyde/utils.lua
-- Utility helpers used by HyDE Lua modules.
--
-- Usage:
--   local utils = require("hyde.utils")
--   local module = utils.check_require("some.module")
--   local is_list = utils.is_nonempty_list({1, 2, 3})
--   local pattern = utils.compile_pattern_list({"foo", "bar"})
--   local regex_table = utils.regex_compile({type = {"foo", "bar"}})
--
-- The module is also exposed globally as `hyde.utils` and `check_require`.

local util = {}

-- Safely require a module only if it exists in package.path.
--
-- Parameters:
--   module_name (string): The Lua module name to load.
--
-- Returns:
--   any | nil: The required module if found, otherwise nil.
--
-- Example:
--   local lfs = util.check_require("lfs")
--   if lfs then
--     -- use lfs safely
--   end
function util.check_require(module_name)
  if type(module_name) ~= "string" then
    return nil
  end

  local filename = package.searchpath(module_name, package.path)
  if filename then
    return require(module_name)
  end

  return nil
end

-- Returns true when the value is a non-empty list-like table.
--
-- Parameters:
--   value (any): Value to test.
--
-- Returns:
--   boolean: true when value is a table and contains at least one element.
--
-- Example:
--   util.is_nonempty_list({"a"}) --> true
--   util.is_nonempty_list({}) --> false
function util.is_nonempty_list(value)
  return type(value) == "table" and #value > 0
end

-- Compile a list of strings into a Lua pattern.
--
-- Parameters:
--   list (table): Array of string values to join.
--   anchored (boolean|nil): Whether to anchor the pattern with ^ and $.
--                          Defaults to true.
--
-- Returns:
--   string|nil: A Lua pattern matching any item in the list, or nil when
--               the input list is empty or invalid.
--
-- Example:
--   util.compile_pattern_list({"foo", "bar"}) --> "^(foo|bar)$"
function util.compile_pattern_list(list, anchored)
  if not util.is_nonempty_list(list) then
    return nil
  end

  if anchored == nil then
    anchored = true
  end

  local pattern = table.concat(list, "|")
  if anchored then
    pattern = "^(" .. pattern .. ")$"
  end

  return pattern
end

-- Convert a table of string lists into a table of Lua patterns.
--
-- Parameters:
--   spec (table): Map of keys to array of strings.
--   anchored (boolean|nil): Whether to anchor each compiled pattern.
--                          Defaults to true.
--
-- Returns:
--   table: A table with the same keys and compiled pattern strings.
--
-- Example:
--   util.regex_compile({ type = {"app", "window"} })
--   --> { type = "^(app|window)$" }
function util.regex_compile(spec, anchored)
  if type(spec) ~= "table" then
    return {}
  end

  if anchored == nil then
    anchored = true
  end

  local out = {}
  for key, value in pairs(spec) do
    if util.is_nonempty_list(value) then
      out[key] = util.compile_pattern_list(value, anchored)
    end
  end

  return out
end

_G.hyde = _G.hyde or {}
_G.hyde.utils = util
_G.check_require = util.check_require

return util
