local w = require('tables').wrap
local parser = clink.arg.new_parser

local function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

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
                    if hosts[trim(hst)] == nill then
                        hosts[trim(hst)]=1
                    end
                end
            end
            line = ssh_config:read("*line")
        end
    end
    ssh_config:close()
    local ssh_known_hosts = io.open(clink.get_env("userprofile") .. "/.ssh/known_hosts")
    if ssh_known_hosts then
        local line = ssh_known_hosts:read("*line")
        while line do
            local parts = split(line, ' ')
            local names = split(parts[1], ',')
            local name = trim(names[1])
            if hosts[name] == nil then
                hosts[name]=1
            end
            line = ssh_known_hosts:read("*line")
        end
    end
    ssh_known_hosts.close()
    real_hosts = {}
    for s,c in pairs(hosts) do
        table.insert(real_hosts, s)
    end
    local result = w(real_hosts)
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
