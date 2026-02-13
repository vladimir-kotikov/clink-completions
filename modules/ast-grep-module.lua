-- Completions for ast-grep -- "Find Code by Syntax"
-- https://ast-grep.github.io

require("arghelper")

--      set CLINK_COMPLETIONS_FLAGDESC={NUMBER}
--              0 -> no descriptions for flags
--              1 -> descriptions only for short flags
--              2 -> (DEFAULT) descriptions for short and long flags

local kind_playground_url = "https://ast-grep.github.io/playground.html"

local flagdesc = (tonumber(os.getenv("CLINK_COMPLETIONS_FLAGDESC") or "2") or 2)
local function maybe_desc(a, i, j)
    if a[i] then
        assert(type(a[i]) == "string")
        local threshold = a[i]:find("^%-%-") and 2 or 1
        if flagdesc >= threshold then
            return a[j]
        end
    end
end

local tmp_parser = clink.argmatcher and clink.argmatcher() or clink.arg.new_parser()
local meta_parser = getmetatable(tmp_parser)
local function is_parser(x)
    return getmetatable(x) == meta_parser
end

--[[
local tmp_link = "link"..tmp_parser
local meta_link = getmetatable(tmp_link)
local function is_link(x)
    return getmetatable(x) == meta_link
end
--]]

local function make_exflags(src)
    local exflags = {}
    for _, f in ipairs(src) do
        local shrt, long
        if not is_parser(f[3]) then
            if f[1] then shrt = { f[1], maybe_desc(f, 1, 3) } end
            if f[2] then long = { f[2], maybe_desc(f, 2, 3) } end
        elseif f[5] then
            if f[1] then shrt = { f[1]..f[3], f[4], maybe_desc(f, 1, 5) } end
            if f[2] then long = { f[2]..f[3], f[4], maybe_desc(f, 2, 5) } end
        elseif f[4] then
            if f[1] then shrt = { f[1]..f[3], f[4], "" } end
            if f[2] then long = { f[2]..f[3], f[4], "" } end
        elseif f[3] then
            if f[1] then shrt = { f[1]..f[3] } end
            if f[2] then long = { f[2]..f[3] } end
        end
        if shrt then table.insert(exflags, shrt) end
        if long then table.insert(exflags, long) end
    end
    return exflags
end

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
    { "auto",       "Try to use colors, but don't force the issue (when piped, no console, etc)" },
    { "always",     "Try very hard to emit colors, potentially using console APIs on Windows (NYI)" },
    { "ansi",       "Emit ANSI color codes" },
    { "never",      "Never emit colors" },
})
local config_file = clink.argmatcher():addarg(ymlfilematches)
local dirs = clink.argmatcher():addarg(clink.dirmatches)
local error_format = clink.argmatcher():_addexarg({
    { "github",     "GitHub Action" },
    { "sarif",      "SARIF (Static Analysis Results Interchange Format)" },
})
local file_type = clink.argmatcher():_addexarg({
    { "hidden",     "Search hidden files and directories" },
    { "dot",        "Don't respect .ignore files" },
    { "exclude",    "Don't respect ignore files that are manually configured for the repo" },
    { "global",     "Don't respect ignore files that come from 'global' sources" },
    { "parent",     "Don't respect ignore files in parent directories" },
    { "vcs",        "Don't respect version control ignore files (.gitignore, etc)" },
})
local filter_regex = clink.argmatcher():addarg({fromhistory=true})
local fix = clink.argmatcher():addarg({fromhistory=true})
local format = clink.argmatcher():_addexarg({
    { "pattern",    "Print the query parsed in Pattern format" },
    { "ast",        "Print the query in tree-sitter AST format (only named nodes)" },
    { "cst",        "Print the query in tree-sitter CST format (named and unnamed nodes)" },
    { "sexp",       "Print the query in S-expression format" },
})
local globs = clink.argmatcher():addarg({fromhistory=true})
local heading_when = clink.argmatcher():_addexarg({
    { "auto",       "Print heading for terminal tty but not for piped output" },
    { "always",     "Always print heading regardless of output type" },
    { "never",      "Never print heading regardless of output type" },
})
local inspect_granularity = clink.argmatcher():_addexarg({
    { "nothing",    "Do not show any tracing information" },
    { "summary",    "Show summary about how many files are scanned and skipped" },
    { "entity",     "Show per-file/per-rule tracing information" },
})
local json_style = clink.argmatcher():_addexarg({
    { "pretty",     "Prints the matches as a pretty-printed JSON array (not for parsing by programs)" },
    { "stream",     "Prints each match as a separate JSON object" },
    { "compact",    "Prints the matches as a single-line JSON array, without any whitespace" },
})
local kind = clink.argmatcher():addarg({fromhistory=true, "FIND KINDS: "..kind_playground_url})
local lang = clink.argmatcher():addarg({fromhistory=true,
    "c", "cpp", "cs", "css", "go", "html", "js", "json", "lua", "py", "ts", "yml",
})
local num = clink.argmatcher():addarg({"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"})
local pattern = clink.argmatcher():addarg({fromhistory=true})
local report_style = clink.argmatcher():_addexarg({
    { "rich",       "Output a richly formatted diagnostic, with source code previews" },
    { "medium",     "Output a condensed diagnostic, with a line number, severity, message and notes (if any)" },
    { "short",      "Output a short diagnostic, with a line number, severity, and message" },
})
local rule_file = clink.argmatcher():addarg(ymlfilematches)
local rule_id = clink.argmatcher():addarg({fromhistory=true}) -- TODO: is there a way to get a list of rule IDs?
local rule_text = clink.argmatcher():addarg({fromhistory=true})
local strictness = clink.argmatcher():_addexarg({
    { "cst",        "Match exact all node" },
    { "smart",      "Match all node except source trivial nodes" },
    { "ast",        "Match only AST nodes" },
    { "relaxed",    "Match AST node except comments" },
    { "signature",  "Match AST node except comments, without text" },
    { "template",   "Similar to smart but match text only, node kinds are ignored" },
})

local common_flags = make_exflags({
    { "-c", "--config", config_file, " <config_file>",  "Path to ast-grep root config" },
    { "-h", "--help",                                   "Print help" },
    { "-V", "--version",                                "Print version" },
})

local common_run_scan_flags = make_exflags({
    { nil, "--follow",                                  "Follow symbolic links" },
    { nil, "--no-ignore", file_type, " <file_type>",    "Do not respect hidden file system or ignore files" },
    { nil, "--stdin",                                   "Enable search code from stdin" },
    { nil, "--globs", globs, " <globs>",                "Include or exclude file paths (prefix with ! to exclude)" },
    { "-j", "--threads", num, " <num>",                 "Set the approximate number of threads to use" },
    { "-i", "--interactive",                            "Start interactive edit session" },
    { "-U", "--update-all",                             "Apply all rewrite without confirmation if true" },
    { nil, "--files-with-matches",                      "Print only the paths with at least one match and suppress match contents" },
    { nil, "--json",                                    "Output matches in structured JSON" },
    { nil, "--json=", json_style, "<style>",            "Output matches in structured JSON" },
    { nil, "--color", color_when, " <when>",             "Controls output color" },
    { nil, "--inspect", inspect_granularity, " <granularity>", "Inspect information for file/rule discovery and scanning" },
    { "-A", "--after", num, " <num>",                   "Show <num> lines after each match" },
    { "-B", "--before", num, " <num>",                  "Show <num> lines before each match" },
    { "-C", "--context", num, " <num>",                 "Show <num> lines around each match" },
})

local common_new_flags = make_exflags({
    { "-l", "--lang", lang, " <lang>",                  "The language of the item to create" },
    { "-y", "--yes",                                    "Accept all default options without interactive input during creation" },
})

local run_parser = clink.argmatcher()
:_addexflags(common_flags)
:_addexflags(common_run_scan_flags)
:_addexflags(make_exflags({
    { "-p", "--pattern", pattern, " <pattern>",         "AST pattern to match" },
    { nil, "--selector", kind, " <kind>",               "AST kind to extract sub-part of pattern to match; "..kind_playground_url },
    { "-r", "--rewrite", fix, " <fix>",                 "String to replace the matched AST node" },
    { "-l", "--lang", lang, " <lang>",                  "The language of the pattern" },
    { nil, "--debug-query",                             "Print query pattern's tree-sitter AST" },
    { nil, "--debug-query=", format, "<format>",        "Print query pattern's tree-sitter AST" },
    { nil, "--strictness", strictness, " <strictness>", "The strictness of the pattern" },
    { nil, "--heading", heading_when, " <when>",        "Controls whether to print the file name as heading" },
}))
:addarg({hint=arg_expected.."[paths]", clink.filematches})

local scan_parser = clink.argmatcher()
:_addexflags(common_flags)
:_addexflags(common_run_scan_flags)
:_addexflags(make_exflags({
    { "-r", "--rule", rule_file, " <rule_file>",        "Scan the codebase with the single rule located at the path <rule_file>" },
    { nil, "--inline-rules", rule_text, " <rule_text>", "Scan the codebase with a rule defined by the provided <rule_text>" },
    { nil, "--format", error_format, " <format>",       "Output warning/error messages in different formats" },
    { nil, "--report-style", report_style, " <report_style>", "Set the output report style" },
    { nil, "--include-metadata",                        "Include rule metadata in the json output" },
    { nil, "--filter", filter_regex, " <regex>",        "Scan the codebase with rules with ids matching <regex>" },
    { nil, "--error",                                   "Set all rules to error" },
    { nil, "--error=", rule_id, "<rule_id>...",         "Set the specified <rule_id>'s severity to error" },
    { nil, "--warning",                                 "Set all rules to warning" },
    { nil, "--warning=", rule_id, "<rule_id>...",       "Set the specified <rule_id>'s severity to warning" },
    { nil, "--info",                                    "Set all rules to info" },
    { nil, "--info=", rule_id, "<rule_id>...",          "Set the specified <rule_id>'s severity to info" },
    { nil, "--hint",                                    "Set all rules to hint" },
    { nil, "--hint=", rule_id, "<rule_id>...",          "Set the specified <rule_id>'s severity to hint" },
    { nil, "--off",                                     "Turn off all rules" },
    { nil, "--off=", rule_id, "<rule_id>...",           "Turn off rule" },
}))
:addarg({hint=arg_expected.."[paths]", clink.filematches})

local test_parser = clink.argmatcher()
:_addexflags(common_flags)
:_addexflags(make_exflags({
    { "-t", "--test-dir", dirs, " <test_dir>",          "The directories to search test YAML files" },
    { nil, "--snapshot-dir", dirs, " <snapshot_dir>",   "Specify the directory name storing snapshots" },
    { nil, "--skip-snapshot-tests",                     "Only check if the test code is valid, without checking rule output" },
    { "-U", "--update-all",                             "Update the content of all snapshots that have changed in test" },
    { "-i", "--interactive",                            "Start an interactive review to update snapshots selectively" },
    { "-f", "--filter", filter_regex, " <regex>",       "Only run rule test cases that matches 'regex'" },
    { nil, "--include-off",                             "Include 'severity:off' rules in test" },
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
    { "project"..new_subcommand_parser, " [name]",      "Create an new project by scaffolding" },
    { "rule"..new_subcommand_parser, " [name]",         "Create a new rule" },
    { "test"..new_subcommand_parser, " [name]",         "Create a new test case" },
    { "util"..new_subcommand_parser, " [name]",         "Create a new global utility rule" },
})
:_addexarg({
    hint=arg_expected.."[command]",
    { "project"..new_subcommand_parser, " [name]",      "Create an new project by scaffolding" },
    { "rule"..new_subcommand_parser, " [name]",         "Create a new rule" },
    { "test"..new_subcommand_parser, " [name]",         "Create a new test case" },
    { "util"..new_subcommand_parser, " [name]",         "Create a new global utility rule" },
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
    { "-p", "--pattern", pattern_implicit_run, " <pattern>", "AST pattern to match (implies the 'run' subcommand)" },
}))
:_addexarg({
    { "run"..run_parser, " [paths]",                    "Run one time search or rewrite in command line (default command)" },
    { "scan"..scan_parser, " [paths]",                  "Scan and rewrite code by configuration" },
    { "test"..test_parser,                              "Test ast-grep rules" },
    { "new"..new_parser, " [name] [command]",           "Create new ast-grep project or items like rules/tests" },
    { "lsp"..lsp_parser,                                "Start language server" },
    { "completions"..completions_parser, " <shell>",    "Generate shell completion script" },
    { "help"..help_parser, " [<subcommand>]",           "Print help for given subcommand" },
})
:nofiles()
