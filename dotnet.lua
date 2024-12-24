local matchers = require('matchers')
local standalone = not clink or not clink.argmatcher
local clink_version = require('clink_version')

--------------------------------------------------------------------------------
-- Helper functions for invoking `dotnet complete` to let dotnet itself
-- generate completions.

-- luacheck: max line length 100

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
    local word_len = #word
    word = word:gsub('"', '\\"')
    return word, word_len
end

local function append_word(text, word)
    local added_len = 0
    if #text > 0 then
        text = text .. " "
        added_len = 1
    end
    return text .. word, added_len
end

local function sanitize_line(line_state)
    local text = ""
    local endpos = 1
    for i = 1, line_state:getwordcount() do
        local info = line_state:getwordinfo(i)
        local word, word_len, added_len
        if info.alias then
            word = "dotnet"
        elseif not info.redir then
            word, word_len = sanitize_word(line_state, i, info)
        end
        if word then
            if not word_len then
                word_len = #word
            end
            text, added_len = append_word(text, word)
            endpos = endpos + added_len + word_len
        end
    end
    local endword = sanitize_word(line_state, line_state:getwordcount())
    return text, endword, endpos
end

local debug_print_query
if tonumber(os.getenv("DEBUG_CLINK_DOTNET") or "0") > 0 then
    local query_count = 0
    local color_index = 0
    local color_values = { "52", "94", "100", "22", "23", "19", "53" }
    debug_print_query = function (endword)
        query_count = query_count + 1
        color_index = color_index + 1
        if color_index > #color_values then
            color_index = 1
        end
        clink.print("\x1b[s\x1b[H\x1b[1;37;48;5;"..color_values[color_index].."mQUERY #"..query_count..", endword '"..endword.."'\x1b[m\x1b[K\x1b[u", NONL) -- luacheck: no max line length, no global
    end
else
    debug_print_query = function () end
end

local function dotnet_complete(word, index, line_state, builder) -- luacheck: no unused args
    local matches = {}
    local dotnet = "dotnet.exe"

    -- In the background (async auto-suggest), delay `dotnet complete` by 200 ms
    -- to coalesce rapid keypresses into a single query.  Overall, this improves
    -- the responsiveness for showing auto-suggestions which involve slow
    -- network queries.  The drawback is that all background `dotnet complete`
    -- queries take 200 milliseconds longer to show results.  But it can save
    -- many seconds, so on average it works out as feeling more responsive.
    if dotnet and volatile_fixed and builder.setvolatile and rl.islineequal then
        local co, ismain = coroutine.running()
        if not ismain then
            local orig_line = line_state:getline():sub(1, line_state:getcursor() - 1)
            clink.setcoroutineinterval(co, .2)
            coroutine.yield()
            clink.setcoroutineinterval(co, 0)
            if not rl.islineequal(orig_line, true) then
                dotnet = nil
                builder:setvolatile()
            end
        end
    end

    if dotnet then
        local commandline, endword, endpos = sanitize_line(line_state)
        debug_print_query(endword)
        local command = string.format('2>nul %s complete --position %s "%s"', dotnet, endpos, commandline) -- luacheck: no max line length
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

        -- Enable quoting.
        if builder.setforcequoting then
            builder:setforcequoting()
        elseif clink.matches_are_files then
            clink.matches_are_files()
        end
    end
    return matches
end

--------------------------------------------------------------------------------
-- When this script is run as a standalone Lua script, it can traverse the
-- available dotnet commands and flags and output the available completions.
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
        local t = dotnet_complete("", 0, line_state, {})
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

    dump_completions("dotnet", true)
    return

end

--------------------------------------------------------------------------------
-- Argmatcher for the dotnet.exe program.

local parser = clink.arg.new_parser

local function package_reference_onadvance(arg_index, word, word_index, line_state, user_data)
    if arg_index == 1 then
        if word ~= "" and word ~= "package" and word ~= "reference" then
            if user_data and not user_data.project_argument then
                user_data.project_argument = true
                return 0 -- Repeat using the Advance to next argument position BEFORE parsing the word.
            end
        end
    end
end

local package_list = parser({dotnet_complete})
local reference_list = parser({dotnet_complete})
local package_reference_commands = parser({
    "reference" .. reference_list,
    "package" .. package_list,
    onadvance = package_reference_onadvance,
})

local runtime_parser = parser({
    -- Windows
    "win-x64", "win-x86", "win-arm", "win-arm64", "win7-x64", "win7-x86",
    "win81-x64", "win81-x86", "win81-arm", "win10-x64", "win10-x86", "win10-arm",
    "win10-arm64",

    -- Linux
    "linux-x64", "linux-musl-x64", "linux-arm", "rhel-x64", "rhel.6-x64", "tizen",
    "tizen.4.0.0", "tizen.5.0.0",

    -- macOS
    "osx-x64", "osx.10.10-x64", "osx.10.11-x64", "osx.10.12-x64", "osx.10.13-x64",
    "osx.10.14-x64"
})

local framework_parser = parser({
    "netstandard1.0", "netstandard1.1", "netstandard1.2", "netstandard1.3",
    "netstandard1.4", "netstandard1.5", "netstandard1.6", "netstandard2.0",
    "netstandard2.1",

    "netcoreapp1.0", "netcoreapp1.1", "netcoreapp2.0", "netcoreapp2.1",
    "netcoreapp2.2", "netcoreapp3.0", "netcoreapp3.1",

    "net11", "net20", "net35", "net40", "net403", "net45", "net451", "net452",
    "net46", "net461", "net462", "net47", "net471", "net472", "net48"
})

local verbosity_parser = parser({"quiet", "minimal", "normal", "detailed", "diagnostic"})

local configuration_parser = parser({"Debug", "Release"})

local build_parser = parser({matchers.files})

build_parser:add_flags(
    "--configuration"..configuration_parser,
    "--force",
    "--framework"..framework_parser,
    "--help",
    "--interactive",
    "--nologo",
    "--no-dependencies",
    "--no-incremental",
    "--no-restore",
    "--output",
    "--runtime"..runtime_parser,
    "--verbosity"..verbosity_parser,
    "--version-suffix"
)

local publish_parser = parser({matchers.files})

publish_parser:add_flags({
    "--configuration"..configuration_parser,
    "--force",
    "--framework"..framework_parser,
    "--help",
    "--manifest",
    "--no-build",
    "--no-dependencies",
    "--no-restore",
    "--output",
    "--runtime"..runtime_parser,
    "--self-contained",
    "--verbosity"..verbosity_parser,
    "--version-suffix",
}):loop(1)


local clean_parser = parser({matchers.files})

clean_parser:add_flags(
    "--configuration"..configuration_parser,
    "--framework"..framework_parser,
    "--help",
    "--interactive",
    "--nologo",
    "--output",
    "--runtime",
    "--verbosity"..verbosity_parser
)

local mvc_webapp_parser = parser({
    "--auth"..parser({"None", "Individual", "IndividualB2C", "SingleOrg", "MultiOrg", "Windows"}),
    "--aad-b2c-instance",
    "--susi-policy-id",
    "--reset-password-policy-id",
    "--edit-profile-policy-id",
    "--aad-instance",
    "--client-id",
    "--domain",
    "--tenant-id",
    "--callback-path",
    "--org-read-access",
    "--exclude-launch-settings",
    "--no-https",
    "--use-local-db",
    "--no-restore"
}):loop(1)

local new_parser = parser({
    "angular", "react", "reactredux",
    "blazorserver",
    "classlib"..parser({"--framework"..framework_parser, "--langVersion", "--no-restore"}),
    "console"..parser({"--langVersion", "--no-restore"}),
    "gitignore",
    "globaljson"..parser({"--sdk-version"}),
    "grpc",
    "mstest",
    "mvc"..mvc_webapp_parser,
    "nugetconfig",
    "nunit-test",
    "nunit",
    "page"..parser({"--namespace", "--no-pagemodel"}),
    "razorclasslib",
    "razorcomponent",
    "sln",
    "tool-manifest",
    "viewimports"..parser({"--namespace"}),
    "viewstart",
    "web"..parser({"--exclude-launch-settings", "--no-restore", "--no-https"}),
    "webapi",
    "webapp"..mvc_webapp_parser,
    "webconfig",
    "wpf", "wpflib", "wpfcustomcontrollib", "wpfusercontrollib", "winforms", "winformslib",
    "worker",
    "xunit"
})

new_parser:add_flags(
    "--dry-run", "--force", "--help", "--install", "--list", "--language", "--name",
    "--nuget-source", "--output", "--type", "--update-check", "--update-apply"
)

local run_parser = parser({matchers.files})

run_parser:add_flags(
    "--configuration"..configuration_parser,
    "--force",
    "--framework"..framework_parser,
    "--help",
    "--launch-profile",
    "--no-restore",
    "--project",
    "--runtime"..runtime_parser,
    "--verbosity"..verbosity_parser
)

local ef_parser = parser({
    "database"..parser({
        "drop"..parser("--force", "--dry-run"),
        "update"
    }),
    "dbcontext"..parser({
        "info",
        "list",
        "scaffold"..parser(
            "--data-annotations",
            "--context",
            "--context-dir",
            "--force",
            "--output-dir",
            "--schema",
            "--table",
            "--use-database-names"
        ),
    }),
    "migrations"..parser({
        "add"..parser("--output-dir"),
        "list",
        "remove"..parser("--force"),
        "script"..parser("--output-dir", "--idempotent")
    })
})

ef_parser:add_flags(
    "--context", -- <DbContext>
    "--project", -- <Project>
    "--startup-project", -- <Project>
    "--framework"..framework_parser,
    "--configuration"..configuration_parser,
    "--runtime"..runtime_parser,
    "--json", "--help", "--verbose", "--no-color", "--prefix-output"
)

local dotnet_parser = parser({
    "add"..package_reference_commands,
    "build"..build_parser,
    "build-server",
    "clean"..clean_parser,
    "help",
    "list"..package_reference_commands,
    "msbuild",
    "new"..new_parser,
    "nuget",
    "pack",
    "publish"..publish_parser,
    "remove"..package_reference_commands,
    "restore",
    "run"..run_parser,
    "sln"..parser({"add", "remove", "list"}),
    "store",
    "test",
    "tool",
    "vstest",

    -- Tools:
    "ef"..ef_parser
})

dotnet_parser:add_flags(
    "--help", "--info", "--list-sdks", "--list-runtimes"
)

clink.arg.register_parser("dotnet", dotnet_parser)
