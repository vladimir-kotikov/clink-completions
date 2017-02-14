---
 -- tab completion for the Cloud Foundry CLI (cf) on Windows using clink (https://github.com/mridgers/clink)
---
local parser = clink.arg.new_parser

-- execute cf to retrieve newline delimited list of completions
local function list_cf_completions()
    local lines = {}

    local p = io.popen('set GO_FLAGS_COMPLETION=1 && cf')
    if not p then return lines end

    for line in p:lines() do table.insert(lines, line) end

    p:close()
    return lines
end

local completions = function (token)  -- luacheck: no unused args
    return list_cf_completions()
end

local cf_parser = parser({completions})

clink.arg.register_parser("cf", cf_parser)
