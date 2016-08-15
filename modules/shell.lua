local path = require('path')
local w = require('tables').wrap

local shell = {}

local function validate_params(params, allowed_values)
    assert(params == nil or type(params) == 'string', 'options to shell.ls must be string or nil')
    assert(#params == 0 or params:sub(0, 1) == '-', 'options must start with - or be an empty string')
    assert(params:match('^[-'..allowed_values..']*$'), 'param must be one of '..allowed_values..', got '..params)
end

shell.ls = function (options, where)
    validate_params(options, 'rfF')

    -- Init defaults
    local recursive = false
    local find_files = false
    local find_dirs = false

    -- Parse options
    if (options:find('r')) then recursive = true end
    if (options:find('f')) then find_files = true end
    if (options:find('F')) then find_dirs = true end

    if (not find_files and not find_dirs) then
        find_files = true
        find_dirs = true
    end

    local where = where or '*'

    local entries = w(clink.find_files(where))
    :filter(path.is_real_dir)

    local files = entries:filter(function(entry)
        return not clink.is_dir(where ..'/'..entry)
    end)

    local dirs = entries:filter(function(entry)
        return clink.is_dir(where ..'/'..entry)
    end)

    local result = w()
    if (find_files) then result = result:concat(files) end
    if (find_dirs) then result = result:concat(dirs) end

    -- if 'recursive' flag is not set, we don't need to iterate
    -- through directories, so just return files and/or dirs found
    if not recursive then
        return result
    end

    -- iterate through directories and call list_files recursively
    return dirs:reduce({}, function(accum, dir)
        return shell.ls(options, where..'/'..dir)
        :map(function(entry)
            return dir..'/'..entry
        end)
        :concat(accum)
    end)
    :concat(result)
end

shell.grep = function (file_path)

    assert(type(file_path) == 'string' and file_path:len() ~= 0,
        "First argument must be non-empty string")

    local result = w()

    local file = io.open(file_path)
    if file == nil then return result end

    for line in file:lines() do
        result:push(line)
    end

    file:close()
    return result
end

return shell
