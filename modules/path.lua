exports = {}

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