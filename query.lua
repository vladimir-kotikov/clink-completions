local parser = clink.arg.new_parser

local query_parser = parser({
	"process" .. parser({}, "/server:"),
	"session" .. parser({}, "/server:"),
	"termserver" .. parser({}, "/domain:", "/address", "/continue"),
	"user" .. parser({}, "/server:")
}, "/?")

clink.arg.register_parser("query", query_parser)