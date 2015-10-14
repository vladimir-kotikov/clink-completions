-- preamble: common routines

local color = require('color')
local matchers = require('matchers')

function trim(s)
  return s:match "^%s*(.-)%s*$"
end

---
 -- Queries config options value using 'npm config' call
 -- @param  {string}  config_entry  Config option name
 -- @return {string}  Config value for specific option or
 --   empty string in case of any error
---
local function get_npm_config_value (config_entry)
    assert(config_entry and type(config_entry) == "string" and #config_entry > 0,
        "get_npm_config_value: config_entry param should be non-empty string")

    local proc = io.popen("npm config get "..config_entry.." 2>nul")
    if not proc then return "" end

    local value = proc:read()
    proc:close()

    return value or nil
end

local npm_cache = get_npm_config_value("cache")
local npm_globals = get_npm_config_value("prefix")

local modules = matchers.create_dirs_matcher('node_modules/*')
local cached_modules = npm_cache and matchers.create_dirs_matcher(npm_cache..'/*') or {}
local global_modules = npm_globals and matchers.create_dirs_matcher(npm_globals..'/node_modules/*') or {}

-- Reads package.json in current directory and extracts all "script" commands defined 
local function scripts(token)

    local matches = {}

    -- Read package.json first
    local package_json = io.open('package.json')
    -- If there is no such file, then close handle and return
    if package_json == nil then
        package_json:close()
        return matches
    end
    
    -- Read the whole file contents
    local package_contents = package_json:read("*a")
    package_json:close()

    -- First, gind all "scripts" elements in package file
    -- This is necessary since package.json can contain multiple sections
    -- And we'll need to merge them first
    local scripts_sections = {}
    for section in package_contents:gmatch('"scripts"%s*:%s*{(.-)}') do
        table.insert(scripts_sections, trim(section))
    end

    -- Then merge "scripts" sections and try to find
    -- <script_name>: <script_command> pairs
    local scripts = table.concat(scripts_sections, ",\n")
        -- encode escaped quotes, so they won't affect further parsing
        :gsub("\\(.)", function (x)
            return string.format("\\%03d", string.byte(x))
        end)

    for script_name in scripts:gmatch('"(.-)"%s*:%s*(".-")') do
        table.insert(matches, script_name)
    end

    return matches
end

local parser = clink.arg.new_parser

-- end preamble

local install_parser = parser({matchers.dirs},
        "--force",
        "-g", "--global",
        "--link",
        "--no-bin-links",
        "--no-optional",
        "--no-shrinkwrap",
        "--nodedir=/",
        "--production",
        "--save", "--save-dev", "--save-optional",
        "--tag"
        ):loop(1)

-- TODO: list only global modules with -g
local remove_parser = parser({modules}, "-g", "--global"):loop(1)

local search_parser = parser("--long")

local script_parser = parser({scripts})

local npm_parser = parser({
    "add-user",
    "adduser",
    "apihelp",
    "author",
    "bin",
    "bugs",
    "c",
    "cache"..parser({
        "add"..parser({matchers.dirs}),
        "clean"..parser({cached_modules}),
        "ls"
        }),
    "completion",
    "config",
    "ddp",
    "dedupe",
    "deprecate",
    "docs",
    "edit",
    "explore",
    "faq",
    "find" .. search_parser,
    "find-dupes",
    "get",
    "help",
    "help-search",
    "home",
    "info",
    "init",
    "install" .. install_parser,
    "issues",
    "la",
    "link"..parser({matchers.files, global_modules}),
    "list",
    "ll",
    "ln"..parser({matchers.files, global_modules}),
    "login",
    "ls",
    "outdated",
    "owner",
    "pack",
    "prefix",
    "prune",
    "publish"..parser(
        "--tag",
        "--access"..parser({"public", "restricted"})
    ),
    "r",
    "rb",
    "rebuild",
    "rm" .. remove_parser,
    "remove" .. remove_parser,
    "repo",
    "restart",
    "root",
    "run"..script_parser,
    "run-script"..script_parser,
    "search" .. search_parser,
    "set",
    "show",
    "shrinkwrap",
    "star",
    "stars",
    "start",
    "stop",
    "submodule",
    "tag",
    "test",
    "un",
    "uninstall" .. remove_parser,
    "unlink",
    "unpublish",
    "unstar",
    "up"..parser({modules}),
    "update"..parser({modules}),
    "v",
    "version",
    "view",
    "whoami"
    },
    "-h"
)

clink.arg.register_parser("npm", npm_parser)

function npm_prompt_filter()
    local package = io.open('package.json')
    if package ~= nil then
        local package_info = package:read('*a')
        package:close()
        local package_name = string.match(package_info, '"name"%s*:%s*"(.-)"')
        local package_version = string.match(package_info, '"version"%s*:%s*"(.-)"')
        local package_string = color.color_text("("..package_name.."@"..package_version..")", color.YELLOW)
        clink.prompt.value = clink.prompt.value:gsub('{git}', '{git} '..package_string)
    end
    return false
end

clink.prompt.register_filter(npm_prompt_filter, 40)