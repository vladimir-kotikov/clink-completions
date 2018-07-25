local parser = clink.arg.new_parser

local general_options = {
    "--cache-dir",
    "--cert",
    "--client-cert",
    "--disable-pip-version-check",
    "--exists-action",
    "--help",
    "--isolated",
    "--log",
    "--no-cache-dir",
    "--no-color",
    "--proxy",
    "--quiet",
    "--retries",
    "--timeout",
    "--trusted-host",
    "--verbose",
    "--version",
    "-h",
    "-q",
    "-v",
    "-V"
}

local package_index_options = {
    "--extra-index-url",
    "--find-links",
    "--index-url",
    "--no-index",
    "--process-dependency-links",
    "-f",
    "-i"
}

local command_parser = parser({
    "check",
    "completion",
    "config",
    "download",
    "freeze",
    "hash",
    "help",
    "install",
    "list",
    "search",
    "show",
    "uninstall",
    "wheel"
})

local config_parser = parser({
    "edit",
    "get",
    "list",
    "set",
    "unset"
},
    "--editor",
    "--global",
    "--user",
    "--venv"
):add_flags(general_options)

local download_parser = parser(
    "--abi",
    "--build",
    "--constraint",
    "--dest",
    "--global-option",
    "--implementation",
    "--no-binary",
    "--no-build-isolation",
    "--no-clean",
    "--no-deps",
    "--only-binary",
    "--platform",
    "--pre",
    "--progress-bar",
    "--python-version",
    "--require-hashes",
    "--requirement",
    "--src",
    "-b",
    "-c",
    "-d",
    "-r"
):add_flags(general_options):add_flags(package_index_options)

local freeze_parser = parser(
    "--all",
    "--exclude-editable",
    "--find-links",
    "--local",
    "--requirement",
    "--user",
    "-f",
    "-l",
    "-r"
):add_flags(general_options)

local install_parser = parser(
    "--build",
    "--compile ",
    "--constraint",
    "--editable",
    "--force-reinstall ",
    "--global-option ",
    "--ignore-installed",
    "--ignore-requires-python ",
    "--install-option ",
    "--no-binary ",
    "--no-build-isolation ",
    "--no-clean ",
    "--no-compile ",
    "--no-deps ",
    "--no-warn-conflicts ",
    "--no-warn-script-location ",
    "--only-binary ",
    "--pre ",
    "--prefix ",
    "--progress-bar ",
    "--require-hashes ",
    "--requirement",
    "--root ",
    "--src ",
    "--target",
    "--upgrade",
    "--upgrade-strategy ",
    "--user ",
    "-b",
    "-c",
    "-e",
    "-I",
    "-r",
    "-t",
    "-U"
):add_flags(general_options):add_flags(package_index_options)

local list_parser = parser(
    "--editable",
    "--exclude-editable",
    "--format",
    "--include-editable",
    "--local",
    "--not-required",
    "--outdated",
    "--pre",
    "--uptodate",
    "--user",
    "-e",
    "-l",
    "-o",
    "-u"
):add_flags(general_options):add_flags(package_index_options)

local wheel_parser = parser(
    "--build",
    "--build-option",
    "--constraint",
    "--editable",
    "--global-option",
    "--ignore-requires-python",
    "--no-binary",
    "--no-build-isolation",
    "--no-clean",
    "--no-deps",
    "--only-binary",
    "--pre",
    "--progress-bar",
    "--require-hashes",
    "--requirement",
    "--src",
    "--wheel-dir",
    "-b",
    "-c",
    "-e",
    "-r",
    "-w"
):add_flags(general_options):add_flags(package_index_options)

local pip_parser = parser({
    "check",
    "completion"..parser("--bash", "--fish", "--zsh", "-b", "-f", "-z"),
    "config"..config_parser,
    "download"..download_parser,
    "freeze"..freeze_parser,
    "hash"..parser("-a", "--algorithm"),
    "help"..command_parser,
    "install"..install_parser,
    "list"..list_parser,
    "search"..parser("--index", "-i"),
    "show"..parser("--files", "-f"),
    "uninstall"..parser("--requirement", "-r", "--yes", "-y"),
    "wheel"..wheel_parser
}):set_flags(general_options)

clink.arg.register_parser("pip", pip_parser)
clink.arg.register_parser("pip3", pip_parser)
