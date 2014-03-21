-- preamble: common routines

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
                "wp7",
                "wp8",
                "windows8",
                "android",
                "blackberry10",
                "firefoxos",
            }),
            "remove" .. parser(clink.find_dirs("platforms/*")),
            "rm" .. parser(clink.find_dirs("platforms/*")),
            "list", "ls",
            "up" .. parser(clink.find_dirs("platforms/*")),
            "update" .. parser(clink.find_dirs("platforms/*")),
            "check"
            }),
        "plugin" .. parser({
            "add",-- .. parser({dir_match_generator}),
            "remove" .. parser(clink.find_dirs("plugins/*")),
            "rm" .. parser(clink.find_dirs("plugins/*")),
            "list", "ls",
            "search"
        }),
        "prepare" .. parser({
            "wp7",
            "wp8",
            "windows8",
            "android",
            "blackberry10",
            "firefoxos",
            }),
        "compile" .. parser(clink.find_dirs("platforms/*")),
        "build" .. parser(clink.find_dirs("platforms/*")),
        "run" .. parser(
            parser(clink.find_dirs("platforms/*"),
            "--debug", "--release",
            "--device", "--emulator", "--target=")
        ),
        "emulate" .. parser(clink.find_dirs("platforms/*")),
        "serve",
    }, "-h")


clink.arg.register_parser("cordova", cordova_parser)