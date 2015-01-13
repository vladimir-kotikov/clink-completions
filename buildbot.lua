local parser = clink.arg.new_parser

buildbot_parser = parser({
    "create-master" .. parser(
        "-q", "--quiet",
        "-f", "--force",
        "-r", "--relocatable",
        "-n", "--no-logrotate",
        "-c", "--config",
        "-s", "--log-size",
        "-l", "--log-count",
        "--db",
        "--version",
        "--help"
    ),
    "upgrade-master",
    "start",
    "stop",
    "restart",
    "reconfig",
    "sighup",
    "sendchange",
    "debugclient",
    "statuslog",
    "statusgui",
    "try",
    "tryserver",
    "checkconfig",
    "user"
})

buildslave_parser = parser({
    "create-slave",
    "upgrade-slave",
    "start",
    "stop",
    "restart"
    },
    "--version",
    "--help",
    "--verbose"
)

clink.arg.register_parser("buildbot", buildbot_parser)
clink.arg.register_parser("buildslave", buildslave_parser)