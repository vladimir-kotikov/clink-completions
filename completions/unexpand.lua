--------------------------------------------------------------------------------
-- Clink argmatcher for unexpand (uutils / GNU coreutils)
--

local num_arg = clink.argmatcher():addarg({fromhistory=true})

clink.argmatcher("unexpand")
:addarg(clink.filematches)
:adddescriptions({
    ["-a"] = { "转换所有空格序列，而非仅行首空格" },
    ["--all"] = { "转换所有空格序列，而非仅行首空格" },
    ["--first-only"] = { "仅转换行首的空格序列" },
    ["-t"] = { " tabs", "设置制表符位置（逗号分隔）" },
    ["--tabs"] = { " tabs", "设置制表符位置（逗号分隔）" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-a", "--all",
    "--first-only",
    "-t"..num_arg,
    "--tabs=",
    "--help", "--version",
})
