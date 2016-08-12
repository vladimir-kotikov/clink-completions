package.path = "modules/?.lua;".. package.path

local w = require('tables').wrap
local shell = require('shell')

local __filename = debug.getinfo(1,'S').source;

describe("shell module", function()

    -- it("module should export methods", function()
    --     assert_equal(#w(require("shell")):keys(), 4)
    -- end)

    describe('grep function', function ()
        it('should throw if 1st argument is not non-empty string', function ()
            assert_error(function () shell.grep(nil) end)
            assert_error(function () shell.grep(1) end)
            assert_error(function () shell.grep('') end)
            assert_error(function () shell.grep({}) end)
        end)

        it('should return empty table if file does not exist', function ()
            assert_type(shell.grep('foo'), 'table')
        end)

        it('should read lines from file', function ()
            local grepped = shell.grep('spec/fixtures/foo')
            local lines_count = 0
            for line in io.open('spec/fixtures/foo'):lines() do
                assert_equal(grepped[lines_count], line)
                lines_count = lines_count + 1
            end

            assert_equal(lines_count, #grepped)
        end)
    end)

    -- describe("'filter' function", function ()
    --     local test_table = {"a", "b", nil, false}

    --     it("should exist", function()
    --         assert_equal(type(filter), "function")
    --     end)

    --     it("should accept nil arguments", function()
    --         assert_not_error(filter)
    --     end)

    --     it("should return empty table if input table is not specified", function()
    --         assert_empty(filter())
    --     end)

    --     it("should throw if first argument is not a table", function()
    --         assert_error(function() filter("aaa") end)
    --     end)

    --     it("should throw if second argument is not a function", function()
    --         assert_error(function() filter({"a", "b"}, "a") end)
    --         -- TODO: uncomment this
    --         -- assert_error(function() filter({}, "a") end)
    --     end)

    --     it("should filter out falsy values if no filter function specified", function()
    --         assert_tables_equal(filter(test_table), {"a", "b"})
    --     end)

    --     it("should filter out values which doesn't satisfy filter function", function()
    --         local function test_filter1(a) return a == "a" end
    --         local function test_filter2(a) return a == nil end
    --         assert_tables_equal(filter(test_table, test_filter1), {"a"})
    --         assert_tables_equal(filter(test_table, test_filter2), {nil})
    --     end)
    -- end)

    -- describe("'map' function", function ()
    --     local test_table = {"a", "b", "c"}

    --     it("should exist", function()
    --         assert_equal(type(map), "function")
    --     end)

    --     it("should accept nil arguments", function()
    --         assert_not_error(map)
    --     end)

    --     it("should return empty table if input table is not specified", function()
    --         assert_empty(map())
    --     end)

    --     it("should throw if first argument is not a table", function()
    --         assert_error(function() map("aaa") end)
    --     end)

    --     it("should throw if second argument is not a function", function()
    --         assert_error(function() map(test_table, "a") end)
    --     end)

    --     it("should return original table if no map function specified", function()
    --         assert_tables_equal(map(test_table), test_table)
    --     end)

    --     it("should apply map function to all values", function()
    --         local function test_map(a) return a == "a" end
    --         assert_tables_equal(map(test_table, test_map), {true, false, false})
    --     end)
    -- end)

    -- describe("'reduce' function", function ()
    --     local test_table = {1, 2, 3}
    --     local _noop = function() end

    --     it("should exist", function()
    --         assert_equal(type(reduce), "function")
    --     end)

    --     it("should accept nil arguments (except reduce func)", function()
    --         assert_not_error(function() reduce(nil, nil, _noop) end)
    --     end)

    --     it("should return accumulator if input table is not specified", function()
    --         assert_equal(reduce("accum", nil, _noop), "accum")
    --     end)

    --     it("should throw if second argument (source table) is not a table", function()
    --         assert_error(function() reduce({}, "aaa", _noop) end)
    --     end)

    --     it("should throw if third argument (reduce func) is not a function", function()
    --         assert_error(function() reduce({}, {}, "a") end)
    --         -- TODO: uncomment this
    --         -- assert_error(reduce)
    --     end)

    --     it("should apply reduce func to each element of source table", function()
    --         local function test_reduce(a, v) table.insert(a, v+1) return a end
    --         assert_tables_equal(reduce({}, test_table, test_reduce), {2, 3, 4})
    --     end)
    -- end)

    -- describe("'concat' function", function ()
    --     local test_table = {1, 2, 3}
    --     local _noop = function() end

    --     it("should exist", function()
    --         assert_equal(type(concat), "function")
    --     end)

    --     it("should accept nil arguments", function()
    --         assert_not_error(concat)
    --     end)

    --     it("should return empty table if no input arguments specified", function()
    --         assert_empty(concat())
    --     end)

    --     it("should wrap non-table parameter into a table", function()
    --         local ret = concat("a")
    --         assert_not_empty(ret)
    --         assert_type(ret, "table")
    --     end)

    --     it("should omit nil arguments", function()
    --         assert_tables_equal(concat("a", nil, "b"), {"a", "b"})
    --     end)

    --     it("should copy values from table params into result", function()
    --         assert_tables_equal(concat("a", {nil}, {"b"}), {"a", "b"})
    --     end)
    -- end)
end)
