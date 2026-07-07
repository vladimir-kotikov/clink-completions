--------------------------------------------------------------------------------
-- Clink argmatcher for date (uutils / GNU coreutils)
--

local iso_matcher = clink.argmatcher():addarg({"date", "hours", "minutes", "seconds", "ns"})
local rfc3339_matcher = clink.argmatcher():addarg({"date", "seconds", "ns"})

clink.argmatcher("date")
:adddescriptions({
    ["-d"] = { " date", "显示指定日期/时间而非当前时间" },
    ["--date"] = { " date", "显示指定日期/时间而非当前时间" },
    ["-f"] = { " datefile", "从文件中解析日期/时间" },
    ["--file"] = { " datefile", "从文件中解析日期/时间" },
    ["-I"] = { " format", "以 ISO 8601 格式输出，可选精度：date, hours, minutes, seconds, ns" },
    ["--iso-8601"] = { " format", "以 ISO 8601 格式输出，可选精度：date, hours, minutes, seconds, ns" },
    ["-R"] = { "以 RFC 2822 格式输出日期和时间" },
    ["--rfc-2822"] = { "以 RFC 2822 格式输出日期和时间" },
    ["-r"] = { " file", "显示文件的最后修改时间" },
    ["--reference"] = { " file", "显示文件的最后修改时间" },
    ["-u"] = { "以 UTC 时间显示或设置" },
    ["--utc"] = { "以 UTC 时间显示或设置" },
    ["--universal"] = { "以 UTC 时间显示或设置" },
    ["--rfc-3339"] = { " precision", "以 RFC 3339 格式输出，可选精度：date, seconds, ns" },
    ["-s"] = { " string", "设置系统日期和时间" },
    ["--set"] = { " string", "设置系统日期和时间" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-d"..(clink.argmatcher():addarg({fromhistory=true})),
    "--date="..(clink.argmatcher():addarg({fromhistory=true})),
    "-f"..(clink.argmatcher():addarg({fromhistory=true})),
    "--file="..(clink.argmatcher():addarg({fromhistory=true})),
    "-I"..iso_matcher,
    "--iso-8601="..iso_matcher,
    "-R", "--rfc-2822",
    "-r"..clink.filematches,
    "--reference="..clink.filematches,
    "-u", "--utc", "--universal",
    "--rfc-3339="..rfc3339_matcher,
    "-s"..(clink.argmatcher():addarg({fromhistory=true})),
    "--set="..(clink.argmatcher():addarg({fromhistory=true})),
    "--help", "--version",
})
