--------------------------------------------------------------------------------
-- Clink argmatcher for csplit (uutils / GNU coreutils)
--

local num_arg = clink.argmatcher():addarg({fromhistory=true})

clink.argmatcher("csplit")
:addarg(clink.filematches)
:adddescriptions({
    ["-b"] = { " format", "使用 sprintf 格式作为后缀" },
    ["--suffix-format"] = { " format", "使用 sprintf 格式作为后缀" },
    ["-f"] = { " prefix", "使用指定前缀而非 'xx'" },
    ["--prefix"] = { " prefix", "使用指定前缀而非 'xx'" },
    ["-k"] = { "出错时不删除输出文件" },
    ["--keep-files"] = { "出错时不删除输出文件" },
    ["-n"] = { " digits", "使用指定位数的数字后缀（默认 2）" },
    ["--digits"] = { " digits", "使用指定位数的数字后缀（默认 2）" },
    ["-s"] = { "不打印输出文件大小的计数" },
    ["--quiet"] = { "不打印输出文件大小的计数" },
    ["--silent"] = { "不打印输出文件大小的计数" },
    ["-z"] = { "删除空输出文件" },
    ["--elide-empty-files"] = { "删除空输出文件" },
    ["--suppress-matched"] = { "在输出中省略与模式匹配的行" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-b"..(clink.argmatcher():addarg({fromhistory=true})),
    "--suffix-format="..(clink.argmatcher():addarg({fromhistory=true})),
    "-f"..(clink.argmatcher():addarg({fromhistory=true})),
    "--prefix="..(clink.argmatcher():addarg({fromhistory=true})),
    "-k", "--keep-files",
    "-n"..num_arg,
    "--digits="..num_arg,
    "-s", "--quiet", "--silent",
    "-z", "--elide-empty-files",
    "--suppress-matched",
    "--help", "--version",
})
