local ea_parser
local pip_parser

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

ea_parser = clink.arg.new_parser()
ea_parser:set_flags(
	"--verbose",
	"--quiet", "-q",
	"--dry-run", "-n",
	"--help", "-h",
	"--no-user-cfg",
	"--prefix",
	"--zip-ok", "-z",
	"--multi-version", "-m",
	"--upgrade", "-U",
	"--install-dir", "-d",
	"--script-dir", "-s",
	"--exclude-scripts", "-x",
	"--always-copy", "-a",
	"--index-url", "-i",
	"--find-links", "-f",
	"--build-directory", "-b",
	"--optimize", "-O",
	"--record",
	"--always-unzip", "-Z",
	"--site-dirs", "-S",
	"--editable", "-e",
	"--no-deps", "-N",
	"--allow-hosts", "-H",
	"--local-snapshots-ok", "-l",
	"--version",
	"--no-find-links",
	"--user",
	"--help"
	)

local pip_flags = flags(
	"-h", "--help",
	"-v", "--verbose",
	"-V", "--version",
	"-q", "--quiet",
	"--log", "--proxy", "--timeout", "--exists", "--cert"
)

pip_parser = clink.arg.new_parser()
pip_parser:set_arguments({
	"install" .. pip_flags,
	"uninstall" .. pip_flags,
	"freeze" .. pip_flags,
	"list" .. pip_flags,
	"show" .. pip_flags,
	"search" .. pip_flags,
	"wheel" .. pip_flags,
	"zip" .. pip_flags,
	"unzip" .. pip_flags,
	"bundle" .. pip_flags,
	"help" .. pip_flags
})

clink.arg.register_parser("easy_install", ea_parser)
clink.arg.register_parser("pip", pip_parser)