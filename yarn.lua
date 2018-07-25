-- preamble: common routines

local JSON = require("JSON")

-- silence JSON parsing errors
function JSON:assert () end  -- luacheck: no unused args

local w = require('tables').wrap
local matchers = require('matchers')

---
 -- Queries config options value using 'yarn config get' call
 -- @param  {string}  config_entry  Config option name
 -- @return {string}  Config value for specific option or
 --   empty string in case of any error
---
local function get_yarn_config_value (config_entry)
    assert(config_entry and type(config_entry) == "string" and #config_entry > 0,
        "get_yarn_config_value: config_entry param should be non-empty string")

    local proc = io.popen("yarn config get "..config_entry.." 2>nul")
    if not proc then return "" end

    local value = proc:read()
    proc:close()

    return value or nil
end

local modules = matchers.create_dirs_matcher('node_modules/*')

local globals_location = nil
local global_modules_matcher = nil
local function global_modules(token)
    -- If we already have matcher then just return it
    if global_modules_matcher then return global_modules_matcher(token) end

    -- If token starts with . or .. or has path delimiter then return empty
    -- result and do not create a matcher so only fs paths will be completed
    if (token:match('^%.(%.)?') or token:match('[%\\%/]+')) then return {} end

    -- otherwise try to get cache location and return empty table if failed
    globals_location = globals_location or get_yarn_config_value("prefix")
    if not globals_location then return {} end

    -- Create a new matcher, save it in module's variable for further usage and return it
    global_modules_matcher = matchers.create_dirs_matcher(globals_location..'/node_modules/*')
    return global_modules_matcher(token)
end

-- A function that matches all files in bin folder. See #74 for rationale
local bins = matchers.create_files_matcher('node_modules/.bin/*.')

-- Reads package.json in current directory and extracts all "script" commands defined
local function scripts(token)  -- luacheck: no unused args

    -- Read package.json first
    local package_json = io.open('package.json')
    -- If there is no such file, then close handle and return
    if package_json == nil then return w() end

    -- Read the whole file contents
    local package_contents = package_json:read("*a")
    package_json:close()

    local package_scripts = JSON:decode(package_contents).scripts
    return w(package_scripts):keys()
end

local parser = clink.arg.new_parser

-- end preamble


local add_parser = parser(
    "--dev", "-D",
    "--exact", "-E",
    "--optional", "-O",
    "--peer", "-P",
    "--tilde", "-T",
    "--ignore-workspace-root-check", "-W"
)

local command_parser = parser({
    "access",
    "add",
    "autoclean",
    "bin",
    "cache",
    "check",
    "config",
    "create",
    "exec",
    "generate-lock-entry",
    "generateLockEntry",
    "global",
    "help",
    "import",
    "info",
    "init",
    "install",
    "licenses",
    "link",
    "list",
    "login",
    "logout",
    "node",
    "outdated",
    "owner",
    "pack",
    "publish",
    "remove",
    "run",
    "tag",
    "team",
    "unlink",
    "upgrade",
    "upgrade-interactive",
    "upgradeInteractive",
    "version",
    "versions",
    "why",
    "workspace",
    "workspaces"
})

local yarn_parser = parser({
    "access",
    "add"..add_parser,
    "autoclean"..parser("--init", "-I", "--force", "-F"),
    "bin",
    "cache"..parser({
        "clean",
        "dir",
        "list"..parser("--pattern")
    }),
    "check"..parser("--integrity", "--verify-tree"),
    "config"..parser({
        "delete",
        "get"..parser("--global", "-g"),
        "list",
        "set"..parser("--global", "-g")
    }),
    "create",
    "exec",
    "generate-lock-entry",
    "generateLockEntry",
    "global"..parser({
        "add"..add_parser,
        "bin",
        "list"..parser("--depth", "--pattern"),
        "remove"..parser({modules}),
        "upgrade"..parser({modules}),
        "upgrade-interactive",
        "upgradeInteractive"
    }, "--prefix"),
    "help"..command_parser,
    "import",
    "info",
    "init"..parser("--private", "-p", "--yes", "-y"),
    "install",
    "licenses"..parser({"generate-disclaimer", "list"}),
    "link"..parser({matchers.files, global_modules}),
    "list"..parser("--depth", "--pattern"),
    "login",
    "logout",
    "node",
    "outdated"..parser({modules}),
    "owner"..parser({
        "add",
        "list"..parser({modules}),
        "remove"
    }),
    "pack"..parser("--filename", "-f"),
    "publish"..parser(
        "--access"..parser({"public", "restricted"}),
        "--major",
        "--message",
        "--minor",
        "--new-version",
        "--no-commit-hooks",
        "--no-git-tag-version",
        "--patch",
        "--tag"
    ),
    "remove"..parser({modules}),
    "run"..parser({bins, scripts}),
    "tag"..parser({"add", "list", "remove"}),
    "team"..parser({"add", "create", "destroy", "list", "remove"}),
    "unlink"..parser({modules}),
    "upgrade"..parser(
        {modules},
        "-C", "--caret",
        "-E", "--exact",
        "-L", "--latest",
        "-P", "--pattern",
        "-S", "--scope",
        "-T", "--tilde"
    ),
    "upgrade-interactive",
    "upgradeInteractive",
    "version"..parser(
        "--major",
        "--message",
        "--minor",
        "--new-version",
        "--no-commit-hooks",
        "--no-git-tag-version",
        "--patch"
    ),
    "versions",
    "why"..parser({modules}),
    "workspace",
    "workspaces"
    },
    "-h",
    "-s",
    "-v",
    "--cache-folder",
    "--check-files",
    "--cwd",
    "--emoji",
    "--flat",
    "--force",
    "--frozen-lockfile",
    "--global-folder",
    "--har",
    "--help",
    "--https-proxy",
    "--ignore-engines",
    "--ignore-optional",
    "--ignore-platform",
    "--ignore-scripts",
    "--json",
    "--link-duplicates",
    "--link-folder",
    "--modules-folder",
    "--mutex",
    "--network-concurrency",
    "--network-timeout",
    "--no-bin-links",
    "--no-lockfile",
    "--no-node-version-check",
    "--no-progress",
    "--non-interactive",
    "--offline",
    "--prefer-offline",
    "--preferred-cache-folder",
    "--prod",
    "--production",
    "--proxy",
    "--pure-lockfile",
    "--registry",
    "--scripts-prepend-node-path",
    "--silent",
    "--skip-integrity-check",
    "--strict-semver",
    "--update-checksums",
    "--verbose",
    "--version"
)

clink.arg.register_parser("yarn", yarn_parser)
