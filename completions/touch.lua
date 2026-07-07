--------------------------------------------------------------------------------
-- Clink argmatcher for touch (uutils / GNU coreutils)
--

clink.argmatcher("touch")
:addarg(clink.filematches)
:adddescriptions({
    ["-a"] = { "仅更改访问时间" },
    ["-c"] = { "不创建任何文件" },
    ["--no-create"] = { "不创建任何文件" },
    ["-d"] = { " arg", "使用指定日期字符串" },
    ["--date"] = { " arg", "使用指定日期字符串" },
    ["-m"] = { "仅更改修改时间" },
    ["-r"] = { " arg", "使用指定文件的时间戳" },
    ["--reference"] = { " arg", "使用指定文件的时间戳" },
    ["-t"] = { " arg", "使用指定的时间戳" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-a",
    "-c", "--no-create",
    "-d"..(clink.argmatcher():addarg()),
    "--date="..(clink.argmatcher():addarg()),
    "-m",
    "-r"..(clink.argmatcher():addarg(clink.filematches)),
    "--reference="..(clink.argmatcher():addarg(clink.filematches)),
    "-t"..(clink.argmatcher():addarg()),
    "--help", "--version",
})
