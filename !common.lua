
function file_match_generator(word)
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

function dir_match_generator(word)
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
    for _, dir in ipairs(clink.find_dirs(mask, true)) do
        local file = prefix..dir
        if include_dots or (dir ~= "." and dir ~= "..") then
            if clink.is_match(word, file) then
                table.insert(matches, file)
            end
        end
    end

    -- If there was no matches but text is a dir then use it as the single match.
    -- Otherwise tell readline that matches are files and it will do magic.
    if #matches == 0 then
        if clink.is_dir(rl_state.text) then
            table.insert(matches, rl_state.text)
        end
    else
        clink.matches_are_files()
    end

    return matches
end