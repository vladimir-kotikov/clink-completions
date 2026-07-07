--------------------------------------------------------------------------------
-- Clink argmatcher for basenc (uutils / GNU coreutils)
--

local num_arg = clink.argmatcher():addarg({fromhistory=true})

clink.argmatcher("basenc")
:addarg(clink.filematches)
:adddescriptions({
    ["-d"] = { "解码数据" },
    ["--decode"] = { "解码数据" },
    ["--base64"] = { "使用 Base64 编码" },
    ["--base64url"] = { "使用 Base64 URL 安全编码" },
    ["--base32"] = { "使用 Base32 编码" },
    ["--base32hex"] = { "使用 Base32 Hex 编码" },
    ["--base16"] = { "使用 Base16 (Hex) 编码" },
    ["--base2msbf"] = { "使用二进制最高位优先编码" },
    ["--base2lsbf"] = { "使用二进制最低位优先编码" },
    ["--z85"] = { "使用 Z85 编码" },
    ["-i"] = { "解码时忽略非字母字符" },
    ["--ignore-garbage"] = { "解码时忽略非字母字符" },
    ["-w"] = { " cols", "编码行在 cols 个字符后换行（0=不换行）" },
    ["--wrap"] = { " cols", "编码行在 cols 个字符后换行（0=不换行）" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-d", "--decode",
    "--base64",
    "--base64url",
    "--base32",
    "--base32hex",
    "--base16",
    "--base2msbf",
    "--base2lsbf",
    "--z85",
    "-i", "--ignore-garbage",
    "-w"..num_arg,
    "--wrap="..num_arg,
    "--help", "--version",
})
