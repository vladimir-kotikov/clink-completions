local JSON = require("JSON")

-- silence JSON parsing errors
function JSON:assert () end  -- luacheck: no unused args

local color = require('color')

local function escape_percents(s)
    return s:gsub('%%', '%%%%')
end

local function npm_prompt_filter()
    -- Automatically disable this when a .clinkprompt custom prompt is active.
    local customprompt = clink.getclinkprompt and clink.getclinkprompt()
    if customprompt and customprompt ~= "" then return false end

    local package_file = io.open('package.json')
    if not package_file then return false end

    local package_data = package_file:read('*a')
    package_file:close()

    local package = JSON:decode(package_data)
    -- Bail out if package.json is malformed
    if not package then return false end
    -- Don't print package info when the package is private or both version and name are missing
    if package.private or (not package.name and not package.version) then return false end

    local package_name = package.name or "<no name>"
    local package_version = package.version and "@"..package.version or ""
    local package_string = color.color_text("("..package_name..package_version..")", color.YELLOW)
    clink.prompt.value = clink.prompt.value:gsub('{git}', '{git} '..escape_percents(package_string))

    return false
end

clink.prompt.register_filter(npm_prompt_filter, 40)
