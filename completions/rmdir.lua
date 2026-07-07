--------------------------------------------------------------------------------
-- Clink argmatcher for rmdir (uutils / GNU coreutils)
--

clink.argmatcher("rmdir")
:addarg(clink.dirmatches)
:adddescriptions({
    ["-p"] = { "删除目录及其所有空的祖先目录" },
    ["--parents"] = { "删除目录及其所有空的祖先目录" },
    ["--ignore-fail-on-non-empty"] = { "忽略因目录非空导致的失败" },
    ["-v"] = { "显示处理的每个目录" },
    ["--verbose"] = { "显示处理的每个目录" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-p", "--parents",
    "--ignore-fail-on-non-empty",
    "-v", "--verbose",
    "--help", "--version",
})
