--------------------------------------------------------------------------------
-- Clink argmatcher for printenv (GNU coreutils)
--

clink.argmatcher("printenv")
:adddescriptions({
    ["-0"] = { "以 NUL 字符结尾每一行而非换行符" },
    ["--null"] = { "以 NUL 字符结尾每一行而非换行符" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-0", "--null",
    "--help", "--version",
})
