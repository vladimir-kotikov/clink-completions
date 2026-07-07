--------------------------------------------------------------------------------
-- Clink argmatcher for fold (uutils / GNU coreutils)
--

local num_arg = clink.argmatcher():addarg({fromhistory=true})

clink.argmatcher("fold")
:addarg(clink.filematches)
:adddescriptions({
    ["-b"] = { "按字节计数而非列计数" },
    ["--bytes"] = { "按字节计数而非列计数" },
    ["-s"] = { "仅在空白处断行" },
    ["--spaces"] = { "仅在空白处断行" },
    ["-w"] = { " WIDTH", "设置最大行宽为 WIDTH（默认 80）" },
    ["--width"] = { " WIDTH", "设置最大行宽为 WIDTH（默认 80）" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-b", "--bytes",
    "-s", "--spaces",
    "-w"..num_arg, "--width="..num_arg,
    "--help", "--version",
})
