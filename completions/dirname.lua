--------------------------------------------------------------------------------
-- Clink argmatcher for dirname (uutils / GNU coreutils)
--

clink.argmatcher("dirname")
:adddescriptions({
    ["-z"] = { "用空字符（NUL）分隔输出，不使用换行符" },
    ["--zero"] = { "用空字符（NUL）分隔输出，不使用换行符" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-z", "--zero",
    "--help", "--version",
})
