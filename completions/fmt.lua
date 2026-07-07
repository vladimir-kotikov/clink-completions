--------------------------------------------------------------------------------
-- Clink argmatcher for fmt (uutils / GNU coreutils)
--

local num_arg = clink.argmatcher():addarg({fromhistory=true})

clink.argmatcher("fmt")
:addarg(clink.filematches)
:adddescriptions({
    ["-c"] = { "保持段落前两行的缩进" },
    ["--crown-margin"] = { "保持段落前两行的缩进" },
    ["-p"] = { " PREFIX", "仅格式化以 PREFIX 开头的行" },
    ["--prefix"] = { " PREFIX", "仅格式化以 PREFIX 开头的行" },
    ["-s"] = { "仅拆分长行，不合并短行" },
    ["--split-only"] = { "仅拆分长行，不合并短行" },
    ["-u"] = { "单词间统一为一个空格，句子间为两个空格" },
    ["--uniform-spacing"] = { "单词间统一为一个空格，句子间为两个空格" },
    ["-w"] = { " WIDTH", "设置最大行宽为 WIDTH（默认 75）" },
    ["--width"] = { " WIDTH", "设置最大行宽为 WIDTH（默认 75）" },
    ["-g"] = { " GOAL", "设置目标宽度为 GOAL（默认 93% 的宽度）" },
    ["--goal"] = { " GOAL", "设置目标宽度为 GOAL（默认 93% 的宽度）" },
    ["-t"] = { "将段落视为带标签的段落" },
    ["--tagged-paragraph"] = { "将段落视为带标签的段落" },
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
:addflags({
    "-c", "--crown-margin",
    "-p", "--prefix",
    "-s", "--split-only",
    "-u", "--uniform-spacing",
    "-w"..num_arg, "--width="..num_arg,
    "-g"..num_arg, "--goal="..num_arg,
    "-t", "--tagged-paragraph",
    "--help", "--version",
})
