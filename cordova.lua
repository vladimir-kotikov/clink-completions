--preamble: common routines

function dir_match_generator_impl(text)
    -- Strip off any path components that may be on text.
    local prefix = ""
    local i = text:find("[\\/:][^\\/:]*$")
    if i then
        prefix = text:sub(1, i)
    end

    local matches = {}
    local mask = text.."*"

    -- Find matches.
    for _, dir in ipairs(clink.find_dirs(mask, true)) do
        local file = prefix..dir
        if clink.is_match(text, file) then
            table.insert(matches, prefix..dir)
        end
    end

    return matches
end

local function dir_match_generator(word)
    local matches = dir_match_generator_impl(word)

    -- If there was no matches but text is a dir then use it as the single match.
    -- Otherwise tell readline that matches are files and it will do magic.
    if #matches == 0 then
        if clink.is_dir(rl_state.text) then
            table.insert(matches, rl_state.text)
        end
    else
        clink.matches_are_files()
    end

    return matches
end

function file_match_generator_impl(text)
    -- Strip off any path components that may be on text.
    local prefix = ""
    local i = text:find("[\\/:][^\\/:]*$")
    if i then
        prefix = text:sub(1, i)
    end

    local matches = {}
    local mask = text.."*"

    -- Find matches.
    for _, dir in ipairs(clink.find_files(mask, true)) do
        local file = prefix..dir
        if clink.is_match(text, file) then
            table.insert(matches, prefix..dir)
        end
    end

    return matches
end

local function file_match_generator(word)
    local matches = file_match_generator_impl(word)

    -- If there was no matches but text is a dir then use it as the single match.
    -- Otherwise tell readline that matches are files and it will do magic.
    if #matches == 0 then
        if clink.is_dir(rl_state.text) then
            -- table.insert(matches, rl_state.text)
        end
    else
        clink.matches_are_files()
    end

    return matches
end

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

cordova_parser = parser(
    {
    -- common commands
        "create" .. parser(
            "--copy-from",
            "--src=",
            "--link-to="),
        "help",
        "info",
    -- project-level commands
        "platform" .. parser({
            "add" .. parser({
                "wp8",
                "windows8",
                "android",
                "blackberry10",
                "firefoxos",
                dir_match_generator
            }),
            "remove" .. parser({platforms}),
            "rm" .. parser({platforms}),
            "list", "ls",
            "up" .. parser({platforms}),
            "update" .. parser({platforms}),
            "check"
            }),
        "plugin" .. parser({
            "add" .. parser({dir_match_generator,
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
            }),
            "remove" .. parser({plugins}),
            "rm" .. parser({plugins}),
            "list", "ls",
            "search"
        }),
        "prepare" .. parser({platforms}),
        "compile" .. parser({platforms}),
        "build" .. parser({platforms}),
        "run" .. parser(
            {platforms},
            "--debug", "--release",
            "--device", "--emulator", "--target="
        ),
        "emulate" .. parser({platforms}),
        "serve",
    }, "-h")


clink.arg.register_parser("cordova", cordova_parser)
clink.arg.register_parser("cordova-dev", cordova_parser)
