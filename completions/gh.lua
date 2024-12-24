--------------------------------------------------------------------------------
-- GitHub CLI (`gh`) argmatcher.
--
-- Uses delayinit callbacks to dynamically (re-)initialize the argmatcher by
-- running `gh` with command words and `--help`.
--
-- https://github.com/cli/cli

local clink_version = require('clink_version')
if not clink_version.has_linked_setdelayinit_fix then
    log.info("gh.lua argmatcher requires a newer version of Clink; please upgrade.")
    return
end

--------------------------------------------------------------------------------
local debug = nil
--[[
debug = {
    debug_output = true,                -- Enable debugging output.
    debug_log_all_usage = true,         -- Write all USAGE info to dbgfile.
    debug_log_all = true,               -- Write all subcommands and flags to dbgfile.
    debug_warn_missed_usage = true,     -- Print warning for any USAGE lines that fail to parse.
    --debug_nodelay = true,               -- No delayinit; initialize the full argmatcher tree immediately.
}
--]]

--------------------------------------------------------------------------------
-- luacheck: globals NONL
local dbgpro = "\x1b[s\x1b[H"
local dbgcolor = "\x1b[36m"
local dbgepi = "\x1b[K\x1b[u"
local norm = "\x1b[m"
local red = "\x1b[38;5;160m"
local reverse = "\x1b[7m"
local unreverse = "\x1b[27m"
local function dbgprint(msg)
    if debug and debug.debug_output then
        clink.print(dbgpro..dbgcolor..msg..norm..dbgepi, NONL)
    end
end

local dbgfile
local function dbgout(msg)
    if dbgfile then
        dbgfile:write(msg.."\n")
    end
end

--------------------------------------------------------------------------------
local help_commands = {}
local forwards = {}

local function delayinit(argmatcher)
    argmatcher:setdelayinit(nil)

    local help_command = help_commands[argmatcher]
    if not help_command then
        log.info("Internal error in help_command map.")
        return
    end

    dbgfile = io.open("c:/tmp/gh_parser_output.log", "w")

    forwards.run(argmatcher, help_command)

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

    if dbgfile then
        dbgfile:close()
    end
end

local gh_matcher = clink.argmatcher("gh"):setdelayinit(delayinit)
help_commands[gh_matcher] = ""
help_commands[""] = gh_matcher

--------------------------------------------------------------------------------
-- This parser recognizes this layout (similar to GNU):
--
--      ... ignore lines unless they start with at least 2 spaces ...
--        -a...         description which could be
--                      more than one line
--        -a...
--                      description which could be
--                      more than one line
--
-- Some lines define more than one flag, delimited by commas:
--
--        -b, --bar, etc  description
--        -b, --bar, etc ...
--                      description
--
-- Some flags accept arguments, and follow these layouts:
--
--        --abc[=X]     Defines --abc and --abc=X.
--        --def=Y       Defines --def=Y.
--        -g, --gg=Z    Define -g and --gg= with required Z arg.
--        -j Z          Define -j with required Z arg.
--        -k[Z]         Define -k with optional Z arg, with no space.
--        --color[=WHEN],   <-- Notice the `,`
--        --colour[=WHEN]
--
-- Some flags have a predefined list of args:
--
--        --foo=XYZ     description which could be
--                      more than one line
--                      XYZ is 'a', 'b', or 'c'
--
-- Recognizes many variations of file and dir arg types.
-- Other arg types use fromhistory=true.
--
-- Special exception:
--
--      A minus sign followed by an arbitrary number isn't representable as a
--      flag in Clink.

local function make_subcommand_argmatcher(help_command, word, aliased)
    local matcher
    if help_command and word then
        help_command = help_command..word.." "
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

local function patesc(s)
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

local function override_parser_cmdflag(help_command, flags, parser)
    parser = parser or clink.argmatcher():addarg({fromhistory=true})
    arg_parsers[join_words(help_command, flags)] = parser
    return parser
end

arg_parsers["<file>"] = clink.argmatcher():addarg(clink.filematches)
arg_parsers["<dir>"] = clink.argmatcher():addarg(clink.dirmatches)
override_parser_cmdflag("", "-h --hostname", override_parser_cmdflag("", "--hostname"))
override_parser_cmdflag("", "-R --repo")
override_parser_cmdflag("auth", "-s --scopes")
override_parser_cmdflag("codespace", "-c --codespace")
override_parser_cmdflag("label create", "-c --color")
override_parser_cmdflag("label edit", "-c --color")

local arg_values = {}
arg_values["pr checkout"] = { "this", "that" }

local _file_keywords = { "file", "files", "filename", "filenames", "glob" }
local _dir_keywords = { "dir", "dirs", "directory", "directories", "path", "paths" }

for _, k in ipairs(_file_keywords) do
    _file_keywords[" <" .. k .. ">"] = true
    _file_keywords["<" .. k .. ">"] = true
    _file_keywords[" " .. k] = true
    _file_keywords[k] = true
    _file_keywords[" " .. k:upper()] = true
    _file_keywords[k:upper()] = true
end

for _, k in ipairs(_dir_keywords) do
    _dir_keywords[" <" .. k .. ">"] = true
    _dir_keywords["<" .. k .. ">"] = true
    _dir_keywords[" " .. k] = true
    _dir_keywords[k] = true
    _dir_keywords[" " .. k:upper()] = true
    _dir_keywords[k:upper()] = true
end

local function map_display(display)
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
        args = args or display and arg_parsers[join_words(help_command, nil, display)]
        args = args or display and arg_parsers[display]
    end
    args = args or arg_parsers[help_command]
    if not args and help_command ~= "" then
        help_command = help_command:gsub("[^%s]+ $", "")
        goto retry
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
            --dbgout(string.format("        %-32s  %-24s  %s", pending.subcommand, pending.display or "", pending.desc))
        elseif pending.flag then
            if pending.display and not pending.predefined_parser then
                dbgout(string.format("        %-32s  %-24s  %s", pending.flag, pending.display or "", pending.desc))
            end
        end
    end

    if pending.subcommand then
        -- TODO: arginfo.
        context.argvalues = context.argvalues or {}
        local argmatcher = make_subcommand_argmatcher(context.help_command, pending.subcommand, pending.aliased)
        table.insert(context.argvalues, pending.subcommand..argmatcher)
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
    pending.desc = (pending.desc or ""):gsub("%.+$", "")
    if pending.display then
        descriptions[key] = { pending.display, pending.desc }
    else
        descriptions[key] = { pending.desc }
    end
end

--------------------------------------------------------------------------------
local function earlier_gap(a, b)
    local r
    if not a or not a.ofs then
        r = b
    elseif not b or not b.ofs then
        r = a
    elseif a.ofs <= b.ofs then
        r = a
    else
        r = b
    end
    return r and r.ofs and r or nil
end

local function find_flag_gap(line, allow_no_gap)
    local colon  = { len=3, ofs=line:find(" : ") }
    local spaces = { len=2, ofs=line:find("  ") }
    local tab    = { len=1, ofs=line:find("\t") }

    local gap = earlier_gap(earlier_gap(colon, spaces), tab)
    if gap then
        return gap
    end

    local space  = { len=1, ofs=line:find(" ") }
    if not space.ofs then
        if allow_no_gap then
            return { len=0, ofs=#line + 1 }
        else
            return
        end
    end

    if not line:find("[ \t][-/][^ \t/]", space.ofs) then
        return space
    end
end

--------------------------------------------------------------------------------
local function parse_section(section, line)
    if line:find("FLAGS") then return "FLAGS" end
    if line:find("ALIAS COMMANDS") then return "ALIASES" end
    if line:find("COMMANDS") then return "COMMANDS" end
    if line:find("USAGE") then return "USAGE" end
    if line:find("[^ ]") then return section end
end

--------------------------------------------------------------------------------
local function parse_line(context, flags, descriptions, hideflags, line)
    context.section = parse_section(context.section, line)

    -- Parse continuations.
    local x = line:match("^            +([^ ].+)$")
    if x then
        -- The line is an arg list.
        if not context.arg_line_missing_desc and
                context.pending and
                context.pending.expect_args then
            local words = string.explode(line, " ,")
            if clink.upper(words[1]) == words[1] and words[2] == "is" then
                local arglist = {}
                for _,w in ipairs(words) do
                    local arg = w:match('^"(.*)"$')
                    if arg then
                        table.insert(arglist, arg)
                    end
                end
                context.pending.argmatcher = clink.argmatcher():addarg(arglist)
                context.pending.expect_args = nil
            end
        else
            -- The line is part of a description.
            context.arg_line_missing_desc = nil
            if context.desc then
                context.desc = context.desc .. " "
            end
            context.desc = (context.desc or "") .. x
        end
        return
    end

    -- Add any pending subcommand or flags.
    if context.pending then
        local p = context.pending
        if context.desc then
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

    -- Parse if the line declares usage arguments.
    if section == "USAGE" then
        local expected = context.help_command:gsub(" +$", "")
        local args = line:match("gh "..patesc(expected).." *(.*)$")
        if not args then
            expected = help_commands[help_commands[context.help_command]]
            args = line:match("gh "..patesc(expected).." *(.*)$")
        end
        if args then
            if debug and (debug.debug_log_all_usage or debug.debug_log_all) then
                if debug.debug_log_all then
                    dbgout("")
                end
                dbgout(string.format("%-40s%s", context.help_command, args))
            end
            if debug and not debug.debug_output then
                dbgprint("USAGE:  "..reverse..context.help_command..unreverse.."  "..args)
            end
            -- TODO: Use addarg() and provide an appropriate argmatcher via lookup.
        else
            if debug and debug.debug_warn_missed_usage and line ~= "USAGE" then
                clink.print(red.."unexpected usage:"..norm, '"'..context.help_command..'"', '"'..line..'"')
            end
        end
        return
    end

    -- Parse if the line declares a subcommand.
    if section == "COMMANDS" then
        local subcommand, desc = line:match("^  ([^ ]+): +(.+)$")
        if subcommand then
            context.pending.subcommand = subcommand
            context.pending.argmatcher = get_arg_values(context.help_command)
            context.pending.predefined_parser = context.pending.argmatcher and true
            context.desc = desc
        end
        return
    end

    -- Parse if the line declares an alias.
    if section == "ALIASES" then
        local subcommand, aliased = line:match('^  ([^ ]+): +[^"]*"([^"]+).*$')
        if subcommand then
            if debug and debug.debug_warnings and context.help_command ~= "" then
                clink.print(red..'unexpected alias:'..norm..'  "'..context.help_command..'"  -->  "'..aliased..'"')
            end
            context.pending.subcommand = subcommand
            context.pending.aliased = aliased.." "
            context.desc = line:match(": +(.*)$")
        end
        return
    end

    -- Parse if the line declares one or more flags.
    if section == "FLAGS" then
        local s = line:match("^  +(%-[^ ].*)$")
        if s then
            if context.carryover then
                s = context.carryover .. " " .. s
                context.carryover = nil
            end
            local gap = find_flag_gap(s)
            if not gap and s:find(",$") then
                context.carryover = s
            else
                if gap then
                    context.arg_line_missing_desc = false
                    context.desc = s:sub(gap.ofs + gap.len):match("^[ \t]*([^ \t].*)$")
                    s = s:sub(1, gap.ofs - 1)
                else
                    context.arg_line_missing_desc = true
                end

                -- All flags on a single line share one argmatcher.
                local p = context.pending
                local d
                local list = string.explode(s, ",")
                p.expect_args = nil
                local flag_key
                for _,f in ipairs(list) do
                    f = f:match("^ *([^ ].*)$")
                    if f then
                        --[[if f:find("^[^%s]*%[=") then
                            error("Does this case work?")
                            -- Add two flags.
                            f,d = f:match("^([^[]+)%[=(.*)%]$")
                            if f then
                                local feq = f .. "="
                                p.arginfo = p.arginfo or d
                                p.expect_args = true
                                table.insert(p, { flag=f, has_arg=false })
                                table.insert(p, { flag=feq, has_arg=true, display=d })
                            end
                        else--]]
                        if f:find("^[^%s]*=") then
                            -- Add a flag with an arg.
                            f,d = f:match("^([^=]+=)(.*)$")
                            if f then
                                p.arginfo = p.arginfo or d
                                p.expect_args = true
                                table.insert(p, { flag=f, has_arg=true, display=d })
                            end
                        elseif f:find(" ") then
                            -- Add a flag with an arg.
                            f,d = f:match("^([^ ]+) +(.*)$")
                            if f then
                                p.arginfo = p.arginfo or d
                                p.expect_args = true
                                table.insert(p, { flag=f, has_arg=true, display=d })
                            end
                        else
                            -- Add a flag verbatim.
                            table.insert(p, { flag=f })
                        end
                        flag_key = flag_key and flag_key.." "..f or f
                    end
                end
                p.argmatcher = get_arg_parser(context.help_command, flag_key, p.display)
                p.predefined_parser = p.argmatcher and true
            end
        end
        return
    end
end

--------------------------------------------------------------------------------
forwards.run = function(argmatcher, help_command, config)
    local flags = {}
    local descriptions = {}
    local hideflags = {}
    local context = { pending={}, help_command=help_command }
    config = config or {}

    local lines
    do
        local r = io.popen("2>nul gh.exe "..help_command.." --help")
        if not r then
            return
        end

        lines = {}
        for line in r:lines() do
            if unicode.fromcodepage then -- luacheck: no global
                line = unicode.fromcodepage(line) -- luacheck: no global
            end
            table.insert(lines, line)
        end
        r:close()
    end

    if lines then
        for _,line in ipairs(lines) do
            parse_line(context, flags, descriptions, hideflags, line)
        end
    end
    parse_line(context, flags, descriptions, hideflags, "")

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
