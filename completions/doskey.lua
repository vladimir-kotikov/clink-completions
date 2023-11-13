require('arghelper')

local function exe_matches_all(word, word_index, line_state, match_builder) -- luacheck: no unused args
    match_builder:addmatch({ match="all", display="\x1b[1mALL" })
    match_builder:addmatch({ match="cmd.exe", display="\x1b[1mCMD.EXE" })
    match_builder:addmatches(clink.filematches(""))
end

local function exe_matches(word, word_index, line_state, match_builder) -- luacheck: no unused args
    match_builder:addmatch({ match="cmd.exe", display="\x1b[1mCMD.EXE" })
    match_builder:addmatches(clink.filematches(""))
end

local function require_equal_sign(arg_index, word, word_index, line_state, classifications) -- luacheck: no unused
    if arg_index == 1 then
        local x = line_state:getwordinfo(word_index)
        local y = line_state:getwordinfo(word_index + 1)
        if x and y then
            local line = line_state:getline()
            local s = line:sub(x.offset + x.length, y.offset - 1)
            if not s:find("=") then
                local color = settings.get("color.unexpected") or ""
                local delta = s:find("[ \t]")
                delta = delta and (delta - 1) or #s
                local lastinfo = line_state:getwordinfo(line_state:getwordcount())
                local endoffset = lastinfo.offset + lastinfo.length
                local tailoffset = x.offset + x.length + delta
                if endoffset > tailoffset then
                    local tail = line:sub(endoffset):match("^([^&|]+)[&|]?.*$") or ""
                    endoffset = endoffset + #tail
                end
                classifications:applycolor(tailoffset, endoffset - tailoffset, color, true)
            end
        end
    end
end

-- luacheck: no max line length
clink.argmatcher("doskey")
:_addexflags({
    {"/reinstall",  "Installs a new copy of Doskey"},
    {"/macros",     "Display all Doskey macros for the current executable"},
    {"/macros:"..clink.argmatcher():addarg(exe_matches_all), "Display all Doskey macros for the named executable ('ALL' for all executables)"},
    {"/exename="..clink.argmatcher():addarg(exe_matches), "Specifies the executable"},
    {"/macrofile=", "Specifies a file of macros to install"},
})
:addarg()
:chaincommand()
:setclassifier(require_equal_sign)
