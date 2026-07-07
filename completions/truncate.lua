--------------------------------------------------------------------------------
-- Clink argmatcher for truncate (uutils / GNU coreutils)
--

clink.argmatcher("truncate")
:addarg(clink.filematches)
:adddescriptions({
    ["-c"] = { "不创建任何文件" },
    ["--no-create"] = { "不创建任何文件" },
    ["-o"] = { "将 SIZE 视为 I/O 块数而非字节数" },
    ["--io-blocks"] = { "将 SIZE 视为 I/O 块数而非字节数" },
    ["-r"] = { " file", "以参考文件的大小为基准" },
    ["--reference"] = { " file", "以参考文件的大小为基准" },
    ["-s"] = { " SIZE", "设置或调整文件大小" },
    ["--size"] = { " SIZE", "设置或调整文件大小" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-c", "--no-create",
    "-o", "--io-blocks",
    "-r"..clink.filematches,
    "--reference="..clink.filematches,
    "-s"..(clink.argmatcher():addarg({fromhistory=true})),
    "--size="..(clink.argmatcher():addarg({fromhistory=true})),
    "--help", "--version",
})
