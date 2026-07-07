--------------------------------------------------------------------------------
-- Clink argmatcher for shuf (uutils / GNU coreutils)
--

local num_arg = clink.argmatcher():addarg({fromhistory=true})

clink.argmatcher("shuf")
:addarg(clink.filematches)
:adddescriptions({
    ["-e"] = { "将每个命令行参数视为输入行" },
    ["--echo"] = { "将每个命令行参数视为输入行" },
    ["-i"] = { " lo-hi", "将 lo 到 hi 范围内的数字作为输入" },
    ["--input-range"] = { " lo-hi", "将 lo 到 hi 范围内的数字作为输入" },
    ["-n"] = { " count", "最多输出 count 行" },
    ["--head-count"] = { " count", "最多输出 count 行" },
    ["-o"] = { " file", "将输出写入文件而非标准输出" },
    ["--output"] = { " file", "将输出写入文件而非标准输出" },
    ["--random-source"] = { " file", "从指定文件获取随机字节" },
    ["-r"] = { "允许输出行重复" },
    ["--repeat"] = { "允许输出行重复" },
    ["-z"] = { "以 NUL 字符结束行，而非换行符" },
    ["--zero-terminated"] = { "以 NUL 字符结束行，而非换行符" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-e", "--echo",
    "-i"..(clink.argmatcher():addarg({fromhistory=true})),
    "--input-range="..(clink.argmatcher():addarg({fromhistory=true})),
    "-n"..num_arg,
    "--head-count="..num_arg,
    "-o"..clink.filematches,
    "--output="..clink.filematches,
    "--random-source="..clink.filematches,
    "-r", "--repeat",
    "-z", "--zero-terminated",
    "--help", "--version",
})
