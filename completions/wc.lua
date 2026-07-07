--------------------------------------------------------------------------------
-- Clink argmatcher for wc (uutils / GNU coreutils)
--

clink.argmatcher("wc")
:addarg(clink.filematches)
:adddescriptions({
    ["-c"] = { "打印字节数" },
    ["--bytes"] = { "打印字节数" },
    ["-m"] = { "打印字符数" },
    ["--chars"] = { "打印字符数" },
    ["-l"] = { "打印行数" },
    ["--lines"] = { "打印行数" },
    ["-L"] = { "打印最长行的长度" },
    ["--max-line-length"] = { "打印最长行的长度" },
    ["-w"] = { "打印单词数" },
    ["--words"] = { "打印单词数" },
    ["--files0-from"] = { " FILE", "从 FILE 中读取以 NUL 分隔的文件名" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-c", "--bytes",
    "-m", "--chars",
    "-l", "--lines",
    "-L", "--max-line-length",
    "-w", "--words",
    "--files0-from="..(clink.argmatcher():addarg(clink.filematches)),
    "--help", "--version",
})
