local w = require('tables').wrap
local parser = clink.arg.new_parser

local function trim (string_to_trim)
	return string_to_trim:match("^%s*(.-)%s*$")
end

local function get_command (line)
	return trim(line):match("^(%S+) ")
end

local function read_lines (command, start, stop)
    local lines = w({})
    local f = io.popen(command)
    if not f then return lines end

	local list_start = false
	local list_end = true

    for line in f:lines() do
		if list_start and list_end then
			table.insert(lines, get_command(line))
		end

		if string.match(line, start) then
			list_start = true
		end

		if string.match(line, stop) then
			list_end = false
		end
	end

    f:close()
    return lines
end

local function list_docker_commands()
	return read_lines("docker --help", "Commands:", "Block until a container stops"):filter()
end

local docker_commands = function ()
	return list_docker_commands()
end

local docker_commands_parser = parser({docker_commands})

clink.arg.register_parser("docker", docker_commands_parser)
