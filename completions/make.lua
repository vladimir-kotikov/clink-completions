local clink_version = require('clink_version')
if not clink_version.supports_argmatcher_delayinit then
    print("make.lua argmatcher requires a newer version of Clink; please upgrade.")
    return
end

local function get_targets(_word, _word_index, line_state)
    local targets = {}
    -- run current makefile command to database file
    local file = io.popen(line_state:getline()..' -pqrR 2>nul')
    if not file then
        return
    end

    local target_pattern_base = '^([^%s]+):'
    local last_line = ''
    for line in file:lines() do
        if not line:find('#', 1) then -- Only process lines which are not comments
            local possible_target = line:match( target_pattern_base..'$') -- check for cases when target has no deps
            if possible_target == nil then
                possible_target = line:match( target_pattern_base..' ') -- when target has some deps
            end

            if possible_target and not last_line:find( '# Not a target') then
                table.insert(targets, {match=possible_target})
            end
        end
        last_line = line
    end
    file:close()
    return targets
end

local make_parser = clink.argmatcher("make")
make_parser:addarg({ get_targets })
make_parser:nofiles()

require('help_parser').run(make_parser, 'gnu', 'make --help', nil)
