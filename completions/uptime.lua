--------------------------------------------------------------------------------
-- Clink argmatcher for uptime (GNU coreutils)
--

clink.argmatcher("uptime")
:adddescriptions({
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "--help", "--version",
})
