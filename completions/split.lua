--------------------------------------------------------------------------------
-- Clink argmatcher for split (uutils / GNU coreutils)
--

local num_arg = clink.argmatcher():addarg({fromhistory=true})
local chunks_matcher = clink.argmatcher():addarg({fromhistory=true})

clink.argmatcher("split")
:addarg(clink.filematches)
:adddescriptions({
    ["-a"] = { " N", "生成长度为 N 的后缀（默认 2）" },
    ["--suffix-length"] = { " N", "生成长度为 N 的后缀（默认 2）" },
    ["-b"] = { " size", "每个输出文件的大小" },
    ["--bytes"] = { " size", "每个输出文件的大小" },
    ["-C"] = { " size", "每个输出文件的最大行大小" },
    ["--line-bytes"] = { " size", "每个输出文件的最大行大小" },
    ["-d"] = { "使用数字后缀而非字母后缀" },
    ["--numeric-suffixes"] = { "使用数字后缀而非字母后缀" },
    ["--filter"] = { " command", "将输出通过 shell 命令管道化" },
    ["-l"] = { " N", "每个输出文件的行数" },
    ["--lines"] = { " N", "每个输出文件的行数" },
    ["-n"] = { " chunks", "生成 chunks 个输出文件（N, l/N, r/N, l/K/N, r/K/N）" },
    ["--number"] = { " chunks", "生成 chunks 个输出文件（N, l/N, r/N, l/K/N, r/K/N）" },
    ["-t"] = { " sep", "将 sep 作为行分隔符而非换行符" },
    ["--separator"] = { " sep", "将 sep 作为行分隔符而非换行符" },
    ["-u"] = { "立即从输入复制到输出，不使用缓冲" },
    ["--unbuffered"] = { "立即从输入复制到输出，不使用缓冲" },
    ["--verbose"] = { "在打开每个输出文件前打印诊断信息" },
    ["--hex-suffixes"] = { "使用十六进制后缀" },
    ["--additional-suffix"] = { " suffix", "在所有文件名末尾追加后缀" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-a"..num_arg,
    "--suffix-length="..num_arg,
    "-b"..(clink.argmatcher():addarg({fromhistory=true})),
    "--bytes="..(clink.argmatcher():addarg({fromhistory=true})),
    "-C"..(clink.argmatcher():addarg({fromhistory=true})),
    "--line-bytes="..(clink.argmatcher():addarg({fromhistory=true})),
    "-d", "--numeric-suffixes",
    "--filter="..(clink.argmatcher():addarg({fromhistory=true})),
    "-l"..num_arg,
    "--lines="..num_arg,
    "-n"..chunks_matcher,
    "--number="..chunks_matcher,
    "-t"..(clink.argmatcher():addarg({fromhistory=true})),
    "--separator="..(clink.argmatcher():addarg({fromhistory=true})),
    "-u", "--unbuffered",
    "--verbose",
    "--hex-suffixes",
    "--additional-suffix="..(clink.argmatcher():addarg({fromhistory=true})),
    "--help", "--version",
})
