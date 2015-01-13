function git_prompt_filter()
    local head = io.open('.git/HEAD')
    if head ~= nil then
        h = head:read()
        local branch = string.match(h, "/([%w-]+)$")
        if (branch) then
            clink.prompt.value = color_text("["..branch.."]", "black", "white").." "..clink.prompt.value
        end
        head:close()
    end
    return false
end

clink.prompt.register_filter(git_prompt_filter, 50)