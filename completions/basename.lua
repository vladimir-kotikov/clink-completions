--------------------------------------------------------------------------------
-- Clink argmatcher for basename (uutils / GNU coreutils)
--

clink.argmatcher("basename")
:adddescriptions({
    ["-s"] = { " arg", "移除指定后缀" },
    ["--suffix"] = { " arg", "移除指定后缀" },
    ["-z"] = { "用空字符（NUL）分隔输出，不使用换行符" },
    ["--zero"] = { "用空字符（NUL）分隔输出，不使用换行符" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-s"..(clink.argmatcher():addarg()),
    "--suffix="..(clink.argmatcher():addarg()),
    "-z", "--zero",
    "--help", "--version",
})
