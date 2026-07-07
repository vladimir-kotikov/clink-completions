--------------------------------------------------------------------------------
-- Clink argmatcher for tr (uutils / GNU coreutils)
--

clink.argmatcher("tr")
:adddescriptions({
    ["-c"] = { "使用 SET1 的补集" },
    ["--complement"] = { "使用 SET1 的补集" },
    ["-d"] = { "删除 SET1 中的字符，不进行替换" },
    ["--delete"] = { "删除 SET1 中的字符，不进行替换" },
    ["-s"] = { "将重复字符压缩为单个字符" },
    ["--squeeze-repeats"] = { "将重复字符压缩为单个字符" },
    ["-t"] = { "将 SET1 截断为 SET2 的长度" },
    ["--truncate-set1"] = { "将 SET1 截断为 SET2 的长度" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-c", "--complement",
    "-d", "--delete",
    "-s", "--squeeze-repeats",
    "-t", "--truncate-set1",
    "--help", "--version",
})
