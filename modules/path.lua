exports = {}

local funclib = require('funclib')

exports.list_files = function (base_path, mask, recursive, reverse_separator)
    local mask = mask or '/*'

    local entries = funclib.filter(clink.find_files(base_path..mask),
        function(entry) return exports.is_real_dir(entry) end
    )

    local files = funclib.filter(entries,
        function(entry) return not clink.is_dir(base_path..'/'..entry) end
    )

    -- if 'recursive' flag is not set, we don't need to iterate
    -- through directories, so just return files found
    if not recursive then return files end

    local dirs = funclib.filter(entries,
        function(entry) return clink.is_dir(base_path..'/'..entry) end
    )

    local sep = reverse_separator and '/' or '\\'
    -- iterate through directories and call list_files recursively
    local dirs_entries = funclib.reduce({}, dirs,
        function(accum, dir)
            local dir_entries = exports.list_files(base_path..'/'..dir)
            local mapped_entries = funclib.map(dir_entries,
                function(entry) return dir..sep..entry end
            )
            return funclib.concat(accum, mapped_entries)
        end
    )

    return funclib.concat(files, dirs_entries)
end

exports.basename = function (path)
    local prefix = path
    local i = path:find("[\\/:][^\\/:]*$")
    if i then
        prefix = path:sub(i + 1)
    end
    return prefix
end

exports.pathname = function (path)
    local prefix = ""
    local i = path:find("[\\/:][^\\/:]*$")
    if i then
        prefix = path:sub(1, i-1)
    end
    return prefix
end

exports.is_metadir = function (dirname)
    return dirname == '.' or dirname == '..'
end

exports.is_real_dir = function (dirname)
    return not exports.is_metadir(dirname)
end

return exports