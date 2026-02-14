--------------------------------------------------------------------------------
-- Helpers to make it easy to add descriptions in argmatchers.
--
--      argmatcher:_addexflags()
--      argmatcher:_addexarg()
--
-- The _addexflags() and _addexarg() functions accept the following format,
-- and both functions accept the same input format.
--
--      local a = clink.argmatcher()
--
--      a:_addexflags({
--          nosort=true,                    -- Disables sorting the matches.
--          some_function,                  -- Adds some_function.
--          "-a",                           -- Adds match "-a".
--          { "-b" },                       -- Adds match "-b".
--          { "-c", "Use colors" },         -- Adds match "-c" and description "Use colors".
--          { "-d", " date",  "List newer than date" },
--                                          -- Adds string "-d", arginfo " date", and
--                                             description "List newer than date".
--          { "-D", " date",  "" },         -- Adds string "-D" and arginfo " date",
--                                             without a description.
--          {                               -- Nested table, following the same format.
--              { "-e" },
--              { "-f" },
--          },
--          { "-o" },
--          { "--option" },
--
--          -- Add hide=true to hide the match.
--          { "-x", hide=true },
--
--          -- Use hide_unless="list of flags" to hide the match unless any of
--          -- the specified flags are present.
--          { hide_unless="-o --option", "--no-option" },
--
--          -- Add opteq=true when there's a linked argmatcher to also add a
--          -- hidden opposite style:
--          { "-x"..argmatcher, opteq=true },   -- Adds "-x"..argmatcher, and a hidden "-x="..argmatcher.
--          { "-x="..argmatcher, opteq=true },  -- Adds "-x="..argmatcher, and a hidden "-x"..argmatcher.
--          -- Also, adding opteq=true or opteq=false to an outer table applies
--          -- to everything nested within the table.
--
--          -- Allow "-xy" meaning "-x -y", and also "-xARG" meaning "-x ARG".
--          concat_one_letter_flags=true,
--
--          -- Allow "-xARG" meaning "-x ARG".
--          adjacent_one_letter_flags=true,
--      })
--
-- The arghelper script also fills in compatibility methods for any of the
-- following argmatcher methods that may be missing in older versions of Clink.
-- This makes backward compatibility much easier, because your code can use
-- newer APIs and they'll just do nothing if the version of Clink in use doesn't
-- actually support them.
--
--      argmatcher:addarg()
--      argmatcher:addflags()
--      argmatcher:nofiles()
--      argmatcher:adddescriptions()
--      argmatcher:hideflags()
--      argmatcher:setflagsanywhere()
--      argmatcher:setendofflags()
--
-- The arghelper script also returns an export table with additional helper
-- functions.
--
--      local arghelper = require("arghelper")
--      arghelper.make_arg_hider_func()
--      arghelper.make_one_letter_concat_classifier_func()
--      arghelper.make_exflags()
--
-- arghelper.make_arg_hider_func()
--
--      Use the arghelper.make_arg_hider_func() function to create and return a
--      match function that omits the specified matches when displaying or
--      completing matches, while still letting input coloring apply color to
--      them.  If make_arg_hider_func() is used more than once in the same
--      argument position, only the last one will take effect.
--
--          local arghelper = require("arghelper")
--
--          clink.argmatcher("foo")
--          :addarg({
--              "abc", "def",
--              "Abc", "Def",
--              arghelper.make_arg_hider_func("Abc", "Def")
--          })
--
--      The arghelper.make_arg_hider_func() accepts as many arguments as you
--      like, and the argument types can be tables, functions, and strings.
--
--          - Strings are added to the list of matches to hide.
--          - Functions can return more arguments.
--          - Tables can contain more arguments (tables, functions, and strings).
--
--          clink.argmatcher("foo")
--          :addarg({
--              "abc", "def",
--              "Abc", "Def",
--              "ABC", "DEF",
--              arghelper.make_arg_hider_func({
--                  {"Abc", "ABC"},
--                  function ()
--                      return {"Def", "DEF"}
--                  end
--              })
--          })
--
-- arghelper.make_one_letter_concat_classifier_func()
--
--      Use the arghelper.make_one_letter_concat_classifier_func() function to
--      create and return a classifier function that allows concatenating
--      multiple one letter flags, for example "-xy" instead of "-x -y".
--
--      The arghelper.make_one_letter_concat_classifier_func() accepts up to
--      two arguments:
--
--          - A table of flag strings.  For any strings of the form "-x" or
--            "/x" or "-x-" or "/x-" or "-x+" or "/x+", the one-letter flags
--            will be recognized even when they're concatenated.  For example,
--            the XCOPY program allows concatenating flags, e.g. "xcopy /suh",
--            and this function helps accommodate that.
--          - The argmatcher.  Passing the argmatcher lets the
--            arghelper.make_one_letter_concat_classifier_func() function
--            merge new concatenate-able flags into a pre-existing collection.
--            This makes it possible to use
--            arghelper.make_one_letter_concat_classifier_func() more than
--            once in the same argmatcher and merge the configuration, instead
--            of replacing the older configuration.
--
--      The even easier thing to do is include concat_one_letter_flags=true
--      when passing a table into argmatcher:_addexflags().  That will
--      automatically use make_one_letter_concat_classifier_func().
--
-- arghelper.make_exflags()
--
--      Use the arghelper.make_exflags() function to create and return a table
--      suitable for passing to _addexflags(), from an input table using a new
--      format that provides both short and long flags together.
--
--          local arghelper = require("arghelper")
--
--          local files = clink.argmatcher():addarg(clink.filematches)
--
--          clink.argmatcher("foo")
--          :_addexflags(arghelper.make_exflags({
--              -- Simple example with both short and long flags.
--              { "-a", "--all",                        "Both short and long flags" },
--              -- Simple examples with only short or long flags.
--              { nil, "--long",                        "Only a long flag" },
--              { "-s", nil,                            "Only a short flag" },
--              -- Arguments may be specified, and are linked with the short
--              -- and/or long flags, whichever are provided.
--              { "-f", "--file", files, " <file>",     "Argument is applied to both -f and --file" },
--          }))
--
--      All of the fields like opteq=, hide=, hide_unless=, nosort=,
--      concat_one_letter_flags=, adjacent_one_letter_flags=, etc are also
--      supported here in the same ways as usual.
--
--------------------------------------------------------------------------------
-- Changes:
--
--  2026/02/14
--      - `arghelper.make_exflags()` makes a table for _addexflags() from a
--        table using a new format that can specify both short and long flags
--        together, and automatically links the same argument argmatcher, if
--        provided.
--
--  2024/09/16
--      - Support for `hint="text"` and `hint=func` in _addexarg() and
--        _addexflags().
--
--  2024/08/05
--      - Support for `concat_one_letter_flags=true` in _addexflags() to make
--        input line coloring recognize concatenated one-letter flags like the
--        commonly used getopt library allows (for example `-xy` for `-x -y`).
--      - `arghelper.make_one_letter_concat_classifier_func()` makes a
--        classifier function that handles input line coloring for a list of
--        one-letter flags that can be concatenated.
--
--  2024/07/23
--      - Support for `onalias=func` in _addexarg() and _addexflags().
--
--  2024/04/11
--      - Support for `hide_unless=func` in _addexflags().
--
--  2023/11/18
--      - Support for `hide=true` in _addexarg().
--
--  2023/11/14
--      - Support for `onadvance=func` and `onlink=func` in _addexarg() and
--        _addexflags().
--
--  2023/01/29
--      - `local arghelper = require("arghelper.lua")` returns an export table.
--      - `arghelper.make_arg_hider_func()` makes a match function that hides
--        specified args.
--
--  2022/10/22
--      - Support for `onarg=func` in _addexarg() and _addexflags().
--      - Support for `delayinit=func` in _addexarg() and _addexflags().
--      - Support for `loopchars="chars"` in _addexflags().
--
--  2022/07/30
--      - `hide=true` hides a match (in _addexflags()).
--      - `opteq=true` affects nested tables (in _addexarg() and _addexflags()).
--
--  2022/07/06
--      - Fixed backward compatibility shim to work on v0.4.9 as well.
--
--  2022/03/22
--      - Initial version.
--------------------------------------------------------------------------------

if not clink then
    -- E.g. some unit test systems will run this module *outside* of Clink.
    return
end

local tmp = clink.argmatcher and clink.argmatcher() or clink.arg.new_parser()
local meta_parser = getmetatable(tmp)
local interop = {}

local tmp_link = "link"..tmp
local meta_link = getmetatable(tmp_link)

local function is_parser(x)
    return meta_parser and getmetatable(x) == meta_parser
end

local function is_link(x)
    return meta_link and getmetatable(x) == meta_link
end

local function condense_stack_trace(skip_levels)
    local append
    local ret = ""
    local stack = debug.traceback(skip_levels)
    for _,s in string.explode(stack, "\n") do
        s = s:gsub("^ *(.-) *$", "%1")
        if #s > 0 then
            if append then
                ret = ret .. append
            else
                append = " / "
            end
            ret = ret .. s
        end
    end
    return ret
end

local function is_one_letter_flag(flag)
    if not flag:find("^%-%-") then
        local letter,plusminus = flag:match("^([-/][^-/])([-+:=]?)$")
        if letter then
            return letter, plusminus
        end
    end
end

local function make_arg_hider_func(...)
    if not clink.onfiltermatches then
        if log and log.info then
            log.info("make_arg_hider_func requires clink.onfiltermatches; "..condense_stack_trace())
        end
        return
    end

    local args = {...}

    local function filter_matches()
        local function onfilter(matches, completion_type, filename_completion_desired)
            local index = {}

            local function add_to_index(tbl)
                for _,add in ipairs(tbl) do
                    if type(add) == "table" then
                        add_to_index(add)
                    elseif type(add) == "function" then
                        add_to_index(add(matches, completion_type, filename_completion_desired))
                    elseif type(add) == "string" then
                        index[add] = true
                    end
                end
            end

            add_to_index(args)

            for j = #matches, 1, -1 do
                local m = matches[j].match
                if index[m] then
                    table.remove(matches, j)
                end
            end

            return matches
        end

        clink.onfiltermatches(onfilter)
        return {}
    end

    return filter_matches
end

local function make_one_letter_concat_classifier_func(list, parser)
    -- Allow :_addexflags() to ADD to an existing collection of flags, rather
    -- than REPLACING the collection of flags.
    local one_letter_flags = parser and parser.one_letter_flags or {}
    if parser then
        parser.one_letter_flags = one_letter_flags
    end

    local function func(arg_index, word, word_index, line_state, classifications)
        if arg_index == 0 then
            if #word > 2 and word:sub(1, 2) ~= "--" then
                local color_flag = settings.get("color.flag")
                if color_flag then
                    local apply_len = 0
                    local unexpected
                    local arginfo
                    local i = 2
                    local len = #word
                    local info = line_state:getwordinfo(word_index)
                    local pre = word:sub(1, 1)
                    while i <= len do
                        local letter = pre..word:sub(i, i)
                        local next_symbol = word:sub(i + 1, i + 1)
                        if next_symbol == ":" or next_symbol == "=" then
                            letter = letter..next_symbol
                        end
                        local olf = one_letter_flags[letter]
                        if olf then
                            i = i + #letter - 1
                            apply_len = i - 1
                            if not olf.linked and olf.plusminus and word:find("^[-+]", i) then
                                i = i + 1
                                apply_len = i - 1
                            end
                            if olf.arginfo then
                                arginfo = i - 1
                                break
                            end
                        else
                            unexpected = i
                            break
                        end
                    end
                    if apply_len > 0 then
                        classifications:applycolor(info.offset, apply_len, color_flag, true)
                        if arginfo then
                            if #word > arginfo then
                                local color_input = settings.get("color.input") or ""
                                classifications:applycolor(info.offset + arginfo, #word - arginfo, color_input, true) -- luacheck: no max line length
                            end
                        elseif unexpected then
                            if #word >= unexpected then
                                local color_unexpected = settings.get("color.unexpected") or ""
                                local color_nope = settings.get("color.unrecognized") or color_unexpected
                                classifications:applycolor(info.offset + unexpected - 1, 1, color_nope, true)
                                classifications:applycolor(info.offset + unexpected - 0, #word - unexpected, color_unexpected, true) -- luacheck: no max line length
                            end
                        end
                    end
                end
            end
        end
    end

    for _,flag in ipairs(list) do
        if type(flag) == "string" then
            local letter,plusminus = is_one_letter_flag(flag)
            if letter then
                local olf = one_letter_flags[letter]
                if not olf then
                    olf = {}
                    one_letter_flags[letter] = olf
                end
                if plusminus and plusminus:find("^[-+]") then
                    olf.plusminus = true
                end
                if type(list[flag]) == "table" then
                    if list[flag].one_letter_arginfo then
                        olf.arginfo = true
                    end
                    if list[flag].one_letter_linked then
                        olf.linked = true
                    end
                end
            end
        end
    end

    return func
end

local function make_one_letter_concat_onalias_func(parser)
    if not parser or parser.has_one_letter_concat_onalias_func then
        return
    end

    if not parser.one_letter_flags then
        parser.one_letter_flags = {}
    end

    local function func(arg_index, word, word_index, line_state) -- luacheck: no unused
        if arg_index == 0 then
            if #word > 2 and word:sub(2, 2) ~= "-" then
                local split_pos = 0
                local i = 2
                local len = #word
                local pre = word:sub(1, 1)
                local one_letter_flags = parser.one_letter_flags
                while i <= len do
                    local letter = pre..word:sub(i, i)
                    local olf = one_letter_flags[letter]
                    if not olf then
                        return
                    elseif olf.linked then
                        split_pos = i
                        break
                    elseif olf.plusminus and word:find("^[-+]", i + 1) then
                        i = i + 1
                    end
                    i = i + 1
                end
                if split_pos > 2 and split_pos < len then
                    local info = line_state:getwordinfo(word_index)
                    local quote = info.quoted and line_state:getline():sub(info.offset - 1, info.offset - 1) or ""
                    local text = word:sub(1, split_pos - 1)..quote.." "..quote..word:sub(1, 1)..word:sub(split_pos)
                    return text
                end
            end
        end
    end

    parser.has_one_letter_concat_onalias_func = true
    return func
end

local function apply_list_field_names(dst, src)
    dst.delayinit = src.delayinit
    dst.fromhistory = src.fromhistory
    dst.hint = src.hint
    dst.loopchars = src.loopchars
    dst.nosort = src.nosort
    dst.onadvance = src.onadvance
    dst.onalias = src.onalias
    dst.onlink = src.onlink
    dst.onarg = src.onarg
end

local function apply_element_field_names(dst, src)
    dst.hide = src.hide
    dst.hide_unless = src.hide_unless
    dst.opteq = src.opteq
end

local flagdesc = (tonumber(os.getenv("CLINK_COMPLETIONS_FLAGDESC") or "2") or 2)
local function maybe_desc(f, i_flag, i_desc)
    if f[i_flag] then
        assert(type(f[i_flag]) == "string")
        local threshold = f[i_flag]:find("^%-%-") and 2 or 1
        if flagdesc >= threshold and type(f[i_desc]) == "string" then
            return f[i_desc]
        end
    end
end

local function valid_str(s)
    return type(s) == "string" and s ~= ""
end

local function make_exflags(src)
    local exflags = {}
    for _, f in ipairs(src) do
        local shrt, long
        if not is_parser(f[3]) then
            if valid_str(f[1]) then shrt = { f[1], maybe_desc(f, 1, 3) } end
            if valid_str(f[2]) then long = { f[2], maybe_desc(f, 2, 3) } end
        elseif f[5] then    -- Empty string is valid and meaningful at f[5].
            if valid_str(f[1]) then shrt = { f[1]..f[3], f[4], maybe_desc(f, 1, 5) } end
            if valid_str(f[2]) then long = { f[2]..f[3], f[4], maybe_desc(f, 2, 5) } end
        elseif f[4] then    -- Empty string is valid and meaningful at f[4].
            if valid_str(f[1]) then shrt = { f[1]..f[3], f[4], "" } end
            if valid_str(f[2]) then long = { f[2]..f[3], f[4], "" } end
        else
            if valid_str(f[1]) then shrt = { f[1]..f[3] } end
            if valid_str(f[2]) then long = { f[2]..f[3] } end
        end
        if shrt then
            apply_element_field_names(shrt, f)
            table.insert(exflags, shrt)
        end
        if long then
            apply_element_field_names(long, f)
            table.insert(exflags, long)
        end
    end
    apply_list_field_names(exflags, src)
    return exflags
end

if not tmp.addarg then
    interop.addarg = function(parser, ...)
        -- Extra braces to make sure exactly one argument position is added.
        parser:add_arguments({...})
        return parser
    end
end

if not tmp.addflags then
    interop.addflags = function(parser, ...)
        parser:add_flags(...)
        return parser
    end
end

if not tmp.nofiles then
    interop.nofiles = function(parser)
        parser:disable_file_matching()
        return parser
    end
end

if not tmp.adddescriptions then
    interop.adddescriptions = function(parser)
        return parser
    end
end

if not tmp.hideflags then
    interop.hideflags = function(parser)
        return parser
    end
end

if not tmp.setflagsanywhere then
    interop.setflagsanywhere = function(parser)
        return parser
    end
end

if not tmp.setendofflags then
    interop.setendofflags = function(parser)
        return parser
    end
end

if not tmp._addexflags or not tmp._addexarg then
    local function onarg_hide_unless(arg_index, word, word_index, line_state, user_data) -- luacheck: no unused
        if arg_index == 0 then
            local present = user_data.present
            if not present then
                present = {}
                user_data.present = present
            end
            word = word:gsub("[:=].*$", "")
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

    local function maybe_one_letter_flag(concat_flags, invalid_flags, flag, arginfo, linked)
        local letter,plusminus = is_one_letter_flag(flag)
        if letter then
            table.insert(concat_flags, flag)
            local tbl = concat_flags[flag]
            if not tbl then
                tbl = {}
                concat_flags[flag] = tbl
            end
            if arginfo then
                tbl.one_letter_arginfo = true
            end
            if linked then
                tbl.one_letter_linked = true
            end
            if #flag > 2 and not plusminus then
                local flag2 = flag:sub(1, 2)
                if is_one_letter_flag(flag2) and concat_flags[flag2] then
                    concat_flags[flag2].one_letter_arginfo = true
                end
            end
        else
            if #flag > 2 then
                local flag2 = flag:sub(1, 2)
                -- Allow things like -v and -vv, but only if -v is already
                -- defined before -vv.
                if flag:sub(2, 2) ~= flag:sub(3, 3) or not concat_flags or not concat_flags[flag2] then
                    invalid_flags[flag2] = true
                end
            end
        end
    end

    local function add_elm(elm, list, descriptions, hide, hide_unless, in_opteq, concat_flags, invalid_flags, adjacent_flags) -- luacheck: no max line length
        local arg
        local opteq = in_opteq
        if elm[1] then
            arg = elm[1]
        else
            if type(elm) == "table" and not is_link(elm) and not is_parser(elm) then
                return
            end
            arg = elm
        end
        if elm.opteq ~= nil then
            opteq = elm.opteq
        end

        local t = type(arg)
        local arglinked = is_link(arg)
        if arglinked or is_parser(arg) then
            t = "matcher"
        elseif t == "table" then
            if elm[4] then
                t = "nested"
            else
                for _,scan in ipairs(elm) do
                    if type(scan) == "table" then
                        t = "nested"
                        break
                    end
                end
            end
        elseif t == "string" then
            if concat_flags then
                -- Flags like "-M[n]" color the flag but don't support
                -- completions of the "[n]" part (elm[3] catches them).
                maybe_one_letter_flag(concat_flags, invalid_flags, arg, elm[3])
            end
        end
        if arglinked then
            -- Flags like "-p port" accept "-pport" as well.
            if concat_flags then
                maybe_one_letter_flag(concat_flags, invalid_flags, arg._key, true, true)
            elseif adjacent_flags then
                maybe_one_letter_flag(adjacent_flags, invalid_flags, arg._key, true, true)
            end
        end
        if t == "string" or t == "number" or t == "matcher" then
            if t == "matcher" then
                table.insert(list, arg)
                if opteq and arglinked and clink.argmatcher then
                    local altkey
                    if arg._key:sub(-1) == '=' then
                        altkey = arg._key:sub(1, #arg._key - 1)
                    else
                        altkey = arg._key..'='
                    end
                    table.insert(hide, altkey)
                    table.insert(list, { altkey..arg._matcher })
                end
            else
                table.insert(list, tostring(arg))
            end
            if elm[2] and descriptions then
                local name = arglinked and arg._key or arg
                if elm[3] then
                    descriptions[name] = { elm[2], elm[3] }
                else
                    descriptions[name] = { elm[2] }
                end
            end
            if elm.hide then
                local name = arglinked and arg._key or arg
                table.insert(hide, name)
            end
            if hide_unless and elm.hide_unless then
                local unless = {}
                for _,u in ipairs(string.explode(elm.hide_unless)) do
                    table.insert(unless, u)
                end
                if unless[1] then
                    hide_unless[arg] = unless
                end
            end
        elseif t == "function" then
            table.insert(list, arg)
        elseif t == "nested" then
            for _,sub_elm in ipairs(elm) do
                add_elm(sub_elm, list, descriptions, hide, hide_unless, opteq, concat_flags, invalid_flags, adjacent_flags) -- luacheck: no max line length
            end
        else
            pause("unrecognized input table format.")
            error("unrecognized input table format.")
        end
    end

    local function build_lists(tbl, is_flags)
        local list = {}
        local descriptions = (not ARGHELPER_DISABLE_DESCRIPTIONS) and {} -- luacheck: no global
        local hide = {}
        local hide_unless = is_flags and {}
        local concat_flags = tbl.concat_one_letter_flags and {} or nil
        local invalid_flags = {}
        local adjacent_flags = tbl.adjacent_one_letter_flags and {} or nil
        if type(tbl) ~= "table" then
            pause('table expected.')
            error('table expected.')
        end
        for _,elm in ipairs(tbl) do
            local t = type(elm)
            if t == "table" then
                add_elm(elm, list, descriptions, hide, hide_unless, tbl.opteq, concat_flags, invalid_flags, adjacent_flags) -- luacheck: no max line length
            elseif t == "string" or t == "number" or t == "function" then
                table.insert(list, elm)
            end
        end
        apply_list_field_names(list, tbl)
        if hide_unless then
            local any = false
            for _,_ in pairs(hide_unless) do -- luacheck: ignore 512
                any = true
                break
            end
            if not any then
                hide_unless = nil
            end
        end
        if adjacent_flags then
            concat_flags = concat_flags or {}
            for k,v in pairs(adjacent_flags) do
                if type(k) == "number" then
                    table.insert(concat_flags, v)
                else
                    concat_flags[k] = v
                end
            end
        end
        if concat_flags then
            for k,_ in pairs(invalid_flags) do
                concat_flags[k] = nil
            end
            local remove = {}
            for i,v in ipairs(concat_flags) do
                if invalid_flags[v] then
                    table.insert(remove, i)
                end
            end
            for i = #remove, 1, -1 do
                table.remove(concat_flags, remove[i])
            end
        end
        return list, descriptions, hide, hide_unless, concat_flags
    end

    if not tmp._addexflags then
        interop._addexflags = function(parser, tbl)
            local flags, descriptions, hide, hide_unless, concat_flags = build_lists(tbl, true--[[is_flags]])
            if hide_unless then
                if tbl.onarg then
                    local fwd = tbl.onarg
                    flags.onarg = function(arg_index, word, word_index, line_state, user_data)
                        fwd(arg_index, word, word_index, line_state, user_data)
                        onarg_hide_unless(arg_index, word, word_index, line_state, user_data)
                    end
                else
                    flags.onarg = onarg_hide_unless
                end
                table.insert(flags, function (word, word_index, line_state, match_builder, user_data) -- luacheck: no unused, no max line length
                    clink.onfiltermatches(function (matches)
                        return do_filter(matches, hide_unless, user_data)
                    end)
                    return {}
                end)
            end
            parser:addflags(flags)
            if descriptions then
                parser:adddescriptions(descriptions)
            end
            if hide then
                parser:hideflags(hide)
            end
            if concat_flags and parser.setclassifier then
                parser:setclassifier(make_one_letter_concat_classifier_func(concat_flags, parser))
                parser:addflags({ onalias=make_one_letter_concat_onalias_func(parser) })
            end
            return parser
        end
    end
    if not tmp._addexarg then
        interop._addexarg = function(parser, tbl)
            local args, descriptions, hide = build_lists(tbl)
            parser:addarg(args, make_arg_hider_func(hide))
            if descriptions then
                parser:adddescriptions(descriptions)
            end
            return parser
        end
    end
end

-- If nothing was missing, then no interop functions got added, and the meta
-- table doesn't need to be modified.
for _,_ in pairs(interop) do -- luacheck: ignore 512
    local old_index = meta_parser.__index
    meta_parser.__index = function(parser, key)
        local value = rawget(interop, key)
        if value then
            return value
        elseif not old_index then
            return rawget(parser, key)
        elseif type(old_index) == "function" then
            return old_index(parser, key)
        elseif old_index == meta_parser then
            return rawget(old_index, key)
        else
            return old_index[key]
        end
    end
    break
end

local exports = {
    make_arg_hider_func = make_arg_hider_func,
    make_one_letter_concat_classifier_func = make_one_letter_concat_classifier_func,
    make_one_letter_concat_onalias_func = make_one_letter_concat_onalias_func,
    make_exflags = make_exflags,
}

return exports
