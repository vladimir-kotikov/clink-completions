local concat = require('funclib').concat
local filter = require('funclib').filter
local map = require('funclib').map
local reduce = require('funclib').reduce

local exports = {}

local wrap_filter = function (tbl, filter_func)
    return exports.wrap(filter(tbl, filter_func))
end

local wrap_map = function (tbl, map_func)
    return exports.wrap(map(tbl, map_func))
end

local wrap_reduce = function (tbl, accum, reduce_func)
    local res = reduce(accum, tbl, reduce_func)
    return (type(res) == "table" and exports.wrap(res) or res)
end

local wrap_concat = function (tbl, ...)
    return exports.wrap(concat(tbl, ...))
end

exports.wrap = function (tbl)
    assert(type(tbl) == "table")

    local mt = getmetatable(tbl) or {}
    mt.__index = mt.__index or {}
    mt.__index.filter = wrap_filter
    mt.__index.map = wrap_map
    mt.__index.reduce = wrap_reduce
    mt.__index.concat = wrap_concat
    mt.__index.keys = function (tbl)
        local res = {}
        for k,_ in pairs(tbl) do
            table.insert(k)
        end
        return exports.wrap(res)
    end

    return setmetatable(tbl, mt)
end

return exports