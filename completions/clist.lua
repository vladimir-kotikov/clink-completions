local choco = require("chocolatey_module")
clink.arg.register_parser("clist", choco.clist_parser)
