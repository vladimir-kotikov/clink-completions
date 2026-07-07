--------------------------------------------------------------------------------
-- Clink argmatcher for env (uutils / GNU coreutils)
--

clink.argmatcher("env")
:adddescriptions({
    ["-i"] = { "从空环境开始" },
    ["--ignore-environment"] = { "从空环境开始" },
    ["-u"] = { " arg", "从环境中移除变量" },
    ["--unset"] = { " arg", "从环境中移除变量" },
    ["-0"] = { "用空字符（NUL）分隔输出行" },
    ["--null"] = { "用空字符（NUL）分隔输出行" },
    ["-C"] = { " arg", "切换到指定目录再执行命令" },
    ["--chdir"] = { " arg", "切换到指定目录再执行命令" },
    ["-S"] = { "分割字符串处理多个参数" },
    ["--split-string"] = { "分割字符串处理多个参数" },
    ["-v"] = { "显示程序的详细调试信息" },
    ["--debug"] = { "显示程序的详细调试信息" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-i", "--ignore-environment",
    "-u"..(clink.argmatcher():addarg()),
    "--unset="..(clink.argmatcher():addarg()),
    "-0", "--null",
    "-C"..(clink.argmatcher():addarg(clink.dirmatches)),
    "--chdir="..(clink.argmatcher():addarg(clink.dirmatches)),
    "-S", "--split-string",
    "-v", "--debug",
    "--help", "--version",
})
