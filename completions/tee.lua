--------------------------------------------------------------------------------
-- Clink argmatcher for tee (uutils / GNU coreutils)
--

clink.argmatcher("tee")
:addarg(clink.filematches)
:adddescriptions({
    ["-a"] = { "追加到文件，不覆盖" },
    ["--append"] = { "追加到文件，不覆盖" },
    ["-i"] = { "忽略中断信号" },
    ["--ignore-interrupts"] = { "忽略中断信号" },
    ["-p"] = { "对管道错误进行诊断" },
    ["--output-error"] = { " arg", "设置输出错误处理模式" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-a", "--append",
    "-i", "--ignore-interrupts",
    "-p",
    "--output-error="..(clink.argmatcher():addarg({"warn", "warn-nopipe", "exit", "exit-nopipe"})),
    "--help", "--version",
})
