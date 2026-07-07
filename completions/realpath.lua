--------------------------------------------------------------------------------
-- Clink argmatcher for realpath (uutils / GNU coreutils)
--

clink.argmatcher("realpath")
:addarg(clink.filematches)
:adddescriptions({
    ["-e"] = { "所有路径组件必须存在" },
    ["--canonicalize-existing"] = { "所有路径组件必须存在" },
    ["-m"] = { "路径组件不需要存在" },
    ["--canonicalize-missing"] = { "路径组件不需要存在" },
    ["-L"] = { "跟随符号链接（默认）" },
    ["--logical"] = { "跟随符号链接（默认）" },
    ["-P"] = { "不跟随符号链接，使用物理路径" },
    ["--physical"] = { "不跟随符号链接，使用物理路径" },
    ["-q"] = { "静默模式，不显示错误" },
    ["--quiet"] = { "静默模式，不显示错误" },
    ["-s"] = { "只打印路径，抑制错误信息" },
    ["--strip"] = { "只打印路径，抑制错误信息" },
    ["-z"] = { "用空字符（NUL）分隔输出，不使用换行符" },
    ["--zero"] = { "用空字符（NUL）分隔输出，不使用换行符" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-e", "--canonicalize-existing",
    "-m", "--canonicalize-missing",
    "-L", "--logical",
    "-P", "--physical",
    "-q", "--quiet",
    "-s", "--strip",
    "-z", "--zero",
    "--help", "--version",
})
