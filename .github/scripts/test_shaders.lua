-- Run from the repository root: lua .github/scripts/test_shaders.lua
-- Uses real file/state handling; compositor and menu calls never reach the desktop.
package.path = './Configs/.local/lib/hyde/?.lua;./Configs/.local/lib/hyde/?/init.lua;' .. package.path
require('luautils.init')
local lfs = require('lfs')
local root = os.tmpname()
os.remove(root)
assert(lfs.mkdir(root))
local function mkdir(path)
    local current = ''
    for part in path:gmatch('[^/]+') do current = current .. '/' .. part; lfs.mkdir(current) end
end
local function write(path, value)
    local f = assert(io.open(path, 'w')); assert(f:write(value)); assert(f:close())
end
local function read(path)
    local f = assert(io.open(path)); local value = f:read('*a'); f:close(); return value
end
local function remove_tree(path)
    for name in lfs.dir(path) do
        if name ~= '.' and name ~= '..' then
            local child = path .. '/' .. name
            if lfs.symlinkattributes(child, 'mode') == 'directory' then remove_tree(child) else os.remove(child) end
        end
    end
    lfs.rmdir(path)
end
local xdg = {config=root..'/config', state=root..'/state', data=root..'/data', cache=root..'/cache', runtime=root..'/runtime'}
package.loaded['luautils.xdg'] = xdg
local dir = xdg.config .. '/hypr/shaders/'
mkdir(dir); mkdir(xdg.data)
local current = {shader='', damage=2}
local calls, rejection, unreadable = 0, false, false
local function config(value)
    if value.debug then current.damage = value.debug.damage_tracking end
    if value.decoration then current.shader = value.decoration.screen_shader end
end
package.loaded['luautils.hypr.hyprctl'] = {
    get_option=function(name)
        if unreadable then return nil, 'connection failed' end
        if name == 'debug:damage_tracking' then return {int=current.damage} end
        return {str=current.shader}
    end,
    exec=function(command, code)
        assert(command == 'eval')
        calls = calls + 1
        if rejection then rejection=false; return 'simulated IPC failure' end
        assert(load(code, 'compositor', 't', {hl={config=config}}))()
        return 'ok'
    end
}
local menu
package.loaded['luautils.selector.rofi'] = {select=function(items, opts) return menu(items, opts) end}
write(dir..'disable.frag', '#version 300 es\n')
write(dir..'static.frag', '#version 300 es\n#define SHADER_NAME Static\nvoid main() {}\n')
write(dir..'animated.frag', '#version 300 es\n#define HYPRLAND_HOOK debug:damage_tracking false\nuniform float time;\nvoid main() {}\n')
write(dir..'other.frag', read(dir..'animated.frag'))
write(dir..'invalid.frag', '#define HYPRLAND_HOOK exec arbitrary-command\nvoid main() {}\n')
write(dir..'duplicate.frag', '#define HYPRLAND_HOOK debug:damage_tracking false\n#define HYPRLAND_HOOK debug:damage_tracking false\n')
write(dir..'comments.frag', '/*\n#define HYPRLAND_HOOK exec ignored\n*/\n// #define HYPRLAND_HOOK exec ignored\nuniform float time;\n#define SHADER_NAME ignored\n')
write(dir..'malicious.frag', '#version 300 es\n#define SHADER_NAME evil`id`$(id)"\\bad\nvoid main() {}\n')
write(dir..'include.frag', '// !source=missing.inc\nvoid main() {}\n')
write(dir..'missing.frag', 'void main() {}\n')
local sh = require('shaders')
local function snapshot() return {runtime={shader=current.shader,damage=current.damage}, state=read(sh.state_file), mirror=read(xdg.state..'/hyde/staterc')} end
local function unchanged(before)
    assert(current.shader == before.runtime.shader and current.damage == before.runtime.damage, 'runtime changed')
    assert(read(sh.state_file) == before.state, 'persisted selection changed')
    assert(read(xdg.state..'/hyde/staterc') == before.mirror, 'shell state changed')
end
local function token() return require('dkjson').decode(read(xdg.runtime..'/hyde/shaders/preview')).token end
local ok, err = xpcall(function()
    local first = assert(sh.set('static'))
    local before = snapshot()
    local bytes = read(first.compiled)
    local item, failure = sh.set('animated')
    assert(not item and failure:find('GPU usage',1,true)); unchanged(before)
    for _, name in ipairs({'invalid','duplicate','include','unknown'}) do
        assert(not sh.set(name)); unchanged(before)
    end
    os.remove(dir..'missing.frag')
    assert(not sh.set('missing')); unchanged(before)
    assert(sh.find('comments').name == 'comments' and sh.find('comments').hook == nil)
    local tainted = sh.find('malicious')
    assert(tainted and not tainted.name:find('[%c`$"\\]'), 'shell-unsafe characters survived into the menu entry')
    unreadable=true; assert(not sh.set('static')); unreadable=false; unchanged(before)
    rejection=true; assert(not sh.set('animated',true)); unchanged(before)
    local old_rename=os.rename
    os.rename=function(from,to)
        if to==sh.state_file then return nil,'simulated state write failure' end
        return old_rename(from,to)
    end
    assert(not sh.set('animated',true)); os.rename=old_rename; unchanged(before)
    assert(read(first.compiled)==bytes)
    print('PASS: denied consent, invalid hooks, missing files/includes, IPC and state failures preserve selection')

    local stale
    menu=function()
        stale=token()
        local previous_calls=calls
        assert(sh.preview('animated',stale)); assert(calls==previous_calls)
        assert(sh.preview('other',stale)); assert(calls==previous_calls)
        assert(sh.preview('comments',stale))
        assert(current.shader~=first.compiled)
        previous_calls=calls
        local preview_path=current.shader
        assert(sh.preview('comments',stale))
        assert(calls==previous_calls and current.shader==preview_path, 'duplicate preview reloaded shader')
        assert(sh.preview('disable',stale)); assert(current.shader=='')
        assert(read(first.compiled)==bytes and read(sh.state_file)==before.state)
        return nil
    end
    local selected, cancel_err=sh.select()
    assert(not selected and not cancel_err); unchanged(before)
    local previous_calls=calls
    assert(sh.preview('static',stale)); assert(calls==previous_calls)
    print('PASS: previews preserve committed cache, cancellation restores runtime, duplicate/late callbacks are ignored')

    -- Simulate another callback arriving while the first waits for selection to settle.
    local socket=require('socket')
    local real_sleep=socket.sleep
    menu=function()
        local id=token()
        socket.sleep=function()
            socket.sleep=real_sleep
            assert(sh.preview('disable',id))
        end
        local count=calls
        assert(sh.preview('comments',id))
        assert(calls==count+1 and current.shader=='', 'outdated preview applied after newer selection')
        return nil
    end
    local result, failure=sh.select()
    socket.sleep=real_sleep
    assert(not result and not failure); unchanged(before)
    print('PASS: rapid selections apply only the latest preview')

    -- A second menu must keep the first menu's original snapshot, not its preview.
    local nested = false
    menu=function()
        assert(sh.preview('comments',token()))
        if not nested then
            nested=true
            local inner, inner_err=sh.select()
            assert(not inner and not inner_err)
        end
        return nil
    end
    local replaced, replaced_err=sh.select()
    assert(not replaced and replaced_err:find('replaced',1,true)); unchanged(before)
    -- An explicit selection supersedes a pending menu and its queued previews.
    menu=function()
        stale=token()
        assert(sh.preview('comments',stale))
        assert(sh.set('static'))
        return nil
    end
    assert(not sh.select())
    before=snapshot()
    previous_calls=calls
    assert(sh.preview('disable',stale)); assert(calls==previous_calls); unchanged(before)
    print('PASS: overlapping menus and concurrent selections cannot restore a stale preview')

    local prompts=0
    menu=function(_,opts)
        prompts=prompts+1
        if opts.on_selection_changed then return 'animated' end
        assert(opts.current_name=='Cancel')
        return 'Cancel'
    end
    assert(not sh.select()); assert(prompts==2); unchanged(before)
    menu=function(_,opts)
        if opts.on_selection_changed then return 'animated' end
        return 'Enable (higher GPU usage)'
    end
    local animated=assert(sh.select())
    assert(current.damage==0 and animated.previous_damage==2)
    -- Reload/session restoration executes the generated state, not the selector.
    current={shader='',damage=2}
    _G.hl={config=config}; local persisted=dofile(sh.state_file); _G.hl=nil
    assert(current.shader==animated.compiled and current.damage==0 and persisted.hook)
    assert(sh.reload()); assert(current.damage==0)
    assert(sh.set('other')); assert(current.damage==0)
    assert(sh.set('disable')); assert(current.shader=='' and current.damage==2)
    print('PASS: explicit confirmation, state replay, reload and animated-to-animated-to-disabled restore original value 2')

    current.damage=0
    assert(sh.set('animated')); assert(sh.set('static')); assert(current.damage==0)
    current.damage=1
    assert(sh.set('animated',true)); assert(sh.set('static')); assert(current.damage==1)
    current.damage=2
    assert(sh.set('animated',true)); current.damage=1
    assert(sh.set('static')); assert(current.damage==1)
    print('PASS: original values 0/1/2 and subsequent manual changes are respected')

    assert(sh.set('animated',true))
    local original_damage=dofile(sh.state_file).previous_damage
    local missing_cache=current.shader
    os.remove(missing_cache)
    current={shader=missing_cache,damage=0}
    _G.hl={config=config}; dofile(sh.state_file); _G.hl=nil
    assert(current.shader=='' and current.damage==original_damage)

    local dangerous='quotes " \\ and newline\n_G.injected=true --'
    sh.find('static').description=dangerous
    assert(sh.set('static'))
    assert(dofile(sh.state_file).description==dangerous and not _G.injected)
    os.remove(current.shader)
    current={shader='',damage=2}
    _G.hl={config=config}; dofile(sh.state_file); _G.hl=nil
    assert(current.shader=='' and current.damage==2)
    print('PASS: metadata is stored as data; missing compiled cache restores safely')
end, debug.traceback)
remove_tree(root)
if not ok then error(err,0) end
