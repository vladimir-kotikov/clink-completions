---
 -- Composer completions
---

-- preamble: common routines
local JSON = require("JSON")

-- silence JSON parsing errors
function JSON:assert () end  -- luacheck: no unused args

local color = require("color")
local parser = clink.arg.new_parser

---
 -- Queries composer for available tasks
 --
 -- @return {table} - Table of available tasks, either available for current project or global ones
---
local function get_tasks()

    local localTasks = {
    }

    local proc = io.popen("composer list --raw 2>nul")
    if not proc then return {} end

    for line in proc:lines() do
        local value = string.match(line, "^(%S+)")
        table.insert(localTasks, value)
    end

    proc:close()

    return localTasks

end

local local_tasks_parser = parser(
    {
        get_tasks
    }
):loop(0)

-- Register parsers
-- Note: Order is important
clink.arg.register_parser("composer", local_tasks_parser)

-- Prompt
local function composer_prompt_filter()
    local package_file = io.open('composer.json')
    if package_file ~= nil then

        local package_data = package_file:read('*a')
        package_file:close()

        local package = JSON:decode(package_data)
        -- Bail out if composer.json is malformed
        if not package then return false end

        local package_name = package.name or "<no name>"
        local package_version = package.version and ":"..package.version or ""
        local package_string = color.color_text("("..package_name..package_version..") ", color.YELLOW)

        clink.prompt.value = clink.prompt.value .. package_string
    end
    return false
end

clink.prompt.register_filter(composer_prompt_filter, 40)
