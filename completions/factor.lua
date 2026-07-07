--------------------------------------------------------------------------------
-- Clink argmatcher for factor (GNU coreutils)
--

clink.argmatcher("factor")
:adddescriptions({
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "--help", "--version",
})
