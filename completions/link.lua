--------------------------------------------------------------------------------
-- Clink argmatcher for link (uutils / GNU coreutils)
--

clink.argmatcher("link")
:adddescriptions({
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "--help", "--version",
})
