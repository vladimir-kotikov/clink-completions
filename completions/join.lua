--------------------------------------------------------------------------------
-- Clink argmatcher for join (uutils / GNU coreutils)
--

clink.argmatcher("join")
:addarg(clink.filematches)
:adddescriptions({
    ["-a"] = { " FILENUM", "为文件 FILENUM 中无法配对的行也打印" },
    ["-e"] = { " EMPTY", "用 EMPTY 替换缺失的输入字段" },
    ["-i"] = { "比较时忽略大小写" },
    ["--ignore-case"] = { "比较时忽略大小写" },
    ["-j"] = { " FIELD", "等同于 -1 FIELD -2 FIELD" },
    ["-o"] = { " FORMAT", "按 FORMAT 指定输出格式" },
    ["-t"] = { " CHAR", "使用 CHAR 作为输入/输出字段分隔符" },
    ["-v"] = { " FILENUM", "仅打印文件 FILENUM 中无法配对的行" },
    ["-1"] = { " FIELD", "按文件1的第 FIELD 个字段连接" },
    ["-2"] = { " FIELD", "按文件2的第 FIELD 个字段连接" },
    ["--check-order"] = { "检查输入是否已排序" },
    ["--nocheck-order"] = { "不检查输入是否已排序" },
    ["--header"] = { "将每文件的第一行视为字段标题" },
    ["-z"] = { "用 NUL 字节终止行" },
    ["--zero-terminated"] = { "用 NUL 字节终止行" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-a", "-e",
    "-i", "--ignore-case",
    "-j", "-o", "-t",
    "-v",
    "-1", "-2",
    "--check-order", "--nocheck-order",
    "--header",
    "-z", "--zero-terminated",
    "--help", "--version",
})
