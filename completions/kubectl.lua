local kubectl_parser = require("kubectl_parser")
clink.arg.register_parser("kubectl", kubectl_parser)
