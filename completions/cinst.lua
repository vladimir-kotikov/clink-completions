local choco = require("chocolatey_module")
clink.arg.register_parser("cinst", choco.cinst_parser)
