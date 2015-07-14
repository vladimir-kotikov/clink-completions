-- preamble: common routines

local matchers = require('matchers')

function trim(s)
  return s:match "^%s*(.-)%s*$"
end

local modules = matchers.create_dirs_matcher('node_modules/*')

-- Reads package.json in current directory and extracts all "script" commands defined 
local function scripts(token)

    local matches = {}
    local match_filters = {}

    -- Read package.json first
    local package_json = io.open('package.json')
    -- If there is no such file, then close handle and return
    if package_json == nil then
        package_json:close()
        return matches
    end
    
    -- Read the whole file contents
    local package_contents = package_json:read("*a")
    
    -- First, gind all "scripts" elements in package file
    -- This is necessary since package.json can contain multiple sections
    -- And we'll need to merge them first
    local scripts_sections = {}
    for section in package_contents:gmatch('"scripts"%s*:%s*{(.-)}') do
        table.insert(scripts_sections, trim(section))
    end

    -- Then merge "scripts" sections found and try to find
    -- <script_name>: <script_command> pairs
    local scripts = table.concat(scripts_sections, ",\n")
    for script_name, script_command in scripts:gmatch('"(.-)"%s*:%s*(".-")') do
        table.insert(matches, script_name)
        -- This line adds match filter for each command, since we want to
        -- see not only command name, but command content as well
        -- TODO: check how this will looks when command is too long
        -- TODO: add coloring
        table.insert(match_filters, script_name.." -> "..script_command)
    end

    -- Finally close the handle
    package_json:close()
    -- And register match filters and return the matches collection
    clink.match_display_filter = function (matches)
        return match_filters
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
    "cache",
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
    "link",
    "list",
    "ll",
    "ln",
    "login",
    "ls",
    "outdated",
    "owner",
    "pack",
    "prefix",
    "prune",
    "publish",
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
    "up",
    "update",
    "v",
    "version",
    "view",
    "whoami"
    },
    "-h"
)

clink.arg.register_parser("npm", npm_parser)
