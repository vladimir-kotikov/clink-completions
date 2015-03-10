function git_prompt_filter()
    local head = io.open('.git/HEAD')
    local colors = {
        clean = "\x1b[1;37;40m",
        dirty = "\x1b[31;1m",
    }
    -- TODO: there is no status detection now 
    -- so color will always be a colors.clean
    local color = colors.clean

    if head ~= nil then
        local h = head:read()
        local branch = string.match(h, "/([%w-]+)$")

        if branch then
            if clink.prompt.value:match("{git}") then
                clink.prompt.value = string.gsub(clink.prompt.value, "{git}", color.."("..branch..")")
            else
                clink.prompt.value = color.."("..branch..") "..clink.prompt.value
            end
        else
            clink.prompt.value = string.gsub(clink.prompt.value, "{git}", "")
        end

        head:close()
    else 
        clink.prompt.value = string.gsub(clink.prompt.value, "{git}", "")
    end

    return false
end

clink.prompt.register_filter(git_prompt_filter, 50)