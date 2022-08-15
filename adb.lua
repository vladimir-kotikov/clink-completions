--- adb.lua, Android ADB completion for Clink.
-- @compatible Android SDK Platform-tools v31.0.3 (ADB v1.0.41)
-- @author Goldie Lin
-- @date 2021-08-27
-- @see [Clink](https://github.com/mridgers/clink/)
-- @usage
--   Place it in "%LocalAppData%\clink\" if installed globally,
--   or "ConEmu/ConEmu/clink/" if you used portable ConEmu & Clink.
--

-- luacheck: no unused args
-- luacheck: ignore clink rl_state

local function ltrim(s)  -- luacheck: ignore
    return s:match("^%s*(.*)")
end

local function rtrim(s)  -- luacheck: ignore
    return s:match("(.-)%s*$")
end

local function lrtrim(s)  -- luacheck: ignore
    return s:match("^%s*(.-)%s*$")
end

local function table_length(t)
    local c = 0
    for _ in pairs(t) do c = c + 1 end
    return c
end

local function table_contains(t, e)
    for _, v in pairs(t) do
        if v == e then
            return true
        end
    end
    return false
end

local function dump(o)  -- luacheck: ignore
    if type(o) == 'table' then
        local s = '{ '
        local i = 1
        local max = table_length(o)
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s..'['..k..']="'..dump(v)..'"'
            if i ~= max then s = s..', ' end
            i = i + 1
        end
        return s..' }'
    else
        return tostring(o)
    end
end

local function split_str_to_table(inputstr, sep)  -- luacheck: ignore
    local t = {}
    if sep == nil then sep = "%s" end
    for s in inputstr:gmatch("([^"..sep.."]+)") do
        table.insert(t, s)
    end
    return t
end

local null_parser = clink.arg.new_parser()
null_parser:disable_file_matching()

local devices_parser = clink.arg.new_parser()
devices_parser:disable_file_matching()
devices_parser:set_flags(
    "-l"
)

local reconnect_parser = clink.arg.new_parser()
reconnect_parser:disable_file_matching()
reconnect_parser:set_arguments({
    "device",
    "offline"
})

local networking_options_parser = clink.arg.new_parser()
networking_options_parser:set_flags(
    "--list",
    "--no-rebind",
    "--remove",
    "--remove-all"
)

local mdns_parser = clink.arg.new_parser()
mdns_parser:disable_file_matching()
mdns_parser:set_arguments({
    "check",
    "services"
})

local push_parser = clink.arg.new_parser()
push_parser:set_flags(
    "--sync",
    "-n",
    "-z",
    "-Z"
)

local pull_parser = clink.arg.new_parser()
pull_parser:set_flags(
    "-a",
    "-z",
    "-Z"
)

local sync_parser = clink.arg.new_parser()
sync_parser:set_flags(
    "-n",
    "-l",
    "-z",
    "-Z"
)
sync_parser:set_arguments({
    "all",
    "data",
    "odm",
    "oem",
    "product_services",
    "product",
    "system",
    "system_ext",
    "vendor"
})

local shell_bu_backup_parser = clink.arg.new_parser()
shell_bu_backup_parser:set_flags(
    "-f",
    "-all",
    "-apk",
    "-noapk",
    "-obb",
    "-noobb",
    "-shared",
    "-noshared",
    "-system",
    "-nosystem",
    "-keyvalue",
    "-nokeyvalue"
)
local backup_parser = shell_bu_backup_parser

local shell_bu_parser = clink.arg.new_parser()
shell_bu_parser:set_arguments({
    "backup" .. shell_bu_backup_parser,
    "restore"
})

local shell_parser = clink.arg.new_parser()
shell_parser:set_flags(
    "-e",
    "-n",
    "-T",
    "-t",
    "-x"
)
shell_parser:set_arguments({
    "bu" .. shell_bu_parser
})

local install_parser = clink.arg.new_parser()
install_parser:set_flags(
    "-l",
    "-r",
    "-t",
    "-s",
    "-d",
    "-g",
    "--abi",
    "--instant",
    "--no-streaming",
    "--streaming",
    "--fastdeploy",
    "--no-fastdeploy",
    "--force-agent",
    "--date-check-agent",
    "--version-check-agent",
    "--local-agent"
)

local install_multiple_parser = clink.arg.new_parser()
install_multiple_parser:set_flags(
    "-l",
    "-r",
    "-t",
    "-s",
    "-d",
    "-p",
    "-g",
    "--abi",
    "--instant",
    "--no-streaming",
    "--streaming",
    "--fastdeploy",
    "--no-fastdeploy",
    "--force-agent",
    "--date-check-agent",
    "--version-check-agent",
    "--local-agent"
)

local install_multi_package_parser = clink.arg.new_parser()
install_multi_package_parser:set_flags(
    "-l",
    "-r",
    "-t",
    "-s",
    "-d",
    "-p",
    "-g",
    "--abi",
    "--instant",
    "--no-streaming",
    "--streaming",
    "--fastdeploy",
    "--no-fastdeploy",
    "--force-agent",
    "--date-check-agent",
    "--version-check-agent",
    "--local-agent"
)

local uninstall_parser = clink.arg.new_parser()
uninstall_parser:set_flags(
    "-k"
)

local logcat_format_parser = clink.arg.new_parser()
logcat_format_parser:disable_file_matching()
logcat_format_parser:set_arguments({
    "brief",
    "help",
    "long",
    "process",
    "raw",
    "tag",
    "thread",
    "threadtime",
    "time",
    "color",
    "descriptive",
    "epoch",
    "monotonic",
    "printable",
    "uid",
    "usec",
    "UTC",
    "year",
    "zone"
})

local logcat_buffer_parser = clink.arg.new_parser()
logcat_buffer_parser:disable_file_matching()
logcat_buffer_parser:set_arguments({
    "default",  -- default = main,system,crash
    "all",
    "main",
    "radio",
    "events",
    "system",
    "crash",
    "security",
    "kernel"
})

local logcat_parser = clink.arg.new_parser()
logcat_parser:disable_file_matching()
logcat_parser:set_flags(
    "-s",
    "-f",
    "--file",
    "-r",
    "--rotate-kbytes",
    "-n",
    "--rotate-count",
    "--id",
    "-v"       .. logcat_format_parser,
    "--format" .. logcat_format_parser,
    "-D",
    "--dividers",
    "-c",
    "--clear",
    "-d",
    "-e",
    "--regex",
    "-m",
    "--max-count",
    "--print",
    "-t",
    "-T",
    "-g",
    "--buffer-size",
    "-G",
    "--buffer-size=",
    "-L",
    "--last",
    "-b"       .. logcat_buffer_parser,
    "--buffer" .. logcat_buffer_parser,
    "-B",
    "--binary",
    "-S",
    "--statistics",
    "-p",
    "--prune",
    "-P",
    "--prune=",
    "--pid",
    "--wrap"
)
logcat_parser:set_arguments({
    "*:V",
    "*:D",
    "*:I",
    "*:W",
    "*:E",
    "*:F",
    "*:S",
})

local remount_parser = clink.arg.new_parser()
remount_parser:disable_file_matching()
remount_parser:set_flags(
    "-R"
)

local reboot_parser = clink.arg.new_parser()
reboot_parser:disable_file_matching()
reboot_parser:set_arguments({
    "bootloader",
    "recovery",
    "sideload",
    "sideload-auto-reboot",
    "edl"
})

local adb_parser = clink.arg.new_parser()
adb_parser:set_flags(
    "-a",
    "-d",
    "-e",
    "-s",
    "-p",
    "-t",
    "-H",
    "-P",
    "-L"
)
adb_parser:set_arguments({
    "help"                          .. null_parser,
    "version"                       .. null_parser,
    "devices"                       .. devices_parser,
    "connect"                       .. null_parser,
    "disconnect"                    .. null_parser,
    "pair"                          .. null_parser,
    "reconnect"                     .. reconnect_parser,
    "ppp",
    "forward"                       .. networking_options_parser,
    "reverse"                       .. networking_options_parser,
    "mdns"                          .. mdns_parser,
    "push"                          .. push_parser,
    "pull"                          .. pull_parser,
    "sync"                          .. sync_parser,
    "shell"                         .. shell_parser,
    "emu",
    "install"                       .. install_parser,
    "install-multiple"              .. install_multiple_parser,
    "install-multi-package"         .. install_multi_package_parser,
    "uninstall"                     .. uninstall_parser,
    "backup"                        .. backup_parser,
    "restore",
    "bugreport",
    "jdwp"                          .. null_parser,
    "logcat"                        .. logcat_parser,
    "disable-verity"                .. null_parser,
    "enable-verity"                 .. null_parser,
    "keygen",
    "wait-for-device"               .. null_parser,
    "wait-for-recovery"             .. null_parser,
    "wait-for-rescue"               .. null_parser,
    "wait-for-sideload"             .. null_parser,
    "wait-for-bootloader"           .. null_parser,
    "wait-for-disconnect"           .. null_parser,
    "wait-for-any-device"           .. null_parser,
    "wait-for-any-recovery"         .. null_parser,
    "wait-for-any-rescue"           .. null_parser,
    "wait-for-any-sideload"         .. null_parser,
    "wait-for-any-bootloader"       .. null_parser,
    "wait-for-any-disconnect"       .. null_parser,
    "wait-for-usb-device"           .. null_parser,
    "wait-for-usb-recovery"         .. null_parser,
    "wait-for-usb-rescue"           .. null_parser,
    "wait-for-usb-sideload"         .. null_parser,
    "wait-for-usb-bootloader"       .. null_parser,
    "wait-for-usb-disconnect"       .. null_parser,
    "wait-for-local-device"         .. null_parser,
    "wait-for-local-recovery"       .. null_parser,
    "wait-for-local-rescue"         .. null_parser,
    "wait-for-local-sideload"       .. null_parser,
    "wait-for-local-bootloader"     .. null_parser,
    "wait-for-local-disconnect"     .. null_parser,
    "get-state"                     .. null_parser,
    "get-serialno"                  .. null_parser,
    "get-devpath"                   .. null_parser,
    "remount"                       .. remount_parser,
    "reboot-bootloader"             .. null_parser,
    "reboot"                        .. reboot_parser,
    "sideload",
    "root"                          .. null_parser,
    "unroot"                        .. null_parser,
    "usb"                           .. null_parser,
    "tcpip",
    "start-server"                  .. null_parser,
    "kill-server"                   .. null_parser,
    "attach"                        .. null_parser,
    "detach"                        .. null_parser
})

local function adb_devices_serialno_match_generator(text, first, last)
    local matched_cmd = false
    local leading = rl_state.line_buffer:sub(1, last)
    local trailing = rl_state.line_buffer:sub(last + 1)
    local a, b = leading:match('^%s*(adb%s+-s)%s+([%w]*)%s*$')
    local c = trailing:match('^%s*([%w]*)%s*')
    if a and b then
        matched_cmd = true
        local serialno = {}
        for line in io.popen('adb devices 2>NUL'):lines() do
            if line ~= 'List of devices attached' then
                table.insert(serialno, line:match('^(%w+)%s+.*$'))
            end
        end
        -- print('\nsn = '..dump(serialno))  -- DEBUG
        if table_contains(serialno, b) then
            return false
        end
        if c and c ~= "" then
            if table_contains(serialno, c) then
                return false
            end
        end
        if b == "" then
            for _, v in pairs(serialno) do
                clink.add_match(v)
            end
        else
            for _, v in pairs(serialno) do
                if v:find('^'..b) then
                    clink.add_match(v)
                end
            end
        end
    end
    return matched_cmd
end

local function adb_devices_transportid_match_generator(text, first, last)
    local matched_cmd = false
    local leading = rl_state.line_buffer:sub(1, last)
    local trailing = rl_state.line_buffer:sub(last + 1)
    local a, b = leading:match('^%s*(adb%s+-t)%s+([%w]*)%s*$')
    local c = trailing:match('^%s*([%w]*)%s*')
    if a and b then
        matched_cmd = true
        local transport_id = {}
        for line in io.popen('adb devices -l 2>NUL'):lines() do
            if line ~= 'List of devices attached' then
                table.insert(transport_id, line:match('^.*%s+transport_id:(%d+)%s*.*$'))
            end
        end
        -- print('\ntransport_id = '..dump(transport_id))  -- DEBUG
        if table_contains(transport_id, b) then
            return false
        end
        if c and c ~= "" then
            if table_contains(transport_id, c) then
                return false
            end
        end
        if b == "" then
            for _, v in pairs(transport_id) do
                clink.add_match(v)
            end
        else
            for _, v in pairs(transport_id) do
                if v:find('^'..b) then
                    clink.add_match(v)
                end
            end
        end
    end
    return matched_cmd
end

clink.arg.register_parser("adb", adb_parser)
clink.register_match_generator(adb_devices_serialno_match_generator, 10)
clink.register_match_generator(adb_devices_transportid_match_generator, 11)
