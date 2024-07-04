-- Clink script to generate completions for Cloud Foundry CLI.
-- https://github.com/cloudfoundry/cli

local fullname = ...

local function get_completions(matchtype, word, word_index, line_state, match_builder, user_data) -- luacheck: no unused
    -- Collect the command arguments.
    local args = ""
    for i = 1, line_state:getwordcount() do
        local info = line_state:getwordinfo(i)
        if info and not info.redir then
            if args == "" then
                -- Skip first non-redir word; it's the program name.
                args = " "
            else
                local w = line_state:getword(i)
                if w:sub(-1) == "\\" then
                    -- Compensate for \" command line parsing.
                    w = w.."\\"
                end
                args = args..' "'..w..'"'
            end
        end
    end

    -- Get completions.
    local command = string.format('2>nul set GO_FLAGS_COMPLETION=verbose& 2>nul "%s" %s', fullname, args)
    local f = io.popen(command)
    if f then
        -- Add completions to the match builder.
        for line in f:lines() do
            local mt = matchtype
            local w, d = line:match("^([^ ]+) +# (.*)$")
            w = w or line
            if w:sub(-1) == "\\" then
                mt = "dir"
            end
            if w and d then
                -- Include the description when available.
                match_builder:addmatch({ match=w, description=d }, mt)
            else
                match_builder:addmatch(w, mt)
            end
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
