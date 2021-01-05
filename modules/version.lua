local exports = {}

-- Busted runs these modules scripts *outside* of Clink.
-- So these Clink scripts have to work without any Clink APIs being available.
clink = clink or {}

local clink_version_encoded = clink.version_encoded or 0

exports.supports_display_filter_description = function ()
    return clink_version_encoded >= 10010012
end

exports.supports_color_settings = function ()
    return clink_version_encoded >= 10010009
end

exports.supports_query_rl_var = function ()
    return clink_version_encoded >= 10010009
end

return exports
