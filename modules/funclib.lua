
local exports = {}

--- Implementation of table.filter function. Applies filter function to each
 --    element of table and returns a new table with values for which filter
 --    returns 'true'.
 --
 -- @param tbl    a table to filter. Default is an empty table.
 -- @param filter function that accepts an element of table, specified in the
 --    first argument and returns either 'true' or 'false'. If not specified,
 --    then default function is used that returns its argument.
 --
 -- @return a new table with values that are not filtered out by 'filter' function.
exports.filter = function (tbl, filter)
    if not tbl then return {} end
    if not filter then filter = function(v) return v end end
    local ret = {}
    for _,v in ipairs(tbl) do
        if filter(v) then table.insert(ret, v) end
    end
    return ret
end

--- Implementation of table.map function. Applies filter function to each
 --    element of table and returns a new table with values returned by mapper
 --    function.
 --
 -- @param tbl      a table to filter. Default is an empty table.
 -- @param map_func function that accepts an element of table, specified in the
 --    first argument and returns a new value for resultant table. If not
 --    specified, then 'map' function returns it input table.
 --
 -- @return a new table with values produced by 'map_func'.
exports.map = function (tbl, map_func)
    if not tbl then return {} end
    if not map_func then return tbl end
    local ret = {}
    for _,v in ipairs(tbl) do
        table.insert(ret, map_func(v))
    end
    return ret
end

--- Implementation of table.reduce function. Iterates through table and calls
 --    'func' function passing an accumulator and an entry from the original
 --    table. The result of table is stored in accumulator and passed to next
 --    'func' call.
 --
 -- @param accum an accumulator, initial value that will be passed to first
 --    'func' call.
 -- @param tbl   a table to reduce. Default is an empty table.
 -- @param func  function that accepts two params: an accumulator and an element
 --    of table, specified in the first argument and returns a new value for
 --    accumulator.
 --
 -- @return a resultant accumulator value.
exports.reduce = function (accum, tbl, func)
    if not tbl then return accum end
    local ret = accum
    for _,v in ipairs(tbl) do
        ret = func(ret, v)
    end
    return ret
end

--- Concatenates any number of input values into one table. If input parameter is
 --    a table then its values is copied to the end of resultant table. If the
 --    parameter is single value, then it is appended to the resultant table. If
 --    the input value is 'nil', then it is omitted.
 -- 
 -- @return a result of concatenation. The result is always a table.
exports.concat = function (...)
    local ret = {}
    for _,arg in ipairs({...}) do
        if type(arg) == 'table' then
            for _,v in ipairs(arg) do
                table.insert(ret, v)
            end
        elseif arg ~= nil then
            table.insert(ret, arg)
        end
    end

    return ret
end

return exports
