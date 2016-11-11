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

local install_parser = parser(
        "--flat",
        "--force",
        "--har",
        "--no-lockfile",
        "--production",
        "--pure-lockfile"
    )

local add_parser = parser(
        "--dev",
        "--exact",
        "--optional",
        "--peer",
        "--tilde"
    )

local script_parser = parser({scripts})

local yarn_parser = parser({
    "access"..parser({
        "edit",
        "grant"..parser({
            "read-only",
            "read-write"
            }),
        "ls-packages",
        "ls-collaborators",
        "public",
        "revoke",
        "restricted"
    }),
    "add".. add_parser,
    "bin",
    "cache"..parser({
        "clean",
        "dir",
        "ls"
    }),
    "check"..parser("--integrity"),
    "clean",
    "config"..parser({
        "delete",
        "get",
        "list",
        "set"..parser("-g", "--global")
    }),
    "generate-lock-entry",
    "global"..parser({
        "add".. add_parser,
        "bin",
        "ls",
        "remove"..parser({modules})
    }),
    "info",
    "init",
    "install".. install_parser,
    "licenses"..parser({"generate-disclaimer", "ls"}),
    "link"..parser({matchers.files, global_modules}),
    "login",
    "logout",
    "ls",
    "outdated",
    "owner"..parser({"add", "ls", "rm"}),
    "pack"..parser("--filename"),
    "publish"..parser(
        "--access"..parser({"public", "restricted"}),
        "--tag"
    ),
    "remove"..parser({modules}),
    "run"..script_parser,
    "self-update",
    "tag"..parser({"add", "ls", "rm"}),
    "team"..parser({"add", "create", "destroy", "ls", "rm"}),
    "test",
    "unlink"..parser({modules}),
    "upgrade",
    "version"..parser("--new-version"),
    "why"..parser({modules})
    },
    "-h",
    "-v",
    "--cache-folder",
    "--global-folder",
    "--help",
    "--json",
    "--modules-folder",
    "--mutex",
    "--no-emoji",
    "--offline",
    "--prefer-offline",
    "--version"
)

clink.arg.register_parser("yarn", yarn_parser)
