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

local parser = clink.arg.new_parser

local function boxes()
    return clink.find_dirs(clink.get_env("userprofile") .. "/.vagrant.d/boxes/*")
end

local function any()
    return true
end

local vagrant_parser = parser({
    "box" .. parser({
        "add" .. parser(
            {""},
            {file_match_generator},
            "--checksum",
            "--checksum-type",--..parser({"md5", "sha1", "sha256"}),
            "-c", "--clean",
            "-f", "--force",
            "--insecure",
            "--cacert",
            "--cert",
            "--provider"
            ),
        "list" .. parser("-i", "--box-info"),
        "outdated"..parser("--global", "-h", "--help"),
        "remove" .. parser(boxes(), {}),
        "repackage" .. parser(boxes()),
        "update"
        }),
    "connect",
    "destroy" .. parser("-f", "--force"),
    "halt" .. parser("-f", "--force"),
    "init" .. parser(boxes(), {}, "--output"),
    "package" .. parser("--base", "--output", "--include", "--vagrantfile"),
    "plugin" .. parser({
        "install" .. parser(
            "--entry-point",
            "--plugin-prerelease",
            "--plugin-source",
            "--plugin-version"
            ),
        "license",
        "list",
        "uninstall",
        "update" .. parser(
            "--entry-point",
            "--plugin-prerelease",
            "--plugin-source",
            "--plugin-version"
            )
        }),
    "provision" .. parser("--provision-with", "--no-parallel", "--parallel"),
    "reload" .. parser("--provision-with", "--no-parallel", "--parallel"),
    "resume",
    "ssh" .. parser("-c", "--command", "-p", "--plain") ,
    "ssh-config",
    "status",
    "suspend",
    "up" .. parser(
        "--provision",
        "--no-provision",
        "--provision-with",
        "--destroy-on-error",
        "--no-destroy-on-error",
        "--parallel",
        "--no-parallel",
        "--provider"
        )
    }, "-h", "--help", "-v", "--version")

clink.arg.register_parser("vagrant", vagrant_parser)
clink.arg.register_parser("vagrant", parser({"help"..parser(vagrant_parser:flatten_argument(1))}))