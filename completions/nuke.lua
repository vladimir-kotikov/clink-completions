-- This script generates completions for Nuke.Build.
--
-- However, this does not apply input line coloring.  There isn't a good way to
-- support input line coloring, because there's no documentation about
-- Nuke.Build's command line interface.  The ":complete" command lists
-- completions based on the entire input line before that point, but reveals
-- nothing about why those are the completions for that specific argument
-- position in that specific command line.
--
-- The ":complete" command is designed to be easy to hook into bash, zsh, and
-- fish but the side effect is it doesn't support features like input line
-- coloring or descriptions for matches.

if (clink.version_encoded or 0) < 10030037 then
    print("nuke.lua requires a newer version of Clink; please upgrade.")
    return
end

-- Prepare the input line for passing safely as an argument to "nuke :complete".
local function sanitize_line(line_state)
    local text = ""

    local function sanitize_word(index, info)
        local end_offset = info.offset + info.length - 1
        if end_offset < info.offset and index == line_state:getwordcount() then
            end_offset = line_state:getcursor() - 1
        end

        local word = line_state:getline():sub(info.offset, end_offset)
        word = word:gsub('"', '\\"')
        return word
    end

    for i = 1, line_state:getwordcount() do
        local info = line_state:getwordinfo(i)
        local word
        if info.alias then
            word = "nuke"
        elseif not info.redir then
            word = sanitize_word(i, info)
        end
        if word then
            if #text > 0 then
                text = text .. " "
            end
            text = text .. word
        end
    end

    return text
end

-- Run "nuke :complete" with the sanitized input line to get completions.  The
-- 'filter' argument here enables differentiating between flags vs arguments in
-- the nuke command.
local function nuke_complete(line_state, builder, filter)
    local matches = {}

    -- Run 'nuke :complete' to get completions.
    local nuke = '"nuke"'
    local commandline = sanitize_line(line_state)
    local command = '2>nul '..nuke..' :complete "'..commandline..'"'
    local f = io.popen(command)
    if f then
        for line in f:lines() do
            line = line:gsub('"', '')
            if line ~= "" and line:find(filter) then
                -- Add non-blank words to the list of completion matches.
                table.insert(matches, line)
            end
        end
        f:close()
    end

    -- Mark the matches volatile even when generation was skipped due to
    -- running in a coroutine.  Otherwise it'll never run it in the main
    -- coroutine, either.
    builder:setvolatile()

    -- Enable quoting.
    if builder.setforcequoting then
        builder:setforcequoting()
    end

    return matches
end

local function nuke_complete_flags(word, index, line_state, builder) -- luacheck: no unused args
    -- Filter completions to only include flags.
    return nuke_complete(line_state, builder, '^%-')
end

local function nuke_complete_nonflags(word, index, line_state, builder) -- luacheck: no unused args
    -- Filter completions to exclude flags.
    return nuke_complete(line_state, builder, '^[^-]')
end

clink.argmatcher("nuke")
:addflags(nuke_complete_flags)
:addarg(nuke_complete_nonflags)
:setflagprefix("-")
:loop()

-- Apply the flag color to every word that starts with "--".  This doesn't
-- produce accurate input line coloring, but at least it makes the input line a
-- little more readable.
local clf = clink.classifier(1)
function clf:classify(commands) -- luacheck: no unused
    for _, c in ipairs(commands) do
        local ls = c.line_state
        for i = 1, ls:getwordcount() do
            local word = ls:getword(i)
            if word:sub(1, 2) == "--" then
                c.classifications:classifyword(i, 'f')
            end
        end
    end
end
