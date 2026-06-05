local choco = require("chocolatey_module")
clink.arg.register_parser("cup", choco.cup_parser)
