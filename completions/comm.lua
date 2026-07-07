--------------------------------------------------------------------------------
-- Clink argmatcher for comm (uutils / GNU coreutils)
--

clink.argmatcher("comm")
:addarg(clink.filematches)
:adddescriptions({
    ["-1"] = { "抑制第1列（文件1独有的行）" },
    ["-2"] = { "抑制第2列（文件2独有的行）" },
    ["-3"] = { "抑制第3列（两个文件共有的行）" },
    ["--check-order"] = { "检查输入是否已排序" },
    ["--nocheck-order"] = { "不检查输入是否已排序" },
    ["--total"] = { "在末尾输出总计摘要" },
    ["-z"] = { "用 NUL 字节终止行" },
    ["--zero-terminated"] = { "用 NUL 字节终止行" },
    ["--output-delimiter"] = { " STR", "使用 STR 作为输出列分隔符" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-1",
    "-2",
    "-3",
    "--check-order", "--nocheck-order",
    "--total",
    "-z", "--zero-terminated",
    "--output-delimiter",
    "--help", "--version",
})
