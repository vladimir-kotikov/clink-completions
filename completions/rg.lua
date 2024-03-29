------------------------------------------------------------------------------
-- RG

-- luacheck: no max line length

local function try_require(module)
  local r
  pcall(function() r = require(module) end)
  return r
end

try_require("arghelper")

local function onarg_contains_opt(arg_index, word, _, _, user_data)
  if arg_index == 0 then
    local present = user_data.present
    if not present then
      present = {}
      user_data.present = present
    end
    present[word] = true
  end
end

local function do_filter(matches, conditions, user_data)
  local ret = {}
  local present = user_data.present or {}
  for _,m in ipairs(matches) do
    local test_list = conditions[m.match]
    if test_list then
      local ok
      for _,test in ipairs(test_list) do
        if present[test] then
          ok = true
          break
        end
      end
      if not ok then
        goto continue
      end
    end
    table.insert(ret, m)
::continue::
  end
  return ret
end

local rg_aftercontext = clink.argmatcher():addarg({})
local rg_beforecontext = clink.argmatcher():addarg({})
local rg_color = clink.argmatcher():addarg({"never", "auto", "always", "ansi"})
local rg_colors = clink.argmatcher():addarg({})
local rg_context = clink.argmatcher():addarg({})
local rg_contextseparator = clink.argmatcher():addarg({})
local rg_dfasizelimit = clink.argmatcher():addarg({})
local rg_encoding = clink.argmatcher():addarg({})
local rg_engine = clink.argmatcher():addarg({"default", "pcre2", "auto"})
local rg_fieldcontextseparator = clink.argmatcher():addarg({})
local rg_fieldmatchseparator = clink.argmatcher():addarg({})
local rg_file = clink.argmatcher():addarg({})
local rg_generate = clink.argmatcher():addarg({"man", "complete-bash", "complete-zsh", "complete-fish", "complete-powershell"})
local rg_glob = clink.argmatcher():addarg({})
local rg_hostnamebin = clink.argmatcher():addarg({"(__fish_complete_command)"})
local rg_hyperlinkformat = clink.argmatcher():addarg({})
local rg_iglob = clink.argmatcher():addarg({})
local rg_ignorefile = clink.argmatcher():addarg({})
local rg_maxcolumns = clink.argmatcher():addarg({})
local rg_maxcount = clink.argmatcher():addarg({})
local rg_maxdepth = clink.argmatcher():addarg({})
local rg_maxfilesize = clink.argmatcher():addarg({})
local rg_pathseparator = clink.argmatcher():addarg({})
local rg_pre = clink.argmatcher():addarg({"(__fish_complete_command)"})
local rg_preglob = clink.argmatcher():addarg({})
local rg_regexp = clink.argmatcher():addarg({})
local rg_regexsizelimit = clink.argmatcher():addarg({})
local rg_replace = clink.argmatcher():addarg({})
local rg_sort = clink.argmatcher():addarg({"none", "path", "modified", "accessed", "created"})
local rg_sortr = clink.argmatcher():addarg({"none", "path", "modified", "accessed", "created"})
local rg_threads = clink.argmatcher():addarg({})
local rg_type = clink.argmatcher():addarg({"(rg", "--type-list", "|", "string", "replace", ":", "t)"})
local rg_typeadd = clink.argmatcher():addarg({})
local rg_typeclear = clink.argmatcher():addarg({})
local rg_typenot = clink.argmatcher():addarg({"(rg", "--type-list", "|", "string", "replace", ":", "t)"})

local rg__hide_unless = {
  ["--ignore"] = { "--no-ignore" },
  ["--ignore-dot"] = { "--no-ignore-dot" },
  ["--ignore-exclude"] = { "--no-ignore-exclude" },
  ["--ignore-files"] = { "--no-ignore-files" },
  ["--ignore-global"] = { "--no-ignore-global" },
  ["--ignore-messages"] = { "--no-ignore-messages" },
  ["--ignore-parent"] = { "--no-ignore-parent" },
  ["--ignore-vcs"] = { "--no-ignore-vcs" },
  ["--messages"] = { "--no-messages" },
  ["--no-auto-hybrid-regex"] = { "--auto-hybrid-regex" },
  ["--no-binary"] = { "--binary" },
  ["--no-block-buffered"] = { "--block-buffered" },
  ["--no-byte-offset"] = { "-b", "--byte-offset" },
  ["--no-column"] = { "--column" },
  ["--no-context-separator"] = { "--context-separator" },
  ["--no-crlf"] = { "--crlf" },
  ["--no-encoding"] = { "-E", "--encoding" },
  ["--no-fixed-strings"] = { "-F", "--fixed-strings" },
  ["--no-follow"] = { "-L", "--follow" },
  ["--no-glob-case-insensitive"] = { "--glob-case-insensitive" },
  ["--no-heading"] = { "--heading" },
  ["--no-hidden"] = { "-.", "--hidden" },
  ["--no-ignore-file-case-insensitive"] = { "--ignore-file-case-insensitive" },
  ["--no-include-zero"] = { "--include-zero" },
  ["--no-invert-match"] = { "-v", "--invert-match" },
  ["--no-json"] = { "--json" },
  ["--no-line-buffered"] = { "--line-buffered" },
  ["--no-max-columns-preview"] = { "--max-columns-preview" },
  ["--no-mmap"] = { "--mmap" },
  ["--no-multiline"] = { "-U", "--multiline" },
  ["--no-multiline-dotall"] = { "--multiline-dotall" },
  ["--no-one-file-system"] = { "--one-file-system" },
  ["--no-pcre2"] = { "-P", "--pcre2" },
  ["--no-pre"] = { "--pre" },
  ["--no-search-zip"] = { "-z", "--search-zip" },
  ["--no-sort-files"] = { "--sort-files" },
  ["--no-stats"] = { "--stats" },
  ["--no-text"] = { "-a", "--text" },
  ["--no-trim"] = { "--trim" },
  ["--pcre2-unicode"] = { "--no-pcre2-unicode" },
  ["--require-git"] = { "--no-require-git" },
  ["--unicode"] = { "--no-unicode" },
}

clink.argmatcher("rg")
:adddescriptions({
  ["--after-context"] = { " arg", "Show NUM lines after each match." },
  ["--auto-hybrid-regex"] = { "(DEPRECATED) Use PCRE2 if appropriate." },
  ["--before-context"] = { " arg", "Show NUM lines before each match." },
  ["--binary"] = { "Search binary files." },
  ["--block-buffered"] = { "Force block buffering." },
  ["--byte-offset"] = { "Print the byte offset for each matching line." },
  ["--case-sensitive"] = { "Search case sensitively (default)." },
  ["--color"] = { " arg", "When to use color." },
  ["--colors"] = { " arg", "Configure color settings and styles." },
  ["--column"] = { "Show column numbers." },
  ["--context"] = { " arg", "Show NUM lines before and after each match." },
  ["--context-separator"] = { " arg", "Set the separator for contextual chunks." },
  ["--count"] = { "Show count of matching lines for each file." },
  ["--count-matches"] = { "Show count of every match for each file." },
  ["--crlf"] = { "Use CRLF line terminators (nice for Windows)." },
  ["--debug"] = { "Show debug messages." },
  ["--dfa-size-limit"] = { " arg", "The upper size limit of the regex DFA." },
  ["--encoding"] = { " arg", "Specify the text encoding of files to search." },
  ["--engine"] = { " arg", "Specify which regex engine to use." },
  ["--field-context-separator"] = { " arg", "Set the field context separator." },
  ["--field-match-separator"] = { " arg", "Set the field match separator." },
  ["--file"] = { " arg", "Search for patterns from the given file." },
  ["--files"] = { "Print each file that would be searched." },
  ["--files-with-matches"] = { "Print the paths with at least one match." },
  ["--files-without-match"] = { "Print the paths that contain zero matches." },
  ["--fixed-strings"] = { "Treat all patterns as literals." },
  ["--follow"] = { "Follow symbolic links." },
  ["--generate"] = { " arg", "Generate man pages and completion scripts." },
  ["--glob"] = { " arg", "Include or exclude file paths." },
  ["--glob-case-insensitive"] = { "Process all glob patterns case insensitively." },
  ["--heading"] = { "Print matches grouped by each file." },
  ["--help"] = { "Show help output." },
  ["--hidden"] = { "Search hidden files and directories." },
  ["--hostname-bin"] = { " arg", "Run a program to get this system's hostname." },
  ["--hyperlink-format"] = { " arg", "Set the format of hyperlinks." },
  ["--iglob"] = { " arg", "Include/exclude paths case insensitively." },
  ["--ignore"] = { "Don't use ignore files." },
  ["--ignore-case"] = { "Case insensitive search." },
  ["--ignore-dot"] = { "Don't use .ignore or .rgignore files." },
  ["--ignore-exclude"] = { "Don't use local exclusion files." },
  ["--ignore-file"] = { " arg", "Specify additional ignore files." },
  ["--ignore-file-case-insensitive"] = { "Process ignore files case insensitively." },
  ["--ignore-files"] = { "Don't use --ignore-file arguments." },
  ["--ignore-global"] = { "Don't use global ignore files." },
  ["--ignore-messages"] = { "Suppress gitignore parse error messages." },
  ["--ignore-parent"] = { "Don't use ignore files in parent directories." },
  ["--ignore-vcs"] = { "Don't use ignore files from source control." },
  ["--include-zero"] = { "Include zero matches in summary output." },
  ["--invert-match"] = { "Invert matching." },
  ["--json"] = { "Show search results in a JSON Lines format." },
  ["--line-buffered"] = { "Force line buffering." },
  ["--line-number"] = { "Show line numbers." },
  ["--line-regexp"] = { "Show matches surrounded by line boundaries." },
  ["--max-columns"] = { " arg", "Omit lines longer than this limit." },
  ["--max-columns-preview"] = { "Show preview for lines exceeding the limit." },
  ["--max-count"] = { " arg", "Limit the number of matching lines." },
  ["--max-depth"] = { " arg", "Descend at most NUM directories." },
  ["--max-filesize"] = { " arg", "Ignore files larger than NUM in size." },
  ["--messages"] = { "Suppress some error messages." },
  ["--mmap"] = { "Search with memory maps when possible." },
  ["--multiline"] = { "Enable searching across multiple lines." },
  ["--multiline-dotall"] = { "Make '.' match line terminators." },
  ["--no-auto-hybrid-regex"] = { "(DEPRECATED) Use PCRE2 if appropriate." },
  ["--no-binary"] = { "Search binary files." },
  ["--no-block-buffered"] = { "Force block buffering." },
  ["--no-byte-offset"] = { "Print the byte offset for each matching line." },
  ["--no-column"] = { "Show column numbers." },
  ["--no-config"] = { "Never read configuration files." },
  ["--no-context-separator"] = { "Set the separator for contextual chunks." },
  ["--no-crlf"] = { "Use CRLF line terminators (nice for Windows)." },
  ["--no-encoding"] = { "Specify the text encoding of files to search." },
  ["--no-filename"] = { "Never print the path with each matching line." },
  ["--no-fixed-strings"] = { "Treat all patterns as literals." },
  ["--no-follow"] = { "Follow symbolic links." },
  ["--no-glob-case-insensitive"] = { "Process all glob patterns case insensitively." },
  ["--no-heading"] = { "Print matches grouped by each file." },
  ["--no-hidden"] = { "Search hidden files and directories." },
  ["--no-ignore"] = { "Don't use ignore files." },
  ["--no-ignore-dot"] = { "Don't use .ignore or .rgignore files." },
  ["--no-ignore-exclude"] = { "Don't use local exclusion files." },
  ["--no-ignore-file-case-insensitive"] = { "Process ignore files case insensitively." },
  ["--no-ignore-files"] = { "Don't use --ignore-file arguments." },
  ["--no-ignore-global"] = { "Don't use global ignore files." },
  ["--no-ignore-messages"] = { "Suppress gitignore parse error messages." },
  ["--no-ignore-parent"] = { "Don't use ignore files in parent directories." },
  ["--no-ignore-vcs"] = { "Don't use ignore files from source control." },
  ["--no-include-zero"] = { "Include zero matches in summary output." },
  ["--no-invert-match"] = { "Invert matching." },
  ["--no-json"] = { "Show search results in a JSON Lines format." },
  ["--no-line-buffered"] = { "Force line buffering." },
  ["--no-line-number"] = { "Suppress line numbers." },
  ["--no-max-columns-preview"] = { "Show preview for lines exceeding the limit." },
  ["--no-messages"] = { "Suppress some error messages." },
  ["--no-mmap"] = { "Search with memory maps when possible." },
  ["--no-multiline"] = { "Enable searching across multiple lines." },
  ["--no-multiline-dotall"] = { "Make '.' match line terminators." },
  ["--no-one-file-system"] = { "Skip directories on other file systems." },
  ["--no-pcre2"] = { "Enable PCRE2 matching." },
  ["--no-pcre2-unicode"] = { "(DEPRECATED) Disable Unicode mode for PCRE2." },
  ["--no-pre"] = { "Search output of COMMAND for each PATH." },
  ["--no-require-git"] = { "Use .gitignore outside of git repositories." },
  ["--no-search-zip"] = { "Search in compressed files." },
  ["--no-sort-files"] = { "(DEPRECATED) Sort results by file path." },
  ["--no-stats"] = { "Print statistics about the search." },
  ["--no-text"] = { "Search binary files as if they were text." },
  ["--no-trim"] = { "Trim prefix whitespace from matches." },
  ["--no-unicode"] = { "Disable Unicode mode." },
  ["--null"] = { "Print a NUL byte after file paths." },
  ["--null-data"] = { "Use NUL as a line terminator." },
  ["--one-file-system"] = { "Skip directories on other file systems." },
  ["--only-matching"] = { "Print only matched parts of a line." },
  ["--passthru"] = { "Print both matching and non-matching lines." },
  ["--path-separator"] = { " arg", "Set the path separator for printing paths." },
  ["--pcre2"] = { "Enable PCRE2 matching." },
  ["--pcre2-unicode"] = { "(DEPRECATED) Disable Unicode mode for PCRE2." },
  ["--pcre2-version"] = { "Print the version of PCRE2 that ripgrep uses." },
  ["--pre"] = { " arg", "Search output of COMMAND for each PATH." },
  ["--pre-glob"] = { " arg", "Include or exclude files from a preprocessor." },
  ["--pretty"] = { "Alias for colors, headings and line numbers." },
  ["--quiet"] = { "Do not print anything to stdout." },
  ["--regex-size-limit"] = { " arg", "The size limit of the compiled regex." },
  ["--regexp"] = { " arg", "A pattern to search for." },
  ["--replace"] = { " arg", "Replace matches with the given text." },
  ["--require-git"] = { "Use .gitignore outside of git repositories." },
  ["--search-zip"] = { "Search in compressed files." },
  ["--smart-case"] = { "Smart case search." },
  ["--sort"] = { " arg", "Sort results in ascending order." },
  ["--sort-files"] = { "(DEPRECATED) Sort results by file path." },
  ["--sortr"] = { " arg", "Sort results in descending order." },
  ["--stats"] = { "Print statistics about the search." },
  ["--stop-on-nonmatch"] = { "Stop searching after a non-match." },
  ["--text"] = { "Search binary files as if they were text." },
  ["--threads"] = { " arg", "Set the approximate number of threads to use." },
  ["--trace"] = { "Show trace messages." },
  ["--trim"] = { "Trim prefix whitespace from matches." },
  ["--type"] = { " arg", "Only search files matching TYPE." },
  ["--type-add"] = { " arg", "Add a new glob for a file type." },
  ["--type-clear"] = { " arg", "Clear globs for a file type." },
  ["--type-list"] = { "Show all supported file types." },
  ["--type-not"] = { " arg", "Do not search files matching TYPE." },
  ["--unicode"] = { "Disable Unicode mode." },
  ["--unrestricted"] = { "Reduce the level of \"smart\" filtering." },
  ["--version"] = { "Print ripgrep's version." },
  ["--vimgrep"] = { "Print results im a vim compatible format." },
  ["--with-filename"] = { "Print the file path with each matching line." },
  ["--word-regexp"] = { "Show matches surrounded by word boundaries." },
  ["-."] = { "Search hidden files and directories." },
  ["-0"] = { "Print a NUL byte after file paths." },
  ["-a"] = { "Search binary files as if they were text." },
  ["-A"] = { " arg", "Show NUM lines after each match." },
  ["-b"] = { "Print the byte offset for each matching line." },
  ["-B"] = { " arg", "Show NUM lines before each match." },
  ["-c"] = { "Show count of matching lines for each file." },
  ["-C"] = { " arg", "Show NUM lines before and after each match." },
  ["-d"] = { " arg", "Descend at most NUM directories." },
  ["-e"] = { " arg", "A pattern to search for." },
  ["-E"] = { " arg", "Specify the text encoding of files to search." },
  ["-f"] = { " arg", "Search for patterns from the given file." },
  ["-F"] = { "Treat all patterns as literals." },
  ["-g"] = { " arg", "Include or exclude file paths." },
  ["-h"] = { "Show help output." },
  ["-H"] = { "Print the file path with each matching line." },
  ["-i"] = { "Case insensitive search." },
  ["-I"] = { "Never print the path with each matching line." },
  ["-j"] = { " arg", "Set the approximate number of threads to use." },
  ["-l"] = { "Print the paths with at least one match." },
  ["-L"] = { "Follow symbolic links." },
  ["-m"] = { " arg", "Limit the number of matching lines." },
  ["-M"] = { " arg", "Omit lines longer than this limit." },
  ["-n"] = { "Show line numbers." },
  ["-N"] = { "Suppress line numbers." },
  ["-o"] = { "Print only matched parts of a line." },
  ["-p"] = { "Alias for colors, headings and line numbers." },
  ["-P"] = { "Enable PCRE2 matching." },
  ["-q"] = { "Do not print anything to stdout." },
  ["-r"] = { " arg", "Replace matches with the given text." },
  ["-s"] = { "Search case sensitively (default)." },
  ["-S"] = { "Smart case search." },
  ["-t"] = { " arg", "Only search files matching TYPE." },
  ["-T"] = { " arg", "Do not search files matching TYPE." },
  ["-u"] = { "Reduce the level of \"smart\" filtering." },
  ["-U"] = { "Enable searching across multiple lines." },
  ["-v"] = { "Invert matching." },
  ["-V"] = { "Print ripgrep's version." },
  ["-w"] = { "Show matches surrounded by word boundaries." },
  ["-x"] = { "Show matches surrounded by line boundaries." },
  ["-z"] = { "Search in compressed files." },
})
:addflags({
  "-e"..rg_regexp,
  "--regexp"..rg_regexp,
  "-f"..rg_file,
  "--file"..rg_file,
  "-A"..rg_aftercontext,
  "--after-context"..rg_aftercontext,
  "-B"..rg_beforecontext,
  "--before-context"..rg_beforecontext,
  "--binary",
  "--no-binary",
  "--block-buffered",
  "--no-block-buffered",
  "-b",
  "--byte-offset",
  "--no-byte-offset",
  "-s",
  "--case-sensitive",
  "--color"..rg_color,
  "--colors"..rg_colors,
  "--column",
  "--no-column",
  "-C"..rg_context,
  "--context"..rg_context,
  "--context-separator"..rg_contextseparator,
  "--no-context-separator",
  "-c",
  "--count",
  "--count-matches",
  "--crlf",
  "--no-crlf",
  "--debug",
  "--dfa-size-limit"..rg_dfasizelimit,
  "-E"..rg_encoding,
  "--encoding"..rg_encoding,
  "--no-encoding",
  "--engine"..rg_engine,
  "--field-context-separator"..rg_fieldcontextseparator,
  "--field-match-separator"..rg_fieldmatchseparator,
  "--files",
  "-l",
  "--files-with-matches",
  "--files-without-match",
  "-F",
  "--fixed-strings",
  "--no-fixed-strings",
  "-L",
  "--follow",
  "--no-follow",
  "--generate"..rg_generate,
  "-g"..rg_glob,
  "--glob"..rg_glob,
  "--glob-case-insensitive",
  "--no-glob-case-insensitive",
  "--heading",
  "--no-heading",
  "-h",
  "--help",
  "-.",
  "--hidden",
  "--no-hidden",
  "--hostname-bin"..rg_hostnamebin,
  "--hyperlink-format"..rg_hyperlinkformat,
  "--iglob"..rg_iglob,
  "-i",
  "--ignore-case",
  "--ignore-file"..rg_ignorefile,
  "--ignore-file-case-insensitive",
  "--no-ignore-file-case-insensitive",
  "--include-zero",
  "--no-include-zero",
  "-v",
  "--invert-match",
  "--no-invert-match",
  "--json",
  "--no-json",
  "--line-buffered",
  "--no-line-buffered",
  "-n",
  "--line-number",
  "-N",
  "--no-line-number",
  "-x",
  "--line-regexp",
  "-M"..rg_maxcolumns,
  "--max-columns"..rg_maxcolumns,
  "--max-columns-preview",
  "--no-max-columns-preview",
  "-m"..rg_maxcount,
  "--max-count"..rg_maxcount,
  "-d"..rg_maxdepth,
  "--max-depth"..rg_maxdepth,
  "--max-filesize"..rg_maxfilesize,
  "--mmap",
  "--no-mmap",
  "-U",
  "--multiline",
  "--no-multiline",
  "--multiline-dotall",
  "--no-multiline-dotall",
  "--no-config",
  "--no-ignore",
  "--ignore",
  "--no-ignore-dot",
  "--ignore-dot",
  "--no-ignore-exclude",
  "--ignore-exclude",
  "--no-ignore-files",
  "--ignore-files",
  "--no-ignore-global",
  "--ignore-global",
  "--no-ignore-messages",
  "--ignore-messages",
  "--no-ignore-parent",
  "--ignore-parent",
  "--no-ignore-vcs",
  "--ignore-vcs",
  "--no-messages",
  "--messages",
  "--no-require-git",
  "--require-git",
  "--no-unicode",
  "--unicode",
  "-0",
  "--null",
  "--null-data",
  "--one-file-system",
  "--no-one-file-system",
  "-o",
  "--only-matching",
  "--path-separator"..rg_pathseparator,
  "--passthru",
  "-P",
  "--pcre2",
  "--no-pcre2",
  "--pcre2-version",
  "--pre"..rg_pre,
  "--no-pre",
  "--pre-glob"..rg_preglob,
  "-p",
  "--pretty",
  "-q",
  "--quiet",
  "--regex-size-limit"..rg_regexsizelimit,
  "-r"..rg_replace,
  "--replace"..rg_replace,
  "-z",
  "--search-zip",
  "--no-search-zip",
  "-S",
  "--smart-case",
  "--sort"..rg_sort,
  "--sortr"..rg_sortr,
  "--stats",
  "--no-stats",
  "--stop-on-nonmatch",
  "-a",
  "--text",
  "--no-text",
  "-j"..rg_threads,
  "--threads"..rg_threads,
  "--trace",
  "--trim",
  "--no-trim",
  "-t"..rg_type,
  "--type"..rg_type,
  "-T"..rg_typenot,
  "--type-not"..rg_typenot,
  "--type-add"..rg_typeadd,
  "--type-clear"..rg_typeclear,
  "--type-list",
  "-u",
  "--unrestricted",
  "-V",
  "--version",
  "--vimgrep",
  "-H",
  "--with-filename",
  "-I",
  "--no-filename",
  "-w",
  "--word-regexp",
  "--auto-hybrid-regex",
  "--no-auto-hybrid-regex",
  "--no-pcre2-unicode",
  "--pcre2-unicode",
  "--sort-files",
  "--no-sort-files",
  onarg = onarg_contains_opt,
  function(_, _, _, _, user_data) clink.onfiltermatches(function(matches) return do_filter(matches, rg__hide_unless, user_data) end) end,
})
