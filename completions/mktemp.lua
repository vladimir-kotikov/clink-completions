--------------------------------------------------------------------------------
-- Clink argmatcher for mktemp (uutils / GNU coreutils)
--

clink.argmatcher("mktemp")
:adddescriptions({
    ["-d"] = { "创建目录而非文件" },
    ["--directory"] = { "创建目录而非文件" },
    ["-p"] = { " arg", "指定临时文件目录" },
    ["--tmpdir"] = { " arg", "指定临时文件目录" },
    ["-q"] = { "静默模式，执行失败时不显示错误" },
    ["--quiet"] = { "静默模式，执行失败时不显示错误" },
    ["-t"] = { " arg", "指定模板" },
    ["-u"] = { "试运行，不实际创建文件或目录" },
    ["--dry-run"] = { "试运行，不实际创建文件或目录" },
    ["--suffix"] = { " arg", "追加后缀到模板" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-d", "--directory",
    "-p"..(clink.argmatcher():addarg(clink.dirmatches)),
    "--tmpdir="..(clink.argmatcher():addarg(clink.dirmatches)),
    "-q", "--quiet",
    "-t"..(clink.argmatcher():addarg()),
    "-u", "--dry-run",
    "--suffix="..(clink.argmatcher():addarg()),
    "--help", "--version",
})
