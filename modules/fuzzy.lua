local exports = {}

local function endsWith (str, _end)
   return _end == '' or str:sub(-#_end) == _end
end

local function charAt (str, index)
    return str:sub(index, index)
end

local function isLastPathSegment (needle, candidate)
    return endsWith(candidate, '/'..needle) or endsWith(candidate, '\\'..needle)
end

-- returns a match score
-- param needle - the query string to match to candidate
-- param candidate - whe whole string to check against needle
exports.is_fuzzy_match = function (needle, candidate)
    -- Return a perfect score if string is query or the file name itself matches the query.
    if candidate == needle or isLastPathSegment(needle, candidate) then return 1 end

    local totalCharacterScore = 0
    local indexInQuery = 1
    local indexInString = 1

    while indexInQuery <= #needle do

        local char = charAt(needle, indexInQuery)
        -- use regexp to find either upper or lowercase variant
        local index = candidate:find("["..char:lower()..char:upper().."]", indexInString)

        -- if char isn't present in string then overall score is 0
        if index == nil then return 0 end

        -- Start from minimal score
        local characterScore = 0.1
        -- Same case bonus.
        if charAt(candidate, index) == char then
            characterScore = characterScore + 0.1
        end

        if index == 1 or charAt(candidate, index - 1) == '/' or charAt(candidate, index - 1) == '\\' then
            -- Start of string bonus
            characterScore = characterScore + 0.8
        elseif charAt(candidate, index - 1):find('[-_ ]') then
            -- Start of word bonus
            characterScore = characterScore + 0.7
        end

        -- increment counter
        indexInQuery = indexInQuery + 1
        -- set start position for the next iteration
        indexInString = index + 1
        -- increment total character score
        totalCharacterScore = totalCharacterScore + characterScore
    end

    local queryScore = totalCharacterScore / #needle
    local result = ((queryScore * (#needle / #candidate)) + queryScore) / 2

    return result
end

return exports
