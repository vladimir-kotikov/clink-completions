--------------------------------------------------------------------------------
-- Clink argmatcher for expand (uutils / GNU coreutils)
--

local num_arg = clink.argmatcher():addarg({fromhistory=true})

clink.argmatcher("expand")
:addarg(clink.filematches)
:adddescriptions({
    ["-i"] = { "仅转换行首的制表符" },
    ["--initial"] = { "仅转换行首的制表符" },
    ["-t"] = { " tabs", "设置制表符位置（逗号分隔）" },
    ["--tabs"] = { " tabs", "设置制表符位置（逗号分隔）" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-i", "--initial",
    "-t"..num_arg,
    "--tabs=",
    "--help", "--version",
})
