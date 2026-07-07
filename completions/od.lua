--------------------------------------------------------------------------------
-- Clink argmatcher for od (uutils / GNU coreutils)
--

local num_arg = clink.argmatcher():addarg({fromhistory=true})
local radix_matcher = clink.argmatcher():addarg({"d", "o", "x", "n"})
local endian_matcher = clink.argmatcher():addarg({"big", "little"})
local format_matcher = clink.argmatcher():addarg({"a", "c", "d", "o", "u", "x", "f", "F"})

clink.argmatcher("od")
:addarg(clink.filematches)
:adddescriptions({
    ["-A"] = { " radix", "指定地址基数：d=十进制 o=八进制 x=十六进制 n=无" },
    ["--address-radix"] = { " radix", "指定地址基数：d=十进制 o=八进制 x=十六进制 n=无" },
    ["-j"] = { " bytes", "跳过起始的 bytes 个字节" },
    ["--skip-bytes"] = { " bytes", "跳过起始的 bytes 个字节" },
    ["-N"] = { " bytes", "最多读取 bytes 个字节" },
    ["--read-bytes"] = { " bytes", "最多读取 bytes 个字节" },
    ["-S"] = { " bytes", "输出至少 bytes 个图形字符的字符串" },
    ["--strings"] = { " bytes", "输出至少 bytes 个图形字符的字符串" },
    ["-t"] = { " type", "指定输出格式：a, c, d, o, u, x, f, F" },
    ["--format"] = { " type", "指定输出格式：a, c, d, o, u, x, f, F" },
    ["-v"] = { "不使用 * 标记省略重复行" },
    ["--output-duplicates"] = { "不使用 * 标记省略重复行" },
    ["-w"] = { " bytes", "每行输出的字节数" },
    ["--width"] = { " bytes", "每行输出的字节数" },
    ["--endian"] = { " order", "指定字节序：big, little" },
    ["--traditional"] = { "接受传统格式的参数" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-A"..radix_matcher,
    "--address-radix="..radix_matcher,
    "-j"..num_arg,
    "--skip-bytes="..num_arg,
    "-N"..num_arg,
    "--read-bytes="..num_arg,
    "-S"..num_arg,
    "--strings="..num_arg,
    "-t"..format_matcher,
    "--format="..format_matcher,
    "-v", "--output-duplicates",
    "-w"..num_arg,
    "--width="..num_arg,
    "--endian="..endian_matcher,
    "--traditional",
    "--help", "--version",
})
