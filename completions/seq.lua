--------------------------------------------------------------------------------
-- Clink argmatcher for seq (uutils / GNU coreutils)
--

local num_arg = clink.argmatcher():addarg({fromhistory=true})

clink.argmatcher("seq")
:adddescriptions({
    ["-f"] = { " format", "使用 printf 风格的浮点格式" },
    ["--format"] = { " format", "使用 printf 风格的浮点格式" },
    ["-s"] = { " string", "使用指定字符串分隔数字（默认换行符）" },
    ["--separator"] = { " string", "使用指定字符串分隔数字（默认换行符）" },
    ["-w"] = { "通过用前导零填充使数字等宽" },
    ["--equal-width"] = { "通过用前导零填充使数字等宽" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-f"..(clink.argmatcher():addarg({fromhistory=true})),
    "--format="..(clink.argmatcher():addarg({fromhistory=true})),
    "-s"..(clink.argmatcher():addarg({fromhistory=true})),
    "--separator="..(clink.argmatcher():addarg({fromhistory=true})),
    "-w", "--equal-width",
    "--help", "--version",
})
