local kubectl_parser = require("kubectl_parser")
clink.arg.register_parser("oc", kubectl_parser)
