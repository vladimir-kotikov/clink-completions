--- scrcpy.lua, Genymobile's scrcpy completion for Clink.
-- @compatible scrcpy v1.21
-- @author Goldie Lin
-- @date 2021-12-12
-- @see [Clink](https://github.com/mridgers/clink/)
-- @see [scrcpy](https://github.com/Genymobile/scrcpy)
-- @usage
--   Place it in "%LocalAppData%\clink\" if installed globally,
--   or "ConEmu/ConEmu/clink/" if you used portable ConEmu & Clink.
--

-- luacheck: no unused args
-- luacheck: ignore clink rl_state

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

local null_parser = clink.arg.new_parser()
null_parser:disable_file_matching()

local bitrate_parser = clink.arg.new_parser()
bitrate_parser:disable_file_matching()
bitrate_parser:set_arguments({
    "8000000"           .. null_parser,
    "8000K"             .. null_parser,
    "8M"                .. null_parser
})

local crop_parser = clink.arg.new_parser()
crop_parser:disable_file_matching()
crop_parser:set_arguments({
    "720:1280:50:50"    .. null_parser
})

local display_parser = clink.arg.new_parser()
display_parser:disable_file_matching()
display_parser:set_arguments({
    "0"                 .. null_parser
})

local lockvideoorientation_parser = clink.arg.new_parser()
lockvideoorientation_parser:disable_file_matching()
lockvideoorientation_parser:set_arguments({
    "unlocked"          .. null_parser,
    "initial"           .. null_parser,
    "0"                 .. null_parser,
    "1"                 .. null_parser,
    "2"                 .. null_parser,
    "3"                 .. null_parser
})

local maxfps_parser = clink.arg.new_parser()
maxfps_parser:disable_file_matching()
maxfps_parser:set_arguments({
    "60"                .. null_parser
})

local maxsize_parser = clink.arg.new_parser()
maxsize_parser:disable_file_matching()
maxsize_parser:set_arguments({
    "0"                 .. null_parser
})

local portnumber_parser = clink.arg.new_parser()
portnumber_parser:disable_file_matching()
portnumber_parser:set_arguments({
    "27183"             .. null_parser
})

local pushtarget_parser = clink.arg.new_parser()
pushtarget_parser:disable_file_matching()
pushtarget_parser:set_arguments({
    "/sdcard/"
})

local recordformat_parser = clink.arg.new_parser()
recordformat_parser:disable_file_matching()
recordformat_parser:set_arguments({
    "mp4"               .. null_parser,
    "mkv"               .. null_parser
})

local renderdriver_parser = clink.arg.new_parser()
renderdriver_parser:disable_file_matching()
renderdriver_parser:set_arguments({
    "direct3d"          .. null_parser,
    "metal"             .. null_parser,
    "opengl"            .. null_parser,
    "opengles"          .. null_parser,
    "opengles2"         .. null_parser,
    "software"          .. null_parser
})

local rotation_parser = clink.arg.new_parser()
rotation_parser:disable_file_matching()
rotation_parser:set_arguments({
    "0"                 .. null_parser,
    "1"                 .. null_parser,
    "2"                 .. null_parser,
    "3"                 .. null_parser
})

local shortcutmod_parser = clink.arg.new_parser()
shortcutmod_parser:disable_file_matching()
shortcutmod_parser:set_arguments({
    "lalt,lsuper"       .. null_parser,
    "lctrl"             .. null_parser,
    "rctrl"             .. null_parser,
    "lalt"              .. null_parser,
    "ralt"              .. null_parser,
    "lsuper"            .. null_parser,
    "rsuper"            .. null_parser
})

local verbosity_parser = clink.arg.new_parser()
verbosity_parser:disable_file_matching()
verbosity_parser:set_arguments({
    "debug"             .. null_parser,
    "info"              .. null_parser,
    "warn"              .. null_parser,
    "error"             .. null_parser
})

local windowx_parser = clink.arg.new_parser()
windowx_parser:disable_file_matching()
windowx_parser:set_arguments({
    "-1"                .. null_parser
})

local windowy_parser = clink.arg.new_parser()
windowy_parser:disable_file_matching()
windowy_parser:set_arguments({
    "-1"                .. null_parser
})

local windowwidth_parser = clink.arg.new_parser()
windowwidth_parser:disable_file_matching()
windowwidth_parser:set_arguments({
    "0"                 .. null_parser
})

local windowheight_parser = clink.arg.new_parser()
windowheight_parser:disable_file_matching()
windowheight_parser:set_arguments({
    "0"                 .. null_parser
})

local scrcpy_parser = clink.arg.new_parser()
scrcpy_parser:disable_file_matching()
scrcpy_parser:set_flags(
    "--always-on-top"            .. null_parser,
    "-b"                         .. bitrate_parser,
    "--bit-rate"                 .. bitrate_parser,
    "--codec-options",
    "--crop"                     .. crop_parser,
    "--disable-screensaver"      .. null_parser,
    "--display"                  .. display_parser,
    "--display-buffer",
    "--encoder",
    "--force-adb-forward"        .. null_parser,
    "--forward-all-clicks"       .. null_parser,
    "-f"                         .. null_parser,
    "--fullscreen"               .. null_parser,
    "-K"                         .. null_parser,
    "--hid-keyboard"             .. null_parser,
    "-h"                         .. null_parser,
    "--help"                     .. null_parser,
    "--legacy-paste"             .. null_parser,
    "--lock-video-orientation"   .. lockvideoorientation_parser,
    "--max-fps"                  .. maxfps_parser,
    "-m"                         .. maxsize_parser,
    "--max-size"                 .. maxsize_parser,
    "--no-clipboard-autosync"    .. null_parser,
    "-n"                         .. null_parser,
    "--no-control"               .. null_parser,
    "-N"                         .. null_parser,
    "--no-display"               .. null_parser,
    "--no-key-repeat"            .. null_parser,
    "--no-mipmaps"               .. null_parser,
    "-p"                         .. portnumber_parser,
    "--port"                     .. portnumber_parser,
    "--power-off-on-close"       .. null_parser,
    "--prefer-text"              .. null_parser,
    "--push-target"              .. pushtarget_parser,
    "--raw-key-events"           .. null_parser,
    "-r",
    "--record",
    "--record-format"            .. recordformat_parser,
    "--render-driver"            .. renderdriver_parser,
    "--render-expired-frames"    .. null_parser,
    "--rotation"                 .. rotation_parser,
    "-s",
    "--serial",
    "--shortcut-mod"             .. shortcutmod_parser,
    "-S"                         .. null_parser,
    "--turn-screen-off"          .. null_parser,
    "-t"                         .. null_parser,
    "--show-touches"             .. null_parser,
    "--tunnel-host",
    "--tunnel-port",
    "--v4l2-sink",
    "--v4l2-buffer",
    "-V"                         .. verbosity_parser,
    "--verbosity"                .. verbosity_parser,
    "-v"                         .. null_parser,
    "--version"                  .. null_parser,
    "-w"                         .. null_parser,
    "--stay-awake"               .. null_parser,
    "--tcpip",
    "--window-borderless"        .. null_parser,
    "--window-title",
    "--window-x"                 .. windowx_parser,
    "--window-y"                 .. windowy_parser,
    "--window-width"             .. windowwidth_parser,
    "--window-height"            .. windowheight_parser
)

local function scrcpy_serialno_match_generator(text, first, last)
    local matched_cmd = false
    local leading = rl_state.line_buffer:sub(1, last)
    local trailing = rl_state.line_buffer:sub(last + 1)
    local a, b = leading:match('^%s*(scrcpy%s.-%s--serial)%s+([%w]*)%s*$')
    if not a then
        a, b = leading:match('^%s*(scrcpy%s.-%s-s)%s+([%w]*)%s*$')
    end
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

clink.arg.register_parser("scrcpy", scrcpy_parser)
clink.register_match_generator(scrcpy_serialno_match_generator, 20)
