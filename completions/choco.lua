local choco = require("chocolatey_module")
clink.arg.register_parser("choco", choco.chocolatey_parser)
