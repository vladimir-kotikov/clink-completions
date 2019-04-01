local parser = clink.arg.new_parser

local loadenv_parser = parser()
local env_dirs = clink.find_dirs('E:\\env\\*', true)
local arguments = {}
for _, dirname in pairs(env_dirs) do
    if dirname ~= '.' and dirname ~= '..' then
        table.insert(arguments, dirname)
    end
end
loadenv_parser:set_arguments(arguments)
loadenv_parser:disable_file_matching()

clink.arg.register_parser('loadenv', loadenv_parser)
clink.arg.register_parser('loadenv.bat', loadenv_parser)
