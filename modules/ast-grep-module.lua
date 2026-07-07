-- Completions for ast-grep -- "Find Code by Syntax"
-- https://ast-grep.github.io

local arghelper = require("arghelper")
local make_exflags = arghelper.make_exflags

--      set CLINK_COMPLETIONS_FLAGDESC={NUMBER}
--              0 -> no descriptions for flags
--              1 -> descriptions only for short flags
--              2 -> (DEFAULT) descriptions for short and long flags

local kind_playground_url = "https://ast-grep.github.io/playground.html"

local function filterfilematches(match_word, ext)
    ext = "."..ext:gsub("^%.+", "")
    if clink.filematchesexact then
        return clink.filematchesexact(match_word.."*"..ext)
    else
        local word, expanded = rl.expandtilde(match_word)

        local root = (path.getdirectory(word) or ""):gsub("/", "\\")
        if expanded then
            root = rl.collapsetilde(root)
        end

        local _, ismain = coroutine.running()

        local matches = {}
        for _, i in ipairs(os.globfiles(word.."*"..ext, true)) do
            local m = path.join(root, i.name)
            table.insert(matches, { match = m, type = i.type })
            if not ismain and _ % 250 == 0 then
                coroutine.yield()
            end
        end
        for _, i in ipairs(os.globdirs(word.."*", true)) do
            local m = path.join(root, i.name)
            table.insert(matches, { match = m, type = i.type })
            if not ismain and _ % 250 == 0 then
                coroutine.yield()
            end
        end
        return matches
    end
end

local function ymlfilematches(match_word)
    return filterfilematches(match_word, "yml")
end

local arg_expected = "Argument expected:  "

-- luacheck: no max line length

local color_when = clink.argmatcher():_addexarg({
    { "auto",       "尝试使用颜色，但不过度强制（管道输出、无控制台等情况）" },
    { "always",     "尽力使用颜色，可能在 Windows 上使用控制台 API（NYI）" },
    { "ansi",       "输出 ANSI 颜色代码" },
    { "never",      "永不输出颜色" },
})
local config_file = clink.argmatcher():addarg(ymlfilematches)
local dirs = clink.argmatcher():addarg(clink.dirmatches)
local error_format = clink.argmatcher():_addexarg({
    { "github",     "GitHub Action" },
    { "sarif",      "SARIF（静态分析结果交换格式）" },
})
local file_type = clink.argmatcher():_addexarg({
    { "hidden",     "搜索隐藏文件和目录" },
    { "dot",        "不遵守 .ignore 文件" },
    { "exclude",    "不遵守为仓库手动配置的忽略文件" },
    { "global",     "不遵守来自 'global' 源的忽略文件" },
    { "parent",     "不遵守父目录中的忽略文件" },
    { "vcs",        "不遵守版本控制忽略文件（.gitignore 等）" },
})
local filter_regex = clink.argmatcher():addarg({fromhistory=true})
local fix = clink.argmatcher():addarg({fromhistory=true})
local format = clink.argmatcher():_addexarg({
    { "pattern",    "以 Pattern 格式打印解析后的查询" },
    { "ast",        "以 tree-sitter AST 格式打印查询（仅具名节点）" },
    { "cst",        "以 tree-sitter CST 格式打印查询（具名和未具名节点）" },
    { "sexp",       "以 S 表达式格式打印查询" },
})
local globs = clink.argmatcher():addarg({fromhistory=true})
local heading_when = clink.argmatcher():_addexarg({
    { "auto",       "为终端 tty 打印标题，但不为管道输出打印" },
    { "always",     "始终打印标题，无论输出类型如何" },
    { "never",      "永不打印标题，无论输出类型如何" },
})
local inspect_granularity = clink.argmatcher():_addexarg({
    { "nothing",    "不显示任何追踪信息" },
    { "summary",    "显示扫描和跳过的文件数量的摘要" },
    { "entity",     "显示每个文件/每条规则的追踪信息" },
})
local json_style = clink.argmatcher():_addexarg({
    { "pretty",     "以美化格式的 JSON 数组打印匹配（不用于程序解析）" },
    { "stream",     "将每个匹配打印为单独的 JSON 对象" },
    { "compact",    "以单行 JSON 数组打印匹配，不含空白字符" },
})
local kind = clink.argmatcher():addarg({fromhistory=true, "FIND KINDS: "..kind_playground_url})
local lang = clink.argmatcher():addarg({fromhistory=true,
    "c", "cpp", "cs", "css", "go", "html", "js", "json", "lua", "py", "ts", "yml",
})
local num = clink.argmatcher():addarg({"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"})
local pattern = clink.argmatcher():addarg({fromhistory=true})
local report_style = clink.argmatcher():_addexarg({
    { "rich",       "输出丰富格式的诊断信息，包含源代码预览" },
    { "medium",     "输出精简的诊断信息，包含行号、严重性、消息和注释（如有）" },
    { "short",      "输出简短诊断信息，包含行号、严重性和消息" },
})
local rule_file = clink.argmatcher():addarg(ymlfilematches)
local rule_id = clink.argmatcher():addarg({fromhistory=true}) -- TODO: is there a way to get a list of rule IDs?
local rule_text = clink.argmatcher():addarg({fromhistory=true})
local strictness = clink.argmatcher():_addexarg({
    { "cst",        "匹配精确所有节点" },
    { "smart",      "匹配所有节点，源普通节点除外" },
    { "ast",        "仅匹配 AST 节点" },
    { "relaxed",    "匹配 AST 节点，注释除外" },
    { "signature",  "匹配 AST 节点，注释和文本除外" },
    { "template",   "类似于 smart，但仅匹配文本，忽略节点类型" },
})

local common_flags = make_exflags({
    { "-c", "--config", config_file, " <config_file>",  "ast-grep 根配置的路径" },
    { "-h", "--help",                                   "打印帮助" },
    { "-V", "--version",                                "打印版本" },
})

local common_run_scan_flags = make_exflags({
    { nil, "--follow",                                  "跟踪符号链接" },
    { nil, "--no-ignore", file_type, " <file_type>",    "不遵守隐藏文件系统或忽略文件" },
    { nil, "--stdin",                                   "启用从 stdin 搜索代码" },
    { nil, "--globs", globs, " <globs>",                "包含或排除文件路径（前缀 ! 表示排除）" },
    { "-j", "--threads", num, " <num>",                 "设置要使用的近似线程数" },
    { "-i", "--interactive",                            "启动交互式编辑会话" },
    { "-U", "--update-all",                             "如果为 true，则无需确认应用所有重写" },
    { nil, "--files-with-matches",                      "仅打印至少有一个匹配的路径，并抑制匹配内容" },
    { nil, "--json",                                    "以结构化 JSON 输出匹配" },
    { nil, "--json=", json_style, "<style>",            "以结构化 JSON 输出匹配" },
    { nil, "--color", color_when, " <when>",             "控制输出颜色" },
    { nil, "--inspect", inspect_granularity, " <granularity>", "检查文件/规则发现和扫描的信息" },
    { "-A", "--after", num, " <num>",                   "显示每个匹配后的 <num> 行" },
    { "-B", "--before", num, " <num>",                  "显示每个匹配前的 <num> 行" },
    { "-C", "--context", num, " <num>",                 "显示每个匹配周围的 <num> 行" },
})

local common_new_flags = make_exflags({
    { "-l", "--lang", lang, " <lang>",                  "要创建的项目的语言" },
    { "-y", "--yes",                                    "创建时接受所有默认选项，无需交互输入" },
})

local run_parser = clink.argmatcher()
:_addexflags(common_flags)
:_addexflags(common_run_scan_flags)
:_addexflags(make_exflags({
    { "-p", "--pattern", pattern, " <pattern>",         "要匹配的 AST 模式" },
    { nil, "--selector", kind, " <kind>",               "要提取模式子部分以匹配的 AST 类型；"..kind_playground_url },
    { "-r", "--rewrite", fix, " <fix>",                 "替换匹配的 AST 节点的字符串" },
    { "-l", "--lang", lang, " <lang>",                  "模式的语言" },
    { nil, "--debug-query",                             "打印查询模式的 tree-sitter AST" },
    { nil, "--debug-query=", format, "<format>",        "打印查询模式的 tree-sitter AST" },
    { nil, "--strictness", strictness, " <strictness>", "模式的严格性" },
    { nil, "--heading", heading_when, " <when>",        "控制是否将文件名打印为标题" },
}))
:addarg({hint=arg_expected.."[paths]", clink.filematches})

local scan_parser = clink.argmatcher()
:_addexflags(common_flags)
:_addexflags(common_run_scan_flags)
:_addexflags(make_exflags({
    { "-r", "--rule", rule_file, " <rule_file>",        "使用位于路径 <rule_file> 的单个规则扫描代码库" },
    { nil, "--inline-rules", rule_text, " <rule_text>", "使用提供的 <rule_text> 定义的规则扫描代码库" },
    { nil, "--format", error_format, " <format>",       "以不同格式输出警告/错误消息" },
    { nil, "--report-style", report_style, " <report_style>", "设置输出报告样式" },
    { nil, "--include-metadata",                        "在 JSON 输出中包含规则元数据" },
    { nil, "--filter", filter_regex, " <regex>",        "使用 ID 匹配 <regex> 的规则扫描代码库" },
    { nil, "--error",                                   "将所有规则设置为 error" },
    { nil, "--error=", rule_id, "<rule_id>...",         "将指定 <rule_id> 的严重性设置为 error" },
    { nil, "--warning",                                 "将所有规则设置为 warning" },
    { nil, "--warning=", rule_id, "<rule_id>...",       "将指定 <rule_id> 的严重性设置为 warning" },
    { nil, "--info",                                    "将所有规则设置为 info" },
    { nil, "--info=", rule_id, "<rule_id>...",          "将指定 <rule_id> 的严重性设置为 info" },
    { nil, "--hint",                                    "将所有规则设置为 hint" },
    { nil, "--hint=", rule_id, "<rule_id>...",          "将指定 <rule_id> 的严重性设置为 hint" },
    { nil, "--off",                                     "关闭所有规则" },
    { nil, "--off=", rule_id, "<rule_id>...",           "关闭规则" },
}))
:addarg({hint=arg_expected.."[paths]", clink.filematches})

local test_parser = clink.argmatcher()
:_addexflags(common_flags)
:_addexflags(make_exflags({
    { "-t", "--test-dir", dirs, " <test_dir>",          "搜索测试 YAML 文件的目录" },
    { nil, "--snapshot-dir", dirs, " <snapshot_dir>",   "指定存储快照的目录名称" },
    { nil, "--skip-snapshot-tests",                     "仅检查测试代码是否有效，不检查规则输出" },
    { "-U", "--update-all",                             "更新测试中所有已更改的快照内容" },
    { "-i", "--interactive",                            "启动交互式审查以选择性更新快照" },
    { "-f", "--filter", filter_regex, " <regex>",       "仅运行匹配 'regex' 的规则测试用例" },
    { nil, "--include-off",                             "在测试中包含 'severity:off' 规则" },
}))

local new_subcommand_parser = clink.argmatcher()
:_addexflags(common_flags)
:_addexflags(common_new_flags)
:addarg()

local function new_onadvance(arg_index, word, _, _, _)
    if arg_index == 1 then
        if word == "project" or word == "rule" or word == "test" or word == "util" then
            return 1    -- Ignore this arg_index.
        end
    end
end

local new_parser = clink.argmatcher()
:_addexflags(common_flags)
:_addexflags(common_new_flags)
:_addexarg({
    hint=arg_expected.."[name|command]",
    onadvance=new_onadvance,
    { "project"..new_subcommand_parser, " [name]",      "通过脚手架创建新项目" },
    { "rule"..new_subcommand_parser, " [name]",         "创建新规则" },
    { "test"..new_subcommand_parser, " [name]",         "创建新测试用例" },
    { "util"..new_subcommand_parser, " [name]",         "创建新的全局工具规则" },
})
:_addexarg({
    hint=arg_expected.."[command]",
    { "project"..new_subcommand_parser, " [name]",      "通过脚手架创建新项目" },
    { "rule"..new_subcommand_parser, " [name]",         "创建新规则" },
    { "test"..new_subcommand_parser, " [name]",         "创建新测试用例" },
    { "util"..new_subcommand_parser, " [name]",         "创建新的全局工具规则" },
})
:nofiles()

local lsp_parser = clink.argmatcher()
:_addexflags(common_flags)
:nofiles()

local completions_parser = clink.argmatcher()
:_addexflags(common_flags)
:addarg({"bash", "elvish", "fish", "powershell", "zsh"})
:nofiles()

local help_new_parser = clink.argmatcher():addarg({"project", "rule", "test", "util"})
local help_parser = clink.argmatcher():addarg({"run", "scan", "test", "new"..help_new_parser, "lsp", "help"})

local function implicit_run_onlink(_, arg_index, _, _, _, _)
    if arg_index == 1 then
        return run_parser
    end
end

local pattern_implicit_run = clink.argmatcher():addarg({fromhistory=true, onlink=implicit_run_onlink})

clink.argmatcher("ast-grep", "sg")
:_addexflags(common_flags)
:_addexflags(make_exflags({
    { "-p", "--pattern", pattern_implicit_run, " <pattern>", "AST 模式匹配（隐含 'run' 子命令）" },
}))
:_addexarg({
    { "run"..run_parser, " [paths]",                    "在命令行运行一次性搜索或重写（默认命令）" },
    { "scan"..scan_parser, " [paths]",                  "通过配置扫描和重写代码" },
    { "test"..test_parser,                              "测试 ast-grep 规则" },
    { "new"..new_parser, " [name] [command]",           "创建新的 ast-grep 项目或项目项（如规则/测试）" },
    { "lsp"..lsp_parser,                                "启动语言服务器" },
    { "completions"..completions_parser, " <shell>",    "生成 shell 补全脚本" },
    { "help"..help_parser, " [<subcommand>]",           "打印指定子命令的帮助信息" },
})
:nofiles()
