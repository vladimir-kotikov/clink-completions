--------------------------------------------------------------------------------
-- Clink argmatcher for cksum (uutils / GNU coreutils)
--

local algo_matcher = clink.argmatcher():addarg({"crc", "md5", "sha1", "sha256", "sha512", "blake2b", "sm3"})

clink.argmatcher("cksum")
:addarg(clink.filematches)
:adddescriptions({
    ["-a"] = { " algorithm", "指定校验和算法：crc, md5, sha1, sha256, sha512, blake2b, sm3" },
    ["--algorithm"] = { " algorithm", "指定校验和算法：crc, md5, sha1, sha256, sha512, blake2b, sm3" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-a"..algo_matcher,
    "--algorithm="..algo_matcher,
    "--help", "--version",
})
