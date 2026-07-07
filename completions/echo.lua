--------------------------------------------------------------------------------
-- Clink argmatcher for echo (uutils / GNU coreutils)
--

clink.argmatcher("echo")
:adddescriptions({
    ["-n"] = { "不输出尾随换行符" },
    ["-e"] = { "启用反斜杠转义解释" },
    ["-E"] = { "禁用反斜杠转义解释（默认）" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-n",
    "-e",
    "-E",
    "--help", "--version",
})
