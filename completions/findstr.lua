require('arghelper')

local dir_matcher = clink.argmatcher():addarg(clink.dirmatches)
local file_matcher = clink.argmatcher():addarg({
    { match="/", display="/ (console)" },
    clink.filematches
})

local a_parser = clink.argmatcher():addarg({fromhistory=true})
local c_parser = clink.argmatcher():addarg("search_string")

local flag_def_table = {
    {"/b",          "Matches pattern if at the beginning of a line"},
    {"/e",          "Matches pattern if at the end of a line"},
    {"/l",          "Uses search strings literally"},
    {"/r",          "Uses search strings as regular expressions (default)"},
    {"/s",          "Search in subdirectories also"},
    {"/i",          "Case insensitive search"},
    {"/x",          "Prints lines that match exactly"},
    {"/v",          "Prints only lines that do not contain a match"},
    {"/n",          "Prints the line number before each line that matches"},
    {"/m",          "Prints only the filename if a file contains a match"},
    {"/o",          "Prints character offset before each matching line"},
    {"/p",          "Skips files with non-printable characters"},
    {"/offline",    "Do not skip files with offline attribute set"},
    {"/a:", a_parser, "hexattr", "Specifies color attribute with two hex digits"},
    {"/f:", file_matcher, "file", "Reads file list from the specified file (/ stands for console)"},
    {"/c:", c_parser, "string", "Uses specified string as literal search string"},
    {"/g:", file_matcher, "file", "Gets search strings from the specified file (/ stands for console)"},
    {"/d:", dir_matcher, "dir[;dir...]", "Search a semicolon delimited list of directories"},
}

local flags = { concat_one_letter_flags=true }
for _,f in ipairs(flag_def_table) do
    if f[3] then
        table.insert(flags, { f[1]..f[2], f[3], f[4] })
        table.insert(flags, { hide=true, f[1]:upper()..f[2], f[3], f[4] })
    else
        table.insert(flags, { f[1], f[2] })
        table.insert(flags, { hide=true, f[1]:upper(), f[2] })
    end
end

-- luacheck: no max line length
clink.argmatcher("findstr")
:setflagsanywhere(false)
:_addexflags(flags)
