--------------------------------------------------------------------------------
-- Clink argmatcher for tail (uutils / GNU coreutils)
--

local num_arg = clink.argmatcher():addarg({fromhistory=true})

clink.argmatcher("tail")
:addarg(clink.filematches)
:adddescriptions({
    ["-c"] = { " NUM", "输出最后 NUM 个字节" },
    ["--bytes"] = { " NUM", "输出最后 NUM 个字节" },
    ["-f"] = { "持续输出追加的数据" },
    ["--follow"] = { "持续输出追加的数据" },
    ["-F"] = { "等同于 --follow=name --retry" },
    ["-n"] = { " NUM", "输出最后 NUM 行（默认 10）" },
    ["--lines"] = { " NUM", "输出最后 NUM 行（默认 10）" },
    ["--max-unchanged-stats"] = { " N", "连续 N 次 stat 未变则重新打开文件" },
    ["--pid"] = { " PID", "进程 PID 终止后退出" },
    ["-q"] = { "不打印文件头信息" },
    ["--quiet"] = { "不打印文件头信息" },
    ["--silent"] = { "不打印文件头信息" },
    ["--retry"] = { "文件不可访问时持续重试打开" },
    ["-s"] = { " SEC", "每隔 SEC 秒检查一次（默认 1.0）" },
    ["--sleep-interval"] = { " SEC", "每隔 SEC 秒检查一次（默认 1.0）" },
    ["-v"] = { "始终打印文件头信息" },
    ["--verbose"] = { "始终打印文件头信息" },
    ["-z"] = { "用 NUL 字节终止行" },
    ["--zero-terminated"] = { "用 NUL 字节终止行" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-c"..num_arg, "--bytes="..num_arg,
    "-f", "--follow",
    "-F",
    "-n"..num_arg, "--lines="..num_arg,
    "--max-unchanged-stats="..num_arg,
    "--pid="..num_arg,
    "-q", "--quiet", "--silent",
    "--retry",
    "-s"..num_arg, "--sleep-interval="..num_arg,
    "-v", "--verbose",
    "-z", "--zero-terminated",
    "--help", "--version",
})
