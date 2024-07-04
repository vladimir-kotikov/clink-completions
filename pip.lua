-- -*- coding: utf-8 -*-
-- preamble: common routines

local matchers = require("matchers")
local w = require("tables").wrap

local parser = clink.arg.new_parser

local function get_packages(dir, token)
    local list
    if not dir or dir == "" then
        list = {}
    else
        local finder = matchers.create_files_matcher(dir .. "\\*.dist-info")
        list = finder(token)
    end
    return w(list)
end

local function pip_libs_list(token)
    local sysconfig = {}

    local handle = io.popen('2>nul python -m sysconfig')
    if handle then
        for line in handle:lines() do
            local name, value = line:match('^%s+(.-) = "(.*)"%s*$')
            if name and value then
                sysconfig[name] = value
            end
        end
        handle:close()
    end

    local platlib = get_packages(sysconfig["platlib"], token)
    local purelib = get_packages(sysconfig["purelib"], token)

    local list = platlib:concat(purelib):map(
        function(package)
            package = package:gsub("-[%d%.]+dist%-info$", "")
            return package
        end
    )

    return list
end

local pip_default_flags = {
    "--help",
    "-h",
    "--isolated",
    "--verbose",
    "-v",
    "--version",
    "-V",
    "--quiet",
    "-q",
    "--log",
    "--proxy",
    "--retries",
    "--timeout",
    "--exists-action",
    "--trusted-host",
    "--cert",
    "--client-cert",
    "--cache-dir",
    "--no-cache-dir",
    "--disable-pip-version-check",
    "--no-color"
}

local pip_requirement_flags = {
    "--requirement" .. parser({clink.matches_are_files}),
    "-r" .. parser({clink.matches_are_files})
}

local pip_index_flags = {
    "--index-url",
    "-i",
    "--extra-index-url",
    "--no-index",
    "--find-links",
    "-f"
}

local pip_install_download_wheel_flags = {
    pip_requirement_flags,
    "--no-binary",
    "--only-binary",
    "--prefer-binary",
    "--no-build-isolation",
    "--use-pep517",
    "--constraint",
    "-c",
    "--src",
    "--no-deps",
    "--progress-bar" .. parser({"off", "on", "ascii", "pretty", "emoji"}),
    "--global-option",
    "--pre",
    "--no-clean",
    "--requires-hashes"
}

local pip_install_download_flags = {
    pip_install_download_wheel_flags,
    "--platform",
    "--python-version",
    "--implementation" .. parser({"pp", "jy", "cp", "ip"}),
    "--abi"
}

local pip_install_parser =
    parser(
    {},
    "--editable",
    "-e",
    "--target",
    "-t",
    "--user",
    "--root",
    "--prefix",
    "--build",
    "-b",
    "--upgrade",
    "-U",
    "--upgrade-strategy" .. parser({"eager", "only-if-needed"}),
    "--force-reinstall",
    "--ignore-installed",
    "-I",
    "--ignore-requires-python",
    "--install-option",
    "--compile",
    "--no-compile",
    "--no-warn-script-location",
    "--no-warn-conflicts"
):loop(1)
pip_install_parser:add_flags(pip_install_download_flags)
pip_install_parser:add_flags(pip_index_flags)
pip_install_parser:add_flags(pip_default_flags)

local pip_download_parser = parser({}, "--build", "-b", "--dest", "-d"):loop(1)
pip_download_parser:add_flags(pip_install_download_flags)
pip_download_parser:add_flags(pip_index_flags)
pip_download_parser:add_flags(pip_default_flags)

local pip_uninstall_parser =
    parser({pip_libs_list}, "--yes", "-y"):add_flags(pip_default_flags, pip_requirement_flags):loop(1)

local pip_freeze_parser = parser({}, "--find-links", "--local", "-l", "--user", "--all", "--exclude-editable")
pip_freeze_parser:add_flags(pip_default_flags, pip_requirement_flags)

local pip_list_parser =
    parser(
    {},
    "--outdated",
    "-o",
    "--uptodate",
    "-u",
    "--editable",
    "-e",
    "--local",
    "-l",
    "--user",
    "--pre",
    "--format" .. parser({"columns", "freeze", "json"}),
    "--not-required",
    "--exclude-editable",
    "--include-editable"
)
pip_list_parser:add_flags(pip_default_flags)

local pip_config_parser =
    parser(
    {
        "list",
        "edit",
        "get",
        "set",
        "unset"
    },
    "--editor",
    "--global",
    "--user",
    "--venv",
    pip_default_flags
)
pip_config_parser:add_flags(pip_default_flags)

local pip_search_parser = parser({}, "--index", "-i"):add_flags(pip_default_flags)

local pip_wheel_parser =
    parser(
    {},
    "--wheel-dir",
    "-w",
    "--build-option",
    "--editable",
    "-e",
    "--ignore-requires-python",
    "--build",
    "-b"
):loop(1)
pip_wheel_parser:add_flags(pip_install_download_flags)
pip_wheel_parser:add_flags(pip_index_flags)
pip_wheel_parser:add_flags(pip_default_flags)

local pip_hash_parser =
    parser(
    {},
    "--algorithm" .. parser({"sha256", "sha384", "sha512"}),
    "-a" .. parser({"sha256", "sha384", "sha512"}),
    pip_default_flags
)
pip_hash_parser:add_flags(pip_default_flags)

local pip_completion_parser = parser({}, "--bash", "-b", "--zsh", "-z", "--fish", "-f"):add_flags(pip_default_flags)

local pip_help_parser =
    parser(
    {
        "install",
        "download",
        "uninstall",
        "freeze",
        "list",
        "show",
        "config",
        "search",
        "wheel",
        "hash",
        "completion",
        "help"
    }
)
pip_help_parser:add_flags(pip_default_flags)

local pip_parser =
    parser(
    {
        "install" .. pip_install_parser,
        "download" .. pip_download_parser,
        "uninstall" .. pip_uninstall_parser,
        "freeze" .. pip_freeze_parser,
        "list" .. pip_list_parser,
        "show" .. parser({pip_libs_list}, pip_default_flags),
        "config" .. pip_config_parser,
        "search" .. pip_search_parser,
        "wheel" .. pip_wheel_parser,
        "hash" .. pip_hash_parser,
        "completion" .. pip_completion_parser,
        "help" .. pip_help_parser
    }
)
pip_parser:add_flags(pip_default_flags)

clink.arg.register_parser("pip", pip_parser)
