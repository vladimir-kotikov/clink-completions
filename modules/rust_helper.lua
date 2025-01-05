-- Helper for completions for Rust commands.
--
-- Uses delayinit callbacks to dynamically (re-)initialize the argmatcher by
-- running the program with appropriate help commands.

local exports = {}

--------------------------------------------------------------------------------
local clink_version = require('clink_version')
if not clink_version.has_linked_setdelayinit_fix then
    log.info("rust_helper.lua requires a newer version of Clink; please upgrade.")
    return
end

--------------------------------------------------------------------------------
local debug
if os.getenv("DEBUG_RUST_COMPLETIONS") then
    require("dumpvar")
    debug = {
        debug_output = true,                -- Enable debugging output.
        debug_log_all_usage = true,         -- Write all USAGE info to dbgfile.
        debug_log_all = true,               -- Write all subcommands and flags to dbgfile.
        debug_warn_missed_usage = true,     -- Print warning for any USAGE lines that fail to parse.
        --debug_nodelay = true,               -- No delayinit; initialize the full argmatcher tree immediately.
    }
end

local include_long_flag_descriptions = false
local include_nightly_only = false

--------------------------------------------------------------------------------
-- luacheck: globals NONL
local dbgpro = "\x1b[s\x1b[H"
local dbgcolor = "\x1b[36m"
local dbgepi = "\x1b[K\x1b[u"
local norm = "\x1b[m"
--local red = "\x1b[38;5;160m"
--local reverse = "\x1b[7m"
--local unreverse = "\x1b[27m"
local function dbgprint(msg) -- luacheck: no unused
    if debug and debug.debug_output then
        clink.print(dbgpro..dbgcolor..msg..norm..dbgepi, NONL)
    end
end

local function open_tmp_file(name, mode)
    local dir = os.gettemppath()
    if dir then
        return io.open(path.join(dir, name), mode)
    end
end

--------------------------------------------------------------------------------
local forwards = {}

local function delayinit(argmatcher)
    argmatcher:setdelayinit(nil)

    local help_commands = argmatcher.rust_data.help_commands
    local help_command = help_commands[argmatcher]
    if not help_command then
        log.info("Internal error in help_commands map.")
        return
    end

    if not argmatcher.rust_data.dbgformat then
        local dbgfile = open_tmp_file(argmatcher.rust_data.logtag.."_parser_output.log", "w")
        argmatcher.rust_data.dbgformat = function(fmt, ...)
            if dbgfile then
                if fmt then
                    local msg = string.format(fmt.."\n", ...)
                    dbgfile:write(msg)
                else
                    dbgfile:flush()
                end
            end
        end
    end
    argmatcher.rust_data.dbgformat(string.rep("-", 78))

    if argmatcher.rust_data.dashdashlist then
        forwards.run(argmatcher, help_command, { nocommands=true })
        forwards.run(argmatcher, "help", { help_command="--list" })
    else
        if help_command == "" then
            help_command = "help"
        end
        forwards.run(argmatcher, help_command)
    end

    if debug and debug.debug_nodelay then
        local sorted = {}
        while debug.debug_nodelay_init_list or sorted[1] do
            if debug.debug_nodelay_init_list then
                for _,matcher in ipairs(debug.debug_nodelay_init_list) do
                    table.insert(sorted, help_commands[matcher])
                end
                debug.debug_nodelay_init_list = nil
            end
            table.sort(sorted)
            forwards.run(help_commands[sorted[1]], sorted[1])
            table.remove(sorted, 1)
        end
    end

    argmatcher.rust_data.dbgformat()

    argmatcher:setflagprefix("+") -- for +toolchain syntax.
end

function exports.make_rust_argmatcher(pgm)
    local matcher = clink.argmatcher(path.getbasename(pgm)):setdelayinit(delayinit)

    local help_commands = {}
    help_commands[matcher] = ""
    help_commands[""] = matcher

    local data = {}
    data.pgm = pgm
    data.logtag = path.getbasename(pgm)
    data.help_commands = help_commands
    matcher.rust_data = data

    return matcher
end

--------------------------------------------------------------------------------
local function make_subcommand_argmatcher(help_command, word, aliased, rust_data)
    local matcher
    if help_command and word then
        local help_commands = rust_data.help_commands
        help_command = help_command.." "..word
        matcher = help_commands[help_command]
        if not matcher then
            matcher = clink.argmatcher()
            help_commands[matcher] = aliased or help_command
            help_commands[help_command] = matcher
            if aliased then
                help_commands[aliased] = matcher
            end
            if debug and debug.debug_nodelay then
                debug.debug_nodelay_init_list = debug.debug_nodelay_init_list or {}
                table.insert(debug.debug_nodelay_init_list, matcher)
            else
                local rd = {}
                for k,v in pairs(rust_data) do
                    rd[k] = v
                end
                rd.dashdashlist = nil
                matcher.rust_data = rd
                matcher:setdelayinit(delayinit)
            end
        end
    end
    return matcher or clink.argmatcher()
end

local function sentence_casing(text)
    if unicode.iter then -- luacheck: no global
        for str in unicode.iter(text) do -- luacheck: ignore 512, no global
            return clink.upper(str) .. text:sub(#str + 1)
        end
        return text
    else
        return clink.upper(text:sub(1,1)) .. text:sub(2)
    end
end

local function patesc(s) -- luacheck: no unused
    return s:gsub("%-", "%%-")
end

--------------------------------------------------------------------------------
local arg_parsers = {}

local function join_words(help_command, flag, display)
    local s = ""
    if help_command then
        s = s..help_command:gsub(" +$", "").." "
    end
    if flag then
        s = s..flag.." "
    end
    if display then
        s = s..display
    end
    return s:gsub(" +$", "")
end

--[[
local function override_parser_cmdflag(help_command, flags, parser)
    parser = parser or clink.argmatcher():addarg({fromhistory=true})
    arg_parsers[join_words(help_command, flags)] = parser
    return parser
end
]]

local function parse_lint_help(argmatcher)
    argmatcher:setdelayinit(nil)
    local matches = {}
    local r = io.popen("2>&1 rustc.exe -W help")
    if r then
        local listing
        for line in r:lines() do
            if line:match("^%s*$") then
                listing = nil
            elseif listing then
                local name, dflt, meaning = line:match("^%s+([^ ]+)%s%s+([^ ]+)%s%s+(.+)$")
                if not name then
                    name, meaning = line:match("^%s+([^ ]+)%s%s+(.+)$")
                end
                if name then
                    local t
                    if dflt then
                        dflt = string.format("  (%s)", dflt)
                    else
                        t = "alias"
                    end
                    table.insert(matches, { match=name, arginfo=dflt, description=meaning, type=t })
                end
            elseif line:match("^%s+%-%-%-") then
                listing = true
            end
        end
        r:close()
    end
    argmatcher:addarg(matches)
end

local function parse_codegen_help(argmatcher)
    argmatcher:setdelayinit(nil)
    local matches = {}
    local r = io.popen("2>&1 rustc.exe -C help")
    if r then
        for line in r:lines() do
            if line:match("^%s+%-C%s") then
                local name, meaning = line:match("^%s+%-C%s+([^ ]+=)val%s+%-%-%s+(.+)$")
                if name then
                    table.insert(matches, { match=name, description=meaning })
                end
            end
        end
        r:close()
    end
    argmatcher:addarg(matches)
end

local _kind_path = "[kind=]path"
local _kind_path_words = { "crate=", "dependency=", "framework=", "native=" }
local _kind_name = "[kind[:modifiers]=]name[:rename]"
local _kind_name_words = { "dylib=", "framework=", "static=" }

arg_parsers["<file>"] = clink.argmatcher():addarg(clink.filematches)
arg_parsers["<dir>"] = clink.argmatcher():addarg(clink.dirmatches)
arg_parsers["lint"] = clink.argmatcher():setdelayinit(parse_lint_help) -- for RUSTC
arg_parsers["opt[=value]"] = clink.argmatcher():setdelayinit(parse_codegen_help) -- for RUSTC
arg_parsers[_kind_path] = clink.argmatcher():addarg({nosort=true, _kind_path_words, clink.dirmatches}) -- for RUSTC
arg_parsers[_kind_name] = clink.argmatcher():addarg({nosort=true, _kind_name_words, fromhistory=true}) -- for RUSTC

local arg_values = {}
--arg_values["pr checkout"] = { "this", "that" }

local _file_keywords = { "file", "files", "filename", "filenames", "glob" }
local _dir_keywords = { "dir", "dirs", "directory", "directories", "path", "paths" }

for _, k in ipairs(_file_keywords) do
    _file_keywords[" <" .. k .. ">"] = true
    _file_keywords["<" .. k .. ">"] = true
    _file_keywords[" " .. k] = true
    _file_keywords[k] = true
end
for _, k in ipairs(_dir_keywords) do
    _dir_keywords[" <" .. k .. ">"] = true
    _dir_keywords["<" .. k .. ">"] = true
    _dir_keywords[" " .. k] = true
    _dir_keywords[k] = true
end

local function map_display(display)
    display = display:lower()
    if _file_keywords[display] or display:find("file") then
        return "<file>"
    elseif _dir_keywords[display] then
        return "<dir>"
    end
    return display
end

local function get_arg_parser(help_command, flag, display)
    display = display and map_display(display)
    local args
::retry::
    if flag then
        args = args or display and arg_parsers[join_words(help_command, flag, display)]
        args = args or arg_parsers[join_words(help_command, flag)]
        args = args or display and arg_parsers[join_words(nil, flag, display)]
        args = args or arg_parsers[flag]
    end
    if display then
        args = args or arg_parsers[join_words(help_command, nil, display)]
        args = args or arg_parsers[display]
        if not args then
            args = clink.argmatcher():addarg({ fromhistory=true })
            arg_parsers[display] = args
        end
    end
    args = args or arg_parsers[help_command]
    if not args and help_command ~= "" then
        if help_command:find("%s") then
            -- Try stripping off the last word, and retry.
            help_command = help_command:gsub("%s*%g+%s*$", "")
            goto retry
        end
    end
    return args
end

local function get_arg_values(help_command)
    local args
    args = arg_values[help_command]
    return args
end

--------------------------------------------------------------------------------
local function fill_pending_display(p, f)
    local display = f and f.display
    if not display and p.has_arg then
        display = p.arginfo
    end
    if not display then
        p.display = nil
    elseif f.flag:match("[:=]$") then
        p.display = display:gsub("^[ \t]", "")
    else
        p.display = " " .. display:gsub("^[ \t]", "")
    end
end

--------------------------------------------------------------------------------
local function add_pending(context, flags, descriptions, hideflags, pending) -- luacheck: no unused args
    if debug and debug.debug_log_all then
        if pending.subcommand then -- luacheck: ignore 542
            context.dbgformat("        %-32s  %-24s  %s", pending.subcommand, pending.display or "", pending.desc)
        elseif pending.flag then
            if pending.display and not pending.predefined_parser then
                context.dbgformat("        %-32s  %-24s  %s", pending.flag, pending.display or "", pending.desc)
            end
        end
    end

    if pending.subcommand then
        if not context.subcommands[pending.subcommand] then
            context.argvalues = context.argvalues or {}
            local argmatcher = make_subcommand_argmatcher(context.help_command, pending.subcommand, pending.aliased, context.rust_data) -- luacheck: no max line length
            table.insert(context.argvalues, pending.subcommand..argmatcher)
            context.subcommands[pending.subcommand] = true
            context.dbgformat("new subcommand '"..pending.subcommand.."'")
        else
            context.dbgformat("duplicate subcommand '"..pending.subcommand.."'")
        end
    elseif pending.flag then
        if pending.has_arg and pending.display then
            if not pending.argmatcher then
                if not pending.flag:match("[:=]$") and not pending.display:match("^[ \t]") then -- luacheck: ignore 542
                    if debug then
                        -- NOTE: The onadvance and onlink callbacks make this possible, with some effort.
                        error("Argmatchers must be separated from flag by : or = or space (-x<n> etc are not supported); '"..join_words(context.help_command, pending.flag, pending.display).."'.") -- luacheck: no max line length
                    end
                else
                    pending.argmatcher = clink.argmatcher():addarg({fromhistory=true})
                end
            end
            pending.args = pending.argmatcher
        else
            pending.args = nil
        end

        table.insert(flags, { flag=pending.flag, args=pending.args })
    else
        return
    end

    local key = pending.subcommand or pending.flag
    pending.desc = (pending.desc or "")
    pending.desc = pending.desc:gsub("%.%s+.+$", "")
    pending.desc = pending.desc:gsub("%s+<http.->", "")
    pending.desc = pending.desc:gsub("%.+$", "")
    if pending.flag and key == pending.flag and not include_long_flag_descriptions and key:match("^%-%-") then
        pending.desc = "" -- Don't add desc for long flag.
    end
    if pending.display then
        descriptions[key] = { pending.display, pending.desc }
    else
        descriptions[key] = { pending.desc }
    end
end

--------------------------------------------------------------------------------
local function parse_section(section, line)
-- TODO: parse arguments section for cargo
    if line:find("^Arguments:") then return "ARGUMENTS" end
    if line:find("^Options:") or line:find("^OPTIONS") then return "FLAGS" end
    if line:find("Commands:$") then return "COMMANDS" end
    if line:find("^Additional help:") then return "ADDLHELP" end

    local upper = line:match("^(%u+)$")
    return upper or section
end

--------------------------------------------------------------------------------
local function parse_line(context, flags, descriptions, hideflags, line, config)
    local last_line = not line

    context.section = line and parse_section(context.section, line) or nil
    line = line or ""

    -- Parse continuations.
    if context.pending then
        if line:match("^%s*$") and not last_line then
            return
        end
        local x = line:match("^          +([^ ].+)$")
        if x then
            -- The line is part of a description.
            context.arg_line_missing_desc = nil
            if context.desc then
                context.desc = context.desc .. " "
            end
            context.desc = (context.desc or "") .. x
            return
        end
    end

    -- Add any pending subcommand or flags.
    if context.pending and
            context.desc and
            not include_nightly_only and
            context.desc:match("[Nn]ightly%-only") then -- luacheck: ignore 542
        -- Ignore nightly-only flags.
    elseif context.pending then
        local p = context.pending
        if context.desc then
            if not include_nightly_only and line:match("[Nn]ightly%-only") then
                line = ""
            end
            context.expect_args = context.desc:find(";$")
            context.desc = context.desc:gsub("%.+$", "")
            context.desc = context.desc:gsub(";$", "")
            context.desc = sentence_casing(context.desc)
            context.pending.desc = context.desc
            context.desc = nil
        end

        if p.subcommand then
            fill_pending_display(p)
            add_pending(context, flags, descriptions, hideflags, p)
        else
            for _,f in ipairs(p) do
                if f.flag == "-NUM" then -- luacheck: ignore 542
                    -- Clink can't represent minus followed by any number.
                    --TODO:  This is possible with onarg and onlink callbacks.
                else
                    p.flag = f.flag
                    p.has_arg = f.has_arg or (f.has_arg == nil and p.arginfo)
                    fill_pending_display(p, f)
                    add_pending(context, flags, descriptions, hideflags, p)
                end
            end
        end
        context.pending = {}
        context.arg_line_missing_desc = nil
    end

    -- Parse section changes.
    local section = context.section
    if not section then
        return
    end

    -- Parse if the line declares a subcommand.
    if section == "COMMANDS" then
        if not config.nocommands then
            local subcommand, desc = line:match("^%s+(%g+)%s+(.+)$")
            if subcommand and subcommand ~= "..." then
                context.pending.subcommand = subcommand
                context.pending.argmatcher = get_arg_values(context.help_command)
                context.pending.predefined_parser = context.pending.argmatcher and true
                context.desc = desc
            end
        end
        return
    end

    -- Parse if the line declares one or more flags.
    if section == "FLAGS" then
        if line:match("^%s%s+%-") then
            -- All flags on a single line share one argmatcher.
            local short, sarg, long, larg, desc
            line = line:gsub("^%s+", "")
            short = line:match("^(%-[^-%s])")
            if short then
                line = line:sub(#short + 1)
                sarg = line:match("^%s([^-%s][^,%s]*)")
                if sarg then
                    line = line:sub(1 + #sarg + 1)
                end
                if line:match("^,") then
                    line = line:sub(2)
                end
                line = line:gsub("^%s+", "")
            end
            long = line:match("^(%-%-%g+)")
            if long then
                line = line:sub(#long + 1)
                larg = line:match("^%s([^-%s][^,%s]*)")
                if larg then
                    line = line:sub(1 + #larg + 1)
                end
                line = line:gsub("^%s+", "")
            end
            desc = line:gsub("^%s+", "")

            -- Short and long flags.
            local p = context.pending
            local arg = sarg or larg or nil
            local has_arg = arg and true or false
            if arg and arg:find("%|.+%|") then
                arg = arg:gsub("^%[", ""):gsub("%]$", "")
                local arglist = string.explode(arg, "|")
                p.argmatcher = clink.argmatcher():addarg(arglist)
                arg = "VALUE"
            end
            if short then
                table.insert(p, { flag=short, has_arg=has_arg, display=arg })
            end
            if long then
                table.insert(p, { flag=long, has_arg=has_arg, display=arg })
            end
            if short or long then
                if desc and desc ~= "" then
                    context.arg_line_missing_desc = nil
                    context.desc = desc
                else
                    context.arg_line_missing_desc = true
                    context.desc = nil
                end
                p.arginfo = arg
                if not p.argmatcher then
                    p.expect_args = has_arg
                    p.argmatcher = get_arg_parser(context.help_command, short or long, arg)
                end
            end
        end
        return
    end

    --[[
    -- Rustc has an "Additional help:" section which we'll treat as flags that
    -- contain spaces.
    if section == "ADDLHELP" then
        if line:match("^%s%s+%-") then
            local flag, desc = line:match("^%s+(%-.-)%s%s+(.*)$")
            if flag then
                local p = context.pending
                table.insert(p, { flag=flag })
                context.desc = desc
            end
        end
    end
    --]]
end

--------------------------------------------------------------------------------
forwards.run = function(argmatcher, help_command, config)
    local flags = {}
    local descriptions = {}
    local hideflags = {}
    config = config or {}

    local context = {
        pending={},
        subcommands={},
        help_command=help_command,
        pgm=argmatcher.rust_data.pgm,
        rust_data=argmatcher.rust_data,
        dbgformat=argmatcher.rust_data.dbgformat,
    }

    help_command = (config and config.help_command) or help_command or "--help"

    local lines
    do
        -- SIGH, rustup prints help text to stderr, not stdout.
        local nostderr = "2>&1 " -- "2>nul "

        local c = nostderr..context.pgm.." "..help_command
        context.dbgformat("RUN '%s'", c)
        local r = io.popen(c)
        if not r then
            context.dbgformat("popen failed.")
            return
        end

        lines = {}
        for line in r:lines() do
            -- The Rust tools use UTF8, so conversion from ACP isn't needed;
            -- but callers needing conversion can set config.convert_encoding.
            if config.convert_encoding and unicode.fromcodepage then -- luacheck: no global
                line = unicode.fromcodepage(line) -- luacheck: no global
            end
            table.insert(lines, line)
        end
        r:close()
    end

    if lines then
        for _,line in ipairs(lines) do
            parse_line(context, flags, descriptions, hideflags, line, config)
        end
    end
    parse_line(context, flags, descriptions, hideflags, nil, config)

    if config.slashes then
        local slashes = {}
        for _, f in ipairs(flags) do
            if f.flag:match("^%-[^-]") then
                local sf = f.flag:gsub("^%-", "/")
                table.insert(slashes, { flag=sf, args=f.args })
                descriptions[sf] = descriptions[f.flag]
            end
        end
        for _, sf in ipairs(slashes) do
            table.insert(flags, sf)
        end
    end

    local caseless
    if config.case == 1 then
        -- Caseless:  Explicitly forcing caseless.
        caseless = true
    elseif config.case == nil then
        -- Smart case:  Caseless if all flags are upper case.
        caseless = true
        for _, f in ipairs(flags) do
            local lower = clink.lower(f.flag)
            if lower == f.flag then
                local upper = clink.upper(f.flag)
                if upper ~= f.flag then
                    caseless = false
                    break
                end
            end
        end
    end

    local actual_flags = {}

    if caseless then
        for _, f in ipairs(flags) do
            local lower = clink.lower(f.flag)
            if f.flag ~= lower then
                if f.args then
                    table.insert(actual_flags, lower .. f.args)
                else
                    table.insert(actual_flags, lower)
                end
                table.insert(hideflags, lower)
            end
        end
    end

    for _, f in ipairs(flags) do
        if f.args then
            table.insert(actual_flags, f.flag .. f.args)
        else
            table.insert(actual_flags, f.flag)
        end
    end

    argmatcher:addflags(actual_flags)
    argmatcher:adddescriptions(descriptions)
    argmatcher:hideflags(hideflags)

    if context.argvalues then
        argmatcher:addarg(context.argvalues)
    end
end

--------------------------------------------------------------------------------
return exports
