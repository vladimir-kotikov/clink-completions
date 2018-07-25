local JSON = require('JSON')
local parser = clink.arg.new_parser
local la5_args_cache = {}

function JSON:assert () end  -- luacheck: no unused args

local function register_parser(la5_parser)
    local artisan_parser = parser({ 'artisan'..la5_parser })
    la5_parser:disable_file_matching()
    artisan_parser:disable_file_matching()
    clink.arg.register_parser('la5', la5_parser)
    clink.arg.register_parser('php', artisan_parser)
end

local function is_la5_project()
    local artisan_file = io.open(clink.get_cwd()..'/artisan', 'r')
    if artisan_file ~= nil then
        artisan_file:close()
        return true
    end

    return false
end

local function parse_la5_args(word) -- luacheck: no unused args
    if not is_la5_project() then return end
    if #la5_args_cache > 0 then return la5_args_cache end

    local args_list = io.popen('php artisan list --format=json')
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
        table.insert(la5_args_cache, command.name)

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
        if #arguments > 0 and command.name ~= 'help' and command.name ~= 'list' then
            args_opts_parser:set_arguments(arguments)
        end
        args_opts_parser:set_flags(options)
        args_opts_parser:disable_file_matching()

        register_parser( parser({ command.name..args_opts_parser }) )
    end

    local namespace_list = {}
    for _, namespace in pairs(commands_table.namespaces) do
        table.insert(namespace_list, namespace.id)
    end

    register_parser( parser({
        'list'..parser({ namespace_list }):disable_file_matching(),
        'help'..parser({ la5_args_cache }):disable_file_matching()
    }) )

    return la5_args_cache
end

register_parser( parser({ parse_la5_args }) )
