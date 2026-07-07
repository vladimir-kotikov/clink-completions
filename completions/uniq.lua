--------------------------------------------------------------------------------
-- Clink argmatcher for uniq (uutils / GNU coreutils)
--

local num_arg = clink.argmatcher():addarg({fromhistory=true})

clink.argmatcher("uniq")
:addarg(clink.filematches)
:adddescriptions({
    ["-c"] = { "统计每行的出现次数" },
    ["--count"] = { "统计每行的出现次数" },
    ["-d"] = { "仅打印重复行" },
    ["--repeated"] = { "仅打印重复行" },
    ["-D"] = { "打印所有重复行" },
    ["--all-repeated"] = { "打印所有重复行" },
    ["-f"] = { " N", "跳过前 N 个字段" },
    ["--skip-fields"] = { " N", "跳过前 N 个字段" },
    ["-i"] = { "比较时忽略大小写" },
    ["--ignore-case"] = { "比较时忽略大小写" },
    ["-s"] = { " N", "跳过前 N 个字符" },
    ["--skip-chars"] = { " N", "跳过前 N 个字符" },
    ["-u"] = { "仅打印不重复的行" },
    ["--unique"] = { "仅打印不重复的行" },
    ["-z"] = { "用 NUL 字节终止行" },
    ["--zero-terminated"] = { "用 NUL 字节终止行" },
    ["-w"] = { " N", "仅比较每行的前 N 个字符" },
    ["--check-chars"] = { " N", "仅比较每行的前 N 个字符" },
    ["--group"] = { " mode", "分组显示模式：separate, prepend, append, both" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-c", "--count",
    "-d", "--repeated",
    "-D", "--all-repeated",
    "-f"..num_arg, "--skip-fields="..num_arg,
    "-i", "--ignore-case",
    "-s"..num_arg, "--skip-chars="..num_arg,
    "-u", "--unique",
    "-z", "--zero-terminated",
    "-w"..num_arg, "--check-chars="..num_arg,
    "--group",
    "--help", "--version",
})
