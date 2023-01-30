--------------------------------------------------------------------------------
-- It would have been great to simply use the "winget complete" command.  But
-- it has two problems:
--      1.  It doesn't provide completions for lots of things (esp. arguments
--          for most flags).  It never provides filename or directory matches.
--      2.  It can't support input line coloring, because there's no way to
--          populate the parse tree in advance, and because there's no way to
--          reliably infer the parse tree.
--
-- However, we'll use it where we can, because it does provide fancy
-- completions for some things (at least when a partial word is entered, e.g.
-- for `winget install Power` which finds package names with prefix "Power").

local standalone = not clink or not clink.argmatcher
local clink_version = require('clink_version')

--------------------------------------------------------------------------------
-- Helper functions.

-- Clink v1.4.12 and earlier fall into a CPU busy-loop if
-- match_builder:setvolatile() is used during an autosuggest strategy.
local volatile_fixed = clink_version.has_volatile_matches_fix

local function sanitize_word(line_state, index, info)
    if not info then
        info = line_state:getwordinfo(index)
    end

    local end_offset = info.offset + info.length - 1
    if volatile_fixed and end_offset < info.offset and index == line_state:getwordcount() then
        end_offset = line_state:getcursor() - 1
    end

    local word = line_state:getline():sub(info.offset, end_offset)
    word = word:gsub('"', '\\"')
    return word
end

local function append_word(text, word)
    if #text > 0 then
        text = text .. " "
    end
    return text .. word
end

local function sanitize_line(line_state)
    local text = ""
    for i = 1, line_state:getwordcount() do
        local info = line_state:getwordinfo(i)
        local word
        if info.alias then
            word = "winget"
        elseif not info.redir then
            word = sanitize_word(line_state, i, info)
        end
        if word then
            text = append_word(text, word)
        end
    end
    local endword = sanitize_word(line_state, line_state:getwordcount())
    return text, endword
end

local debug_print_query
if tonumber(os.getenv("DEBUG_CLINK_WINGET") or "0") > 0 then
    local query_count = 0
    local color_index = 0
    local color_values = { "52", "94", "100", "22", "23", "19", "53" }
    debug_print_query = function (endword)
        query_count = query_count + 1
        color_index = color_index + 1
        if color_index > #color_values then
            color_index = 1
        end
        clink.print("\x1b[s\x1b[H\x1b[1;37;48;5;"..color_values[color_index].."mQUERY #"..query_count..", endword '"..endword.."'\x1b[m\x1b[K\x1b[u", NONL)
    end
else
    debug_print_query = function () end
end

local function winget_complete(word, index, line_state, builder) -- luacheck: no unused args
    local matches = {}
    local winget = os.getenv("LOCALAPPDATA")

    -- In the background (async auto-suggest), delay `winget complete` by 200 ms
    -- to coalesce rapid keypresses into a single query.  Overall, this improves
    -- the responsiveness for showing auto-suggestions which involve slow
    -- network queries.  The drawback is that all background `winget complete`
    -- queries take 200 milliseconds longer to show results.  But it can save
    -- many seconds, so on average it works out as feeling more responsive.
    if winget and volatile_fixed and builder.setvolatile and rl.islineequal then
        local co, ismain = coroutine.running()
        if not ismain then
            local orig_line = line_state:getline():sub(1, line_state:getcursor() - 1)
            clink.setcoroutineinterval(co, .2)
            coroutine.yield()
            clink.setcoroutineinterval(co, 0)
            if not rl.islineequal(orig_line, true) then
                winget = nil
                builder:setvolatile()
            end
        end
    end

    if winget then
        winget = '"'..path.join(winget, "Microsoft\\WindowsApps\\winget.exe")..'"'

        local commandline, endword = sanitize_line(line_state)
        debug_print_query(endword)
        local command = '2>nul '..winget..' complete --word="'..endword..'" --commandline="'..commandline..'" --position=99999' -- luacheck: no max line length
        local f = io.popen(command)
        if f then
            for line in f:lines() do
                line = line:gsub('"', '')
                if line ~= "" and (standalone or line:sub(1,1) ~= "-") then
                    table.insert(matches, line)
                end
            end
            f:close()
        end

        -- Mark the matches volatile even when generation was skipped due to
        -- running in a coroutine.  Otherwise it'll never run it in the main
        -- coroutine, either.
        if volatile_fixed and builder.setvolatile then
            builder:setvolatile()
        end

        -- Hack to enable quoting.
        if clink.matches_are_files and not clink_version.has_quoting_fix then
            clink.matches_are_files()
        end
    end
    return matches
end

--------------------------------------------------------------------------------
-- When this script is run as a standalone Lua script, it can traverse the
-- available winget commands and flags and output the available completions.
-- This helps when updating the completions this script supports.

if standalone then

    local function ignore_match(match)
        if match == "--help" or
                match == "--no-vt" or
                match == "--rainbow" or
                match == "--retro" or
                match == "--verbose-logs" or
                false then
            return true
        end
    end

    local function dump_completions(line, recursive)
        local line_state = clink.parseline(line..' ""')[1].line_state
        local t = winget_complete("", 0, line_state, {})
        if #t > 0 then
            print(line)
            for _, match in ipairs(t) do
                if not ignore_match(match) then
                    print("", match)
                end
            end
            print()
            if recursive then
                for _, match in ipairs(t) do
                    if not ignore_match(match) then
                        dump_completions(line.." "..match, not match:find("^-") )
                    end
                end
            end
        end
    end

    dump_completions("winget", true)
    return

end

--------------------------------------------------------------------------------
-- Parsers for linking.

local arghelper = require("arghelper")

local empty_arg = clink.argmatcher():addarg()
local contextual_matches = clink.argmatcher():addarg({winget_complete})

local add_source_matches = empty_arg
local arch_matches = contextual_matches
local command_matches = contextual_matches
local count_matches = clink.argmatcher():addarg({fromhistory=true, 10, 20, 40})
local dependency_source_matches = clink.argmatcher():addarg({fromhistory=true})
local file_matches = clink.argmatcher():addarg(clink.filematches)
local header_matches = clink.argmatcher():addarg({fromhistory=true})
local id_matches = contextual_matches
local locale_matches = clink.argmatcher():addarg({fromhistory=true})
local location_matches = clink.argmatcher():addarg(clink.dirmatches)
local moniker_matches = contextual_matches
local name_matches = contextual_matches
local override_matches = clink.argmatcher():addarg({fromhistory=true})
local productcode_matches = clink.argmatcher():addarg({fromhistory=true})
local query_matches = clink.argmatcher():addarg({fromhistory=true})
local scope_matches = contextual_matches
local setting_name_matches = clink.argmatcher():addarg({fromhistory=true})
local source_matches = contextual_matches
local tag_matches = contextual_matches
local type_matches = clink.argmatcher():addarg({"Microsoft.PreIndexed.Package"})
local url_matches = empty_arg
local version_matches = contextual_matches

--------------------------------------------------------------------------------
-- Factored flag definitions.

local arch_locale_flags = {
    { hide=true, "-a"..arch_matches },
    { "--architecture"..arch_matches, " arch", "" },
    { "--locale"..locale_matches, " locale", "" },
}

local common_flags = {
    { "--verbose-logs" },
    { "--no-vt" },
    { "--rainbow" },
    { "--retro" },
    { "--help" },
    { hide=true, "-?" },
    { hide=true, "--wait" },
    { hide=true, "--disable-interactivity" },
    { hide=true, "--verbose" },
}

local query_flags = {
    { hide=true, "-q"..query_matches },
    { "--query"..query_matches, " query", "" },
    { "--id"..id_matches, " id", "" },
    { "--name"..name_matches, " name", "" },
    { "--moniker"..moniker_matches, " moniker", "" },
    { hide=true, "-e" },
    { "--exact" },
}

local query_flags_more = {
    { "--tag"..tag_matches, " tag", "" },
    { "--command"..command_matches, " command", "" },
    { hide=true, "-n"..count_matches, "" },
    { "--count"..count_matches, " count", "" },
}

local source_flags = {
    { hide=true, "-s"..source_matches },
    { "--source"..source_matches, " source", "" },
}

--------------------------------------------------------------------------------
-- Command parsers.

local export_parser = clink.argmatcher():_addexflags({
    opteq=true,
    { hide=true, "-o"..file_matches },
    { "--output"..file_matches, " file", "" },
    source_flags,
    { hide=true, "--include-versions" },
    { hide=true, "--accept-source-agreements" },
    common_flags,
})
:addarg(clink.filematches)
:nofiles()

local features_parser = clink.argmatcher():_addexflags({
    common_flags,
})
:nofiles()

local hash_parser = clink.argmatcher():_addexflags({
    opteq=true,
    { hide=true, "-f"..file_matches },
    { "--file"..file_matches, " file", ""},
    { hide=true, "-m" },
    { "--msix" },
    common_flags,
})
:addarg(clink.filematches)
:nofiles()

local import_parser = clink.argmatcher():_addexflags({
    opteq=true,
    { hide=true, "-i"..file_matches },
    { "--import-file"..file_matches, " file", "" },
    { "--ignore-unavailable" },
    { "--ignore-versions" },
    { "--no-upgrade" },
    { hide=true, "--accept-package-agreements" },
    { hide=true, "--accept-source-agreements" },
    common_flags,
})
:addarg(clink.filematches)
:nofiles()

local install_parser = clink.argmatcher():_addexflags({
    opteq=true,
    query_flags,
    { hide=true, "-m"..file_matches },
    { "--manifest"..file_matches, " file", "" },
    { hide=true, "-v"..version_matches },
    { "--version"..version_matches, " version", "" },
    source_flags,
    { "--scope"..scope_matches, " scope", "" },
    arch_locale_flags,
    { hide=true, "-i" },
    { "--interactive" },
    { hide=true, "-h" },
    { "--silent" },
    { hide=true, "-o"..file_matches },
    { "--log"..file_matches, " file", "" },
    { "--override"..override_matches, " string", "" },
    { hide=true, "-l"..location_matches },
    { "--location"..location_matches, " location", "" },
    { "--force" },
    { "--ignore-security-hash" },
    { "--ignore-local-archive-malware-scan" },
    { "--dependency-source"..dependency_source_matches },
    { "--accept-package-agreements" },
    { "--accept-source-agreements" },
    { "--no-upgrade" },
    { "--header"..header_matches, " header", "" },
    { hide=true, "-r"..file_matches },
    { "--rename"..file_matches, " file", "" },
    common_flags,
})
:addarg({winget_complete})
:nofiles()

local __search_parser_flags = {
    query_flags,
    query_flags_more,
    source_flags,
    { hide=true, "--accept-source-agreements" },
    { "--header"..header_matches, " header", "" },
    common_flags,
}

local list_parser = clink.argmatcher():_addexflags({
    opteq=true,
    __search_parser_flags,
    { "--scope"..scope_matches, " scope", "" },
})
:addarg({winget_complete})
:nofiles()

local search_parser = clink.argmatcher():_addexflags({
    opteq=true,
    __search_parser_flags,
})
:addarg({winget_complete})
:nofiles()

local settings_parser = clink.argmatcher():_addexflags({
    { "--enable"..setting_name_matches, " setting", "" },
    { "--disable"..setting_name_matches, " setting", "" },
})
:addarg(setting_name_matches)
:nofiles()

local show_parser = clink.argmatcher():_addexflags({
    opteq=true,
    query_flags,
    { hide=true, "-m"..file_matches },
    { "--manifest"..file_matches, " file", "" },
    source_flags,
    arch_locale_flags,
    { hide=true, "-v"..version_matches },
    { "--version"..version_matches, " version", "" },
    { "--versions" },
    { "--header"..header_matches, " header", "" },
    { "--accept-source-agreements" },
    common_flags,
})
:addarg({winget_complete})
:nofiles()

local source_add_parser = clink.argmatcher():_addexflags({
    { hide=true, "-n"..add_source_matches },
    { "--name"..add_source_matches, " name", "" },
    { hide=true, "-a"..url_matches },
    { "--arg"..url_matches, " url", "" },
    { hide=true, "-t"..type_matches },
    { "--type"..type_matches, " type", "" },
    { "--header"..header_matches, " header", "" },
    { "--accept-source-agreements" },
    common_flags,
})
:addarg(add_source_matches)
:nofiles()

local source_list_parser = clink.argmatcher():_addexflags({
    { hide=true, "-n"..source_matches },
    { "--name"..source_matches, " name", "" },
    common_flags,
})
:addarg(source_matches)
:nofiles()

local source_update_parser = clink.argmatcher():_addexflags({
    { hide=true, "-n"..source_matches },
    { "--name"..source_matches, " name", "" },
    common_flags,
})
:addarg(source_matches)
:nofiles()

local source_remove_parser = clink.argmatcher():_addexflags({
    { hide=true, "-n"..source_matches },
    { "--name"..source_matches, " name", "" },
    common_flags,
})
:addarg(source_matches)
:nofiles()

local source_reset_parser = clink.argmatcher():_addexflags({
    { hide=true, "-n"..source_matches },
    { "--name"..source_matches, " name", "" },
    { "--force" },
    common_flags,
})
:addarg(source_matches)
:nofiles()

local source_export_parser = clink.argmatcher():_addexflags({
    { hide=true, "-n"..source_matches },
    { "--name"..source_matches, " name", "" },
    common_flags,
})
:addarg(source_matches)
:nofiles()

local source_parser = clink.argmatcher():_addexflags({
    opteq=true,
    common_flags,
})
:addarg({
    "add"..source_add_parser,
    "list"..source_list_parser,
    "update"..source_update_parser,
    "remove"..source_remove_parser,
    "reset"..source_reset_parser,
    "export"..source_export_parser,
    { hide=true, "ls"..source_list_parser },
    { hide=true, "refresh"..source_update_parser },
    { hide=true, "rm"..source_remove_parser },
})
:nofiles()

local uninstall_parser = clink.argmatcher():_addexflags({
    opteq=true,
    query_flags,
    query_flags_more,
    { hide=true, "-m"..file_matches },
    { "--manifest"..file_matches, " file", "" },
    { "--product-code"..productcode_matches, " code", "" },
    { hide=true, "-v"..version_matches },
    { "--version"..version_matches, " version", "" },
    source_flags,
    { "--scope"..scope_matches, " scope", "" },
    { hide=true, "-i" },
    { "--interactive" },
    { hide=true, "-h" },
    { "--silent" },
    { "--force" },
    { "--purge" },
    { "--preserve" },
    { hide=true, "-o"..file_matches },
    { "--log"..file_matches, " file", "" },
    { "--accept-source-agreements" },
    { "--header"..header_matches, " header", "" },
    common_flags,
})
:addarg({winget_complete})
:nofiles()

local upgrade_parser = clink.argmatcher():_addexflags({
    opteq=true,
    query_flags,
    { hide=true, "-m"..file_matches },
    { "--manifest"..file_matches, " file", "" },
    { hide=true, "-v"..version_matches },
    { "--version"..version_matches, " version", "" },
    source_flags,
    { hide=true, "-i" },
    { "--interactive" },
    { hide=true, "-h" },
    { "--silent" },
    { "--purge" },
    { hide=true, "-o"..file_matches },
    { "--log"..file_matches, " file", "" },
    { "--override"..override_matches, " string", "" },
    { hide=true, "-l"..location_matches },
    { "--location"..location_matches, " location", "" },
    { "--scope"..scope_matches, " scope", "" },
    arch_locale_flags,
    { "--ignore-security-hash" },
    { "--ignore-local-archive-malware-scan" },
    { "--force" },
    { "--accept-package-agreements" },
    { "--accept-source-agreements" },
    { "--header"..header_matches, " header", "" },
    { hide=true, "-r" },
    { hide=true, "--recurse" },
    { "--all" },
    { hide=true, "-u" },
    { hide=true, "--unknown" },
    { "--include-unknown" },
    common_flags,
})
:addarg({winget_complete})
:nofiles()

local validate_parser = clink.argmatcher():_addexflags({
    opteq=true,
    { "--manifest"..file_matches, " file", "" },
    common_flags
})
:addarg(clink.filematches)
:nofiles()

local complete_parser = clink.argmatcher():_addexflags({
    nosort=true,
    { "--word"..empty_arg, " word", "" },
    { "--commandline"..empty_arg, " text", "" },
    { "--position"..empty_arg, " num", "" },
})
:nofiles()

--------------------------------------------------------------------------------
-- Define the winget argmatcher.

local winget_command_data_table = {
    { "install",    install_parser,     "add" },
    { "show",       show_parser,        "view" },
    { "source",     source_parser },
    { "search",     search_parser,      "find" },
    { "list",       list_parser,        "ls" },
    { "upgrade",    upgrade_parser,     "update" },
    { "uninstall",  uninstall_parser,   "rm", "remove" },
    { "hash",       hash_parser },
    { "validate",   validate_parser },
    { "settings",   settings_parser,    "config" },
    { "features",   features_parser },
    { "export",     export_parser },
    { "import",     import_parser },
    { nil,          complete_parser,    "complete" },
}

local hidden_aliases = {}
local winget_commands = {}

for _,command in ipairs(winget_command_data_table) do
    local i = 3
    while command[i] do
        if command[2] then
            table.insert(winget_commands, command[i]..command[2])
        else
            table.insert(winget_commands, command[i])
        end
        table.insert(hidden_aliases, command[i])
        i = i + 1
    end
    if command[1] then
        if command[2] then
            table.insert(winget_commands, command[1]..command[2])
        else
            table.insert(winget_commands, command[1])
        end
    end
end

table.insert(winget_commands, arghelper.make_arg_hider_func(hidden_aliases))

clink.argmatcher("winget")
:_addexarg(winget_commands)
:_addexflags({
    common_flags,
    { hide=true, "-v" },
    "--version",
    "--info",
})
