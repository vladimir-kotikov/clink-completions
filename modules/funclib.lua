
local exports = {}

exports.filter = function (tbl, filter)
    if not tbl then return {} end
    if not filter then filter = function(v) return v end end
    local ret = {}
    for _,v in ipairs(tbl) do
        if filter(v) then
            table.insert(ret, v)
        end
    end
    return ret
end

exports.map = function (tbl, map_func)
    if not tbl then return {} end
    local ret = {}
    for _,v in ipairs(tbl) do
        table.insert(ret, map_func(v))
    end
    return ret
end

exports.reduce = function (accum, tbl, func)
    if not tbl then return accum end
    local ret = accum
    for _,v in ipairs(tbl) do
        ret = func(ret, v)
    end
    return ret
end

exports.concat = function (tbl1, tbl2)
    tbl1 = tbl1 or {}
    tbl2 = tbl2 or {}
    if type(tbl1) ~= "table" then tbl1 = {tbl1} end
    if type(tbl2) ~= "table" then tbl2 = {tbl2} end
    local ret = tbl1
    for _,v in ipairs(tbl2) do
        table.insert(ret, v)
    end
    return ret
end

return exports
