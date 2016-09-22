-- see https://hub.github.com/hub.1.html for reference

local parser = clink.arg.new_parser

local hub_parser = parser({
    "browse"..parser("-u", {"wiki", "commits", "issues"}),
    "compare"..parser("-u"),
    "create"..parser("-p", "-d", "-h"),
    "ci-status"..parser("-v"),
    "fork"..parser("--no-remote"),
    "pull-request"..parser(
        "-o", "--browse",
        "-f",
        "-m", "-F", "-i", -- NOTE: these are mutually exclusive
        "-b",
        "-h"
    ),
    "version"
}, "--noop")

clink.arg.register_parser("hub", hub_parser)
