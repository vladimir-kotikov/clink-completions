--------------------------------------------------------------------------------
-- Clink argmatcher for mkdir (uutils / GNU coreutils)
--

clink.argmatcher("mkdir")
:addarg(clink.dirmatches)
:adddescriptions({
    ["-p"] = { "创建父目录（如需要）" },
    ["--parents"] = { "创建父目录（如需要）" },
    ["-m"] = { " arg", "设置权限模式" },
    ["--mode"] = { " arg", "设置权限模式" },
    ["-v"] = { "显示创建的每个目录" },
    ["--verbose"] = { "显示创建的每个目录" },
    ["-Z"] = { "设置 SELinux 安全上下文" },
    ["--context"] = { "设置 SELinux 安全上下文" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-p", "--parents",
    "-m"..(clink.argmatcher():addarg()),
    "--mode="..(clink.argmatcher():addarg()),
    "-v", "--verbose",
    "-Z", "--context",
    "--help", "--version",
})
