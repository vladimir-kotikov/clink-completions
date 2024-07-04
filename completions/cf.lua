-- Clink script to generate completions for Cloud Foundry CLI.
-- https://github.com/cloudfoundry/cli

local fullname = ...

local function get_completions(matchtype, word, word_index, line_state, match_builder, user_data)
    -- Collect the command arguments.
    local args = ""
    for i = 1, line_state:getwordcount() do
        local info = line_state:getwordinfo(i)
        if info and not info.redir then
            if args == "" then
                -- Skip first non-redir word; it's the program name.
                args = " "
            else
                local word = line_state:getword(i)
                if word:sub(-1) == "\\" then
                    -- Compensate for \" command line parsing.
                    word = word.."\\"
                end
                args = args..' "'..word..'"'
            end
        end
    end

    -- Get completions.
    local command = string.format('2>nul set GO_FLAGS_COMPLETION=verbose& 2>nul "%s" %s', fullname, args)
    local f = io.popen(command)
    if f then
        -- Add completions to the match builder.
        for line in f:lines() do
            local match = line
            local word, desc = line:match("^([^ ]+) +# (.*)$")
            if word and desc then
                -- Include the description when available.
                match = { match=word, description=desc }
            end
            match_builder:addmatch(match, matchtype)
        end
        f:close()
    end

    return true
end

local function get_flag_completions(...)
    return get_completions("flag", ...)
end

local function get_word_completions(...)
    return get_completions("word", ...)
end

local name = path.getname(fullname):lower()
if name == "cf.exe" or name == "cf8.exe" then
    local f = io.popen(string.format('2>nul findstr /m /c:code.cloudfoundry.org "%s"', fullname))
    if f then
        local t = f:read("*a") or ""
        if t:lower():find("cf.exe") then
            -- It really is Cloud Foundry, so set up an argmatcher.
            local ext = path.getextension(fullname)
            local cf
            if (clink.version_encoded or 0) >= 10060017 then
                cf = clink.argmatcher(fullname, fullname:sub(1, #fullname - #ext))
            else
                -- Can't use exact lookup in Clink v1.6.16 and earlier because
                -- typing "cf" looks for "cf.EXE" but internally argmatchers are
                -- always registered as lower case names.
                cf = clink.argmatcher("cf")
            end
            cf:setflagprefix("-")
              :addflags(get_flag_completions)
              :addarg(get_word_completions)
              :loop()
        end
    end
end
