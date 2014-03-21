local parser = clink.arg.new_parser

local ea_parser = parser(
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

local pip_flags = parser(
	"-h", "--help",
	"-v", "--verbose",
	"-V", "--version",
	"-q", "--quiet",
	"--log", "--proxy", "--timeout", "--exists", "--cert"
)

local pip_parser = parser(
	{
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