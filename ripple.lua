local parser = clink.arg.new_parser

ripple_parser = parser({
    "emulate" .. parser(
        "--port",
        "--path",
        "--remote",
        "--route"
        ),
    "proxy" .. parser(
        "--port",
        "--route"
        ),
    "version",
    "help"
    })

clink.arg.register_parser("ripple", ripple_parser)