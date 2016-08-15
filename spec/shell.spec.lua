package.path = "modules/?.lua;".. package.path

clink = {}
clink.find_files = function ()
    return {'foo', 'bar', 'baz'}
end

clink.is_dir = function()
    return false
end

-- stub(clink, 'find_files').returns({'foo', 'bar', 'baz'})
-- stub(clink, 'is_dir').returns(false)

local w = require('tables').wrap
local shell = require('shell')

local __filename = debug.getinfo(1,'S').source;


describe("shell module", function()

    -- it("module should export methods", function()
    --     assert_equal(#w(require("shell")):keys(), 4)
    -- end)

    describe('grep function', function ()
        it('should throw if 1st argument is not non-empty string', function ()
            assert.error(function () shell.grep(nil) end)
            assert.error(function () shell.grep(1) end)
            assert.error(function () shell.grep('') end)
            assert.error(function () shell.grep({}) end)
        end)

        it('should return empty table if file does not exist', function ()
            assert.is_table(shell.grep('foo'))
        end)

        it('should return non-empty table if file does exist', function ()
            local grepped = shell.grep('spec/fixtures/foo')
            assert.is_table(grepped)
            assert.is_true(#grepped > 0)
        end)

        it('returned table should have numeric indexes', function ()
            local grepped = shell.grep('spec/fixtures/foo')
            for i,v in ipairs(grepped) do
                assert.is_not_nil(i)
                assert.is_not.equal(v, '')
            end
        end)

        it('should read lines from file', function ()
            local grepped = shell.grep('spec/fixtures/foo')
            local lines_count = 1
            for line in io.open('spec/fixtures/foo'):lines() do
                assert.is.equal(grepped[lines_count], line)
                lines_count = lines_count + 1
            end

            -- use +1 here at table indexes starts w/ 1
            assert.is.equal(lines_count, #grepped + 1)
        end)
    end)

    describe('ls function', function ()

        it('should throw if passed invalid option', function ()
            assert.has.error(function () shell.ls(nil) end)
            assert.has.error(function () shell.ls(1) end)
            assert.has.error(function () shell.ls('') end)
            assert.has.error(function () shell.ls('foo') end)
            assert.has.error(function () shell.ls({}) end)
        end)

        it('should accept valid options in any combinations', function ()
            assert.has.no.error(function () shell.ls('-r') end)
            assert.has.no.error(function () shell.ls('-f') end)
            assert.has.no.error(function () shell.ls('-F') end)
            assert.has.no.error(function () shell.ls('-rf') end)
            assert.has.no.error(function () shell.ls('-rF') end)
            assert.has.no.error(function () shell.ls('-rfF') end)
            assert.has.no.error(function () shell.ls('-fF') end)
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
