--------------------------------------------------------------------------------
-- Clink argmatcher for hostname (GNU coreutils)
--

clink.argmatcher("hostname")
:adddescriptions({
    ["-s"] = { "仅显示短主机名（不包括域名部分）" },
    ["--short"] = { "仅显示短主机名（不包括域名部分）" },
    ["-f"] = { "显示完整限定域名（FQDN）" },
    ["--fqdn"] = { "显示完整限定域名（FQDN）" },
    ["--long"] = { "等同 --fqdn，显示完整限定域名" },
    ["-d"] = { "显示 DNS 域名部分" },
    ["--domain"] = { "显示 DNS 域名部分" },
    ["-i"] = { "显示主机名对应的 IP 地址" },
    ["--ip-address"] = { "显示主机名对应的 IP 地址" },
    ["-A"] = { "显示主机的所有 FQDN" },
    ["--all-fqdns"] = { "显示主机的所有 FQDN" },
    ["-I"] = { "显示主机的所有 IP 地址" },
    ["--all-ip-addresses"] = { "显示主机的所有 IP 地址" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-s", "--short",
    "-f", "--fqdn", "--long",
    "-d", "--domain",
    "-i", "--ip-address",
    "-A", "--all-fqdns",
    "-I", "--all-ip-addresses",
    "--help", "--version",
})
