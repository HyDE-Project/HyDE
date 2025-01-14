-- selene: allow(global_usage)

local M = {}

function M.get_loc()
  local me = debug.getinfo(1, "S")
  local level = 2
  local info = debug.getinfo(level, "S")
  while info and (info.source == me.source or info.source == "@" .. vim.env.MYVIMRC or info.what ~= "Lua") do
    level = level + 1
    info = debug.getinfo(level, "S")
  end
  info = info or me
  local source = info.source:sub(2)
  source = vim.loop.fs_realpath(source) or source
  return source .. ":" .. info.linedefined
end

---@param value any
---@param opts? {loc:string}
function M._dump(value, opts)
  opts = opts or {}
  opts.loc = opts.loc or M.get_loc()
  if vim.in_fast_event() then
    return vim.schedule(function()
      M._dump(value, opts)
    end)
  end
  opts.loc = vim.fn.fnamemodify(opts.loc, ":~:.")
  local msg = vim.inspect(value)
  vim.notify(msg, vim.log.levels.INFO, {
    title = "Debug: " .. opts.loc,
    on_open = function(win)
      vim.wo[win].conceallevel = 3
      vim.wo[win].concealcursor = ""
      vim.wo[win].spell = false
      local buf = vim.api.nvim_win_get_buf(win)
      if not pcall(vim.treesitter.start, buf, "lua") then
        vim.bo[buf].filetype = "lua"
      end
    end,
  })
end

function M.dump(...)
  local value = { ... }
  if vim.tbl_isempty(value) then
    value = nil
  else
    value = vim.tbl_islist(value) and vim.tbl_count(value) <= 1 and value[1] or value
  end
  M._dump(value)
end

function M.extmark_leaks()
  local nsn = vim.api.nvim_get_namespaces()

  local counts = {}

  for name, ns in pairs(nsn) do
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local count = #vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {})
      if count > 0 then
        counts[#counts + 1] = {
          name = name,
          buf = buf,
          count = count,
          ft = vim.bo[buf].ft,
        }
      end
    end
  end
  table.sort(counts, function(a, b)
    return a.count > b.count
  end)
  dd(counts)
end

function estimateSize(value, visited)
  if value == nil then
    return 0
  end
  local bytes = 0

  -- initialize the visited table if not already done
  --- @type table<any, true>
  visited = visited or {}

  -- handle already-visited value to avoid infinite recursion
  if visited[value] then
    return 0
  else
    visited[value] = true
  end

  if type(value) == "boolean" or value == nil then
    bytes = 4
  elseif type(value) == "number" then
    bytes = 8
  elseif type(value) == "string" then
    bytes = string.len(value) + 24
  elseif type(value) == "function" then
    bytes = 32 -- base size for a function
    -- add size of upvalues
    local i = 1
    while true do
      local name, val = debug.getupvalue(value, i)
      if not name then
        break
      end
      bytes = bytes + estimateSize(val, visited)
      i = i + 1
    end
  elseif type(value) == "table" then
    bytes = 40 -- base size for a table entry
    for k, v in pairs(value) do
      bytes = bytes + estimateSize(k, visited) + estimateSize(v, visited)
    end
    local mt = debug.getmetatable(value)
    if mt then
      bytes = bytes + estimateSize(mt, visited)
    end
  end
  return bytes
end

function M.module_leaks(filter)
  local sizes = {}
  for modname, mod in pairs(package.loaded) do
    if not filter or modname:match(filter) then
      local root = modname:match("^([^%.]+)%..*$") or modname
      -- root = modname
      sizes[root] = sizes[root] or { mod = root, size = 0 }
      sizes[root].size = sizes[root].size + estimateSize(mod) / 1024 / 1024
    end
  end
  sizes = vim.tbl_values(sizes)
  table.sort(sizes, function(a, b)
    return a.size > b.size
  end)
  dd(sizes)
end

function M.get_upvalue(func, name)
  local i = 1
  while true do
    local n, v = debug.getupvalue(func, i)
    if not n then
      break
    end
    if n == name then
      return v
    end
    i = i + 1
  end
end

return M
