local parser = clink.arg.new_parser

-- local matchers = require('matchers')
-- local platforms = matchers.create_dirs_matcher('platforms/*')
-- local plugins = matchers.create_dirs_matcher('plugins/*')

-- local platform_add_parser = parser({
--     "wp8",
--     "windows",
--     "android",
--     "blackberry10",
--     "firefoxos",
--     matchers.dirs
-- }, "--usegit", "--save", "--link"):loop(1)


local rn_parser = parser({
    "init"..parser("--verbose"),
    "android"..parser(
        "--project-name",
        "--config"
    ),
    "bundle"..parser(
        "--entry-file",
        "--platform", -- TODO: list platforms
        "--transformer", --TODO parse availble transformers
        "--dev",
        "--prepack",
        "--bridge-config",
        "--bundle-output", --TODO: match folders
        "--bundle-encoding", --TODO: list available encodings
        "--sourcemap-output",
        "--assets-dest", --TODO: match folders
        "--reset-cache",
        "--config"
    ),
    "install"..parser("--config"),
    "link"..parser("--config"),
    "log-android"..parser("--config"),
    "log-ios"..parser("--config"),
    "new-library"..parser(
        "--name",
        "--config"
    ),
    "run-android"..parser(
        "--install-debug",
        "--root", --TODO: complete dirs
        "--flavor",
        "--variant",
        "--config"
    ),
    -- NOTE: there is no completions for run-ios as it won't work on Windows :)
    "run-ios",
    "start"..parser(
        "--port",
        "--host",
        "--root", -- TODO: dirs list
        "--projectRoots", -- TODO: dirs list
        "--assetRoots", -- TODO: dirs list
        "--assetExts",
        "--skipflow",
        "--nonPersistent",
        "--transformer", --TODO: list transformers
        "--reset-cache", "--resetCache",
        "--verbose",
        "--config"
    ),
    "unbundle"..parser(
        "--entry-file",
        "--platform"..parser({"ios", "android"}),
        "--transformer", --TODO: complete transformers
        "--dev",
        "--prepack",
        "--bridge-config",
        "--bundle-output",
        "--bundle-encoding", --TODO: complete encoding (https://nodejs.org/api/buffer.html#buffer_buffer).
        "--sourcemap-output",
        "--assets-dest", --TODO: complete dir
        "--verbose",
        "--reset-cache",
        "--config"
    ),
    "uninstall"..parser("--config"),
    "unlink"..parser("--config"),
    "upgrade"..parser("--config"),
}, "-h", "--help", "-V", "--version")

clink.arg.register_parser("react-native", rn_parser)
clink.arg.register_parser("rn", rn_parser)
