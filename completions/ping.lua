require('arghelper')
local w = require('tables').wrap
local clink_version = require('clink_version')

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

local function extract_address(pattern, match_type, portflag)
    if not pattern then
        return nil
    end

    local addr, port = pattern:match('%[([^%]]+)%]:(%d+)')
    if not addr then
        addr = pattern:match('%[([^%]]+)%]')
    end
    if not addr then
        addr = pattern
    end

    local match
    if portflag and port then
        match = addr .. portflag .. port
    else
        match = addr
    end
    if clink_version.supports_display_filter_description then
        return { match=match, type=match_type }
    else
        return match
    end
end

-- read all Host entries in the user's ssh config file
local function list_ssh_hosts(portflag)
    local matches = w({})
    local lines = read_lines(clink.get_env("userprofile") .. "/.ssh/config")
    for _, line in ipairs(lines) do
        line = line:gsub('(#.*)$', '')
        local host = line:match('^Host%s+(.*)$')
        if host then
            for pattern in host:gmatch('([^%s]+)') do
                if not pattern:match('[%*%?/!]') then
                    table.insert(matches, extract_address(pattern, 'alias', portflag))
                end
            end
        end
    end
    return matches:filter()
end

local function list_known_hosts(portflag)
    return read_lines(clink.get_env("userprofile") .. "/.ssh/known_hosts")
        :map(function (line)
            line = line:gsub('(#.*)$', '')
            return extract_address(line:match('^([^%s,]*).*'), 'cmd', portflag)
        end)
        :filter()
end

local function list_hosts_file()
    local t = w({})
    local lines = read_lines(os.getenv("systemroot") .. "/system32/drivers/etc/hosts")
    for _, line in ipairs(lines) do
        line = line:gsub('(#.*)$', '')
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

local function hosts(token)  -- luacheck: no unused args
    return list_ssh_hosts()
        :concat(list_known_hosts())
        :concat(list_hosts_file())
end

-- luacheck: no max line length
clink.argmatcher("ping")
:addarg({hosts})
:_addexflags({
    {"-t",                  "持续 ping 指定主机直到停止"},
    {"-a",                  "将地址解析为主机名"},
    {"-n"..arg, " count",   "要发送的回显请求数"},
    {"-l"..arg, " size",    "发送缓冲区大小"},
    {"-f",                  "在数据包中设置\"不分段\"标志（仅 IPv4）"},
    {"-i"..arg, " TTL",     "生存时间"},
    {"-v"..arg, " TOS",     "已弃用；服务类型（仅 IPv4）"},
    {"-r"..arg, " count",   "记录 count 跳的路由（仅 IPv4）"},
    {"-s"..arg, " count",   "记录 count 跳的时间戳（仅 IPv4）"},
    {"-j"..host_list, " host-list", "沿 host-list 的松散源路由（仅 IPv4）"},
    {"-k"..host_list, " host-list", "沿 host-list 的严格源路由（仅 IPv4）"},
    {"-w"..arg, " timeout", "等待每个回复的超时时间（毫秒）"},
    {"-R",                  "已弃用；使用路由头测试反向路由（仅 IPv4）"},
    {"-S"..src_addr, " srcaddr", "要使用的源地址"},
    {"-c"..arg, " compartment", "路由隔离舱标识符"},
    {"-p",                  "Ping Hyper-V 网络虚拟化提供程序地址"},
    {"-4",                  "强制使用 IPv4"},
    {"-6",                  "强制使用 IPv6"},
})

