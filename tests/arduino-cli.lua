-- Run from the repository root with Clink and Arduino CLI installed:
-- clink lua tests/arduino-cli.lua
local native_clink = clink
local begin_edit
clink = setmetatable({
    generator=function() return {} end,
    onbeginedit=function(fn) begin_edit=fn end,
}, {__index=native_clink})
local cobra = require('modules/cobra')
local generator = cobra.register('arduino-cli')
local calls = 0
local native_popen = io.popen
io.popen = function(command) calls=calls+1; return native_popen(command) end -- luacheck: ignore 122
local function complete(line, expected)
    -- parseline excludes the synthetic empty word supplied to live generators.
    local parsed = native_clink.parseline(line)
    local state = parsed[#parsed].line_state
    local count = state:getwordcount()
    local empty = line:sub(-1) == ' '
    local proxy = setmetatable({}, {__index=function(_,k)
        if k == 'getwordcount' then return function() return count+(empty and 1 or 0) end end
        if k == 'getwordinfo' then return function(_,i)
            if i>count then return {offset=#line+1,length=0} end
            return state:getwordinfo(i)
        end end
        if k == 'getword' then return function(_,i) return i>count and '' or state:getword(i) end end
        if k == 'getendword' then return function() return empty and '' or state:getendword() end end
        return function(_,...) return state[k](state,...) end
    end})
    local b = {matches={}}
    function b:addmatch(m) self.matches[#self.matches+1]=m end
    function b:addmatches(ms) for _,m in ipairs(ms) do self:addmatch(m) end end
    function b:setsuppressappend() end -- luacheck: no unused
    function b:setnosort() end -- luacheck: no unused
    generator:generate(proxy,b)
    local found=false
    for _,m in ipairs(b.matches) do if (type(m)=='table' and m.match or m)==expected then found=true end end
    assert(found, 'missing '..expected..' for '..line)
    print('LIVE PASS '..line..' -> '..expected..' ('..#b.matches..' matches)')
end
complete('arduino-cli ', 'compile')
complete('arduino-cli core ', 'install')
complete('arduino-cli compile --', '--fqbn')
complete('arduino-cli compile --fqbn arduino:avr:u', 'arduino:avr:uno')
complete('arduino-cli compile --fqbn=arduino:avr:u', 'arduino:avr:uno')
complete('echo ignored & arduino-cli core ', 'install')
complete('"C:\\Program Files\\Arduino\\arduino-cli.exe" core ', 'install')
local previous=calls
complete('arduino-cli core ', 'install')
assert(previous == calls)
begin_edit()
complete('arduino-cli core ', 'install')
assert(previous+1 == calls)
print('PASS cache reuse and new-prompt invalidation')
io.popen = native_popen -- luacheck: ignore 122
clink = native_clink

