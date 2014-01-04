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
		"firewall" .. common_parser,
			-- TODO: add rule parser
		"help",
		"import" .. file_parser,
		"mainmode" .. common_parser,
			-- TODO: add rule parser
		"monitor" .. arguments({
			"?",
			"delete" .. arguments({
				"mmsa" .. arguments({"all"}),
				"qmsa" .. arguments({"all"})}),
			"dump",
			"help",
			"show" .. arguments({
				"consec" .. arguments({
					"rule" .. arguments({"name=", "profile="}, {"verbose"})}),
					-- TODO: disable quoting in arguments ended with '='
					-- TODO: profile argument is optional
				"currentprofile",
				"firewall" .. arguments({
					"rule" .. arguments({"name=", "dir=", "profile="}, {"verbose"})}),
					-- TODO: disable quoting in arguments ended with '='
					-- TODO: profile and dir arguments is optional
				"mainmode" .. arguments({
					"rule" .. arguments({"name=", "profile="}, {"verbose"})}),
					-- TODO: disable quoting in arguments ended with '='
					-- TODO: profile and dir arguments is optional
				"mmsa" .. arguments({"all"}),
				"qmsa" .. arguments({"all"})
				}),
			}),
		"reset" .. arguments({"export" .. file_parser}),
		"set" .. arguments({
			-- TODO: rest of commands
			-- probably need new parser
			"allprofiles" .. arguments({
				"state" .. arguments({"on", "off", "notconfigured"}),
				"firewallpolicy" .. arguments({
					"blockinbound",
					"blockinboundalways",
					"allowinbound",
					"notconfigured",
					"allowoutbound",
					"blockoutbound"
					}),
				"settings" .. arguments({
					"localfirewallrules",
					"localconsecrules",
					"inboundusernotification",
					"remotemanagement",
					"unicastresponsetomulticast"},
					{"enable", "disable", "notconfigured"}
					),
				"logging" .. arguments({
					"allowedconnections" .. arguments({
						"enable", "disable", "notconfigured"
						}),
					"droppedconnections" .. arguments({
						"enable", "disable", "notconfigured"
						}),
					"filename" .. file_parser,
					"maxfilesize" .. arguments({"notconfigured"})
				}),
			}),
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
	"wlan" .. arguments({
		"?",
		"add".. arguments({"filter", 'profile'}),
		"connect",
		"delete",
		"disconnect",
		"dump",
		"export",
		"help",
		"refresh",
		"reportissues",
		"set",
		"show",
		"start",
		"stop"
		})
})

clink.arg.register_parser("netsh", netsh_parser)