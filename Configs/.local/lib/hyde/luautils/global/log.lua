-- log.lua
-- A simple logger for HyDE scripts that uses lgi logging when available.
-- Falls back to console output with optional colors and file logging.

local log = {}
log.usecolor = true
log.outfile = nil
log.level = 'info'

local modes = {
  { name = 'trace', color = '\27[34m' },
  { name = 'debug', color = '\27[36m' },
  { name = 'info',  color = '\27[32m' },
  { name = 'warn',  color = '\27[33m' },
  { name = 'error', color = '\27[31m' },
  { name = 'fatal', color = '\27[35m' },
}

local levels = {}
for i, v in ipairs(modes) do
  levels[v.name] = i
end

local env_level = os.getenv('LOG_LEVEL')
if env_level then
  env_level = env_level:lower()
  if levels[env_level] then
    log.level = env_level
  end
end

local round = function(x, increment)
  increment = increment or 1
  x = x / increment
  return (x > 0 and math.floor(x + .5) or math.ceil(x - .5)) * increment
end

local _tostring = tostring
local stringify = function(...)
  local t = {}
  for i = 1, select('#', ...) do
    local x = select(i, ...)
    if type(x) == 'number' then
      x = round(x, .01)
    end
    t[#t + 1] = _tostring(x)
  end
  return table.concat(t, ' ')
end

local format_msg = function(...)
  if select('#', ...) == 0 then
    return ''
  end
  local first = select(1, ...)
  if type(first) == 'string' and select('#', ...) > 1 then
    return string.format(first, select(2, ...))
  end
  return stringify(...)
end

for i, x in ipairs(modes) do
  local nameupper = x.name:upper()
  log[x.name] = function(...)
    if i < levels[log.level] then
      return
    end

    local msg = format_msg(...)
    local info = debug.getinfo(2, 'Sl')
    local lineinfo = info.short_src .. ':' .. info.currentline

    local prefix = string.format('%s[%-6s%s]\27[0m ',
      log.usecolor and x.color or '',
      nameupper,
      os.date('%H:%M:%S'))

    print(prefix .. lineinfo .. ': ' .. msg)

      if log.outfile then
        local fp = io.open(log.outfile, 'a')
        if fp then
          local str = string.format('[%-6s%s] %s: %s\n',
            nameupper, os.date(), lineinfo, msg)
          fp:write(str)
          fp:close()
        end
      end
    end
  end

return log
