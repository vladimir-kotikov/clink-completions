--------------------------------------------------------------------------------
-- Clink argmatcher for sum (uutils / GNU coreutils)
--

clink.argmatcher("sum")
:addarg(clink.filematches)
:adddescriptions({
    ["-r"] = { "使用 BSD 校验和算法（默认）" },
    ["-s"] = { "使用 System V 校验和算法" },
    ["--sysv"] = { "使用 System V 校验和算法" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-r",
    "-s", "--sysv",
    "--help", "--version",
})
