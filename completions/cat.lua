--------------------------------------------------------------------------------
-- Clink argmatcher for cat (uutils / GNU coreutils)
--

clink.argmatcher("cat")
:addarg(clink.filematches)
:adddescriptions({
    ["-A"] = { "等同于 -vET" },
    ["--show-all"] = { "等同于 -vET" },
    ["-b"] = { "对非空输出行编号" },
    ["--number-nonblank"] = { "对非空输出行编号" },
    ["-e"] = { "等同于 -vE" },
    ["-E"] = { "在每行末尾显示 $" },
    ["--show-ends"] = { "在每行末尾显示 $" },
    ["-n"] = { "对所有输出行编号" },
    ["--number"] = { "对所有输出行编号" },
    ["-s"] = { "抑制重复的空输出行" },
    ["--squeeze-blank"] = { "抑制重复的空输出行" },
    ["-t"] = { "等同于 -vT" },
    ["-T"] = { "将制表符显示为 ^I" },
    ["--show-tabs"] = { "将制表符显示为 ^I" },
    ["-u"] = { "无缓冲的 stdin (忽略)" },
    ["-v"] = { "使用 ^ 和 M- 表示法显示非打印字符" },
    ["--show-nonprinting"] = { "使用 ^ 和 M- 表示法显示非打印字符" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-A", "--show-all",
    "-b", "--number-nonblank",
    "-e",
    "-E", "--show-ends",
    "-n", "--number",
    "-s", "--squeeze-blank",
    "-t",
    "-T", "--show-tabs",
    "-u",
    "-v", "--show-nonprinting",
    "--help", "--version",
})
