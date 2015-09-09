local function disableMatchGenerator(matchGenerator)
    for index,generator in ipairs(clink.generators) do
        if (generator.f == matchGenerator) then
            table.remove(clink.generators, index)
            return
        end
    end
end

-- Disable clink's embedded argument parser. Comment line below to enable it back
-- disableMatchGenerator(argument_match_generator)

-- Global table of available argument parsers
argParsers = {}

-- Define ArgParser class here
local ArgParser = setmetatable({}, {
    __call = function (argParser, ...) return argParser.new(...) end
})
ArgParser.__index = ArgParser

function ArgParser.new()
  return setmetatable({}, ArgParser)
end

function ArgParser:register(command)
    assert(type(command) == "string")
    assert(#command > 0)
    -- TODO: need to respect case when there is already another parser assigned
    -- to this command. ArgParser:mergeWith(anotherParser) or whatever?
    argParsers[command] = self
end

local function tryFindCommand(line)
    -- body
    print (text, first, last)
end

local function argParserMatcher(textToComplete, testStartIndex, textLastIndex)
    -- The whole command line that we will search for command and parser arguments
    local lineBuffer = rl_state.line_buffer
    -- First try to detect command at the beginning of buffer
    local command, commandEndPos = tryFindCommand(lineBuffer.sub(1, testStartIndex - 1))
    -- Didn't found any command so return false to check for another parsers
    if not command then return false end

    local argParser = argParsers[command]
    -- No registered argument parsers found, so just return false
    if not argParser then return false end

    -- Split the rest of buffer to tokens and run parser against tokens set
    argParser:tokenize(lineBuffer.sub(commandEndPos, textLastIndex))
        :parseTokens(tokens)
        :forEach(function (result)
            return clink.is_match(tokens[#tokens], result) and clink.add_match(result)
        end)

    return true

    -- local leading = rl_state.line_buffer:sub(1, first - 1):lower():trim()

    -- -- Extract the command.
    -- local cmd_l, cmd_r
    -- if leading:find("^%s*\"") then
    --     -- Command appears to be surround by quotes.
    --     cmd_l, cmd_r = leading:find("%b\"\"")
    --     if cmd_l and cmd_r then
    --         cmd_l = cmd_l + 1
    --         cmd_r = cmd_r - 1
    --     end
    -- else
    --     -- No quotes so the first, longest, non-whitespace word is extracted.
    --     cmd_l, cmd_r = leading:find("[^%s]+")
    -- end

    -- if not cmd_l or not cmd_r then
    --     return false
    -- end

    -- local regex = "[\\/:]*([^\\/:.]+)(%.*[%l]*)%s*$"
    -- local _, _, cmd, ext = leading:sub(cmd_l, cmd_r):lower():find(regex)

    -- -- Check to make sure the extension extracted is in pathext.
    -- if ext and ext ~= "" then
    --     if not clink.get_env("pathext"):lower():match(ext.."[;$]", 1, true) then
    --         return false
    --     end
    -- end
    
    -- -- Find a registered parser.
    -- local parser = parsers[cmd]
    -- if parser == nil then
    --     return false
    -- end

    -- -- Split the command line into parts.
    -- local str = rl_state.line_buffer:sub(cmd_r + 2, last)
    -- local parts = {}
    -- for _, sub_str in ipairs(clink.quote_split(str, "\"")) do
    --     -- Quoted strings still have their quotes. Look for those type of
    --     -- strings, strip the quotes and add it completely.
    --     if sub_str:sub(1, 1) == "\"" then
    --         local l, r = sub_str:find("\"[^\"]+")
    --         if l then
    --             local part = sub_str:sub(l + 1, r)
    --             table.insert(parts, part)
    --         end
    --     else
    --         -- Extract non-whitespace parts.
    --         for _, r, part in function () return sub_str:find("^%s*([^%s]+)") end do
    --             table.insert(parts, part)
    --             sub_str = sub_str:sub(r + 1)
    --         end
    --     end
    -- end

    -- -- If 'text' is empty then add it as a part as it would have been skipped
    -- -- by the split loop above.
    -- if text == "" then
    --     table.insert(parts, text)
    -- end

    -- -- Extend rl_state with match generation state; text, first, and last.
    -- rl_state.text = text
    -- rl_state.first = first
    -- rl_state.last = last

    -- -- Call the parser.
    -- local needle = parts[#parts]
    -- local ret = parser:go(parts)
    -- if type(ret) ~= "table" then
    --     return not ret
    -- end

    -- -- Iterate through the matches the parser returned and collect matches.
    -- for _, match in ipairs(ret) do
    --     if clink.is_match(needle, match) then
    --         clink.add_match(match)
    --     end
    -- end

    -- return true
end

--------------------------------------------------------------------------------
--clink.register_match_generator(argParserMatcher, 25)