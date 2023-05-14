-- By default, this omits targets with / or \ in them.  To include such targets,
-- set %INCLUDE_PATHLIKE_MAKEFILE_TARGETS% to any non-empty string.

local clink_version = require('clink_version')

require('arghelper')

if not clink_version.supports_argmatcher_delayinit then
    print("make.lua argmatcher requires a newer version of Clink; please upgrade.")
    return
end

-- Table of special targets to always ignore.
local special_targets = {
    ['.PHONY'] = true,
    ['.SUFFIXES'] = true,
    ['.DEFAULT'] = true,
    ['.PRECIOUS'] = true,
    ['.INTERMEDIATE'] = true,
    ['.SECONDARY'] = true,
    ['.SECONDEXPANSION'] = true,
    ['.DELETE_ON_ERROR'] = true,
    ['.IGNORE'] = true,
    ['.LOW_RESOLUTION_TIME'] = true,
    ['.SILENT'] = true,
    ['.EXPORT_ALL_VARIABLES'] = true,
    ['.NOTPARALLEL'] = true,
    ['.ONESHELL'] = true,
    ['.POSIX'] = true,
    ['.NOEXPORT'] = true,
    ['.MAKE'] = true,
}

-- Function to parse a line of make output, and add any extracted target to the
-- specified targets table.
local function extract_target(line, last_line, targets, pathlike)
    -- Ignore comment lines.
    if line:find('#', 1, true) then
        return
    end

    -- Ignore when not a target (is this only for GNU make?).
    if last_line:find('# Not a target') then
        return
    end

    -- Extract possible target.
    local p = (
        line:match('^([^%s]+):$') or    -- When target has no deps.
        line:match('^([^%s]+): '))      -- When target has deps.
    if not p then
        return
    end

    -- Ignore targets with pattern
    if p:find('%%') then
        return
    end

    -- Ignore special targets.
    if special_targets[p] then
        return
    end

    -- Maybe ignore path-like targets.
    local mt
    if pathlike then
        if not p:find('[/\\]') then
            mt = 'alias'
        end
    else
        if p:find('[/\\]') then
            return
        end
    end

    -- Add target.
    table.insert(targets, {match=p, type=mt})
end

-- Sort comparator to sort pathlike targets last.
local function comp_target_sort(a, b)
    local a_alias = (a.type == 'alias')
    local b_alias = (b.type == 'alias')
    if a_alias ~= b_alias then
        return a_alias
    else
        return string.comparematches(a.match, b.match)
    end
end

-- Function to collect available targets.
local function get_targets(word, word_index, line_state, builder, user_data) -- luacheck: no unused
    local make_cmd = '"'..line_state:getword(line_state:getcommandwordindex())..'" -p -q -r'
    if user_data and user_data.makefile then
        make_cmd = make_cmd..' -f "'..user_data.makefile..'"'
    end

    local file = io.popen('2>nul '..make_cmd)
    if not file then
        return
    end

    local targets = {}
    local last_line = ''

    -- Extract targets to be included.
    local pathlike = os.getenv('INCLUDE_PATHLIKE_MAKEFILE_TARGETS') and true
    for line in file:lines() do
        extract_target(line, last_line, targets, pathlike)
        last_line = line
    end

    file:close()

    -- If pathlike targets are allowed to be included, sort them last.
    if pathlike and string.comparematches then
        table.sort(targets, comp_target_sort)
        if builder.setnosort then
            builder:setnosort()
        end
    end

    return targets
end


-- This is empty as all flags for make are parsed by help_parser
local flags_table = {}

-- Function to detect the `-f` flag for overriding the default makefile.
local function onarg_flags(arg_index, word, word_index, line_state, user_data)    -- luacheck: no unused
    if word == '-f' or word == '--file=' or word == '--makefile=' then
        user_data.makefile = line_state:getword(word_index + 1)
    elseif word:match('^-f.+') then
        -- Not sure if this is a bug or not.
        -- But if a path containing : is used, it is split in two words
        local possible_makefile = word:sub(3)
        if possible_makefile:match(':$') then
            possible_makefile = possible_makefile..line_state:getword(word_index + 1)
        end
        user_data.makefile = possible_makefile
    end
end

-- Add onarg function to detect when the user overrides the default makefile.
flags_table.onarg = onarg_flags

-- Create an argmatcher for make.
local make_parser = clink.argmatcher("make")
:_addexflags(flags_table)
:addarg({get_targets})
:loop()

require('help_parser').run(make_parser, 'gnu', 'make --help', nil)
