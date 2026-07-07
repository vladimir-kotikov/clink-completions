--------------------------------------------------------------------------------
-- Clink argmatcher for nl (uutils / GNU coreutils)
--

local num_arg = clink.argmatcher():addarg({fromhistory=true})

clink.argmatcher("nl")
:addarg(clink.filematches)
:adddescriptions({
    ["-b"] = { " style", "正文行编号样式：a=所有行, t=非空行, n=不编号, pREGEXP=匹配正则的行" },
    ["--body-numbering"] = { " style", "正文行编号样式：a=所有行, t=非空行, n=不编号, pREGEXP=匹配正则的行" },
    ["-d"] = { " delim", "逻辑页分隔符（两个字符）" },
    ["--section-delimiter"] = { " delim", "逻辑页分隔符（两个字符）" },
    ["-f"] = { " style", "页脚行编号样式：a=所有行, t=非空行, n=不编号, pREGEXP=匹配正则的行" },
    ["--footer-numbering"] = { " style", "页脚行编号样式：a=所有行, t=非空行, n=不编号, pREGEXP=匹配正则的行" },
    ["-h"] = { " style", "页眉行编号样式：a=所有行, t=非空行, n=不编号, pREGEXP=匹配正则的行" },
    ["--header-numbering"] = { " style", "页眉行编号样式：a=所有行, t=非空行, n=不编号, pREGEXP=匹配正则的行" },
    ["-i"] = { " num", "行号递增步长" },
    ["--line-increment"] = { " num", "行号递增步长" },
    ["-l"] = { " num", "将连续 num 行空行合并为一行" },
    ["--join-blank-lines"] = { " num", "将连续 num 行空行合并为一行" },
    ["-n"] = { " format", "行号格式：ln=居左, rn=居右, rz=居右补零" },
    ["--number-format"] = { " format", "行号格式：ln=居左, rn=居右, rz=居右补零" },
    ["-p"] = { "在每页开头不重置行号" },
    ["--no-renumber"] = { "在每页开头不重置行号" },
    ["-s"] = { " string", "行号与正文之间的分隔字符串" },
    ["--number-separator"] = { " string", "行号与正文之间的分隔字符串" },
    ["-v"] = { " num", "起始行号" },
    ["--starting-line-number"] = { " num", "起始行号" },
    ["-w"] = { " num", "行号宽度" },
    ["--number-width"] = { " num", "行号宽度" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-b",
    "--body-numbering=",
    "-d",
    "--section-delimiter=",
    "-f",
    "--footer-numbering=",
    "-h",
    "--header-numbering=",
    "-i"..num_arg,
    "--line-increment="..num_arg,
    "-l"..num_arg,
    "--join-blank-lines="..num_arg,
    "-n"..(clink.argmatcher():addarg({"ln", "rn", "rz"})),
    "--number-format="..(clink.argmatcher():addarg({"ln", "rn", "rz"})),
    "-p", "--no-renumber",
    "-s",
    "--number-separator=",
    "-v"..num_arg,
    "--starting-line-number="..num_arg,
    "-w"..num_arg,
    "--number-width="..num_arg,
    "--help", "--version",
})
