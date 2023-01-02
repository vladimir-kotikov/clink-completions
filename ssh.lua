-- Some modifications added based on:
-- https://github.com/dodmi/Clink-Addons

local w = require('tables').wrap
local parser = clink.arg.new_parser

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
    return read_lines(clink.get_env("userprofile") .. "/.ssh/config")
        :map(function (line)
            local host = line:match('^Host%s+(.*)$')
            if host then
                for pattern in host:gmatch('([^%s]+)') do
                    if not pattern:match('[%*|%?|/|!]') then
                        return pattern
                    end
                end
            end
        end)
        :filter()
end

local function list_known_hosts()
    return read_lines(clink.get_env("userprofile") .. "/.ssh/known_hosts")
        :map(function (line)
            return line:match('^([^%s,]*).*')
        end)
        :filter()
end

local hosts = function (token)  -- luacheck: no unused args
    return list_ssh_hosts()
        :concat(list_known_hosts())
end

-- return the list of available local ips
local function localIPs(token) -- luacheck: no unused args
    local assignedIPs = {}
    local f = io.popen('2>nul wmic nicconfig list IP')
    if f then
        local netLine
        for line in f:lines() do
            netLine = line:match('%{(.*)%}')
            if netLine then
                for ip in netLine:gmatch('%"([^,%s]*)%"') do
                    table.insert(assignedIPs, ip)
                end
            end
        end
        f:close()
    end
    return assignedIPs
end

-- return the list of supported ciphers
local function supportedCiphers(token) -- luacheck: no unused args
    local ciphers = {}
    local f = io.popen('2>nul ssh -Q cipher')
    if f then
        for line in f:lines() do
            table.insert(ciphers, line)
        end
        f:close()
    end
    return ciphers
end

-- return the list of supported MACs
local function supportedMACs(token) -- luacheck: no unused args
    local macs = {}
    local f = io.popen('2>nul ssh -Q mac')
    if f then
        for line in f:lines() do
            table.insert(macs, line)
        end
        f:close()
    end
    return macs
end

local ssh_parser = parser({hosts},
    "-4", "-6", "-A", "-a", "-C", "-f", "-G", "-g", "-K", "-k",
    "-M", "-N", "-n", "-q", "-s", "-T", "-t", "-V", "-v", "-X",
    "-x", "-Y", "-y", "-I", "-L", "-l", "-m", "-O", "-o", "-p",
    "-R", "-w", "-B", "-c", "-D", "-e", "-S",
    "-Q" .. parser({"cipher", "cipher_auth", "help", "mac", "kex", "kex-gss", "key", "key-cert", "key-plain", "key-sig", "protocol-version", "sig"}), -- luacheck: no max line length
    "-J" .. parser({hosts}),
    "-W" .. parser({hosts}),
    "-E" .. parser({clink.filematches}),
    "-F" .. parser({clink.filematches}),
    "-i" .. parser({clink.filematches}),
    "-b" .. parser({localIPs}),
    "-c" .. parser({supportedCiphers}),
    "-m" .. parser({supportedMACs})
)

clink.arg.register_parser("ssh", ssh_parser)

