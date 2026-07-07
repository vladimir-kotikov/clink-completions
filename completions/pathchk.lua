--------------------------------------------------------------------------------
-- Clink argmatcher for pathchk (uutils / GNU coreutils)
--

clink.argmatcher("pathchk")
:adddescriptions({
    ["-p"] = { "检查所有路径的可移植性" },
    ["--portability"] = { "检查所有路径的可移植性" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-p", "--portability",
    "--help", "--version",
})
