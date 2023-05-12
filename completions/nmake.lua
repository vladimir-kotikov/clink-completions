-- By default, this omits targets with / or \ in them.  To include such targets,
-- set %INCLUDE_NMAKE_PATHLIKE_TARGETS% to any non-empty string.

require('arghelper')

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

local function should_include_pathlike_targets()
    return os.getenv('INCLUDE_NMAKE_PATHLIKE_TARGETS') and true
end

local function extract_target(line, last_line, targets)
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

    -- Ignore special targets.
    if special_targets[p] then
        return
    end

    -- Maybe ignore path-like targets.
    local mt
    if should_include_pathlike_targets() then
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

local function comp_target_sort(a, b)
    local a_alias = (a.type == 'alias')
    local b_alias = (b.type == 'alias')
    if a_alias ~= b_alias then
        return a_alias
    else
        return string.comparematches(a.match, b.match)
    end
end

local function get_targets(_word, _word_index, line_state, builder, user_data) -- luacheck: no unused
    local nmake_cmd = '"'..line_state:getword(line_state:getcommandwordindex())..'" /p /q /r'
    if user_data and user_data.makefile then
        nmake_cmd = nmake_cmd..' "'..user_data.makefile..'"'
    end

    local file = io.popen('2>nul '..nmake_cmd)
    if not file then
        return
    end

    local targets = {}
    local last_line = ''
    for line in file:lines() do
        extract_target(line, last_line, targets)
        last_line = line
    end
    file:close()

    if string.comparematches and should_include_pathlike_targets() then
        table.sort(targets, comp_target_sort)
        if builder.setnosort then
            builder:setnosort()
        end
    end

    return targets
end

local er_parser = clink.argmatcher():addarg({'none', 'prompt', 'queue' ,'send'})
local file_matches = clink.argmatcher():addarg(clink.filematches)

local flags_def = {
    { 'A',                                  'Build all evaluated targets' },
    { 'B',                                  'Build if time stamps are equal' },
    { 'C',                                  'Suppress output messages' },
    { 'D',                                  'Display build information' },
    { 'E',                                  'Override env-var macros' },
    { {'ERRORREPORT:', er_parser, 'mode'},  'Report errors to Microsoft' },
    { {'F', file_matches, ' makefile'},     'Use the specified makefile' },
    { 'G',                                  'Display !include filenames' },
    { 'HELP',                               'Display brief usage message' },
    { 'I',                                  'Ignore exit codes from commands' },
    { 'K',                                  'Build unrelated targets on error' },
    { 'N',                                  'Display commands but do not execute' },
    { 'NOLOGO',                             'Suppress copyright message' },
    { 'P',                                  'Display NMAKE information' },
    { 'Q',                                  'Check time stamps but do not build' },
    { 'R',                                  'Ignore predefined rules/macros' },
    { 'S',                                  'Suppress executed-commands display' },
    { 'T',                                  'Change time stamps but do not build' },
    { 'U',                                  'Dump inline files' },
    { {'X', file_matches, ' stderrfile'},   'Write errors to the specified file' },
    { 'Y',                                  'Disable batch-mode' },
    { '?',                                  'Display brief usage message' },
}

local flags_table = {}
for _, e in ipairs(flags_def) do
    local slash, dash
    local has_args
    if type(e[1]) == 'table' then
        slash = ('/'..e[1][1])..e[1][2]
        dash = ('-'..e[1][1]:lower())..e[1][2]
        has_args = true
    else
        slash = '/'..e[1]
        dash = '-'..e[1]:lower()
    end
    if has_args then
        table.insert(flags_table, { slash, e[1][3], e[2] })
        table.insert(flags_table, { dash, e[1][3], e[2] })
    else
        table.insert(flags_table, { slash, e[2] })
        table.insert(flags_table, { dash, e[2] })
    end
end

clink.argmatcher("nmake")
:_addexflags(flags_table)
:addarg({get_targets})
:loop()
