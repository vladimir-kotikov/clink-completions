local choco = require("chocolatey_module")
clink.arg.register_parser("chocolatey", choco.chocolatey_parser)
