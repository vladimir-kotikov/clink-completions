--------------------------------------------------------------------------------
-- Clink argmatcher for cut (uutils / GNU coreutils)
--

clink.argmatcher("cut")
:addarg(clink.filematches)
:adddescriptions({
    ["-b"] = { " LIST", "仅选择 LIST 指定的字节" },
    ["--bytes"] = { " LIST", "仅选择 LIST 指定的字节" },
    ["-c"] = { " LIST", "仅选择 LIST 指定的字符" },
    ["--characters"] = { " LIST", "仅选择 LIST 指定的字符" },
    ["-d"] = { " DELIM", "使用 DELIM 作为字段分隔符（默认 TAB）" },
    ["--delimiter"] = { " DELIM", "使用 DELIM 作为字段分隔符（默认 TAB）" },
    ["-f"] = { " LIST", "仅选择 LIST 指定的字段" },
    ["--fields"] = { " LIST", "仅选择 LIST 指定的字段" },
    ["--complement"] = { "选择 LIST 指定的补集" },
    ["-s"] = { "不打印不包含分隔符的行" },
    ["--only-delimited"] = { "不打印不包含分隔符的行" },
    ["-z"] = { "用 NUL 字节终止行" },
    ["--zero-terminated"] = { "用 NUL 字节终止行" },
    ["--output-delimiter"] = { " STR", "使用 STR 作为输出分隔符" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-b", "--bytes",
    "-c", "--characters",
    "-d", "--delimiter",
    "-f", "--fields",
    "--complement",
    "-s", "--only-delimited",
    "-z", "--zero-terminated",
    "--output-delimiter",
    "--help", "--version",
})
