--preamble: common routines

local function platforms(token)
    local res = {}
    local platforms = clink.find_dirs('platforms/*')
    for _,platform in ipairs(platforms) do
        if string.match(platform, token) then
            table.insert(res, platform)
        end
    end
    return res
end

local function plugins(token)
    local res = {}
    local plugins = clink.find_dirs('plugins/*')
    for _,plugin in ipairs(plugins) do
        if string.match(plugin, token) then
            table.insert(res, plugin)
        end
    end
    return res
end

-- end preamble

local parser = clink.arg.new_parser

local platform_add_parser = parser({
    "wp8",
    "windows",
    "android",
    "blackberry10",
    "firefoxos",
    dir_match_generator
})

local plugin_add_parser = parser({dir_match_generator,
    "org.apache.cordova.battery-status",
    "org.apache.cordova.camera",
    "org.apache.cordova.contacts",
    "org.apache.cordova.device",
    "org.apache.cordova.device-motion",
    "org.apache.cordova.device-orientation",
    "org.apache.cordova.dialogs",
    "org.apache.cordova.file",
    "org.apache.cordova.file-transfer",
    "org.apache.cordova.geolocation",
    "org.apache.cordova.globalization",
    "org.apache.cordova.inappbrowser",
    "org.apache.cordova.media",
    "org.apache.cordova.media-capture",
    "org.apache.cordova.network-information",
    "org.apache.cordova.splashscreen",
    "org.apache.cordova.vibration"
})

local platform_rm_parser = parser({platforms})
local plugin_rm_parser = parser({plugins}, "-f", "--force")

platform_add_parser:loop(1)
plugin_add_parser:loop(1)
platform_rm_parser:loop(1)
plugin_rm_parser:loop(1)

cordova_parser = parser(
    {
    -- common commands
        "create" .. parser(
            "--copy-from",
            "--src" .. parser(),
            "--link-to="),
        "help",
        "info",
    -- project-level commands
        "platform" .. parser({
            "add" .. platform_add_parser,
            "remove" .. platform_rm_parser,
            "rm" .. parser({platforms}),
            "list", "ls",
            "up" .. parser({platforms}),
            "update" .. parser({platforms}),
            "check"
            }),
        "plugin" .. parser({
            "add" .. plugin_add_parser,
            "remove" .. plugin_rm_parser,
            "rm" .. plugin_rm_parser,
            "list", "ls",
            "search"
        }),
        "prepare" .. parser({platforms}),
        "compile" .. parser({platforms}),
        "build" .. parser({platforms}),
        "run" .. parser(
            {platforms},
            "--nobuild",
            "--debug", "--release",
            "--device", "--emulator", "--target="
        ),
        "emulate" .. parser({platforms}),
        "serve",
    }, "-h", "-d")

clink.arg.register_parser("cordova", cordova_parser)
clink.arg.register_parser("cordova-dev", cordova_parser)
