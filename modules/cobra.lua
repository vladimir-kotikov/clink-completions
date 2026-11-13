-- Cobra's __complete protocol: https://github.com/spf13/cobra/blob/main/completions.go
local cobra = {}

local function quote(word)
    -- getword() already removes quotes. Reject any unexpected literal quote or
    -- control character here so this function can only emit one quoted argument.
    -- cmd can expand % and ! even inside quotes, so skip those requests too.
    if word:find('["%%!%c]') then return nil end
    -- The native executable's argv parser needs trailing backslashes doubled
    -- before the closing quote to keep them literal.
    return '"' .. word:gsub('(\\+)$', '%1%1') .. '"'
end

local function command(executable, words)
    -- Force .exe even for a bare command name. These quoting rules are for a
    -- native executable, not a BAT/CMD script or another PATHEXT entry.
    if not executable:lower():match('%.exe$') then
        executable = executable .. '.exe'
    end
    local quoted = quote(executable)
    if not quoted then return nil end
    -- Keep the redirection first. A command starting with a quote is subject
    -- to cmd.exe /C's outer-quote stripping rules, which can expose metacharacters.
    -- Both this prefix and the per-argument quoting above are required.
    local args = { '2>nul', quoted, '__complete' }
    for _, word in ipairs(words) do
        quoted = quote(word)
        if not quoted then return nil end
        args[#args + 1] = quoted
    end
    return table.concat(args, ' ')
end

-- ShellCompDirective bits from Cobra's completion protocol.
local directive_bits = {
    error = 1,
    no_space = 2,
    no_file_completion = 4,
    filter_file_extensions = 8,
    filter_directories = 16,
    keep_order = 32,
}

local function parse(lines)
    local directive = tonumber((lines[#lines] or ''):match('^:(%d+)$'))
    if not directive or directive > 63 then return nil end
    local matches = {}
    for i = 1, #lines - 1 do
        local line = lines[i]
        if line ~= '' and line:sub(1, 12) ~= '_activeHelp_' then
            local value, description = line:match('^([^\t]+)\t(.*)$')
            matches[#matches + 1] = { match=value or line, description=description }
        end
    end
    local directives = {}
    for name, bit in pairs(directive_bits) do
        directives[name] = directive % (bit * 2) >= bit
    end
    return { matches=matches, directives=directives }
end

local function apply(result, word, builder)
    if not result then return false end
    local directives = result.directives
    if directives.error then return true end
    if directives.no_space then builder:setsuppressappend() end
    if directives.keep_order then builder:setnosort() end
    if directives.filter_directories then
        -- Cobra can optionally name a directory whose children to complete.
        local root = result.matches[1] and result.matches[1].match
        local prefix = root and (root:gsub('[/\\]+$', '') .. '\\') or ''
        for _, match in ipairs(clink.dirmatches(prefix .. word)) do
            if prefix ~= '' then
                if type(match) == 'table' then
                    match.match = match.match:sub(#prefix + 1)
                else
                    match = match:sub(#prefix + 1)
                end
            end
            builder:addmatch(match, 'dir')
        end
        return true
    end
    if directives.filter_file_extensions then
        for _, match in ipairs(clink.filematches(word)) do
            local name = type(match) == 'table' and match.match or match
            local isdir = name:find('[/\\]$') or
                (type(match) == 'table' and (match.type or ''):find('dir', 1, true))
            local accept = isdir
            for _, ext in ipairs(result.matches) do
                local suffix = '.' .. ext.match:gsub('^%.', ''):lower()
                if name:lower():sub(-#suffix) == suffix then accept = true end
            end
            if accept then builder:addmatch(match, isdir and 'dir' or 'file') end
        end
        return true
    end
    builder:addmatches(result.matches)
    return #result.matches > 0 or directives.no_file_completion
end

function cobra.register(name)
    if (clink.version_encoded or 0) < 10030003 then return end
    local cache = {}
    clink.onbeginedit(function() cache = {} end)
    local generator = clink.generator(24)
    local function is_command(line_state)
        local index = line_state:getcommandwordindex()
        if line_state:getwordcount() <= index then return false end
        local word = line_state:getword(index)
        -- During getwordbreakinfo(), Clink leaves the surrounding quotes intact.
        word = word:gsub('^"', ''):gsub('"$', '')
        return (word:match('[^/\\]+$') or word):lower():gsub('%.exe$', '') == name
    end
    function generator:getwordbreakinfo(line_state) -- luacheck: no unused
        if is_command(line_state) then
            -- Cobra needs the prefix, including '=' and ':' in flag/FQBN values.
            return 0, #line_state:getendword()
        end
    end
    function generator:generate(line_state, builder) -- luacheck: no unused
        if not is_command(line_state) then return false end
        local first = line_state:getcommandwordindex()
        local words = {}
        local previous
        for i = first + 1, line_state:getwordcount() do
            local info = line_state:getwordinfo(i)
            if not info.redir then
                local word = line_state:getword(i)
                local start = info.offset - (info.quoted and 1 or 0)
                local gap = previous and line_state:getline():sub(previous, start - 1)
                -- cmd word breaking also splits unquoted key=value,comma lists.
                -- They remain one argv entry unless separated by whitespace.
                if gap and gap:match('^[=,;]*$') then
                    words[#words] = words[#words] .. gap .. word
                else
                    words[#words + 1] = word
                end
                previous = info.offset + info.length + (info.quoted and 1 or 0)
            else
                previous = nil
            end
        end
        local last = line_state:getwordinfo(line_state:getwordcount())
        if last.redir then return false end
        if #words == 0 then words[1] = '' end
        local request = command(line_state:getword(first), words)
        if not request then return true end
        local result = cache[request]
        if result == nil then
            local pipe = io.popen(request)
            if not pipe then return false end
            local lines = {}
            for line in pipe:lines() do lines[#lines + 1] = line end
            local ok = pipe:close()
            result = ok and parse(lines) or false
            cache[request] = result
        end
        return apply(result, line_state:getendword(), builder)
    end
    return generator
end

return cobra
