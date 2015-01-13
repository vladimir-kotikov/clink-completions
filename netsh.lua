local parser = clink.arg.new_parser

local file_parser = parser()

local common_parser = parser({
    "?",
    "add" .. parser({"rule"}),
    "delete" .. parser({"rule"}),
    "dump",
    "help",
    "set" .. parser({"rule"}),
    "show" .. parser({"rule"})
})

local netsh_parser = parser({
    "add" .. parser({"helper" .. file_parser}),
        -- TODO: find .dll files only
    "advfirewall" .. parser({
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
        "monitor" .. parser({
            "?",
            "delete" .. parser({
                "mmsa" .. parser({"all"}),
                "qmsa" .. parser({"all"})}),
            "dump",
            "help",
            "show" .. parser({
                "consec" .. parser({
                    "rule" .. parser({"name=", "profile="}, {"verbose"})}),
                    -- TODO: disable quoting in arguments ended with '='
                    -- TODO: profile argument is optional
                "currentprofile",
                "firewall" .. parser({
                    "rule" .. parser({"name=", "dir=", "profile="}, {"verbose"})}),
                    -- TODO: disable quoting in arguments ended with '='
                    -- TODO: profile and dir arguments is optional
                "mainmode" .. parser({
                    "rule" .. parser({"name=", "profile="}, {"verbose"})}),
                    -- TODO: disable quoting in arguments ended with '='
                    -- TODO: profile and dir arguments is optional
                "mmsa" .. parser({"all"}),
                "qmsa" .. parser({"all"})
                }),
            }),
        "reset" .. parser({"export" .. file_parser}),
        "set" .. parser({
            -- TODO: rest of commands
            -- probably need new parser
            "allprofiles" .. parser({
                "state" .. parser({"on", "off", "notconfigured"}),
                "firewallpolicy" .. parser({
                    "blockinbound",
                    "blockinboundalways",
                    "allowinbound",
                    "notconfigured",
                    "allowoutbound",
                    "blockoutbound"
                    }),
                "settings" .. parser({
                    "localfirewallrules",
                    "localconsecrules",
                    "inboundusernotification",
                    "remotemanagement",
                    "unicastresponsetomulticast"},
                    {"enable", "disable", "notconfigured"}
                    ),
                "logging" .. parser({
                    "allowedconnections" .. parser({
                        "enable", "disable", "notconfigured"
                        }),
                    "droppedconnections" .. parser({
                        "enable", "disable", "notconfigured"
                        }),
                    "filename" .. file_parser,
                    "maxfilesize" .. parser({"notconfigured"})
                }),
            }),
            "currentprofile",
            "domainprofile",
            "global",
            "privateprofile",
            "publicprofile"
        }),
        "show".. parser({
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
    "branchcache" .. parser({"exportkey", "flush", "importkey", "smb"}) ,
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
    "wlan" .. parser({
        "?",
        "add".. parser({"filter", 'profile'}),
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
},"-a", "-c", "-r", "-u", "-p", "-f")

clink.arg.register_parser("netsh", netsh_parser)