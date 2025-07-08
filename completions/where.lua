require('arghelper')

--------------------------------------------------------------------------------
-- Helper function to remember the /r argument, if any.

local function onarg_root(arg_index, word, _, _, user_data)
    if arg_index == 1 then
        -- Remember the /r root argument.
        if user_data and user_data.shared_user_data then
            word = word:gsub("['\"]", "")
            user_data.shared_user_data.where_root = word
        end
    end
end

--------------------------------------------------------------------------------
-- Define flags.

local dir_matcher = clink.argmatcher():addarg({clink.dirmatches, onarg=onarg_root})

-- luacheck: push
-- luacheck: no max line length
local flag_def_table = {
    {"/r", dir_matcher, " dir", "Recursively searches and displays the files that match the given pattern starting from the specified directory"},
    {"/q",          "Returns only the exit code, without displaying the list of matched files. (Quiet mode)"},
    {"/f",          "Displays the matched filename in double quotes"},
    {"/t",          "Displays the file size, last modified date and time for all matched files"},
    {"/?",          "Displays help message"},
}
-- luacheck: pop

local flags = {}
for i = 1, 2 do
    for _,f in ipairs(flag_def_table) do
        if i == 2 then
            f[1] = f[1]:gsub("^/", "-")
        end
        if f[3] then
            table.insert(flags, { f[1]..f[2], f[3], f[4] })
            if f[1]:upper() ~= f[1] then
                table.insert(flags, { hide=true, f[1]:upper()..f[2], f[3], f[4] })
            end
        else
            table.insert(flags, { f[1], f[2] })
            if f[1]:upper() ~= f[1] then
                table.insert(flags, { hide=true, f[1]:upper(), f[2] })
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Argmatcher for "where".

local where = clink.argmatcher("where")
:setflagsanywhere(false)
:_addexflags(flags)

--------------------------------------------------------------------------------
-- Allow completion of pattern in "$envvar:pattern" and "path:pattern".

local where__generator = clink.generator(20)

function where__generator:generate(line_state, builder) -- luacheck: no unused
    -- where__generator exists purely to define getwordbreakinfo().
    return
end

function where__generator:getwordbreakinfo(line_state) -- luacheck: no unused
    local cwi = line_state:getcommandwordindex()
    if line_state:getword(cwi):lower() == "where" then
        local prev_word = line_state:getword(line_state:getwordcount() - 1)
        if prev_word ~= "/r" and prev_word ~= "/R" and prev_word ~= "-r" then
            local word = line_state:getendword()
            local scope = word:match("^(.*:)[^:]-$")
            if scope then
                return #scope, 0
            end
            scope = word:match("^(%$[^:]*)$")
            if scope then
                return 1, 0
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Argument completions.

local function get_scope(line_state, word_index)
    if line_state:getwordcount() == word_index and word_index > 1 then
        local last = line_state:getwordinfo(word_index)
        local prev = line_state:getwordinfo(word_index - 1)
        if prev and last and prev.offset+prev.length == last.offset then
            local line = line_state:getline()
            local word = line:sub(prev.offset, prev.offset + prev.length - 1)

            -- Does a finished scope exist?  ("$var:" or "path:")
            local scope, endquote
            if prev.quoted then
                scope = word:match('^(.*:)$')
                endquote = scope:match('":$')
            else
                scope = word:match('^(.*:)$')
            end
            if scope then
                -- "where" has several quirks with respect to out-of-place
                -- quotes in arguments.  This catches a couple of them, but
                -- isn't trying to (and doesn't) catch all quirks.
                local bad
                if scope:find('"') then
                    -- FAILS:   pa"th:*
                    bad = true
                elseif prev.quoted and not endquote and line:sub(last.offset, last.offset + 1) == '""' then
                    -- FAILS:   "path:""*
                    -- works:   "path":""*
                    -- works:   path:""*
                    bad = true
                end
                return scope, bad
            end

            -- Does an unfinished "$var" scope exist?
            scope = word:match('^%$[^:]*$')
            if scope then
                return scope
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Argument completion.

local function where_arg_completion(...) -- luacheck: no unused
    local word, word_index, line_state, builder, user_data = ... -- luacheck: no unused

    -- Construct the where command.
    local scope, bad = get_scope(line_state, word_index)
    if bad then
        return {}
    elseif scope and scope:find("^%$[^:]*$") then
        builder:addmatches(os.getenvnames(), "word")
        builder:setappendcharacter(":")
        return {}
    elseif os.getenv("WHERE_BREAK_PATHPATTERN_SYNTAX") then
        -- PROBLEM:  This code was for vladimir-kotikov/clink-completions#196.
        -- But it's disabled by default because (1) it breaks the `path:pattern`
        -- syntax.  Also, this code doesn't restrict to only executable files as
        -- originally requested, because doing that would break other valid ways
        -- to use where.
        local where_args
        if scope then
            -- When "$envvar:pattern" or "path:pattern" are used.
            scope = scope:gsub('"', '')
            where_args = ' "'..rl.expandtilde(scope)..'*"'
        elseif user_data and user_data.shared_user_data and user_data.shared_user_data.where_root then
            -- When /r is used.
            where_args = ' /r "'..rl.expandtilde(user_data.shared_user_data.where_root)..'" *'
        else
            -- Default.
            where_args = ' *'
        end

        -- Collect matches by running where.
        if where_args then
            local p = io.popen("2>nul where"..where_args)
            if p then
                -- Add matches.
                for l in p:lines() do
                    -- REVIEW:  If filtering by file type is desired, this is a
                    -- good place to add that.
                    builder:addmatch(path.getname(l), "file")
                end
                p:close()
                return {}
            end
        end
    end

    return clink.filematches(...)
end

where:addarg(where_arg_completion):loop(1)
