local matchers = require('matchers')
local parser = clink.arg.new_parser

local boxes = matchers.create_dirs_matcher(clink.get_env("userprofile") .. "/.vagrant.d/boxes/*")

local vagrant_parser = parser({
    "box" .. parser({
        "add" .. parser(
            "--checksum",
            "--checksum-type" .. parser({"md5", "sha1", "sha256"}),
            "-c", "--clean",
            "-f", "--force",
            "--insecure",
            "--cacert",
            "--cert",
            "--provider"
            ),
        "list" .. parser("-i", "--box-info"),
        "outdated"..parser("--global", "-h", "--help"),
        "remove" .. parser({boxes}),
        "repackage" .. parser({boxes}),
        "update"
        }),
    "connect",
    "destroy" .. parser("-f", "--force"),
    "halt" .. parser("-f", "--force"),
    "init" .. parser({boxes}, {}, "--output"),
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

local help_parser = parser(
    {
        "help" .. parser(vagrant_parser:flatten_argument(1))
    }
)

clink.arg.register_parser("vagrant", vagrant_parser)
clink.arg.register_parser("vagrant", help_parser)
