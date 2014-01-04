
-- preamble
-- define support functions

local function parser( ... )
    
    local arguments = {}
    local flags = {}
    
    for _, word in ipairs({...}) do
        if type(word) == "string" then
            table.insert(flags, word)
        elseif type(word) == "table" then
            table.insert(arguments, word)
        end
    end
    
    local p = clink.arg.new_parser()
    p:disable_file_matching()
    p:set_arguments(arguments)
    p:set_flags(flags)

    return p
end

local function boxes()
    return clink.find_dirs(clink.get_env("userprofile") .. "/.vagrant.d/boxes/*")
end

-- define parsers

local init_parser = parser(boxes(), {}, "--output")

local vagrant_parser = parser({
    "box" .. parser({
        "add" .. parser({}, {},
            "--checksum", 
            "--checksum-type",
            "-c", "--clean",
            "-f", "--force",
            "--insecure",
            "--cacert",
            "--cert",
            "--provider"
            ),
        "list" .. parser("-i", "--box-info"),
        "remove" .. parser(boxes(), {}),
        "repackage" .. parser(boxes())
        }),
    "destroy" .. parser("-f", "--force"),
    "halt" .. parser("-f", "--force"),
    "help",
    "init" .. init_parser,
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