--------------------------------------------------------------------------------
-- Clink argmatcher for paste (uutils / GNU coreutils)
--

clink.argmatcher("paste")
:addarg(clink.filematches)
:adddescriptions({
    ["-d"] = { " LIST", "使用 LIST 中的字符作为分隔符（默认 TAB）" },
    ["--delimiters"] = { " LIST", "使用 LIST 中的字符作为分隔符（默认 TAB）" },
    ["-s"] = { "一次粘贴一个文件，而非并行" },
    ["--serial"] = { "一次粘贴一个文件，而非并行" },
    ["-z"] = { "用 NUL 字节终止行" },
    ["--zero-terminated"] = { "用 NUL 字节终止行" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-d", "--delimiters",
    "-s", "--serial",
    "-z", "--zero-terminated",
    "--help", "--version",
})
