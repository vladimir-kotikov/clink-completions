--- fastboot.lua, Android Fastboot completion for Clink.
-- @compatible Android SDK Platform-tools v31.0.3
-- @author Goldie Lin
-- @date 2021-08-27
-- @see [Clink](https://github.com/chrisant996/clink)
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

local flashing_parser = clink.arg.new_parser()
flashing_parser:disable_file_matching()
flashing_parser:set_arguments({
    "lock",
    "unlock",
    "lock_critical",
    "unlock_critical",
    "lock_bootloader",
    "unlock_bootloader",
    "get_unlock_ability",
    "get_unlock_bootloader_nonce"
})

local partitions = {
    "devinfo",
    "splash",
    "keystore",
    "ssd",
    "frp",
    "misc",
    "aboot",
    "abl",
    "abl_a",
    "abl_b",
    "boot",
    "boot_a",
    "boot_b",
    "recovery",
    "cache",
    "persist",
    "userdata",
    "system",
    "system_a",
    "system_b",
    "vendor",
    "vendor_a",
    "vendor_b"
}

local partitions_parser = clink.arg.new_parser()
partitions_parser:set_arguments(partitions)

local partitions_nofile_parser = clink.arg.new_parser()
partitions_nofile_parser:disable_file_matching()
partitions_nofile_parser:set_arguments(partitions)

local variables_parser = clink.arg.new_parser()
variables_parser:disable_file_matching()
variables_parser:set_arguments({
    "all",
    "serialno",
    "product",
    "secure",
    "unlocked",
    "variant",
    "kernel",
    "version-baseband",
    "version-bootloader",
    "charger-screen-enabled",
    "off-mode-charge",
    "battery-soc-ok",
    "battery-voltage",
    "slot-count",
    "current-slot",
    "has-slot:boot",
    "has-slot:modem",
    "has-slot:system",
    "slot-retry-count:a",
    "slot-retry-count:b",
    "slot-successful:a",
    "slot-successful:b",
    "slot-unbootable:a",
    "slot-unbootable:b"
})

local slots = {
    "a",
    "b"
}

local slot_types = {
    "all",
    "other"
}

local slots_full = {}
for _, i in ipairs(slots) do
    table.insert(slots_full, i)
end
for _, i in ipairs(slot_types) do
    table.insert(slots_full, i)
end

local slots_parser = clink.arg.new_parser()
slots_parser:disable_file_matching()
slots_parser:set_arguments(slots)

local slot_types_parser = clink.arg.new_parser()
slot_types_parser:disable_file_matching()
slot_types_parser:set_arguments(slots_full)

local fs_options = {
    "casefold",
    "compress",
    "projid"
}

local fs_options_parser = clink.arg.new_parser()
fs_options_parser:set_arguments(fs_options)

local flash_raw_parser = clink.arg.new_parser()
flash_raw_parser:set_arguments({
    "boot"
})

local devices_parser = clink.arg.new_parser()
devices_parser:disable_file_matching()
devices_parser:set_flags(
    "-l"
)

local reboot_parser = clink.arg.new_parser()
reboot_parser:disable_file_matching()
reboot_parser:set_arguments({
    "bootloader",
    "emergency"
})

local oem_parser = clink.arg.new_parser()
oem_parser:disable_file_matching()
oem_parser:set_arguments({
    "lock",
    "unlock",
    "device-info",
    "select-display-panel",
    "enable-charger-screen",
    "disable-charger-screen"
})

local gsi_parser = clink.arg.new_parser()
gsi_parser:disable_file_matching()
gsi_parser:set_arguments({
    "wipe",
    "disable"
})

local snapshotupdate_parser = clink.arg.new_parser()
snapshotupdate_parser:disable_file_matching()
snapshotupdate_parser:set_arguments({
    "cancel",
    "merge"
})

local fastboot_parser = clink.arg.new_parser()
fastboot_parser:set_flags(
    "-w",
    "-u",
    "-s",
    "--dtb",
    "-c",
    "--cmdline",
    "-i",
    "-h",
    "--help",
    "-b",
    "--base",
    "--kernel-offset",
    "--ramdisk-offset",
    "--tags-offset",
    "--dtb-offset",
    "-n",
    "--page-size",
    "--header-version",
    "--os-version",
    "--os-patch-level",
    "-S",
    "--slot"                   .. slot_types_parser,
    "-a"                       .. slots_parser,
    "--set-active="            .. slots_parser,
    "--skip-secondary",
    "--skip-reboot",
    "--disable-verity",
    "--disable-verification",
    "--fs-options="            .. fs_options_parser,
    "--wipe-and-use-fbe",
    "--unbuffered",
    "--force",
    "-v",
    "--verbose",
    "--version"
)
fastboot_parser:set_arguments({
    "help"                         .. null_parser,
    "update",
    "flashall"                     .. null_parser,
    "flashing"                     .. flashing_parser,
    "flash"                        .. partitions_parser,
    "erase"                        .. partitions_nofile_parser,
    "format"                       .. partitions_nofile_parser,
    "getvar"                       .. variables_parser,
    "set_active"                   .. slots_parser,
    "boot",
    "flash:raw"                    .. flash_raw_parser,
    "devices"                      .. devices_parser,
    "continue"                     .. null_parser,
    "reboot"                       .. reboot_parser,
    "reboot-bootloader"            .. null_parser,
    "oem"                          .. oem_parser,
    "gsi"                          .. gsi_parser,
    "wipe-super"                   .. null_parser,
    "create-logical-partition",
    "delete-logical-partition",
    "resize-logical-partition",
    "snapshot-update"              .. snapshotupdate_parser,
    "fetch"                        .. partitions_nofile_parser,
    "stage",
    "get_staged",
})

local function fastboot_devices_serialno_match_generator(text, first, last)
    local matched_cmd = false
    local leading = rl_state.line_buffer:sub(1, last)
    local trailing = rl_state.line_buffer:sub(last + 1)
    local a, b = leading:match('^%s*(fastboot%s+-s)%s+([%w]*)%s*$')
    local c = trailing:match('^%s*([%w]*)%s*')
    if a and b then
        matched_cmd = true
        local serialno = {}
        for line in io.popen('fastboot devices 2>NUL'):lines() do
            table.insert(serialno, line:match('^(%w+)%s+.*$'))
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

clink.arg.register_parser("fastboot", fastboot_parser)
clink.register_match_generator(fastboot_devices_serialno_match_generator, 15)
