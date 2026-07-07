--------------------------------------------------------------------------------
-- Clink argmatcher for stat (uutils / GNU coreutils)
--

clink.argmatcher("stat")
:addarg(clink.filematches)
:adddescriptions({
    ["-c"] = { " format", "使用指定的 FORMAT 字符串输出" },
    ["--format"] = { " format", "使用指定的 FORMAT 字符串输出" },
    ["-f"] = { "显示文件系统状态而非文件状态" },
    ["--file-system"] = { "显示文件系统状态而非文件状态" },
    ["-L"] = { "跟随符号链接" },
    ["--dereference"] = { "跟随符号链接" },
    ["-t"] = { "以简洁（一行）格式输出" },
    ["--terse"] = { "以简洁（一行）格式输出" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-c"..(clink.argmatcher():addarg({fromhistory=true})),
    "--format="..(clink.argmatcher():addarg({fromhistory=true})),
    "-f", "--file-system",
    "-L", "--dereference",
    "-t", "--terse",
    "--help", "--version",
})
