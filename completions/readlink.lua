--------------------------------------------------------------------------------
-- Clink argmatcher for readlink (uutils / GNU coreutils)
--

clink.argmatcher("readlink")
:addarg(clink.filematches)
:adddescriptions({
    ["-f"] = { "递归跟随所有符号链接，标准化所有组件" },
    ["--canonicalize"] = { "递归跟随所有符号链接，标准化所有组件" },
    ["-e"] = { "同上，但要求所有路径组件必须存在" },
    ["--canonicalize-existing"] = { "同上，但要求所有路径组件必须存在" },
    ["-m"] = { "同上，但路径组件不需要存在" },
    ["--canonicalize-missing"] = { "同上，但路径组件不需要存在" },
    ["-n"] = { "不输出尾随换行符" },
    ["--no-newline"] = { "不输出尾随换行符" },
    ["-q"] = { "静默模式，抑制大部分错误信息" },
    ["--quiet"] = { "静默模式，抑制大部分错误信息" },
    ["-s"] = { "静默模式，抑制大部分错误信息" },
    ["--silent"] = { "静默模式，抑制大部分错误信息" },
    ["-v"] = { "详细输出，显示错误信息" },
    ["--verbose"] = { "详细输出，显示错误信息" },
    ["-z"] = { "用空字符（NUL）分隔输出，不使用换行符" },
    ["--zero"] = { "用空字符（NUL）分隔输出，不使用换行符" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-f", "--canonicalize",
    "-e", "--canonicalize-existing",
    "-m", "--canonicalize-missing",
    "-n", "--no-newline",
    "-q", "--quiet",
    "-s", "--silent",
    "-v", "--verbose",
    "-z", "--zero",
    "--help", "--version",
})
