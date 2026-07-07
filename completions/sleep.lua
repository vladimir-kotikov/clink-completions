--------------------------------------------------------------------------------
-- Clink argmatcher for sleep (GNU coreutils)
--

clink.argmatcher("sleep")
:adddescriptions({
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "--help", "--version",
})
