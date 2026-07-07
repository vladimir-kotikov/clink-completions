--------------------------------------------------------------------------------
-- Clink argmatcher for numfmt (uutils / GNU coreutils)
--

local num_arg = clink.argmatcher():addarg({fromhistory=true})

clink.argmatcher("numfmt")
:addarg(clink.filematches)
:adddescriptions({
    ["--debug"] = { "显示调试信息" },
    ["-d"] = { " delim", "设置字段分隔符（替代空格/TAB）" },
    ["--delimiter"] = { " delim", "设置字段分隔符（替代空格/TAB）" },
    ["--field"] = { " fields", "要转换的字段（例如 1,2,3 或 1-3）" },
    ["--format"] = { " format", "输出格式" },
    ["--from"] = { " unit", "输入单位：none, si, iec, iec-i, auto" },
    ["--from-unit"] = { " size", "输入数字的单位大小" },
    ["--grouping"] = { "使用数字分组（千位分隔符）" },
    ["--header"] = { " N", "跳过前 N 行（视为标题）" },
    ["--invalid"] = { " mode", "无效输入的处理方式：abort, fail, warn, ignore" },
    ["--padding"] = { " N", "右对齐时的最小宽度" },
    ["--round"] = { " method", "舍入方法：up, down, from-zero, towards-zero, nearest" },
    ["--suffix"] = { " suffix", "输出后缀（例如 B, KB, MB）" },
    ["--to"] = { " unit", "输出单位：none, si, iec, iec-i" },
    ["--to-unit"] = { " size", "输出时使用此基本单位大小" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "--debug",
    "-d",
    "--delimiter=",
    "--field=",
    "--format=",
    "--from="..(clink.argmatcher():addarg({"none", "si", "iec", "iec-i", "auto"})),
    "--from-unit="..num_arg,
    "--grouping",
    "--header="..num_arg,
    "--invalid="..(clink.argmatcher():addarg({"abort", "fail", "warn", "ignore"})),
    "--padding="..num_arg,
    "--round="..(clink.argmatcher():addarg({"up", "down", "from-zero", "towards-zero", "nearest"})),
    "--suffix=",
    "--to="..(clink.argmatcher():addarg({"none", "si", "iec", "iec-i"})),
    "--to-unit="..num_arg,
    "--help", "--version",
})
