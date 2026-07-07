--------------------------------------------------------------------------------
-- Clink argmatcher for pwd (GNU coreutils)
--

clink.argmatcher("pwd")
:adddescriptions({
    ["-L"] = { "使用逻辑路径，即使包含符号链接（默认）" },
    ["--logical"] = { "使用逻辑路径，即使包含符号链接（默认）" },
    ["-P"] = { "避免所有符号链接，使用物理路径" },
    ["--physical"] = { "避免所有符号链接，使用物理路径" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-L", "--logical",
    "-P", "--physical",
    "--help", "--version",
})
