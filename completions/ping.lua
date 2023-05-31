require('arghelper')
local w = require('tables').wrap

-- Hosts from the .ssh/config file use `color.alias`.
-- Hosts from the .ssh/known_hosts use `color.cmd`.
-- Hosts from the hosts file use default color.

local arg = clink.argmatcher():addarg()
local host_list = clink.argmatcher():addarg({fromhistory=true})
local src_addr = clink.argmatcher():addarg({fromhistory=true})

local function read_lines (filename)
    local lines = w({})
    local f = io.open(filename)
    if not f then
        return lines
    end

    for line in f:lines() do
        table.insert(lines, line)
    end

    f:close()
    return lines
end

-- read all Host entries in the user's ssh config file
local function list_ssh_hosts()
    return read_lines(os.getenv("userprofile") .. "/.ssh/config")
        :map(function (line)
            local host = line:match('^Host%s+(.*)$')
            if host then
                for pattern in host:gmatch('([^%s]+)') do
                    if not pattern:match('[%*|%?|/|!]') then
                        return pattern
                    end
                end
            end
            return nil
        end)
        :filter()
        :map(function(line)
            return { match=line, type="alias" }
        end)
end

local function list_known_hosts()
    return read_lines(os.getenv("userprofile") .. "/.ssh/known_hosts")
        :map(function (line)
            return line:match('^([^%s,]*).*')
        end)
        :filter()
        :map(function (line)
            return { match=line, type="cmd" }
        end)
end

local function list_hosts_file()
    local t = w({})
    local lines = read_lines(os.getenv("systemroot") .. "/system32/drivers/etc/hosts")
    for _, line in ipairs(lines) do
        local ip, hosts = line:match('^%s*([0-9.:]+)%s(.*)$')
        if ip then
            table.insert(t, ip)
            for _, host in ipairs(string.explode(hosts)) do
                table.insert(t, host)
            end
        end
    end
    return t:filter()
end

local hosts = function (token)  -- luacheck: no unused args
    return list_ssh_hosts()
        :concat(list_known_hosts())
        :concat(list_hosts_file())
end

-- luacheck: no max line length
clink.argmatcher("ping")
:addarg({hosts})
:_addexflags({
    {"-t",                  "Ping the specified host until stopped"},
    {"-a",                  "Resolve addresses to hostnames"},
    {"-n"..arg, " count",   "Number of echo requests to send"},
    {"-l"..arg, " size",    "Send buffer size"},
    {"-f",                  "Set Don't Fragment flag in packet (IPv4-only)"},
    {"-i"..arg, " TTL",     "Time To Live"},
    {"-v"..arg, " TOS",     "Deprecated; Type of Service (IPv4-only)"},
    {"-r"..arg, " count",   "Record route for count hops (IPv4-only)"},
    {"-s"..arg, " count",   "Timestamp for count hops (IPv4-only)"},
    {"-j"..host_list, " host-list", "Loose source route along host-list (IPv4-only)"},
    {"-k"..host_list, " host-list", "Strict source route along host-list (IPv4-only)"},
    {"-w"..arg, " timeout", "Timeout in milliseconds to wait for each reply"},
    {"-R",                  "Deprecated; Use routing header to test reverse route also (IPv4-only)"},
    {"-S"..src_addr, " srcaddr", "Source address to use"},
    {"-c"..arg, " compartment", "Routing compartment identifier"},
    {"-p",                  "Ping a Hyper-V Network Virtualization provider address"},
    {"-4",                  "Force using IPv4"},
    {"-6",                  "Force using IPv6"},
})

