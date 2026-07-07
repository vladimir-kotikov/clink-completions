--------------------------------------------------------------------------------
-- Clink argmatcher for nproc (GNU coreutils)
--

clink.argmatcher("nproc")
:adddescriptions({
    ["--all"] = { "打印已安装的处理器的数量" },
    ["--ignore"] = { " arg", "从总数中排除 N 个处理器" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "--all",
    "--ignore="..(clink.argmatcher():addarg({fromhistory=true})),
    "--help", "--version",
})
