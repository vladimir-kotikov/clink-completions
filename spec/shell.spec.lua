local w = require('tables').wrap
local shell = require('shell')

describe("shell module", function()

    it("should export methods", function()
        assert.equal(#w(require("shell")):keys(), 2)
    end)

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

        before_each(function ()
            _G.clink = {}
            stub(_G.clink, 'find_files').returns(w({'.', '..', 'foo', 'bar', 'baz'}))
            stub(_G.clink, 'is_dir').invokes(function (fname)
                return not not fname:find('ba')
            end)
        end)

        after_each(function () _G.clink = nil end)

        it('should throw if passed invalid option', function ()
            assert.has.error(function () shell.ls(nil) end)
            assert.has.error(function () shell.ls(1) end)
            assert.has.error(function () shell.ls('foo') end)
            assert.has.error(function () shell.ls({}) end)
        end)

        it('should accept valid options in any combinations', function ()
            -- emulate only files to avoid infinite recursion
            _G.clink.is_dir.returns(false)

            assert.has.no.error(function () shell.ls('-r') end)
            assert.has.no.error(function () shell.ls('-f') end)
            assert.has.no.error(function () shell.ls('-F') end)
            assert.has.no.error(function () shell.ls('-rf') end)
            assert.has.no.error(function () shell.ls('-rF') end)
            assert.has.no.error(function () shell.ls('-rfF') end)
            assert.has.no.error(function () shell.ls('-fF') end)
        end)

        it('should not yield . and .. directories', function ()
            assert.equal(3, #shell.ls('', 'foo'))
            assert.are.same({'foo', 'bar', 'baz'}, shell.ls('', 'foo'))
        end)

        it('should return only files when "f" option is specified', function ()
            assert.equal(1, #shell.ls('-f'))
            assert.equal('foo', shell.ls('-f')[1])
        end)

        it('should return only dirs when "F" option is specified', function ()
            assert.equal(2, #shell.ls('-F'))
            assert.are.same({'bar', 'baz'}, shell.ls('-F'))
        end)

        it('should return both files and dirs when "fF" option (on neither "f" nor "F") is specified', function ()
            assert.equal(3, #shell.ls('-fF'))
            assert.equal(3, #shell.ls(''))
            assert.are.same({'foo', 'bar', 'baz'}, shell.ls('-fF'))
            assert.are.same({'foo', 'bar', 'baz'}, shell.ls(''))
        end)
    end)
end)
