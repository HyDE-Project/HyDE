-- luautils/global/notify.lua
-- Notification helper for HyDE. Uses notify-send in the background so the
-- caller continues even if the notification daemon stalls.
--
-- Usage:
--   local notify = require('luautils.global.notify')
--   notify.send(summary, body, { urgency = 'critical', icon = 'dialog-warning', timeout = 5000 })

local M = {}

local function sh_quote(s)
    if not s then return "''" end
    s = tostring(s)
    return "'" .. s:gsub("'", "'\\''") .. "'"
end

-- detect notify-send command
local notify_send_checked = false
local notify_send_available = false

local function has_notify_send()
    if notify_send_checked then
        return notify_send_available
    end
    local f = io.popen('command -v notify-send 2>/dev/null')
    if not f then return false end
    local out = f:read('*l')
    f:close()
    notify_send_checked = true
    notify_send_available = out and out ~= ''
    return notify_send_available
end

-- Primary send function
function M.send(summary, body, opts)
    opts = opts or {}
    local urgency = opts.urgency or 'normal'
    local icon = opts.icon or ''
    local timeout = tonumber(opts.timeout) or 5000
    local replace_id = tonumber(opts.replace_id) or 0

    -- Call notify-send in background with & so we don't block.
    if has_notify_send() then
        local icon_flag = ''
        if icon ~= '' then
            icon_flag = ' -i ' .. sh_quote(icon)
        end
        local cmd = string.format('notify-send -a "HyDE Power" -t %d -r %d -u %s%s %s %s >/dev/null 2>&1 &',
            timeout, replace_id, tostring(urgency), icon_flag, sh_quote(summary or ''), sh_quote(body or ''))
        -- Use sh -c to ensure & is interpreted by the shell
        os.execute('sh -c ' .. sh_quote(cmd))
        return true
    else
        -- As last resort just print the notification to stdout
        io.write(string.format('NOTIFY [%s] %s: %s\n', urgency, summary or '', body or ''))
        return false
    end
end

-- alias
M.notify = M.send

return M
