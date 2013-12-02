local net_parser
local accounts_parser
local help_parser

local function flags(...)
    local p = clink.arg.new_parser()
    p:disable_file_matching()
    p:set_flags(...)
    return p
end

local function arguments(...)
    local p = clink.arg.new_parser()
    p:disable_file_matching()
    p:set_arguments(...)
    return p
end

net_parser = clink.arg.new_parser()
net_parser:disable_file_matching()
net_parser:set_flags("/?")
net_parser:set_arguments({
	"accounts" .. flags("/forcelogoff:", "/forcelogoff:no", "/domain",
						"/maxpwage:", "/maxpwage:unlimited", "/minpwage:",
						"/minpwlen:","/uniquepw:"),
	"computer" .. arguments({"*" .. flags("/add", "/del")}),
	"config" .. arguments({"server", "workstation"}),
	"continue",
	"file",
	"group",
	"helpmsg",
	"localgroup",
	"pause",
	"session" .. arguments({flags("/delete", "/list")}),
	"share",
	"start",
	"statistics" .. arguments({"server", "workstation"}),
	"stop",
	"time" .. flags("/domain", "/rtsdomain", "/set"),
	"use" .. flags("/user:", "/smartcard", "/savecred", "/delete",
				   "/persistent:yes", "/persistent:no"),
	"user",
	"view" .. flags("/cache", "/all", "/domain")
})

help_parser = clink.arg.new_parser()
help_parser:disable_file_matching()
help_parser:set_arguments({
	"help" .. arguments(net_parser:flatten_argument(1))
})

clink.arg.register_parser("net", net_parser)
clink.arg.register_parser("net", help_parser)