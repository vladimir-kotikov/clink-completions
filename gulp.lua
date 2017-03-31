---
 -- Gulpjs completions
 -- Schema: gulp [--gulpfile location] task [--flag [file or dir]]
 --         gulp --version
 --
 -- Available flags: https://github.com/gulpjs/gulp/blob/master/docs/CLI.md
 -- Note: doesn't allow for stacking multiple tasks or multiple flags, because clink flags must be strings
 -- Note: doesn't use --color and --no-color becase these flags override available arguments
 -- Note: doesn't use short flags (-v, -S)
---

-- preamble: common routines

local parser = clink.arg.new_parser
local matchers = require("matchers")
local color = require("color")

local gulpfileFlags = {
    "--require" .. parser({matchers.files}),
    "--cwd" .. parser({matchers.dirs}),
    "--verify",
    "--silent"
}

---
 -- Check if file exists
 --
 -- @param {string} location - Should not be in quotes
 -- @return {boolean}
---
local function is_available(gulpfileLocation)

    if gulpfileLocation == nil then return false end

    local gulpfileMatch = clink.find_files(gulpfileLocation .. "*")

    return #gulpfileMatch ~= 0
end

---
 -- Queries gulp in current working directory for available tasks
 --
 -- @return {table} - Table of available tasks
---
local function get_local_tasks()

    -- Local tasks. Should have all --tasks* commands too (including --depth which doesn't work when defined here)
    local localTasks = {
        "--tasks"
    }

    local gulpFileLocation = "gulpfile.js"
    local gulpBabelFileLocation = "gulpfile.babel.js"

    -- Check if gulpfile exists to laod tasks
    if not is_available(gulpFileLocation) and not is_available(gulpBabelFileLocation) then return {} end

    -- When there are no tasks, doesn't have to return local tasks
    local proc = io.popen("gulp --tasks-simple 2>nul")
    if not proc then return {} end

    -- Stack all tasks
    for line in proc:lines() do
        table.insert(localTasks, line)
    end

    proc:close()

    return localTasks
end

---
 -- Queries gulp in provided location for available tasks
 --
 -- @return {table} - Table of available tasks
---
local function get_remote_tasks()

    -- Remote tasks
    local remoteTasks = {
        "--tasks"
    }

    -- Retrieve gulpfile location (match quoted then unquoted, works for all scenarios)
    local gulpfileLocation = string.match(rl_state.line_buffer, '^gulp %-%-gulpfile "([^"]-)" +')
        or string.match(rl_state.line_buffer, '^gulp %-%-gulpfile (.-) +')

    -- Check if gulpfile exists to laod tasks
    if not is_available(gulpfileLocation) then return {} end

    -- Readline buffer should be gulp --gulpfile [path to gulpfile]
    local proc = io.popen('gulp --gulpfile "' .. gulpfileLocation .. '" --tasks-simple 2>nul')
    if not proc then return {} end

    -- Stack all tasks
    for line in proc:lines() do
        table.insert(remoteTasks, line)
    end

    proc:close()

    return remoteTasks
end

-- end preamble

-- Tasks defined in local gulpfile.js + Relevant flags
local local_tasks_parser = parser(
    {
        get_local_tasks
    },
    {
        gulpfileFlags
    }
):loop(1)

-- Tasks defined in remote gulpfile.js + Relevant flags
local remote_tasks_parser = parser(
    {
        "--gulpfile"
    },
    {
        matchers.files
    },
    {
        get_remote_tasks
    },
    {
        gulpfileFlags
    }
):loop(2)

-- Global tasks
local global_tasks_parser = parser(
    {
        "--version"
    }
):loop(0)

-- Register parsers
-- Note: Order is important
clink.arg.register_parser("gulp", local_tasks_parser)
clink.arg.register_parser("gulp", remote_tasks_parser)
clink.arg.register_parser("gulp", global_tasks_parser)

-- Prompt
local function gulp_prompt_filter()
    if is_available("gulpfile.js") or is_available("gulpfile.babel.js") then
        clink.prompt.value = clink.prompt.value .. color.color_text("[gulp]", color.RED) .. " "
    end
    return true
end

clink.prompt.register_filter(gulp_prompt_filter, 60)
