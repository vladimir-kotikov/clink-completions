require("arghelper")

-- TODO: update with new flags that winget supports now.

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

--------------------------------------------------------------------------------
-- Helper functions.

-- Clink v1.4.12 and earlier fall into a CPU busy-loop if
-- match_builder:setvolatile() is used during an autosuggest strategy.
local volatile_fixed = ((clink.version_encoded or 0) >= 10040013)

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
    local endword = ""
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
    endword = sanitize_word(line_state, line_state:getwordcount())
    return text, endword
end

local function winget_complete(word, index, line_state, builder) -- luacheck: no unused args
    local matches = {}
    local winget = os.getenv("LOCALAPPDATA")
    if winget then
        -- Don't run `winget complete` in the background.  Since the results
        -- have to be volatile, it would rerun and potentially hit the network
        -- for every letter typed or deleted.
        local _, ismain = coroutine.running()
        if ismain then
            winget = '"'..path.join(winget, "Microsoft\\WindowsApps\\winget.exe")..'"'
            local commandline, endword = sanitize_line(line_state)
            local command = '2>nul '..winget..' complete --word="'..endword..'" --commandline="'..commandline..'" --position=99999'
            local f = io.popen(command)
            if f then
                for line in f:lines() do
                    line = line:gsub('"', '')
                    if line:sub(1,1) ~= "-" then
                        table.insert(matches, line)
                    end
                end
                f:close()
            end
        end

        -- Mark the matches volatile even when generation was skipped due to
        -- running in a coroutine.  Otherwise it'll never run it in the main
        -- coroutine, either.
        if volatile_fixed and builder.setvolatile then
            builder:setvolatile()
        end

        -- Hack to enable quoting.
        if clink.matches_are_files then
            clink.matches_are_files()
        end
    end
    return matches
end

--------------------------------------------------------------------------------
-- Parsers for linking.

local empty_arg = clink.argmatcher():addarg()
local contextual_matches = clink.argmatcher():addarg({winget_complete})

local add_source_matches = empty_arg
local arch_matches = clink.argmatcher():addarg({fromhistory=true})
local command_matches = clink.argmatcher():addarg({fromhistory=true})
local count_matches = clink.argmatcher():addarg({fromhistory=true, 10, 20, 40})
local file_matches = clink.argmatcher():addarg(clink.filematches)
local header_matches = clink.argmatcher():addarg({fromhistory=true})
local id_matches = clink.argmatcher():addarg({fromhistory=true})
local locale_matches = clink.argmatcher():addarg({fromhistory=true})
local location_matches = clink.argmatcher():addarg(clink.dirmatches)
local moniker_matches = clink.argmatcher():addarg({fromhistory=true})
local name_matches = clink.argmatcher():addarg({fromhistory=true})
local override_matches = clink.argmatcher():addarg({fromhistory=true})
local productcode_matches = clink.argmatcher():addarg({fromhistory=true})
local query_matches = clink.argmatcher():addarg({fromhistory=true})
local scope_matches = clink.argmatcher():addarg({fromhistory=true})
local setting_name_matches = clink.argmatcher():addarg({fromhistory=true})
local source_matches = contextual_matches
local tag_matches = clink.argmatcher():addarg({fromhistory=true})
local type_matches = clink.argmatcher():addarg({"Microsoft.PreIndexed.Package"})
local url_matches = empty_arg
local version_matches = contextual_matches

--------------------------------------------------------------------------------
-- Factored flag definitions.

local common_flags = {
    { hide=true, "--verbose-logs" },
    { hide=true, "--no-vt" },
    { hide=true, "--rainbow" },
    { hide=true, "--retro" },
    { hide=true, "-?" },
    { "--help" },
}

local query_flags = {
    { hide=true, "-q"..query_matches },
    { "--query"..query_matches, " query", "" },
    { "--id"..id_matches, " id", "" },
    { "--name"..name_matches, " name", "" },
    { "--moniker"..moniker_matches, " moniker", "" },
    { "--tag"..tag_matches, " tag", "" },
    { "--command"..command_matches, " command", "" },
    { hide=true, "-n"..count_matches, "" },
    { "--count"..count_matches, " count", "" },
    { hide=true, "-e" },
    { "--exact" },
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
    { hide=true, "--accept-package-agreements" },
    { hide=true, "--accept-source-agreements" },
    common_flags,
})
:addarg(clink.filematches)
:nofiles()

local install_parser = clink.argmatcher():_addexflags({
    opteq=true,
    { hide=true, "-m"..file_matches },
    { "--manifest"..file_matches, " file", "" },
    { hide=true, "-v"..version_matches },
    { "--version"..version_matches, " version", "" },
    source_flags,
    { "--scope"..scope_matches, " scope", "" },
    { hide=true, "-a"..arch_matches },
    { "--architecture"..arch_matches, " arch", "" },
    { hide=true, "-i" },
    { "--interactive" },
    { hide=true, "-h" },
    { "--silent" },
    { "--locale"..locale_matches, " locale", "" },
    { hide=true, "-o"..file_matches },
    { "--log"..file_matches, " file", "" },
    { "--override"..override_matches, " string", "" },
    { hide=true, "-l"..location_matches },
    { "--location"..location_matches, " location", "" },
    { "--force" },
    { "--accept-package-agreements" },
    { "--accept-source-agreements" },
    { "--header"..header_matches, " header", "" },
    { hide=true, "-r"..file_matches },
    { "--rename"..file_matches, " file", "" },
    common_flags,
})
:addarg({winget_complete})
:nofiles()

local list_parser = clink.argmatcher():_addexflags({
    opteq=true,
    query_flags,
    source_flags,
    { hide=true, "--accept-source-agreements" },
    { "--header"..header_matches, " header", "" },
    common_flags,
})
:addarg({winget_complete})
:nofiles()

local search_parser = list_parser

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
    common_flags,
})
:addarg(name_matches)
:nofiles()

local source_list_parser = clink.argmatcher():_addexflags({
    { hide=true, "-n"..source_matches },
    { "--name"..source_matches, " name", "" },
    common_flags,
})
:addarg(name_matches)
:nofiles()

local source_update_parser = clink.argmatcher():_addexflags({
    { hide=true, "-n"..source_matches },
    { "--name"..source_matches, " name", "" },
    common_flags,
})
:addarg(name_matches)
:nofiles()

local source_remove_parser = clink.argmatcher():_addexflags({
    { hide=true, "-n"..source_matches },
    { "--name"..source_matches, " name", "" },
    common_flags,
})
:addarg(name_matches)
:nofiles()

local source_reset_parser = clink.argmatcher():_addexflags({
    { "--force" },
    common_flags,
})
:nofiles()

local source_export_parser = clink.argmatcher():_addexflags({
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
})
:nofiles()

local uninstall_parser = clink.argmatcher():_addexflags({
    opteq=true,
    query_flags,
    { hide=true, "-m"..file_matches },
    { "--manifest"..file_matches, " file", "" },
    { "--product-code"..productcode_matches, " code", "" },
    { hide=true, "-v"..version_matches },
    { "--version"..version_matches, " version", "" },
    { hide=true, "-i" },
    { "--interactive" },
    { hide=true, "-h" },
    { "--silent" },
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
    { "--force" },
    { "--accept-package-agreements" },
    { "--accept-source-agreements" },
    { "--header"..header_matches, " header", "" },
    { "--all" },
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

local winget_parser = {
    "install" .. install_parser,
    "show" .. show_parser,
    "source" .. source_parser,
    "search" .. search_parser,
    "list" .. list_parser,
    "upgrade" .. upgrade_parser,
    "uninstall" .. uninstall_parser,
    "hash" .. hash_parser,
    "validate" .. validate_parser,
    "settings" .. settings_parser,
    "features" .. features_parser,
    "export" .. export_parser,
    "import" .. import_parser,
    { hide=true, "complete" .. complete_parser },
}

clink.argmatcher("winget")
:_addexarg(winget_parser)
:_addexflags({
    common_flags,
    { hide=true, "-v" },
    "--version",
    "--info",
})
