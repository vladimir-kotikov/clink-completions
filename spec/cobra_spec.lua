local cobra = require('modules/cobra')

describe('Cobra completion protocol', function()
    it('quotes cmd arguments without allowing expansion or embedded quotes', function()
        assert.equals('"a & b"', cobra.quote('a & b'))
        assert.equals('"C:\\sketches\\\\"', cobra.quote('C:\\sketches\\'))
        for _, word in ipairs({'%PATH%', '!PATH!', 'a"b', 'a\nb', 'a\rb'}) do
            assert.is_nil(cobra.quote(word))
            assert.is_nil(cobra.command('arduino-cli', {word}))
        end
        assert.equals('2>nul "arduino-cli" __complete "core" ""',
            cobra.command('arduino-cli', {'core', ''}))
    end)

    it('requires a final protocol directive and separates descriptions', function()
        assert.is_nil(cobra.parse({'diagnostic'}))
        assert.is_nil(cobra.parse({':64'}))
        local result = cobra.parse({'uno\tArduino Uno', '_activeHelp_hint', '', ':4'})
        assert.same({{match='uno', description='Arduino Uno'}}, result.matches)
        assert.equals(4, result.directive)
    end)

    local function builder()
        return {
            matches={},
            addmatch=function(self, match) self.matches[#self.matches + 1] = match end,
            addmatches=function(self, matches) self.matches = matches end,
            setsuppressappend=function(self) self.no_space = true end,
            setnosort=function(self) self.no_sort = true end,
        }
    end

    it('honors error, spacing, ordering and filename fallback directives', function()
        local b = builder()
        assert.is_true(cobra.apply(cobra.parse({'ignored', ':1'}), '', b))
        assert.same({}, b.matches)
        assert.is_false(cobra.apply(cobra.parse({':0'}), '', b))
        assert.is_true(cobra.apply(cobra.parse({':4'}), '', b))
        assert.is_true(cobra.apply(cobra.parse({'one', ':34'}), '', b))
        assert.is_true(b.no_space)
        assert.is_true(b.no_sort)
    end)

    it('filters extensions and directories without offering filter metadata', function()
        local original = clink
        clink = {
            filematches=function() return {'a.ino', 'b.INO', 'c.txt', 'folder\\'} end,
            dirmatches=function(word)
                assert.equals('parent\\ch', word)
                return {{match='parent\\child\\', type='dir'}}
            end,
        }
        local b = builder()
        cobra.apply(cobra.parse({'ino', ':8'}), '', b)
        assert.same({'a.ino', 'b.INO', 'folder\\'}, b.matches)
        b = builder()
        cobra.apply(cobra.parse({'parent', ':16'}), 'ch', b)
        assert.same({{match='child\\', type='dir'}}, b.matches)
        clink = original
    end)
end)
