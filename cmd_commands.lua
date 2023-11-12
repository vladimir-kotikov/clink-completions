require("arghelper")

--------------------------------------------------------------------------------
-- FOR
--
-- This argmatcher for the FOR command requires Clink v1.5.14 or higher.
-- It handles the syntax quirks:
--      - At most one flag may be used.
--      - The /r and /f flags have optional arguments.
--      - The /f "options" allows multiple keywords in a single quoted string.
--      - The (...) set must be surrounded by parentheses.

if (clink.version_encoded or 0) >= 10050014 then

local function is_flag(word)
    local flag = word:match("^/[dDrRlLfF?]$")
    if flag then
        return flag:lower()
    end
end

local function get_full_word(line_state, word_index, reject_quoted)
    local info = line_state:getwordinfo(word_index)
    if info and (not reject_quoted or not info.quoted) then
        local line = line_state:getline()
        local st = info.offset
        local en = info.offset + info.length
        if st > 1 then
            st = st - 1
        end
        local word = line:sub(st, en):gsub("^ +", ""):gsub(" +$", "")
        return word
    end
end

local function onadvance_flag(_, word, word_index, line_state, user_data)
    local flag = is_flag(word)
    if not flag then
        if word_index < line_state:getwordcount() then
            return 1            -- Ignore this arg_index.
        elseif word ~= "/" then
            return 1            -- Ignore this arg_index.
        end
    end
    user_data.flag = flag
end

-- luacheck: push
-- luacheck: no max line length
local option_matches = {
    { match="/d",                           description="Match (set) against directories" },
    { match="/r",  arginfo=" [dir]",        description="Walk dir recursively, executing the FOR command in each directory" },
    { match="/l",                           description="The set is a sequence of numbers (start,step,end)" },
    { match="/f",  arginfo=' ["options"]',  description="File processing; each file in the set is read and processed" },
}
-- luacheck: pop

local function display_options()
    clink.onfiltermatches(function ()
        return { "/d", "/r", "/l", "/f" }
    end)
    return option_matches
end

local function onadvance_dir(_, word, _, _, user_data)
    if user_data.flag ~= "/r" or word:find("^%%") then
        return 1                -- Ignore this arg_index.
    end
end

local function onadvance_options(_, word, _, _, user_data)
    if user_data.flag ~= "/f" or word:find("^%%") then
        return 1                -- Ignore this arg_index.
    end
end

local function init_in_arg_builder(_, _, _, builder, _)
    clink.onfiltermatches(function ()
        return { "in \x28" }
    end)
    builder:setsuppressappend()
    builder:setsuppressquoting()
    return {}
end

local lower_case_vars = {
    "%a", "%b", "%c", "%d", "%e", "%f", "%g", "%h", "%i", "%j", "%k", "%l", "%m",
    "%n", "%o", "%p", "%q", "%r", "%s", "%t", "%u", "%v", "%w", "%x", "%y", "%z",
}
local upper_case_vars = {
    "%A", "%B", "%C", "%D", "%E", "%F", "%G", "%H", "%I", "%J", "%K", "%L", "%M",
    "%N", "%O", "%P", "%Q", "%R", "%S", "%T", "%U", "%V", "%W", "%X", "%Y", "%Z",
}

--[=[
local function filter_vars()
    clink.onfiltermatches(function ()
        return lower_case_vars
    end)
    return {}
end
--]=]

local function get_delimiter_after(line_state, word_index)
    local s
    local x = line_state:getwordinfo(word_index)
    if x then
        local y = line_state:getwordinfo(word_index + 1)
        if y then
            local line = line_state:getline()
            s = line:sub(x.offset + x.length, y.offset - 1)
        end
    end
    return s or ""
end

local function repeat_unless_close_paren(_, _, word_index, line_state, _)
    local after = get_delimiter_after(line_state, word_index)
    if not after:find("%)") then
        return 0                -- Repeat this arg_index.
    end
end

local function for_classifier(arg_index, word, word_index, line_state, classifications)
    local zap, zapafter

    if arg_index == 1 then
        classifications:classifyword(word_index, "f")
    elseif arg_index == 3 then
        local info = line_state:getwordinfo(word_index)
        zap = not info.quoted and #word > 0
    elseif arg_index == 4 then
        word = get_full_word(line_state, word_index, true)
        if not word or not word:find("^%%") then
            zap = true
        elseif #word > 2 then
            zap = true
        elseif #word == 2 then
            zap = not word:match("^%%[a-zA-Z]$")
        end
    elseif arg_index == 5 then
        word = word:lower()
        zap = (word ~= "i" and word ~= "in")
        if not zap and word_index < line_state:getwordcount() then
            local after = get_delimiter_after(line_state, word_index)
            zap = not after:find("%s+%(")
            zapafter = zap
        end
    elseif arg_index == 7 then
        word = word:lower()
        zap = (word ~= "d" and word ~= "do")
    end

    if zap then
        local color = settings.get("color.unexpected") or ""
        local wordinfo = line_state:getwordinfo(word_index)
        local lastinfo = line_state:getwordinfo(line_state:getwordcount())
        local endoffset = lastinfo.offset + lastinfo.length
        local tailoffset = wordinfo.offset
        if zapafter then
            tailoffset = tailoffset + wordinfo.length
        elseif wordinfo.quoted then
            tailoffset = tailoffset - 1
        end
        if endoffset > tailoffset then
            local line = line_state:getline()
            local tail = line:sub(endoffset):match("^([^&|]+)[&|]?.*$") or ""
            endoffset = endoffset + #tail
        end
        classifications:applycolor(tailoffset, endoffset - tailoffset, color, true)
    end
end

clink.argmatcher("for")
:addarg({
    onadvance=onadvance_flag,
    display_options,
    "/d", "/r", "/l", "/f",
    "/D", "/R", "/L", "/F",
    "/?",
})
:addarg({
    onadvance=onadvance_dir,
    clink.dirmatches,
})
:addarg({
    onadvance=onadvance_options,
    -- This has to use a generator to produce completions, since there can be
    -- multiple options in the quoted string.
})
:addarg({
    --filter_vars,
    lower_case_vars,
    upper_case_vars,
})
:addarg({
    "in",
    "in \x28",
    init_in_arg_builder,
})
:addarg({
    onadvance=repeat_unless_close_paren,
    clink.filematches,
})
:addarg("do" .. clink.argmatcher():chaincommand())
:nofiles()
:setclassifier(for_classifier)

local function is_for_f_options(line_state)
    local cwi = line_state:getcommandwordindex()
    if line_state:getword(cwi + 1):lower() == "/f" then
        local sinfo = line_state:getwordinfo(cwi + 2)
        if sinfo then
            local count = line_state:getwordcount()
            local einfo = line_state:getwordinfo(count)
            local s = line_state:getline():sub(sinfo.offset, einfo.offset + einfo.length - 1)
            if not s:find('"') then
                local sq = (cwi + 2 == count) and 2 or 1 -- Value for setsuppressquoting().
                return cwi + 2, sq
            end
        end
    end
end

local for_gen = clink.generator(20)
function for_gen:generate(line_state, builder)
    local is, sq = is_for_f_options(line_state)
    if is then
        builder:setsuppressquoting(sq)
        builder:addmatches({
            { match="eol=", suppressappend=true },
            { match="skip=", suppressappend=true },
            { match="delims=", suppressappend=true },
            { match="tokens=", suppressappend=true },
            { match="usebackq ", suppressappend=true },
        })
        return true
    end
end
function for_gen:getwordbreakinfo(line_state)
    if is_for_f_options(line_state) then
        local word = line_state:getendword()
        local last_space = word:find(" [^ ]*$")
        if last_space then
            return last_space, 0
        end
    end
end

local color_options = {}
color_options["eol="] = true
color_options["skip="] = true
color_options["delims="] = true
color_options["tokens="] = true
color_options["usebackq"] = true

local for_cfy = clink.classifier(20)
function for_cfy:classify(commands)
    local arg_color
    for i = 1, #commands do
        local line_state = commands[i].line_state
        local is, sq = is_for_f_options(line_state)
        if is then
            local line = line_state:getline()
            local info = line_state:getwordinfo(is)
            local word = line:sub(info.offset, info.offset + info.length - 1)
            if #word then
                local classifications = commands[i].classifications
                local trailing
                local start
                local text = ""
                local j = 0
                local iter = unicode.iter(word)
                while true do
                    local s = iter()
                    local apply
                    if s == " " or not s then
                        apply = (text == "usebackq")
                        trailing = nil
                        if not apply then
                            start = nil
                            text = ""
                        end
                    elseif not trailing then
                        start = start or j
                        text = text..s
                        if s == "=" then
                            trailing = true
                            apply = color_options[text]
                        end
                    end
                    if apply then
                        if not arg_color then
                            arg_color = settings.get("color.arg")
                        end
                        classifications:applycolor(info.offset + start, #text, arg_color)
                        start = nil
                        text = ""
                    end
                    if not s then
                        break
                    end
                    j = j + #s
                end
            end
        end
    end
end

end -- Version check.

--------------------------------------------------------------------------------
-- START
--
-- This argmatcher for the START command requires Clink v1.5.14 or higher.
-- It handles the fact that a quoted title is optional.

if (clink.version_encoded or 0) >= 10050014 then

local function maybe_string(_, _, word_index, line_state, _)
    local info = line_state:getwordinfo(word_index)
    if not info.quoted then
        return 1    -- Advance; this arg position only accepts a quoted string.
                    -- Anything else should get handled by the next position.
    end
end

local function init_descriptions(argmatcher)
    local descriptions = {
    ["/d"]           = { " dir" },
    ["/b"]           = {},
    ["/i"]           = {},
    ["/min"]         = {},
    ["/max"]         = {},
    ["/separate"]    = {},
    ["/shared"]      = {},
    ["/low"]         = {},
    ["/normal"]      = {},
    ["/high"]        = {},
    ["/realtime"]    = {},
    ["/abovenormal"] = {},
    ["/belownormal"] = {},
    ["/node"]        = { " node" },
    ["/affinity"]    = { " hexmask" },
    ["/wait"]        = {},
    }

    local f = io.popen("2>nul start /?")
    if f then
        local pending = {}
        local seen = {}
        local function finish_pending()
            if pending.flag and pending.desc then
                local desc = pending.desc
                    :gsub("^%s+", "")
                    :gsub("(%.%s.*)$", "")
                    :gsub("%.$", "")
                    :gsub("%s+$", "")
                local t = descriptions[pending.flag]
                if t then
                    table.insert(t, desc)
                end
            end
            pending.flag = nil
            pending.desc = nil
        end
        for line in f:lines() do
            local flag, text
            text = line:match("^%s%s%s%s%s%s%s%s%s%s%s%s+([^%s].*)$")
            if not text then
                flag, text = line:match("^%s%s%s+(/?[A-Za-z]+)%s+([^%s].*)$")
            end
            if flag then
                finish_pending()
                flag = "/"..flag:gsub("^/+", ""):lower()
                if not seen[flag] and descriptions[flag] then
                    seen[flag] = true
                    pending.flag = flag
                    pending.desc = text
                end
            elseif not text then
                finish_pending()
            elseif pending.desc then
                pending.desc = pending.desc.." "..text
            end
        end
        finish_pending()
        f:close()
    end

    if #descriptions["/d"] < 2 then
        table.insert(descriptions["/d"], "Starting directory")
    end

    argmatcher:addarg({
        onadvance=maybe_string,
        fromhistory=true,
    })
    argmatcher:addflags({
        nosort=true,
        "/?",
        "/d"..clink.argmatcher():addarg(clink.dirmatches),
        "/b", "/i",
        "/min", "/max", "/wait",
        "/separate", "/shared",
        "/low", "/normal", "/high", "/realtime", "/abovenormal", "/belownormal",
        "/node"..clink.argmatcher():addarg({fromhistory=true}),
        "/affinity"..clink.argmatcher():addarg({fromhistory=true}),
    })
    argmatcher:adddescriptions(descriptions)
    argmatcher:hideflags("/?")
    argmatcher:chaincommand()
end

clink.argmatcher("start"):setdelayinit(init_descriptions)

end -- Version check.

