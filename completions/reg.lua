require("arghelper")

local function keyname_impl(restricted, _, word_index, line_state, builder, _)
    local matches = {}
    local info = line_state:getwordinfo(word_index)
    if info then
        local word = line_state:getline():sub(info.offset, line_state:getcursor() - 1) or ""

        local machine = word:match("^(\\\\[^\\]+\\)") or ""
        word = word:sub(#machine + 1)

        if not word:find("\\") then
            matches.nosort = true
            if word:match("^[Hh][Kk][LlCcUu]") then
                if restricted then
                    table.insert(matches, machine.."HKLM")
                else
                    table.insert(matches, machine.."HKCU")
                    table.insert(matches, machine.."HKLM")
                    table.insert(matches, machine.."HKCC")
                    table.insert(matches, machine.."HKCR")
                    table.insert(matches, machine.."HKU")
                end
            else
                if restricted then
                    table.insert(matches, machine.."HKEY_LOCAL_MACHINE")
                else
                    table.insert(matches, machine.."HKEY_CURRENT_USER")
                    table.insert(matches, machine.."HKEY_LOCAL_MACHINE")
                    table.insert(matches, machine.."HKEY_CURRENT_CONFIG")
                    table.insert(matches, machine.."HKEY_CLASSES_ROOT")
                    table.insert(matches, machine.."HKEY_USERS")
                end
            end
        elseif restricted and word:upper():find("^HKLM\\+[^\\]*$") then
            table.insert(matches, machine.."HKLM\\SOFTWARE")
        elseif restricted and word:upper():find("^HKEY_LOCAL_MACHINE\\+[^\\]*$") then
            table.insert(matches, machine.."HKEY_LOCAL_MACHINE\\SOFTWARE")
        elseif not restricted or
                word:upper():find("^HKLM\\SOFTWARE\\") or
                word:upper():find("^HKEY_LOCAL_MACHINE\\SOFTWARE\\") then
            local lookup = word:gsub("\\+[^\\]*$", "")
            local command = string.format('2>nul reg.exe query "%s"', lookup)
            local f = io.popen(command)
            if f then
                clink.matches_are_files(true)
                local root = (word:match("^([^\\]+)\\?") or ""):upper()
                for line in f:lines() do
                    if line ~= "" then
                        if line:sub(1, #machine) == machine then
                            line = line:sub(#machine + 1)
                        end
                        if root then
                            line = line:gsub("^[^\\]+", "")
                        end
                        local key = root and root..line or line
                        table.insert(matches, machine..key)
                    end
                end
                f:close()
            end
        end
        builder:setsuppressappend()
    end
    return matches
end

local function keyname_any(word, word_index, line_state, builder, user_data)
    return keyname_impl(false, word, word_index, line_state, builder, user_data)
end

local function keyname_hklm_software(word, word_index, line_state, builder, user_data)
    return keyname_impl(true, word, word_index, line_state, builder, user_data)
end

local user_data_keyname

local function onarg_keyname(arg_index, word, _, _, user_data)
    if arg_index == 1 then
        local ud = user_data.shared_user_data and user_data.shared_user_data or user_data
        ud.keyname = word
    elseif arg_index == 0 and word == "/v" then
        user_data_keyname = user_data.keyname
    end
end

local function valuename_impl(_, _, _, _, user_data)
    local matches = {}
    if user_data then
        local keyname = user_data.shared_user_data and user_data.shared_user_data.keyname or user_data_keyname
        local command = string.format('2>nul reg.exe query "%s" /v *', keyname)
        local f = io.popen(command)
        if f then
            for line in f:lines() do
                local m, t = line:match("^    +([^<>|&%%]+)    (REG[^%s]+)")
                if m then
                    table.insert(matches, { match=m, description=t })
                end
            end
            f:close()
        end
    end
    return matches
end

local function filematches_byext(word, ext)
    if clink.filematchesexact then
        local matches = clink.dirmatches(word) or {}
        for _, m in ipairs(clink.filematchesexact(word.."*."..ext)) do
            table.insert(matches, m)
        end
        return matches
    else
        return clink.filematches(word)
    end
end

local function filematches_hiv(word)
    return filematches_byext(word, "hiv")
end

local function filematches_reg(word)
    return filematches_byext(word, "reg")
end

local valuename = clink.argmatcher():addarg(valuename_impl)

local sep = clink.argmatcher():addarg({fromhistory=true})
local find = clink.argmatcher():addarg({fromhistory=true})
local data = clink.argmatcher():addarg({fromhistory=true})
local types = clink.argmatcher():addarg({
    nosort=true,
    "REG_DWORD",
    "REG_SZ",
    "REG_EXPAND_SZ",
    "REG_QWORD",
    "REG_MULTI_SZ",
    "REG_BINARY",
    "REG_NONE",
})

local common_flags = {
    { "/?",                 "显示帮助" },
    { "/reg:32",            "指定应使用 32 位注册表视图访问该键" },
    { "/reg:64",            "指定应使用 64 位注册表视图访问该键" },
    { hide=true, "/reg:"..clink.argmatcher():_addexarg({
        { "32",                 "指定应使用 32 位注册表视图访问该键" },
        { "64",                 "指定应使用 64 位注册表视图访问该键" },
    }) },
}

local query = clink.argmatcher():_addexflags({
})
:addarg({
    onarg=onarg_keyname,
    keyname_any,
})
:_addexflags({
    onarg=onarg_keyname,
    common_flags,
    { "/v"..valuename, " ValueName", "查询特定的注册表键值" },
    { "/ve",                "查询默认值或空值名称 (Default)" },
    { "/s",                 "递归查询所有子键和值（类似 dir /s）" },
    { "/se"..sep, " Sep",   "指定 REG_MULTI_SZ 的分隔符（1个字符，默认是 \\0）" },
    { "/f"..find, " Data",  "指定要搜索的数据或模式（默认是 *）" },
    { "/k",                 "仅在键名中搜索" },
    { "/d",                 "仅在数据中搜索" },
    { "/c",                 "使用区分大小写的搜索" },
    { "/e",                 "仅返回精确匹配的搜索结果" },
    { "/t"..types, " Type", "指定注册表值的数据类型（默认是所有类型）" },
    { "/z",                 "详细模式：显示值名称类型的数字等效值" },
})
:nofiles()

local add = clink.argmatcher():_addexflags({
    onarg=onarg_keyname,
    common_flags,
    { "/v"..valuename, " ValueName", "要在所选键下添加的值名称" },
    { "/ve",                "为该键添加空值名称 (Default)" },
    { "/t"..types, " Type", "要添加的类型（默认是 REG_SZ）" },
    { "/s"..sep, " Sep",    "指定 REG_MULTI_SZ 的一个字符作为分隔符（默认是 \\0）" },
    { "/d"..data, " Data",  "要分配给正在添加的注册表值名称的数据" },
    { "/f",                 "强制覆盖现有注册表项而不提示" },
})
:addarg({
    onarg=onarg_keyname,
    keyname_any,
})
:nofiles()

local delete = clink.argmatcher():_addexflags({
    onarg=onarg_keyname,
    common_flags,
    { "/v"..valuename, " ValueName", "删除指定键下的值名称" },
    { "/ve",                "删除空值名称的值 (Default)" },
    { "/va",                "删除指定键下的所有值" },
    { "/f",                 "强制删除而不提示" },
})
:addarg({
    onarg=onarg_keyname,
    keyname_any,
})
:nofiles()

local copy = clink.argmatcher():_addexflags({
    common_flags,
    { "/s",                 "复制所有子键和值" },
    { "/f",                 "强制复制而不提示" },
})
:addarg(keyname_any)
:addarg(keyname_any)
:nofiles()

local save = clink.argmatcher():_addexflags({
    common_flags,
    { "/y",                 "强制覆盖现有文件而不提示" },
})
:addarg(keyname_any)
:addarg(filematches_hiv)
:nofiles()

local restore = clink.argmatcher():_addexflags({
    common_flags,
})
:addarg(keyname_any)
:addarg(filematches_hiv)
:nofiles()

local load = clink.argmatcher():_addexflags({
    common_flags,
})
:addarg(keyname_any)
:addarg(filematches_hiv)
:nofiles()

local unload = clink.argmatcher():_addexflags({
    { "/?",                 "显示帮助" },
})
:addarg(keyname_any)
:nofiles()

local compare = clink.argmatcher():_addexflags({
    onarg=onarg_keyname,
    common_flags,
    { "/v"..valuename, " ValueName", "要在所选键下比较的值名称（默认是所有）" },
    { "/ve",                "比较空值名称的值 (Default)" },
    { "/s",                 "比较所有子键和值" },
    { "/oa",                "输出所有差异和匹配项" },
    { "/od",                "仅输出差异（默认）" },
    { "/os",                "仅输出匹配项" },
    { "/on",                "无输出（退出码 0=相同, 1=失败, 2=不同）" },
})
:addarg({
    onarg=onarg_keyname,
    keyname_any,
})
:addarg(keyname_any)
:nofiles()

local export = clink.argmatcher():_addexflags({
    common_flags,
    { "/y",                 "强制覆盖现有文件而不提示" },
})
:addarg(keyname_any)
:addarg(filematches_reg)
:nofiles()

local import = clink.argmatcher():_addexflags({
    common_flags,
})
:addarg(filematches_reg)
:nofiles()

local flags_query = clink.argmatcher():_addexflags({
    common_flags,
    { "/s",                 "递归查询所有子键和值（类似 dir /s）" },
})
:nofiles()

local flags_set = clink.argmatcher():_addexflags({
    common_flags,
    { "/s",                 "递归设置子键的标志" },
})
:addarg("dont_virtualize", "dont_silent_fail", "recurse_flag")
:loop()

local flags_commands = {
    "query" .. flags_query,
    "set" .. flags_set,
}

local flags = clink.argmatcher():_addexflags({
})
:addarg(keyname_hklm_software)
:addarg(flags_commands)
:nofiles()

local commands = {
    { "query"   .. query,   " KeyName",             "查询键或值" },
    { "add"     .. add,     " KeyName",             "添加键或值" },
    { "delete"  .. delete,  " KeyName",             "删除键或值" },
    { "copy"    .. copy,    " KeyName1 KeyName2",   "复制键和值" },
    { "save"    .. save,    " KeyName FileName",    "将配置单元保存到文件" },
    { "restore" .. restore, " KeyName FileName",    "从文件还原配置单元" },
    { "load"    .. load,    " KeyName FileName",    "将配置单元文件加载到键名中" },
    { "unload"  .. unload,  " KeyName",             "从键名中卸载已加载的配置单元文件" },
    { "compare" .. compare, " KeyName1 KeyName2",   "比较键和值" },
    { "export"  .. export,  " KeyName FileName",    "将键和值导出到 .reg 文件" },
    { "import"  .. import,  " FileName",            "从 .reg 文件导入键和值" },
    { "flags"   .. flags,   " KeyName [query|set]", "查询或设置键的标志" },
}

clink.argmatcher("reg")
:_addexflags({
    { "/?",                 "显示帮助" },
})
:_addexarg(commands)
