--------------------------------------------------------------------------------
-- Helpers to make it easy to add descriptions in argmatchers.
--
--      argmatcher:_addexflags()
--      argmatcher:_addexarg()
--
-- These accept the following format:
--
--      local a = clink.argmatcher()
--
--      a:_addexflags({
--          some_function,                  -- Adds some_function.
--          "-a",                           -- Adds match "-a".
--          { "-b" },                       -- Adds match "-b".
--          { "-c", "Use colors" },         -- Adds match "-c" and description "Use colors".
--          { "-d", " date",  "List newer than date" }, -- Adds string "-d", arginfo " date", and description "List newer than date".
--          {                               -- Nested table, following the same format.
--              { "-e" },
--              { "-f" },
--          },
--      })
--
-- Both _addexflags() and _addexarg() accept the same input format.
--
-- This also fills in compatibility methods for any of the following argmatcher
-- methods that may be missing in older versions of Clink.  This makes backward
-- compatibility much easier, because your code can use newer APIs and they'll
-- just do nothing if the version of Clink in use doesn't actually support them.
--
--      argmatcher:addarg()
--      argmatcher:addflags()
--      argmatcher:nofiles()
--      argmatcher:adddescriptions()
--      argmatcher:hideflags()
--      argmatcher:setflagsanywhere()
--      argmatcher:setendofflags()

if not clink then
    -- E.g. some unit test systems will run this module *outside* of Clink.
    return
end

local tmp = clink.argmatcher and clink.argmatcher() or clink.arg.new_parser()
local meta = getmetatable(tmp)
local interop = {}

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
    local link = "link"..tmp
    local meta_link = getmetatable(link)

    local function is_parser(x)
        return getmetatable(x) == meta
    end

    local function is_link(x)
        return getmetatable(x) == meta_link
    end

    local function add_elm(elm, list, descriptions, hide)
        local arg
        local opteq
        if elm[1] then
            arg = elm[1]
            opteq = elm.opteq and is_link(arg)
        else
            if type(elm) == "table" and not is_link(elm) and not is_parser(elm) then
                return
            end
            arg = elm
        end

        local t = type(arg)
        if is_link(arg) or is_parser(arg) then
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
        end
        if t == "string" or t == "number" or t == "matcher" then
            if t == "matcher" then
                table.insert(list, arg)
                if opteq and clink.argmatcher then
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
                local name = is_link(arg) and arg._key or arg
                if elm[3] then
                    descriptions[name] = { elm[2], elm[3] }
                else
                    descriptions[name] = { elm[2] }
                end
            end
        elseif t == "function" then
            table.insert(list, arg)
        elseif t == "nested" then
            for _,sub_elm in ipairs(elm) do
                add_elm(sub_elm, list, descriptions, hide)
            end
        else
            pause("unrecognized input table format.")
            error("unrecognized input table format.")
        end
    end

    local function build_lists(tbl)
        local list = {}
        local descriptions = (not ARGHELPER_DISABLE_DESCRIPTIONS) and {}
        local hide = {}
        if type(tbl) ~= "table" then
            pause('table expected.')
            error('table expected.')
        end
        for _,elm in ipairs(tbl) do
            local t = type(elm)
            if t == "table" then
                add_elm(elm, list, descriptions, hide)
            elseif t == "string" or t == "number" or t == "function" then
                table.insert(list, elm)
            end
        end
        list.fromhistory = tbl.fromhistory
        list.nosort = tbl.nosort
        return list, descriptions, hide
    end

    if not tmp._addexflags then
        interop._addexflags = function(parser, tbl)
            local flags, descriptions, hide = build_lists(tbl)
            parser:addflags(flags)
            if descriptions then
                parser:adddescriptions(descriptions)
            end
            if hide then
                parser:hideflags(hide)
            end
            return parser
        end
    end
    if not tmp._addexarg then
        interop._addexarg = function(parser, tbl)
            local args, descriptions = build_lists(tbl)
            parser:addarg(args)
            if descriptions then
                parser:adddescriptions(descriptions)
            end
            return parser
        end
    end
end

-- If nothing was missing, then no interop functions got added, and the meta
-- table doesn't need to be modified.
for _,_ in pairs(interop) do
    local old_index = meta.__index
    meta.__index = function(parser, key)
        local value = rawget(interop, key)
        if value then
            return value
        elseif not old_index then
            return rawget(parser, key)
        elseif type(old_index) == "function" then
            return old_index(parser, key)
        elseif old_index == meta then
            return rawget(old_index, key)
        else
            return old_index[key]
        end
    end
    break
end
