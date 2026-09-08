-- Every fix for #1901's remaining call sites (dconf.lua, batterynotify.lua,
-- altab.lua) uses this exact single-quote-escaping idiom, already
-- established elsewhere in the codebase (hyde/dispatcher.lua, among
-- others). Rather than loading each of those three files -- which pull in
-- lgi/Gio/DBus -- this proves the shared escaping logic itself is actually
-- injection-proof against both vulnerable shapes those files had, and still
-- resolves a real command name correctly.
--
-- The three sites had two distinct unsafe shapes, and a payload crafted for
-- one does not exploit the other -- both are exercised explicitly:
--   1. No shell quoting at all (dconf.lua, batterynotify.lua before the fix):
--      "command -v " .. value .. " ...". Any value containing a shell
--      metacharacter runs as a separate command outright.
--   2. Quoted but not escaped (altab.lua before the fix):
--      "command -v '" .. value .. "' ...". A value containing a single quote
--      closes that quote early, so its remainder runs unquoted.

local function shell_quote(arg)
    arg = tostring(arg)
    arg = arg:gsub("'", "'\\''")
    return "'" .. arg .. "'"
end

local failures = 0
local function check(condition, message)
    if not condition then
        failures = failures + 1
        print("    fail: " .. message)
    end
end

local function marker_was_created(cmd)
    local marker = os.tmpname()
    os.remove(marker)
    -- Grouped so the redirect swallows every command in a ";"-separated
    -- payload, not just the last one -- an unredirected earlier command
    -- (e.g. the sanity checks' own "command -v sh") would otherwise leak
    -- its output to this test's stdout.
    os.execute("{ " .. cmd:gsub("MARKER", marker) .. "; } >/dev/null 2>&1")
    local f = io.open(marker, "r")
    local created = f ~= nil
    if f then
        f:close()
        os.remove(marker)
    end
    return created
end

-- Shape 1, unfixed: no shell quoting at all -- confirms the payload below is
-- a real exploit against that shape before checking the fix neutralizes it.
check(
    marker_was_created('command -v sh; touch MARKER; echo x'),
    "sanity check failed: the unquoted-shape payload did not execute against the actually-unquoted template -- the test payload itself is wrong"
)

-- Shape 1, fixed: same payload, now through shell_quote.
check(
    not marker_was_created("command -v " .. shell_quote("sh; touch MARKER; echo x")),
    "a value with no framing quotes still executed an injected command once passed through shell_quote"
)

-- Shape 2, unfixed: quoted but not escaped (altab.lua/path.lua's original
-- bug) -- confirms this payload is a real exploit against that shape too.
check(
    marker_was_created("command -v 'x'; touch MARKER; echo '' 2>/dev/null"),
    "sanity check failed: the quote-closing payload did not execute against the actually-quoted-not-escaped template -- the test payload itself is wrong"
)

-- Shape 2, fixed: same style of payload, now through shell_quote.
check(
    not marker_was_created("command -v " .. shell_quote("x'; touch MARKER; echo '") .. " 2>/dev/null"),
    "a quote-closing payload still executed an injected command once passed through shell_quote"
)

-- A value that is merely quoted, not escaped, breaks the same way on a bare
-- single quote with no command at all -- the plain "lost functionality" half
-- of #1901 (a HOME/username with an apostrophe), not just code execution.
local quote_only_payload = "o'brien"
local handle = io.popen("echo " .. shell_quote(quote_only_payload))
local echoed = handle:read("*l")
handle:close()
check(echoed == quote_only_payload, "a value containing a single quote did not round-trip through shell_quote: got " .. tostring(echoed))

-- A real command name must still resolve correctly once quoted -- the fix
-- must not make command lookup fail for the common, unremarkable case.
local sh_handle = io.popen("command -v " .. shell_quote("sh") .. " 2>/dev/null")
local sh_path = sh_handle:read("*l")
sh_handle:close()
check(sh_path ~= nil and sh_path ~= "", "a plain command name ('sh') no longer resolves once quoted")

os.exit(failures == 0 and 0 or 1)
