--------------------------------------------------------------------------------
-- Clink argmatcher for base32 (uutils / GNU coreutils)
--

clink.argmatcher("base32")
:addarg(clink.filematches)
:adddescriptions({
    ["-d"] = { "解码数据" },
    ["--decode"] = { "解码数据" },
    ["-i"] = { "解码时忽略非字母字符" },
    ["--ignore-garbage"] = { "解码时忽略非字母字符" },
    ["-w"] = { " cols", "编码行在 cols 个字符后换行（0=不换行，默认 76）" },
    ["--wrap"] = { " cols", "编码行在 cols 个字符后换行（0=不换行，默认 76）" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-d", "--decode",
    "-i", "--ignore-garbage",
    "-w"..(clink.argmatcher():addarg({fromhistory=true})),
    "--wrap="..(clink.argmatcher():addarg({fromhistory=true})),
    "--help", "--version",
})
