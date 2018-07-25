local JSON = require('JSON')
local parser = clink.arg.new_parser
local composer_args_cache = {}

function JSON:assert () end  -- luacheck: no unused args


local function register_parser(c_parser)
    c_parser:disable_file_matching()
    local cg_parser = parser({ 'global'..c_parser })
    cg_parser:disable_file_matching()
    clink.arg.register_parser('c', c_parser)
    clink.arg.register_parser('composer', c_parser)
    clink.arg.register_parser('c', cg_parser)
    clink.arg.register_parser('composer', cg_parser)
end

local function parse_composer_args(word) -- luacheck: no unused args
    if #composer_args_cache > 0 then return composer_args_cache end

    local args_list = io.popen('composer list --format=json')
    if args_list == nil then return end

    local args_json = args_list:read('*a')
    args_list:close()

    if not args_json:gmatch('[{}%[%]]') then return end

    while args_json:sub(1, 1) ~= '{' do
        args_json = args_json:sub(2)
    end

    local commands_table = JSON:decode(args_json)
    if commands_table == nil then return end

    for _, command in pairs(commands_table.commands) do
        table.insert(composer_args_cache, command.name)

        local arguments = {}
        for _, argument in pairs(command.definition.arguments) do
            table.insert(arguments, argument.name)
        end

        local options = {}
        for _, option in pairs(command.definition.options) do
            table.insert(options, option.name)
            if option.shortcut:len() > 0 then
                table.insert(options, option.shortcut)
            end
        end

        local args_opts_parser = parser()
        if #arguments > 0 and command.name ~= 'help' then
            args_opts_parser:set_arguments(arguments)
        end
        args_opts_parser:set_flags(options)
        args_opts_parser:disable_file_matching()

        register_parser( parser({ command.name..args_opts_parser }) )
    end

    register_parser( parser({
        'help'..parser({ composer_args_cache }):disable_file_matching()
    }) )

    return composer_args_cache
end

register_parser( parser({ parse_composer_args }) )
