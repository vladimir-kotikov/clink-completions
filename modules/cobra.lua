-- Completion protocol shared by commands built with github.com/spf13/cobra.
local cobra = {}

-- io.popen uses cmd.exe. Quote each argument independently, and decline input
-- which cmd would expand even inside quotes. Never execute the edited line.
function cobra.quote(word)
    if word:find('["%%!\r\n%z]') then return nil end
    return '"' .. word:gsub('(\\+)$', '%1%1') .. '"'
end

function cobra.command(executable, words)
    local quoted = cobra.quote(executable)
    if not quoted then return nil end
    local args = { '2>nul', quoted, '__complete' }
    for _, word in ipairs(words) do
        quoted = cobra.quote(word)
        if not quoted then return nil end
        args[#args + 1] = quoted
    end
    return table.concat(args, ' ')
end

function cobra.parse(lines)
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
    return { matches=matches, directive=directive }
end

local function has(value, flag)
    return value % (flag * 2) >= flag
end

function cobra.apply(result, word, builder)
    if not result then return false end
    local directive = result.directive
    if has(directive, 1) then return true end
    if has(directive, 2) then builder:setsuppressappend() end
    if has(directive, 32) then builder:setnosort() end
    if has(directive, 16) then
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
    if has(directive, 8) then
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
    return #result.matches > 0 or has(directive, 4)
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
                if previous and previous == start then
                    words[#words] = words[#words] .. word
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
        local command = cobra.command(line_state:getword(first), words)
        if not command then return true end
        local result = cache[command]
        if result == nil then
            local pipe = io.popen(command)
            if not pipe then return false end
            local lines = {}
            for line in pipe:lines() do lines[#lines + 1] = line end
            local ok = pipe:close()
            result = ok and cobra.parse(lines) or false
            cache[command] = result
        end
        return cobra.apply(result, line_state:getendword(), builder)
    end
    return generator
end

return cobra
