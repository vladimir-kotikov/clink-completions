local w = require('tables').wrap
local parser = clink.arg.new_parser

-- read all Host entries in the user's ssh config file
local function list_ssh_hosts()
    local hosts = {}
    local ssh_config = io.open(clink.get_env("userprofile") .. "/.ssh/config")
    if ssh_config then
        local line = ssh_config:read("*line")
        while line do
            local hostss = line:match("^Host (.*)$")
            if hostss then
                for hst in string.gmatch(hostss, "%S+") do
                    table.insert(hosts, trim(hst))
                end
            end
            line = ssh_config:read("*line")
        end
    end
    ssh_config:close()
    local result = w(hosts)
    return result
end

local hosts = function (token)
    return list_ssh_hosts()
    :filter(function(path)
        return clink.is_match(token, path)
    end)
end

local ssh_hosts_parser = parser({hosts})

clink.arg.register_parser("ssh", ssh_hosts_parser)
