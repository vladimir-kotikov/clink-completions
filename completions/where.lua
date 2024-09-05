require('arghelper')

local dir_matcher = clink.argmatcher():addarg(clink.dirmatches)

-- luacheck: push
-- luacheck: no max line length
local flag_def_table = {
    {"/r", dir_matcher, " dir", "Recursively searches and displays the files that match the given pattern starting from the specified directory"},
    {"/q",          "Returns only the exit code, without displaying the list of matched files. (Quiet mode)"},
    {"/f",          "Displays the matched filename in double quotes"},
    {"/t",          "Displays the file size, last modified date and time for all matched files"},
    {"/?",          "Displays help message"},
}
-- luacheck: pop

local flags = {}
for _,f in ipairs(flag_def_table) do
    if f[3] then
        table.insert(flags, { f[1]..f[2], f[3], f[4] })
        if f[1]:upper() ~= f[1] then
            table.insert(flags, { hide=true, f[1]:upper()..f[2], f[3], f[4] })
        end
    else
        table.insert(flags, { f[1], f[2] })
        if f[1]:upper() ~= f[1] then
            table.insert(flags, { hide=true, f[1]:upper(), f[2] })
        end
    end
end

-- luacheck: no max line length
clink.argmatcher("where")
:setflagsanywhere(false)
:_addexflags(flags)
