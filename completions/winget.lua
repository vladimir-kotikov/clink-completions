require("arghelper")

--------------------------------------------------------------------------------
-- It would have been great to simply use the "winget complete" command.
-- But it doesn't provide completions for lots of things.

--------------------------------------------------------------------------------
-- Helper functions.

local function winget_complete(command)
    local matches = {}
    local winget = os.getenv("USERPROFILE")
    if winget then
        winget = '"'..path.join(winget, "AppData\\Local\\Microsoft\\WindowsApps\\winget.exe")..'"'
        local f = io.popen('2>nul '..winget..' complete --word="" --commandline="winget '..command..' " --position='..tostring(9 + #command)) -- luacheck: no max line length
        if f then
            for line in f:lines() do
                table.insert(matches, line)
            end
            f:close()
        end
    end
    return matches
end

local function complete_export_source()
    return winget_complete("export --source")
end

--------------------------------------------------------------------------------
-- Parsers for linking.

local add_source_matches = clink.argmatcher():addarg()
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
local source_matches = clink.argmatcher():addarg({complete_export_source})
local tag_matches = clink.argmatcher():addarg({fromhistory=true})
local type_matches = clink.argmatcher():addarg({"Microsoft.PreIndexed.Package"})
local url_matches = clink.argmatcher():addarg()
local version_matches = clink.argmatcher():addarg()

--------------------------------------------------------------------------------
-- Factored flag definitions.

local common_flags = {
    { hide=true, "--verbose-logs" },
    { hide=true, "--no-vt" },
    { hide=true, "--rainbow" },
    { hide=true, "--retro" },
    { "-?" },
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

local help_parser = clink.argmatcher():addarg({
    "export",
    "features",
    "hash",
    "help",
    "import",
    "info",
    "install",
    "list",
    "search",
    "settings",
    "show",
    "source",
    "uninstall",
    "upgrade",
    "validate",
})
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

local info_parser = clink.argmatcher():_addexflags({
    common_flags,
})
:nofiles()

local install_parser = clink.argmatcher():_addexflags({
    opteq=true,
    query_matches,
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
:addarg(query_matches)
:nofiles()

local list_parser = clink.argmatcher():_addexflags({
    opteq=true,
    query_flags,
    source_flags,
    { hide=true, "--accept-source-agreements" },
    { "--header"..header_matches, " header", "" },
    common_flags,
})
:addarg(query_matches)
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
:addarg(query_matches)
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
:addarg(query_matches)
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
:addarg(query_matches)
:nofiles()

local validate_parser = clink.argmatcher():_addexflags({
    opteq=true,
    { "--manifest"..file_matches, " file", "" },
    common_flags
})
:addarg(clink.filematches)
:nofiles()

--------------------------------------------------------------------------------
-- Define the winget argmatcher.

local winget_parser = {
    "export" .. export_parser,
    "features" .. features_parser,
    "hash" .. hash_parser,
    "help" .. help_parser,
    "import" .. import_parser,
    "info" .. info_parser,
    "install" .. install_parser,
    "list" .. list_parser,
    "search" .. search_parser,
    "settings" .. settings_parser,
    "show" .. show_parser,
    "source" .. source_parser,
    "uninstall" .. uninstall_parser,
    "upgrade" .. upgrade_parser,
    "validate" .. validate_parser,
}

clink.argmatcher("winget"):addarg(winget_parser):addflags("--version", "--info", "--help")
