--------------------------------------------------------------------------------
-- DIRX argmatcher for Clink.

--------------------------------------------------------------------------------
-- Helper functions.

local function args(...) -- luacheck: no unused
    return clink.argmatcher():addarg(...)
end

local function flags(...) -- luacheck: no unused
    return clink.argmatcher():addflags(...)
end

--------------------------------------------------------------------------------
-- Backward compatibility.

require('arghelper')

--------------------------------------------------------------------------------
-- Multi-character flags.

local mcf = require('multicharflags')

local attrs = mcf.addcharflagsarg(clink.argmatcher(), {
    { "r",          "只读文件" },
    { "h",          "隐藏文件" },
    { "s",          "系统文件" },
    { "a",          "待归档文件" },
    { "d",          "目录" },
    { "i",          "未建立内容索引的文件" },
    { "j",          "重解析点（junction 助记符）" },
    { "l",          "重解析点（link 助记符）" },
    { "e",          "加密文件" },
    { "t",          "临时文件" },
    { "p",          "稀疏文件" },
    { "c",          "压缩文件" },
    { "o",          "脱机文件" },
    { "+",          "前缀，表示"任意"" },
    { "-",          "前缀，表示"非"" },
})

local quash = mcf.addcharflagsarg(clink.argmatcher(), {
    { "v",          "隐藏卷信息" },
    { "h",          "隐藏标题" },
    { "s",          "隐藏摘要" },
    { "-",          "前缀，表示隐藏下一个类型（默认）" },
    { "+",          "前缀，表示取消隐藏下一个类型" },
})

local skips = mcf.addcharflagsarg(clink.argmatcher(), {
    { "d",          "跳过隐藏目录（与 '-s' 一起使用时）" },
    { "j",          "跳过接合点（与 '-s' 一起使用时）" },
    { "r",          "跳过没有备用数据流的文件" },
    { "-",          "前缀，表示跳过下一个类型（默认）" },
    { "+",          "前缀，表示取消跳过一个类型" },
})

local sorts = mcf.addcharflagsarg(clink.argmatcher(), {
    { "n",          "按名称排序[如果未指定 'e' 则包含扩展名]（字母顺序）" },
    { "e",          "按扩展名排序（字母顺序）" },
    { "g",          "目录优先分组" },
    { "d",          "按日期/时间排序（最旧优先）" },
    { "s",          "按大小排序（最小优先）" },
    { "c",          "按压缩比排序" },
    { "a",          "简单 ASCII 顺序（'10' 排在 '2' 之前）" },
    { "u",          "不排序" },
    { "r",          "反转所有选项的排序" },
    { "-",          "前缀，表示反转排序" },
})

local sizes = mcf.addcharflagsarg(clink.argmatcher(), {
    { "a",          "使用分配大小" },
    { "c",          "使用压缩大小" },
    { "f",          "使用文件大小（默认）" },
    { "S",          "显示长文件大小" },
})

local times = mcf.addcharflagsarg(clink.argmatcher(), {
    { "a",          "使用访问时间" },
    { "c",          "使用创建时间" },
    { "w",          "使用写入时间（默认）" },
    { "T",          "显示长日期和时间" },
})

--------------------------------------------------------------------------------
-- Argument sub-parsers.

local helps = clink.argmatcher():_addexarg({
    { "alphabetical", "按字母顺序显示标志的帮助文本" },
    { "colors",     "文件列表颜色编码的帮助" },
    { "colorsamples", "显示 ANSI 颜色代码" },
    { "defaultcolors", "打印默认颜色字符串" },
    { "icons",      "图标和 Nerd Fonts 的帮助" },
    { "pictures",   "格式图片的帮助" },
    { "printallicons", "打印所有图标的列表" },
    { "regex",      "正则表达式语法的帮助" },
})

local hexcode = clink.argmatcher():_addexarg({
    nosort=true,
    { "002e",       "'..' 两个句点" },
    { "2026",       "'…' 省略号" },
    { "2192",       "'→' 向右箭头" },
    { "25b8",       "'▸' 向右三角形" },
    { "00bb",       "'»' 向右双箭头" },
})

local pictures = clink.argmatcher():_addexarg({
    fromhistory=true,
    { "PICTURE",    "格式图片（参见 '-? pictures'）" },
})

local when = clink.argmatcher():addarg("always", "auto", "never")
local jwhen = clink.argmatcher():addarg({ nosort=true, "always", "fat", "normal", "never" })
local morec = clink.argmatcher():addarg({ fromhistory=true })
local cols = clink.argmatcher():addarg({ fromhistory=true, "80", "100", "120" })
local levels = clink.argmatcher():addarg({ fromhistory=true, 1, 2, 3, 4, 5 })
local globs = clink.argmatcher():addarg({ fromhistory=true })
local sizestyles = clink.argmatcher():addarg({
    nosort=true,
    "mini", "short", "normal",
})
local timestyles = clink.argmatcher():addarg({
    nosort=true,
    "locale", "mini", "iso", "compact", "short", "long-iso", "normal", "full", "relative",
})

--------------------------------------------------------------------------------
-- DIRX argmatcher.
-- luacheck: no max line length
local list_of_flags = {
    { "-?", helps, " [topic]",  "显示帮助文本" },
    { "-V",                     "显示版本信息" },
    { "--version" },
    { "--nix" },            --  "Use Unix-y default options"
    { hide_unless="--nix", "--no-nix" },
    { "--debug" },
    { hide_unless="--debug", "--no-debug" },
    { hide=true, "--",          "" },

    -- Display options.
    { "-1",                     "每行显示一列" },
    { "-2",                     "每行显示两列" },
    { "-4",                     "每行显示四列" },
    { "-a",                     "显示所有文件（包括隐藏文件等）" },
    { "--all" },
    { "-b",                     "简洁模式；仅显示名称" },
    { "--bare" },
    { hide_unless="/b -b --bare", "--no-bare" },
    { "-B",                     "选择默认选项以实现简洁的近乎简洁的视图" },
    { "--almost-bare" },
    { "-c",                     "使用颜色显示" },
    { "--color" },
    { "--no-color" },
    { "-g",                     "显示 git 文件状态" },
    { "-gg",                    "显示 git 仓库状态" },
    { "--git" },
    { hide_unless="/g -g /gg -gg --git --git-repos", "--no-git" },
    { "--git-repos" },
    { hide_unless="/g -g /gg -gg --git --git-repos", "--no-git-repos" },
    { "-G",                     "--wide 的同义词" },
    { "--grid" },
    { hide_unless="/G -G /w -w --grid --wide --nix", "--no-grid" },
    { "-i",                     "显示文件图标" },
    { "--icons" },
    { "--icons=", when, "when", "" },
    { hide_unless="/i -i --icons", "--no-icons" },
    { "-k",                     "使用色阶高亮显示" },
    { "--color-scale" },
    { opteq=true, "--color-scale=", args("all", "size", "time"), "which", "" },
    { hide_unless="/k -k --color-scale", "--no-color-scale" },
    { "-l",                     "长格式模式；每行一个文件" },
    { "--long" },
    { hide_unless="/l -l --long", "--no-long" },
    { "-n",                     "使用普通列表格式" },
    { "-p",                     "分页输出" },
    { "-Q",                     "重置隐藏的输出类型" },
    { "-Q:", quash, "types",    "隐藏输出类型" },
    { opteq=true, "--quash=", quash, "types", "" },
    { "-R",                     "--recurse 的同义词" },
    { "-s",                     "子目录；递归列出文件" },
    { "--recurse" },
    { "-u",                     "使用量模式；目录大小信息" },
    { "--usage" },
    { "-v",                     "纵向排序列" },
    { "--vertical" },
    { "--horizontal" },
    { "-w",                     "宽列表模式" },
    { "--wide" },
    { hide_unless="/w -w /G -G --wide --grid --nix", "--no-wide" },
    { "-z",                     "使用 FAT 列表格式" },
    { "--fat" },
    { hide_unless="/z -z --fat", "--no-fat" },
    { opteq=true, "--color-scale-mode=", args("fixed", "gradient"), "mode", "" },
    { "--hyperlinks" },
    { hide_unless="--hyperlinks", "--no-hyperlinks" },
    { "--tree" },
    { hide_unless="--tree", "--no-tree" },

    -- Filtering and sorting options.
    { "-a:", attrs, "attrs",    "按属性筛选文件" },
    { "-A",                     "显示所有文件，但隐藏 . 和 .." },
    { "--almost-all" },
    { "-h",                     "隐藏 . 和 .. 目录" },
    { "-I", globs, " glob",     "要忽略的文件 Glob 模式" },
    { "--ignore-glob=", globs, "glob", "" },
    { "-L", levels, " depth",   "限制 -s 递归的深度" },
    { opteq=true, "--levels=", levels, "depth", "" },
    { hide=true, opteq=true, "--level=", levels, "depth", "" },
    { hide=true, "-o",          "" },
    { "-o:", sorts, "options",  "按排序顺序列出文件" },
    { "-X",                     "重置跳过的类型" },
    { "-X:", skips, "types",    "在 -s 期间跳过的类型" },
    { opteq=true, "--skip=", skips, "types", "" },
    { "--digit-sort" },
    { "--git-ignore" },
    { hide_unless="--git-ignore", "--no-git-ignore" },
    { "--hide-dot-files" },
    { hide_unless="--hide-dot-files --nix", "--no-hide-dot-files" },
    { "--numeric-sort" },
    { "--reverse" },
    { hide_unless="--reverse", "--no-reverse" },
    { "--string-sort" },
    { "--word-sort" },

    -- Field options.
    { "-C",                     "显示压缩比" },
    { "--ratio" },
    { hide_unless="/C -C --ratio", "--no-ratio" },
    { "-q",                     "显示文件所有者" },
    { "--owner" },
    { hide_unless="/q -q --owner", "--no-owner" },
    { "-r",                     "显示备用数据流" },
    { hide=true, "-:",          "" },
    { "--streams" },
    { hide_unless="/r -r /: -: --streams", "--no-streams" },
    { "-S",                     "在宽模式下显示文件大小" },
    { "--size" },
    { "--no-size" },
    { "-Sa",                    "使用分配大小" },
    { "-Sc",                    "使用压缩大小" },
    { "-Sf",                    "使用文件大小（默认）" },
    { hide=true, "-S:", sizes, "which", "" },
    { "-t",                     "显示文件属性" },
    { "--attributes" },
    { hide_unless="/t -t --attributes --nix", "--no-attributes" },
    { "-T",                     "在宽模式下显示文件时间" },
    { "--time" },
    { "--no-time" },
    { "-Ta",                    "使用访问时间" },
    { "-Tc",                    "使用创建时间" },
    { "-Tw",                    "使用写入时间（默认）" },
    { hide=true, "-T:", times, "which", "" },
    { "-x",                     "显示 8.3 短文件名" },
    { "--short-names" },
    { hide_unless="/x -x --short-names", "--no-short-names" },

    -- Formatting options.
    { "-,",                     "显示千位分隔符（默认）" },
    { "-f", pictures, " picture", "指定格式图片" },
    { "-F",                     "显示完整文件路径" },
    { "--full-paths" },
    { "-j",                     "在 FAT 列表格式中对齐名称" },
    { "-J",                     "在非 FAT 列表格式中对齐名称" },
    { "--justify" },
    { "--justify=", jwhen, "when", "" },
    { "--lower" },
    { "-SS",                    "显示长文件大小" },
    { "-TT",                    "显示长日期和时间" },
    { "-W", cols, " cols",      "覆盖屏幕宽度" },
    { opteq=true, "--width=", cols, "cols", "" },
    { "-Y",                     "缩写时间" },
    { "-Z",                     "缩写文件大小" },
    { "--bare-relative" },
    { hide_unless="--bare-relative", "--no-bare-relative" },
    { "--classify" },
    { "--no-classify" },        -- Don't hide because it can be used to disable dir brackets.
    { "--compact" },
    { hide_unless="--compact", "--no-compact" },
    { "--escape-codes" },
    { "--escape-codes=", when, "when", "" },
    { hide_unless="--no-fit-columns", "--fit-columns" },
    { "--no-fit-columns" },
    { "--mini-bytes" },
    { hide_unless="--mini-bytes", "--no-mini-bytes" },
    { "--mini-decimal" },
    { hide_unless="--mini-decimal", "--no-mini-decimal" },
    { "--mini-header" },
    { hide_unless="--mini-header --nix", "--no-mini-header" },
    { "--more-colors=", morec, "list", "" },
    { opteq=true, "--nerd-fonts=", args("2", "3"), "ver", "" },
    { opteq=true, "--pad-icons=", args("1", "2", "3", "4"), "spaces", "" },
    { "--relative" },
    { hide_unless="--relative", "--no-relative" },
    { opteq=true, "--size-style=", sizestyles, "style", "" },
    { opteq=true, "--time-style=", timestyles, "style", "" },
    { opteq=true, "--truncate-char=", hexcode, "hexchar", "" },
    { "--utf8" },
    { hide_unless="--utf8", "--no-utf8" },

    { hide=true, "-,-",         "" },
    { hide=true, "-a-",         "" },
    { hide=true, "-b-",         "" },
    { hide=true, "-c-",         "" },
    { hide=true, "-C-",         "" },
    { hide=true, "-F-",         "" },
    { hide=true, "-h-",         "" },
    { hide=true, "-i-",         "" },
    { hide=true, "-j-",         "" },
    { hide=true, "-J-",         "" },
    { hide=true, "-k-",         "" },
    { hide=true, "-K-",         "" },
    { hide=true, "-l-",         "" },
    { hide=true, "-n-",         "" },
    { hide=true, "-p-",         "" },
    { hide=true, "-q-",         "" },
    { hide=true, "-r-",         "" },
    { hide=true, "-s-",         "" },
    { hide=true, "-S-",         "" },
    { hide=true, "-t-",         "" },
    { hide=true, "-T-",         "" },
    { hide=true, "-u-",         "" },
    { hide=true, "-v-",         "" },
    { hide=true, "-w-",         "" },
    { hide=true, "-x-",         "" },
    { hide=true, "-Y-",         "" },
    { hide=true, "-z-",         "" },
    { hide=true, "-Z-",         "" },
}

local function onarg_dirxcmd(arg_index, word, word_index, line_state, user_data) -- luacheck: no unused
    if arg_index == 0 and not user_data.done_dirxcmd then
        user_data.done_dirxcmd = true
        user_data.present = user_data.present or {} -- Cooperates with arghelper.lua!
        for _,w in ipairs(string.explode(os.getenv("DIRXCMD") or "")) do
            user_data.present[w] = true
        end
    end
end

-- IMPORTANT: If slash_flags has an onarg callback, then it will replace the one
-- from minus_flags, which would mess up both the DIRXCMD processing and also
-- the hide_unless stuff in general.
local minus_flags = { concat_one_letter_flags=true, onarg=onarg_dirxcmd }
local slash_flags = { concat_one_letter_flags=true }

local function copy_vars(entry, tbl)
    tbl.hide = entry.hide
    tbl.hide_unless = entry.hide_unless
    tbl.opteq = entry.opteq
    return tbl
end

for _, entry in ipairs(list_of_flags) do
    local minus = entry[1]
    local slash = entry[1]:gsub("^%-", "/")
    local long = entry[1]:find("^%-%-") and true

    local len = #entry
    if len == 2 or len == 3 then
        table.insert(minus_flags, copy_vars(entry, { minus, entry[2] }))
        if not long then
            table.insert(slash_flags, copy_vars(entry, { slash, entry[2] }))
        end
    elseif len == 4 or long then
        if entry[2] then
            table.insert(minus_flags, copy_vars(entry, { minus..entry[2], entry[3], entry[4] }))
        else
            table.insert(minus_flags, copy_vars(entry, { minus, entry[3], entry[4] }))
        end
        if not long then
            table.insert(slash_flags, copy_vars(entry, { slash..entry[2], entry[3], entry[4] }))
        end
    else
        error("unrecognized flag entry format.")
    end
end

clink.argmatcher("dirx")
:_addexflags(minus_flags)
:_addexflags(slash_flags)
