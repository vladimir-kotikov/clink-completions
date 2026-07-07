--------------------------------------------------------------------------------
-- Clink argmatcher for tac (uutils / GNU coreutils)
--

clink.argmatcher("tac")
:addarg(clink.filematches)
:adddescriptions({
    ["-b"] = { "将分隔符附加到记录之前（而非之后）" },
    ["--before"] = { "将分隔符附加到记录之前（而非之后）" },
    ["-r"] = { "将分隔符解释为正则表达式" },
    ["--regex"] = { "将分隔符解释为正则表达式" },
    ["-s"] = { " SEP", "使用 SEP 作为记录分隔符（默认换行符）" },
    ["--separator"] = { " SEP", "使用 SEP 作为记录分隔符（默认换行符）" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-b", "--before",
    "-r", "--regex",
    "-s", "--separator",
    "--help", "--version",
})
