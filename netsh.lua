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

local file_parser = clink.arg.new_parser()

local common_parser = arguments({
	"?",
	"add" .. arguments({"rule"}),
	"delete" .. arguments({"rule"}),
	"dump",
	"help",
	"set" .. arguments({"rule"}),
	"show" .. arguments({"rule"})
})

local netsh_parser = clink.arg.new_parser()
netsh_parser:disable_file_matching()
netsh_parser:set_flags("-a", "-c", "-r", "-u", "-p", "-f" )
netsh_parser:set_arguments({
	"add" .. arguments({"helper" .. file_parser}),
		-- TODO: find .dll files only
	"advfirewall" .. arguments({
		"?",
		"consec" .. common_parser,
			-- TODO: add rule parser
		"dump",
		"export" .. file_parser,
			-- TODO: add rule parser
		"firewall" .. common_parser,
			-- TODO: add rule parser
		"help",
		"import" .. file_parser,
		"mainmode" .. common_parser,
			-- TODO: add rule parser
		"monitor" .. arguments({
			"?",
			"delete",
			"dump",
			"help",
			"show" .. arguments({
				"consec",
				"currentprofile",
				"firewall",
				"mainmode",
				"mmsa",
				"qmsa"
				}),
			}),
		"reset" .. arguments({"export" .. file_parser}),
		"set" .. arguments({
			-- TODO: rest of commands
			-- probably need new parser
			"allprofiles",
			"currentprofile",
			"domainprofile",
			"global",
			"privateprofile",
			"publicprofile"
			}),
		"show".. arguments({
			-- TODO: rest of commands
			-- probably need new parser
			"allprofiles",
			"currentprofile",
			"domainprofile",
			"global",
			"privateprofile",
			"publicprofile",
			"store"
			}),
		}),
	"branchcache" .. arguments({"exportkey", "flush", "importkey", "smb"}) ,
	"bridge",
	"dhcp",
	"dhcpclient",
	"dnsclient",
	"firewall",
	"http",
	"interface",
	"ipsec",
	"lan",
	"mbn",
	"namespace",
	"nap",
	"netio",
	"p2p",
	"ras",
	"routing",
	"rpc",
	"trace",
	"wcn",
	"wfp",
	"winhttp",
	"winsock",
	"wlan",
})


-- net_parser = clink.arg.new_parser()
-- net_parser:disable_file_matching()
-- net_parser:set_flags("/?")
-- net_parser:set_arguments({
-- 	"accounts" .. flags("/forcelogoff:", "/forcelogoff:no", "/domain",
-- 						"/maxpwage:", "/maxpwage:unlimited", "/minpwage:",
-- 						"/minpwlen:","/uniquepw:"),
-- 	"computer" .. arguments({"*" .. flags("/add", "/del")}),
-- 	"config" .. arguments({"server", "workstation"}),
-- 	"continue",
-- 	"file",
-- 	"group",
-- 	"helpmsg",
-- 	"localgroup",
-- 	"pause",
-- 	"session" .. arguments({flags("/delete", "/list")}),
-- 	"share",
-- 	"start",
-- 	"statistics" .. arguments({"server", "workstation"}),
-- 	"stop",
-- 	"time" .. flags("/domain", "/rtsdomain", "/set"),
-- 	"use" .. flags("/user:", "/smartcard", "/savecred", "/delete",
-- 				   "/persistent:yes", "/persistent:no"),
-- 	"user",
-- 	"view" .. flags("/cache", "/all", "/domain")
-- })

-- help_parser = clink.arg.new_parser()
-- help_parser:disable_file_matching()
-- help_parser:set_arguments({
-- 	"help" .. arguments(net_parser:flatten_argument(1))
-- })

-- clink.arg.register_parser("net", net_parser)
clink.arg.register_parser("netsh", netsh_parser)
-- clink.arg.register_parser("netsh", netsh_common_parser)