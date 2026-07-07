--------------------------------------------------------------------------------
-- Clink argmatcher for df (uutils / GNU coreutils)
--

local output_matcher = clink.argmatcher():addarg({"source", "fstype", "itotal", "iused", "iavail", "ipcent", "size", "used", "avail", "pcent", "file", "target"})

clink.argmatcher("df")
:addarg(clink.filematches)
:adddescriptions({
    ["-a"] = { "显示所有文件系统，包括大小为 0 的伪文件系统" },
    ["--all"] = { "显示所有文件系统，包括大小为 0 的伪文件系统" },
    ["-B"] = { " size", "指定块大小（例如 1K, 1M, 1G）" },
    ["--block-size"] = { " size", "指定块大小（例如 1K, 1M, 1G）" },
    ["-h"] = { "以人类可读的格式打印大小（例如 1K 234M 2G）" },
    ["--human-readable"] = { "以人类可读的格式打印大小（例如 1K 234M 2G）" },
    ["-H"] = { "以 SI 单位打印大小（例如 1K=1000）" },
    ["--si"] = { "以 SI 单位打印大小（例如 1K=1000）" },
    ["-i"] = { "显示 inode 信息而非块使用情况" },
    ["--inodes"] = { "显示 inode 信息而非块使用情况" },
    ["-k"] = { "以 1024 字节块显示" },
    ["-l"] = { "仅显示本地文件系统" },
    ["--local"] = { "仅显示本地文件系统" },
    ["--no-sync"] = { "不先调用 sync（默认行为）" },
    ["--output"] = { " field_list", "指定输出的列：source, fstype, itotal, iused, iavail, ipcent, size, used, avail, pcent, file, target" },
    ["-P"] = { "使用 POSIX 输出格式" },
    ["--portability"] = { "使用 POSIX 输出格式" },
    ["--sync"] = { "在获取使用情况前先调用 sync" },
    ["--total"] = { "在末尾显示总计行" },
    ["-t"] = { " type", "仅显示指定类型的文件系统" },
    ["--type"] = { " type", "仅显示指定类型的文件系统" },
    ["-T"] = { "在输出中显示文件系统类型" },
    ["--print-type"] = { "在输出中显示文件系统类型" },
    ["-x"] = { " type", "排除指定类型的文件系统" },
    ["--exclude-type"] = { " type", "排除指定类型的文件系统" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-a", "--all",
    "-B"..(clink.argmatcher():addarg({fromhistory=true})),
    "--block-size="..(clink.argmatcher():addarg({fromhistory=true})),
    "-h", "--human-readable",
    "-H", "--si",
    "-i", "--inodes",
    "-k",
    "-l", "--local",
    "--no-sync",
    "--output="..output_matcher,
    "-P", "--portability",
    "--sync",
    "--total",
    "-t"..(clink.argmatcher():addarg({fromhistory=true})),
    "--type="..(clink.argmatcher():addarg({fromhistory=true})),
    "-T", "--print-type",
    "-x"..(clink.argmatcher():addarg({fromhistory=true})),
    "--exclude-type="..(clink.argmatcher():addarg({fromhistory=true})),
    "--help", "--version",
})
