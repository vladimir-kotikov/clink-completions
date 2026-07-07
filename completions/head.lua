--------------------------------------------------------------------------------
-- Clink argmatcher for head (uutils / GNU coreutils)
--

local num_arg = clink.argmatcher():addarg({fromhistory=true})

clink.argmatcher("head")
:addarg(clink.filematches)
:adddescriptions({
    ["-c"] = { " NUM", "打印每个文件的前 NUM 个字节" },
    ["--bytes"] = { " NUM", "打印每个文件的前 NUM 个字节" },
    ["-n"] = { " NUM", "打印前 NUM 行（默认 10）" },
    ["--lines"] = { " NUM", "打印前 NUM 行（默认 10）" },
    ["-q"] = { "不打印文件头信息" },
    ["--quiet"] = { "不打印文件头信息" },
    ["--silent"] = { "不打印文件头信息" },
    ["-v"] = { "始终打印文件头信息" },
    ["--verbose"] = { "始终打印文件头信息" },
    ["-z"] = { "用 NUL 字节终止行" },
    ["--zero-terminated"] = { "用 NUL 字节终止行" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-c"..num_arg, "--bytes="..num_arg,
    "-n"..num_arg, "--lines="..num_arg,
    "-q", "--quiet", "--silent",
    "-v", "--verbose",
    "-z", "--zero-terminated",
    "--help", "--version",
})
