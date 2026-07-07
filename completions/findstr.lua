require('arghelper')

local dir_matcher = clink.argmatcher():addarg(clink.dirmatches)
local file_matcher = clink.argmatcher():addarg({
    { match="/", display="/ (console)" },
    clink.filematches
})

local a_parser = clink.argmatcher():addarg({fromhistory=true})
local c_parser = clink.argmatcher():addarg("search_string")

local flag_def_table = {
    {"/b",          "匹配行首的模式"},
    {"/e",          "匹配行尾的模式"},
    {"/l",          "按字面使用搜索字符串"},
    {"/r",          "将搜索字符串用作正则表达式（默认）"},
    {"/s",          "同时搜索子目录"},
    {"/i",          "不区分大小写的搜索"},
    {"/x",          "打印完全匹配的行"},
    {"/v",          "仅打印不包含匹配项的行"},
    {"/n",          "在匹配的行前打印行号"},
    {"/m",          "如果文件包含匹配项，则仅打印文件名"},
    {"/o",          "在匹配的行前打印字符偏移量"},
    {"/p",          "跳过包含不可打印字符的文件"},
    {"/offline",    "不跳过设置了脱机属性的文件"},
    {"/a:", a_parser, "hexattr", "用两个十六进制数字指定颜色属性"},
    {"/f:", file_matcher, "file", "从指定文件读取文件列表（/ 代表控制台）"},
    {"/c:", c_parser, "string", "将指定字符串用作字面搜索字符串"},
    {"/g:", file_matcher, "file", "从指定文件获取搜索字符串（/ 代表控制台）"},
    {"/d:", dir_matcher, "dir[;dir...]", "搜索以分号分隔的目录列表"},
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
