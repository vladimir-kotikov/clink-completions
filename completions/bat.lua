-- Completions for bat (https://github.com/sharkdp/bat).

--------------------------------------------------------------------------------
local cached_language_list
local function list_languages(_, _, _, builder)
    if cached_language_list then
        return cached_language_list
    end

    local m = {}
    local f = io.popen('2>nul bat.exe --list-languages')
    if f then
        if builder.setforcequoting then
            builder:setforcequoting()
            for line in f:lines() do
                local lang = line:match('^([^:]+):')
                if lang then
                    table.insert(m, lang)
                end
            end
        else
            for line in f:lines() do
                local lang = line:match('^([^:]+):')
                if lang then
                    if lang:find('[+ ()]') then
                        lang = '"' .. lang .. '"'
                    end
                    table.insert(m, lang)
                end
            end
        end
        f:close()
    end

    cached_language_list = m
    return m
end

--------------------------------------------------------------------------------
local function list_themes(_, _, _, builder)
    local m = {}
    local f = io.popen('2>nul bat.exe --list-themes')
    if f then
        if builder.setforcequoting then
            builder:setforcequoting()
            for line in f:lines() do
                table.insert(m, line)
            end
        else
            for line in f:lines() do
                if line:find('[+ ()]') then
                    line = '"' .. line .. '"'
                end
                table.insert(m, line)
            end
        end
        f:close()
    end
    return m
end

--------------------------------------------------------------------------------
local function map_syntax(word, word_index, line_state, builder, user_data)
    local m = {}
    local info = line_state:getwordinfo(word_index)
    if info then
        local cursorword = line_state:getline():sub(info.offset, line_state:getcursor() - 1)
        if cursorword:find(":$") then
            local l = list_languages(word, word_index, line_state, builder, user_data)
            if (clink.version_encoded or 0) >= 10020038 then
                local norm = "\x1b[m"
                for _, value in ipairs(l) do
                    table.insert(m, { match=cursorword..value, display=norm..value, type="word" })
                end
            else
                for _, value in ipairs(l) do
                    table.insert(m, cursorword..value)
                end
            end
        end
    end
    builder:setvolatile()
    return m
end

--------------------------------------------------------------------------------
local function make_args_with_desc(list)
    local out = clink.argmatcher()
    local values = {}
    local descriptions = {}
    for _, entry in ipairs(list) do
        table.insert(values, entry[1])
        if entry[2] then
            descriptions[entry[1]] = entry[2]
        end
    end
    out:addarg(values)
    if out.adddescriptions then
        out:adddescriptions(descriptions)
    end
    return out
end

--------------------------------------------------------------------------------
-- luacheck: no max line length

local bat = clink.argmatcher('bat')

local dir_completions = clink.argmatcher():addarg(clink.dirmatches)
local file_completions = clink.argmatcher():addarg(clink.filematches)
local when_always_auto_never = clink.argmatcher():addarg({'always', 'auto', 'never'})

local bat_binary = clink.argmatcher():addarg({'no-printing', 'as-text'})
local bat_color = when_always_auto_never
local bat_completion = clink.argmatcher():addarg({'bash', 'fish', 'zsh', 'ps1'})
local bat_decorations = when_always_auto_never
local bat_diffcontext = clink.argmatcher():addarg({'1', '2', '3', '5', '10', '20', '50'})
local bat_filename = file_completions
local bat_highlightline = clink.argmatcher():addarg({})
local bat_ignoredsuffix = clink.argmatcher():addarg({fromhistory=true})
local bat_italictext = when_always_auto_never
local bat_language = clink.argmatcher():addarg({list_languages})
local bat_linerange = clink.argmatcher():addarg({})
local bat_mapsyntax = clink.argmatcher():addarg({map_syntax})
local bat_nonprintablenotation = clink.argmatcher():addarg({"unicode", "caret"})
local bat_pager = clink.argmatcher():addarg({fromhistory=true})
local bat_paging = when_always_auto_never
local bat_source = dir_completions
local bat_squeezelimit = clink.argmatcher():addarg({fromhistory=true})
local bat_stripansi = when_always_auto_never
local bat_style = make_args_with_desc({
    {"default", "recommended components"},
    {"auto", "same as 'default' unless piped"},
    {"full", "all components"},
    {"plain", "no components"},
    {"changes", "Git change markers"},
    {"header", "alias for header-filename"},
    {"header-filename", "filename above content"},
    {"header-filesize", "filesize above content"},
    {"grid", "lines b/w sidebar/header/content"},
    {"numbers", "line numbers in sidebar"},
    {"rule", "separate files"},
    {"snip", "separate ranges"},
})
local bat_tabs = clink.argmatcher():addarg({'0', '1', '2', '3', '4', '8'})
local bat_target = dir_completions
local bat_terminalwidth = clink.argmatcher():addarg({fromhistory=true, '72', '80', '100', '120'})
local bat_theme = clink.argmatcher():addarg({'auto', 'dark', 'light', list_themes})
local bat_themedark = clink.argmatcher():addarg({list_themes})
local bat_themelight = clink.argmatcher():addarg({list_themes})
local bat_wrap = clink.argmatcher():addarg({'auto', 'never', 'character'})

if bat.adddescriptions then
    bat:adddescriptions({
        ["--acknowledgements"] = { "Build acknowledgements.bin" },
        ["--binary"] = { " <behavior>", "How to treat binary content" },
        ["--blank"] = { "Create new data instead of appending" },
        ["--build"] = { "Parse new definitions into cache" },
        ["--cache-dir"] = { "Show bat's cache directory" },
        ["--chop-long-lines"] = { "Truncate all lines longer than screen width" },
        ["--clear"] = { "Reset definitions to defaults" },
        ["--color"] = { " <when>", "When to use colored output" },
        ["--completion"] = { " <shell>", "Show shell completion for a certain shell" },
        ["--config-dir"] = { "Display location of configuration directory" },
        ["--config-file"] = { "Display location of configuration file" },
        ["--decorations"] = { " <when>", "When to use --style decorations" },
        ["--diagnostic"] = { "Print diagnostic info for bug reports" },
        ["--diff"] = { "Only show lines with Git changes" },
        ["--diff-context"] = { " <N>", "Show N context lines around Git changes" },
        ["--file-name"] = { " <name>", "Specify the display name" },
        ["--force-colorization"] = { "Force color and decorations" },
        ["--generate-config-file"] = { "Generates a default configuration file" },
        ["--help"] = { "Print all $bat-cache help" },
        ["--highlight-line"] = { " <N:M>", "Highlight line(s) N to [M]" },
        ["--ignored-suffix"] = { " <suffix>", "Ignore extension" },
        ["--italic-text"] = { " <when>", "When to use italic text in the output" },
        ["--language"] = { " <language>", "Set the syntax highlighting language" },
        ["--lessopen"] = { "Enable the $LESSOPEN preprocessor" },
        ["--line-range"] = { " <N:M>", "Only print lines [N] to [M] (either optional)" },
        ["--list-languages"] = { "List syntax highlighting languages" },
        ["--list-themes"] = { "List syntax highlighting themes" },
        ["--map-syntax"] = { " <glob:syntax>", "Map <glob pattern>:<language syntax>" },
        ["--no-config"] = { "Do not use the configuration file" },
        ["--no-custom-assets"] = { "Do not load custom assets" },
        ["--no-lessopen"] = { "Disable the $LESSOPEN preprocessor if enabled (overrides --lessopen)" },
        ["--no-paging"] = { "Alias for --paging=never" },
        ["--nonprintable-notation"] = { " <notation>", "Set notation for non-printable characters" },
        ["--number"] = { "Only show line numbers, no other decorations" },
        ["--pager"] = { " <command>", "Which pager to use" },
        ["--paging"] = { " <when>", "When to use the pager" },
        ["--plain"] = { "Disable decorations" },
        ["--set-terminal-title"] = { "Sets terminal title to filenames when using a pager" },
        ["--show-all"] = { "Show non-printable characters" },
        ["--source"] = { " <dir>", "Load syntaxes and themes from DIR" },
        ["--squeeze-blank"] = { "Squeeze consecutive empty lines into a single empty line" },
        ["--squeeze-limit"] = { " <limit>", "Set the maximum number of consecutive empty lines to be printed" },
        ["--strip-ansi"] = { " <when>", "Specify when to strip ANSI escape sequences from the input" },
        ["--style"] = { " <components>", "Specify which non-content elements to display" },
        ["--tabs"] = { " <T>", "Set tab width (0 to pass tabs through directly)" },
        ["--target"] = { " <dir>", "Store cache in DIR" },
        ["--terminal-width"] = { " <width>", "Set terminal <width>, +<offset>, or -<offset>" },
        ["--theme"] = { " <theme>", "Set the syntax highlighting theme" },
        ["--theme-dark"] = { " <theme>", "Set the syntax highlighting theme for dark backgrounds" },
        ["--theme-light"] = { " <theme>", "Set the syntax highlighting theme for light backgrounds" },
        ["--unbuffered"] = { "This option exists for POSIX-compliance reasons" },
        ["--version"] = { "Show version information" },
        ["--wrap"] = { " <mode>", "Text-wrapping mode" },
        ["-A"] = { "Show non-printable characters" },
        ["-c"] = { "Truncate all lines longer than screen width" },
        ["-d"] = { "Only show lines with Git changes" },
        ["-f"] = { "Force color and decorations" },
        ["-h"] = { "Print a concise overview of $bat-cache help" },
        ["-H"] = { " <N:M>", "Highlight line(s) N to [M]" },
        ["-l"] = { " <language>", "Set the syntax highlighting language" },
        ["-m"] = { " <glob:syntax>", "Map <glob pattern>:<language syntax>" },
        ["-n"] = { "Only show line numbers, no other decorations" },
        ["-p"] = { "Disable decorations" },
        ["-P"] = { "Disable paging" },
        ["-pp"] = { "Disable decorations and paging" },
        ["-r"] = { " <N:M>", "Only print lines [N] to [M] (either optional)" },
        ["-s"] = { "Squeeze consecutive empty lines into a single empty line" },
        ["-u"] = { "This option exists for POSIX-compliance reasons" },
        ["-V"] = { "Show version information" },
    })
end

bat:addflags({
  "--acknowledgements",
  "--binary"..bat_binary,
  "--cache-dir",
  "-c",
  "--chop-long-lines",
  "--color"..bat_color,
  "--completion"..bat_completion,
  "--config-dir",
  "--config-file",
  "--decorations"..bat_decorations,
  "--diagnostic",
  "-d",
  "--diff",
  "--diff-context"..bat_diffcontext,
  "--generate-config-file",
  "--file-name"..bat_filename,
  "-f",
  "--force-colorization",
  "-h",
  "--help",
  "-H"..bat_highlightline,
  "--highlight-line"..bat_highlightline,
  "--ignored-suffix"..bat_ignoredsuffix,
  "--italic-text"..bat_italictext,
  "-l"..bat_language,
  "--language"..bat_language,
  "--lessopen",
  "-r"..bat_linerange,
  "--line-range"..bat_linerange,
  "--list-languages",
  "--list-themes",
  "-m"..bat_mapsyntax,
  "--map-syntax"..bat_mapsyntax,
  "--no-config",
  "--no-custom-assets",
  "--no-lessopen",
  "--nonprintable-notation"..bat_nonprintablenotation,
  "-n",
  "--number",
  "--no-paging",
  "--pager"..bat_pager,
  "--paging"..bat_paging,
  "-p",
  "--plain",
  "--set-terminal-title",
  "-A",
  "--show-all",
  "-s",
  "--squeeze-blank",
  "--squeeze-limit"..bat_squeezelimit,
  "--strip-ansi"..bat_stripansi,
  "-p",
  "--plain",
  "-pp",
  "-P",
  "--style"..bat_style,
  "--tabs"..bat_tabs,
  "--terminal-width"..bat_terminalwidth,
  "--theme"..bat_theme,
  "--theme-dark"..bat_themedark,
  "--theme-light"..bat_themelight,
  "-u",
  "--unbuffered",
  "-V",
  "--version",
  "--wrap"..bat_wrap,
  "--build",
  "--clear",
  "--blank",
  "--source"..bat_source,
  "--target"..bat_target,
  "--acknowledgements",
  "-h",
  "--help",
})

--------------------------------------------------------------------------------
if clink.onbeginedit then
    clink.onbeginedit(function()
        cached_language_list = nil
    end)
end
