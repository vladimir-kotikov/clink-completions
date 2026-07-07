--------------------------------------------------------------------------------
-- It would have been great to simply use the "winget complete" command.  But
-- it has two problems:
--      1.  It doesn't provide completions for lots of things (esp. arguments
--          for most flags).  It never provides filename or directory matches.
--      2.  It can't support input line coloring, because there's no way to
--          populate the parse tree in advance, and because there's no way to
--          reliably infer the parse tree.
--
-- However, we'll use it where we can, because it does provide fancy
-- completions for some things (at least when a partial word is entered, e.g.
-- for `winget install Power` which finds package names with prefix "Power").

local standalone = not clink or not clink.argmatcher
local clink_version = require('clink_version')

--------------------------------------------------------------------------------
-- Helper functions.

-- luacheck: max line length 100

-- Clink v1.4.12 and earlier fall into a CPU busy-loop if
-- match_builder:setvolatile() is used during an autosuggest strategy.
local volatile_fixed = clink_version.has_volatile_matches_fix

local function sanitize_word(line_state, index, info)
    if not info then
        info = line_state:getwordinfo(index)
    end

    local end_offset = info.offset + info.length - 1
    if volatile_fixed and end_offset < info.offset and index == line_state:getwordcount() then
        end_offset = line_state:getcursor() - 1
    end

    local word = line_state:getline():sub(info.offset, end_offset)
    word = word:gsub('"', '\\"')
    return word
end

local function append_word(text, word)
    if #text > 0 then
        text = text .. " "
    end
    return text .. word
end

local function sanitize_line(line_state)
    local text = ""
    for i = 1, line_state:getwordcount() do
        local info = line_state:getwordinfo(i)
        local word
        if info.alias then
            word = "winget"
        elseif not info.redir then
            word = sanitize_word(line_state, i, info)
        end
        if word then
            text = append_word(text, word)
        end
    end
    local endword = sanitize_word(line_state, line_state:getwordcount())
    return text, endword
end

local debug_print_query
if tonumber(os.getenv("DEBUG_CLINK_WINGET") or "0") > 0 then
    local query_count = 0
    local color_index = 0
    local color_values = { "52", "94", "100", "22", "23", "19", "53" }
    debug_print_query = function (endword)
        query_count = query_count + 1
        color_index = color_index + 1
        if color_index > #color_values then
            color_index = 1
        end
        clink.print("\x1b[s\x1b[H\x1b[1;37;48;5;"..color_values[color_index].."mQUERY #"..query_count..", endword '"..endword.."'\x1b[m\x1b[K\x1b[u", NONL) -- luacheck: no max line length, no global
    end
else
    debug_print_query = function () end
end

local function winget_complete(word, index, line_state, builder) -- luacheck: no unused args
    local matches = {}
    local winget = os.getenv("LOCALAPPDATA")

    -- In the background (async auto-suggest), delay `winget complete` by 200 ms
    -- to coalesce rapid keypresses into a single query.  Overall, this improves
    -- the responsiveness for showing auto-suggestions which involve slow
    -- network queries.  The drawback is that all background `winget complete`
    -- queries take 200 milliseconds longer to show results.  But it can save
    -- many seconds, so on average it works out as feeling more responsive.
    if winget and volatile_fixed and builder.setvolatile and rl.islineequal then
        local co, ismain = coroutine.running()
        if not ismain then
            local orig_line = line_state:getline():sub(1, line_state:getcursor() - 1)
            clink.setcoroutineinterval(co, .2)
            coroutine.yield()
            clink.setcoroutineinterval(co, 0)
            if not rl.islineequal(orig_line, true) then
                winget = nil
                builder:setvolatile()
            end
        end
    end

    if winget then
        winget = '"'..path.join(winget, "Microsoft\\WindowsApps\\winget.exe")..'"'

        local commandline, endword = sanitize_line(line_state)
        debug_print_query(endword)
        local command = '2>nul '..winget..' complete --word="'..endword..'" --commandline="'..commandline..'" --position=99999' -- luacheck: no max line length
        local f = io.popen(command)
        if f then
            for line in f:lines() do
                line = line:gsub('"', '')
                if line ~= "" and (standalone or line:sub(1,1) ~= "-") then
                    table.insert(matches, line)
                end
            end
            f:close()
        end

        -- Mark the matches volatile even when generation was skipped due to
        -- running in a coroutine.  Otherwise it'll never run it in the main
        -- coroutine, either.
        if volatile_fixed and builder.setvolatile then
            builder:setvolatile()
        end

        -- Enable quoting.
        if builder.setforcequoting then
            builder:setforcequoting()
        elseif clink.matches_are_files then
            clink.matches_are_files()
        end
    end
    return matches
end

--------------------------------------------------------------------------------
-- When this script is run as a standalone Lua script, it can traverse the
-- available winget commands and flags and output the available completions.
-- This helps when updating the completions this script supports.

if standalone then

    local function ignore_match(match)
        if match == "--help" or
                match == "--no-vt" or
                match == "--rainbow" or
                match == "--retro" or
                match == "--verbose-logs" or
                false then
            return true
        end
    end

    local function dump_completions(line, recursive)
        local line_state = clink.parseline(line..' ""')[1].line_state
        local t = winget_complete("", 0, line_state, {})
        if #t > 0 then
            print(line)
            for _, match in ipairs(t) do
                if not ignore_match(match) then
                    print("", match)
                end
            end
            print()
            if recursive then
                for _, match in ipairs(t) do
                    if not ignore_match(match) then
                        dump_completions(line.." "..match, not match:find("^-") )
                    end
                end
            end
        end
    end

    dump_completions("winget", true)
    return

end

--------------------------------------------------------------------------------
-- Parsers for linking.

-- TODO: ideally "winget complete" could list the available settings so that
-- setting_name_matches could list actual setting names.

local arghelper = require("arghelper")

local empty_arg = clink.argmatcher():addarg()
local contextual_matches = clink.argmatcher():addarg({winget_complete})

local add_source_matches = empty_arg
local arch_matches = contextual_matches
local command_matches = contextual_matches
local count_matches = clink.argmatcher():addarg({fromhistory=true, 10, 20, 40})
local dependency_source_matches = clink.argmatcher():addarg({fromhistory=true})
local file_matches = clink.argmatcher():addarg(clink.filematches)
local header_matches = clink.argmatcher():addarg({fromhistory=true})
local id_matches = contextual_matches
local locale_matches = clink.argmatcher():addarg({fromhistory=true})
local location_matches = clink.argmatcher():addarg(clink.dirmatches)
local moniker_matches = contextual_matches
local name_matches = contextual_matches
local override_matches = clink.argmatcher():addarg({fromhistory=true})
local productcode_matches = clink.argmatcher():addarg({fromhistory=true})
local query_matches = clink.argmatcher():addarg({fromhistory=true})
local scope_matches = contextual_matches
local setting_name_matches = clink.argmatcher():addarg({fromhistory=true})
local source_matches = contextual_matches
local tag_matches = contextual_matches
local type_matches = clink.argmatcher():addarg({"Microsoft.PreIndexed.Package"})
local url_matches = empty_arg
local version_matches = contextual_matches

--------------------------------------------------------------------------------
-- Factored flag definitions.

-- luacheck: no max line length

local arch_locale_flags = {
    { hide=true,    "-a"                .. arch_matches },
    {               "--architecture"    .. arch_matches,        " arch",        "选择要安装的架构" },
    {               "--locale"          .. locale_matches,      " locale",      "要使用的区域设置（BCP47 格式）" },
}

local common_flags = {
    {               "--verbose-logs",                                           "启用 WinGet 详细日志记录" },
    {               "--logs",                                                   "打开默认日志位置" },
    { hide=true,    "--no-vt" },
    { hide=true,    "--rainbow" },
    { hide=true,    "--retro" },
    {               "--help",                                                   "显示所选命令的帮助" },
    { hide=true,    "-?" },
    { hide=true,    "--wait",                                                   "退出前提示用户按任意键" },
    { hide=true,    "--disable-interactivity",                                  "禁用交互式提示" },
    { hide=true,    "--verbose",                                                "启用 WinGet 详细日志记录" },
    { hide=true,    "--open-logs",                                              "打开默认日志位置" },
}

local source_name_flags = {
    { hide=true,    "-n"                .. source_matches },
    {               "--name"            .. source_matches,      " name",        "源的名称" },
}

local query_flags = {
    { hide=true,    "-q"                .. query_matches },
    {               "--query"           .. query_matches,       " query",       "用于搜索软件包的查询" },
    {               "--id"              .. id_matches,          " id",          "按 ID 筛选结果" },
    {               "--name"            .. name_matches,        " name",        "按名称筛选结果" },
    {               "--moniker"         .. moniker_matches,     " moniker",     "按别名筛选结果" },
    { hide=true,    "-e" },
    {               "--exact",                                                  "使用精确匹配查找软件包" },
}

local query_flags_more = {
    {               "--tag"             .. tag_matches,         " tag",         "按标签筛选结果" },
    {               "--command"         .. command_matches,     " command",     "按命令筛选结果" },
    { hide=true,    "-n"                .. count_matches },
    {               "--count"           .. count_matches,       " count",       "显示不超过指定数量的结果（范围 1 到 1000）" },
}

local source_flags = {
    { hide=true,    "-s"                .. source_matches },
    {               "--source"          .. source_matches,      " source",      "使用指定源查找软件包" },
}

--------------------------------------------------------------------------------
-- Command parsers.

local export_parser = clink.argmatcher()
:_addexflags({
    opteq=true,
    common_flags,
    source_flags,
    { hide=true,    "-o"                .. file_matches },
    {               "--output"          .. file_matches,        " file",        "写入结果的文件" },
    { hide=true,    "--include-versions" },
    { hide=true,    "--accept-source-agreements" },
})
:addarg(clink.filematches)
:nofiles()

local features_parser = clink.argmatcher()
:_addexflags({
    common_flags,
})
:nofiles()

local hash_parser = clink.argmatcher()
:_addexflags({
    opteq=true,
    common_flags,
    { hide=true,    "-f"                .. file_matches },
    {               "--file"            .. file_matches,        " file",        "要计算哈希的文件"},
    { hide=true,    "-m" },
    {               "--msix",                                                   "输入文件将被视为 msix；如果已签名，将提供签名哈希" },
})
:addarg(clink.filematches)
:nofiles()

local import_parser = clink.argmatcher()
:_addexflags({
    opteq=true,
    common_flags,
    { hide=true,    "-i"                .. file_matches },
    {               "--import-file"     .. file_matches,        " file",        "描述要安装的软件包的文件" },
    {               "--ignore-unavailable",                                     "忽略不可用的软件包" },
    {               "--ignore-versions",                                        "忽略导入文件中的软件包版本" },
    {               "--no-upgrade",                                             "如果已安装的版本已存在，则跳过升级" },
    {               "--accept-package-agreements",                              "接受所有软件包许可协议" },
    {               "--accept-source-agreements",                               "在源操作期间接受所有源协议" },
})
:addarg(clink.filematches)
:nofiles()

local install_parser = clink.argmatcher()
:_addexflags({
    opteq=true,
    common_flags,
    query_flags,
    source_flags,
    arch_locale_flags,
    { hide=true,    "-m"                .. file_matches },
    {               "--manifest"        .. file_matches,        " file",        "软件包清单的路径" },
    { hide=true,    "-v"                .. version_matches },
    {               "--version"         .. version_matches,     " version",     "使用指定版本；默认为最新版本" },
    {               "--scope"           .. scope_matches,       " scope",       "选择安装范围（用户或计算机）" },
    { hide=true,    "-i" },
    {               "--interactive",                                            "请求交互式安装；可能需要用户输入" },
    { hide=true,    "-h" },
    {               "--silent",                                                 "请求静默安装" },
    { hide=true,    "-o"                .. file_matches },
    {               "--log"             .. file_matches,        " file",        "日志位置（如果支持）" },
    {               "--override"        .. override_matches,    " string",      "覆盖传递给安装程序的参数" },
    { hide=true,    "-l"                .. location_matches },
    {               "--location"        .. location_matches,    " location",    "安装位置（如果支持）" },
    {               "--force",                                                  "覆盖安装程序哈希检查" },
    {               "--ignore-security-hash",                                   "忽略安装程序哈希检查失败" },
    {               "--ignore-local-archive-malware-scan",                      "忽略从本地清单安装归档类型软件包时执行的恶意软件扫描" },
    {               "--dependency-source" .. dependency_source_matches, " source", "使用指定源查找软件包依赖项" },
    {               "--accept-package-agreements",                              "接受所有软件包许可协议" },
    {               "--accept-source-agreements",                               "在源操作期间接受所有源协议" },
    {               "--no-upgrade",                                             "如果已安装的版本已存在，则跳过升级" },
    {               "--header"          .. header_matches,      " header",      "可选的 Windows-Package-Manager REST 源 HTTP 头" },
    { hide=true,    "-r"                .. file_matches },
    {               "--rename"          .. file_matches,        " file",        "重命名可执行文件的值（便携版）" },
})
:addarg({winget_complete})
:nofiles()

local __search_parser_flags = {
    query_flags,
    query_flags_more,
    source_flags,
    { hide=true,    "--accept-source-agreements" },
    {               "--header"          .. header_matches,      " header",      "可选的 Windows-Package-Manager REST 源 HTTP 头" },
    common_flags,
}

local list_parser = clink.argmatcher()
:_addexflags({
    opteq=true,
    __search_parser_flags,
    {               "--scope"           .. scope_matches,       " scope",       "选择已安装软件包的范围筛选器（用户或计算机）" },
})
:addarg({winget_complete})
:nofiles()

local search_parser = clink.argmatcher()
:_addexflags({
    opteq=true,
    __search_parser_flags,
})
:addarg({winget_complete})
:nofiles()

local settings_export_parser = clink.argmatcher()
:_addexflags({
    opteq=true,
    common_flags,
})
:nofiles()

local settings_parser = clink.argmatcher()
:_addexflags({
    {               "--enable"          .. setting_name_matches, " setting",    "启用特定的管理员设置" },
    {               "--disable"         .. setting_name_matches, " setting",    "禁用特定的管理员设置" },
})
:_addexarg({
    { "export" .. settings_export_parser, "以 JSON 格式导出设置" },
})
:nofiles()

local show_parser = clink.argmatcher()
:_addexflags({
    opteq=true,
    common_flags,
    query_flags,
    source_flags,
    arch_locale_flags,
    { hide=true,    "-m" .. file_matches },
    {               "--manifest"        .. file_matches,        " file",        "软件包清单的路径" },
    { hide=true,    "-v" .. version_matches },
    {               "--version"         .. version_matches,     " version",     "使用指定版本；默认为最新版本" },
    {               "--versions",                                               "显示软件包的可用版本" },
    {               "--header"          .. header_matches,      " header",      "可选的 Windows-Package-Manager REST 源 HTTP 头" },
    {               "--accept-source-agreements",                               "在源操作期间接受所有源协议" },
})
:addarg({winget_complete})
:nofiles()

local source_add_parser = clink.argmatcher()
:_addexflags({
    opteq=true,
    common_flags,
    { hide=true,    "-n"                .. add_source_matches },
    {               "--name"            .. add_source_matches,  " name",        "源的名称" },
    { hide=true,    "-a"                .. url_matches },
    {               "--arg"             .. url_matches,         " url",         "传递给源的参数" },
    { hide=true,    "-t"                .. type_matches },
    {               "--type"            .. type_matches,        " type",        "源的类型" },
    {               "--header"          .. header_matches,      " header",      "可选的 Windows-Package-Manager REST 源 HTTP 头" },
    {               "--accept-source-agreements",                               "在源操作期间接受所有源协议" },
})
:addarg(add_source_matches)
:nofiles()
-- REVIEW: :nofiles() isn't really accurate here, but I don't see a good way to
-- accurately support the command's syntax given that "-n" and "-a" are optional
-- but the "name" and "arg" arguments they refer to are required.  So input like
-- "winget source add -n name arg" is weird because "arg" ends up getting parsed
-- as being in the argmatcher's 1st arg position, because the "name" is an
-- argument to the "-n" flag, not an argument to the "winget add" command.

local source_list_parser = clink.argmatcher()
:_addexflags({
    opteq=true,
    common_flags,
    source_name_flags,
})
:addarg(source_matches)
:nofiles()

local source_update_parser = clink.argmatcher()
:_addexflags({
    opteq=true,
    common_flags,
    source_name_flags,
})
:addarg(source_matches)
:nofiles()

local source_remove_parser = clink.argmatcher()
:_addexflags({
    opteq=true,
    common_flags,
    source_name_flags,
})
:addarg(source_matches)
:nofiles()

local source_reset_parser = clink.argmatcher()
:_addexflags({
    opteq=true,
    common_flags,
    source_name_flags,
    {               "--force",                                                  "强制重置源" },
})
:addarg(source_matches)
:nofiles()

local source_export_parser = clink.argmatcher()
:_addexflags({
    opteq=true,
    source_name_flags,
    common_flags,
})
:addarg(source_matches)
:nofiles()

local source_parser = clink.argmatcher()
:_addexflags({
    opteq=true,
    common_flags,
})
:_addexarg({
    { "add"         .. source_add_parser,       " name arg [type]",             "添加新的源" },
    { "list"        .. source_list_parser,      " [name]",                      "列出当前源" },
    {   "ls"        .. source_list_parser },
    { "update"      .. source_update_parser,    " [name]",                      "更新当前源" },
    {   "refresh"   .. source_update_parser },
    { "remove"      .. source_remove_parser,    "移除当前源" },
    {   "rm"        .. source_remove_parser },
    { "reset"       .. source_reset_parser,     "重置源" },
    { "export"      .. source_export_parser,    "导出当前源" },
    arghelper.make_arg_hider_func({"ls", "refresh", "rm"}),
})
:nofiles()

local uninstall_parser = clink.argmatcher()
:_addexflags({
    opteq=true,
    common_flags,
    query_flags,
    query_flags_more,
    source_flags,
    { hide=true,    "-m"                .. file_matches },
    {               "--manifest"        .. file_matches,        " file",        "软件包清单的路径" },
    {               "--product-code"    .. productcode_matches, " code",        "使用产品代码筛选" },
    { hide=true,    "-v"                .. version_matches },
    {               "--version"         .. version_matches,     " version",     "使用指定版本；默认为最新版本" },
    {               "--scope"           .. scope_matches,       " scope",       "选择已安装软件包的范围筛选器（用户或计算机）" },
    { hide=true,    "-i" } ,
    {               "--interactive",                                            "请求交互式安装；可能需要用户输入" },
    { hide=true,    "-h" } ,
    {               "--silent",                                                 "请求静默卸载" },
    {               "--force",                                                  "直接运行命令并继续处理非安全相关问题" },
    {               "--purge",                                                  "删除软件包目录中的所有文件和目录（便携版）" },
    {               "--preserve",                                               "保留软件包创建的所有文件和目录（便携版）" },
    { hide=true,    "-o"                .. file_matches },
    {               "--log"             .. file_matches,        " file",        "日志位置（如果支持）" },
    {               "--accept-source-agreements",                               "在源操作期间接受所有源协议" },
    {               "--header"          .. header_matches,      " header",      "可选的 Windows-Package-Manager REST 源 HTTP 头" },
})
:addarg({winget_complete})
:nofiles()

local upgrade_parser = clink.argmatcher()
:_addexflags({
    opteq=true,
    common_flags,
    query_flags,
    source_flags,
    arch_locale_flags,
    { hide=true,    "-m"                .. file_matches },
    {               "--manifest"        .. file_matches,        " file",        "软件包清单的路径" },
    { hide=true,    "-v"                .. version_matches },
    {               "--version"         .. version_matches,     " version",     "使用指定版本；默认为最新版本" },
    { hide=true,    "-i" },
    {               "--interactive",                                            "请求交互式安装；可能需要用户输入" },
    { hide=true,    "-h" },
    {               "--silent",                                                 "请求静默安装" },
    {               "--purge",                                                  "删除软件包目录中的所有文件和目录（便携版）" },
    { hide=true,    "-o"                .. file_matches },
    {               "--log"             .. file_matches,        " file",        "日志位置（如果支持）" },
    {               "--override"        .. override_matches,    " string",      "覆盖传递给安装程序的参数" },
    { hide=true,    "-l"                .. location_matches },
    {               "--location"        .. location_matches,    " location",    "安装位置（如果支持）" },
    {               "--scope"           .. scope_matches,       " scope",       "选择已安装软件包的范围筛选器（用户或计算机）" },
    {               "--ignore-security-hash",                                   "忽略安装程序哈希检查失败" },
    {               "--ignore-local-archive-malware-scan",                      "忽略从本地清单安装归档类型软件包时执行的恶意软件扫描" },
    {               "--force",                                                  "直接运行命令并继续处理非安全相关问题" },
    {               "--accept-package-agreements",                              "接受所有软件包许可协议" },
    {               "--accept-source-agreements",                               "在源操作期间接受所有源协议" },
    {               "--header"          .. header_matches,      " header",      "可选的 Windows-Package-Manager REST 源 HTTP 头" },
    { hide=true,    "-r" },
    { hide=true,    "--recurse" },
    {               "--all",                                                    "将所有已安装软件包更新到最新版本（如果可用）" },
    { hide=true,    "-u" },
    { hide=true,    "--unknown" },
    {               "--include-unknown",                                        "即使无法确定当前版本也升级软件包" },
})
:addarg({winget_complete})
:loop(1)

local validate_parser = clink.argmatcher()
:_addexflags({
    opteq=true,
    common_flags,
    {               "--manifest"        .. file_matches,        " file",        "要验证的清单的路径" },

})
:addarg(clink.filematches)
:nofiles()

local complete_parser = clink.argmatcher()
:_addexflags({
    nosort=true,
    {               "--word"            .. empty_arg,           " word",        "请求补全前提供的值" },
    {               "--commandline"     .. empty_arg,           " text",        "用于补全的完整命令行" },
    {               "--position"        .. empty_arg,           " num",         "光标在命令行中的位置" },
})
:nofiles()

--------------------------------------------------------------------------------
-- Define the winget argmatcher.

local winget_command_data_table = {
    { "install",    install_parser,     "add",          disp=" [query]",    desc="安装指定的软件包" },
    { "show",       show_parser,        "view",         disp=" [query]",    desc="显示软件包信息" },
    { "source",     source_parser,                      disp=" command",    desc="管理软件包源" },
    { "search",     search_parser,      "find",         disp=" [query]",    desc="查找并显示软件包基本信息" },
    { "list",       list_parser,        "ls",           disp=" [query]",    desc="显示已安装的软件包" },
    { "upgrade",    upgrade_parser,     "update",       disp=" [query]",    desc="显示并执行可用更新" },
    { "uninstall",  uninstall_parser,   "rm", "remove", disp=" [query]",    desc="卸载指定的软件包" },
    { "hash",       hash_parser,                        disp=" file",       desc="计算安装程序文件的哈希值" },
    { "validate",   validate_parser,                    disp=" manifest",   desc="验证清单文件" },
    { "settings",   settings_parser,    "config",       disp=" [command]",  desc="打开设置或配置管理员设置" },
    { "features",   features_parser,                                        desc="显示实验性功能状态" },
    { "export",     export_parser,                      disp=" output",     desc="导出已安装软件包列表" },
    { "import",     import_parser,                      disp=" importfile", desc="安装文件中的所有软件包" },
    { nil,          complete_parser,    "complete" },
}

-- luacheck: max line length 100

local hidden_aliases = {}
local winget_commands = {}

for _,c in ipairs(winget_command_data_table) do
    local i = 3
    while c[i] do
        if c[2] then
            table.insert(winget_commands, c[i]..c[2])
        else
            table.insert(winget_commands, c[i])
        end
        table.insert(hidden_aliases, c[i])
        i = i + 1
    end
    if c[1] then
        if c[2] then
            table.insert(winget_commands, { c[1]..c[2], c.disp or "", c.desc })
        else
            table.insert(winget_commands, { c[1], c.disp or "", c.desc })
        end
    end
end

table.insert(winget_commands, arghelper.make_arg_hider_func(hidden_aliases))

clink.argmatcher("winget")
:_addexarg(winget_commands)
:_addexflags({
    common_flags,
    { hide=true,    "-v" },
    {               "--version",    "显示工具版本" },
    {               "--info",       "显示工具的常规信息" },
})
