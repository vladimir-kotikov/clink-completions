--------------------------------------------------------------------------------
-- Clink argmatcher for true (GNU coreutils)
--

clink.argmatcher("true")
:adddescriptions({
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "--help", "--version",
})
