
local color = require('color')

function npm_prompt_filter()
    local package = io.open('package.json')
    if package ~= nil then
        local package_info = package:read('*a')
        package:close()
        local package_name = string.match(package_info, '"name"%s*:%s*"(%g-)"')
        local package_version = string.match(package_info, '"version"%s*:%s*"(.-)"')
        local package_string = color.color_text("("..package_name.."@"..package_version..")", color.YELLOW)
        clink.prompt.value = clink.prompt.value:gsub('{git}', '{git} '..package_string)
    end
    return false
end

clink.prompt.register_filter(npm_prompt_filter, 40)
