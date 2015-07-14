
local exports = {}

local filter = require('funclib').filter

exports.dirs = function(word)
    return dir_match_generator(word)
end

exports.files = function (word)
    -- Strip off any path components that may be on text.
    local prefix = ""
    local i = word:find("[\\/:][^\\/:]*$")
    if i then
        prefix = word:sub(1, i)
    end

    local include_dots = word:find("%.+$") ~= nil

    local matches = {}
    local mask = word.."*"

    -- Find matches.
    for _, dir in ipairs(clink.find_files(mask, true)) do
        local file = prefix..dir
        if include_dots or (dir ~= "." and dir ~= "..") then
            if clink.is_match(word, file) then
                table.insert(matches, file)
            end
        end
    end

    -- Tell readline that matches are files and it will do magic.
    if #matches ~= 0 then
        clink.matches_are_files()
    end

    return matches
end

exports.create_dirs_matcher = function (dir_pattern)
    return function (token)
        return filter(clink.find_dirs(dir_pattern), function(dir)
            return not string.match(dir, '^%.%.?$') and clink.is_match(token, dir)
        end )
    end
end

exports.create_files_matcher = function (file_pattern)
    return function (token)
        return filter(clink.find_files(file_pattern), function(file)
            return clink.is_match(token, file)
        end )
    end
end

return exports
