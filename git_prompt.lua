
local gitutil = require('gitutil')

-- TODO: cache config based on some modification indicator (system mtime, hash)

local function load_git_config(git_dir)
    if not git_dir then return nil end
    local file = io.open(git_dir.."/config", 'r')
    if not file then return nil end

    local config = {};
    local section;
    for line in file:lines() do
        if (line:sub(1,1) == "[" and line:sub(-1) == "]") then
            if (line:sub(2,5) == "lfs ") then
                section = nil -- skip LFS entries as there can be many and we never use them
            else
                section = line:sub(2,-2)
                config[section] = config[section] or {}
            end
        elseif section then
            local param, value = line:match('^%s-([%w|_]+)%s-=%s+(.+)$')
            if (param and value ~= nil) then
                config[section][param] = value
            end
        end
    end
    file:close();
    return config;
end

---
 -- Escapes every non-alphanumeric character in string with % symbol. This is required
 -- because string.gsub treats plain strings with some symbols (e.g. dashes) as regular
 -- expressions (taken from http://stackoverflow.com/a/34953646)
 -- @param {string} text Text to escape
 -- @returns {string} Escaped text
---
local function escape(text)
    return text and text:gsub("([^%w])", "%%%1") or ""
end

local function get_git_config_value(git_config, section, param)
    if (not param) or (not section) then return nil end
    if not git_config then return nil end

    return git_config[section] and git_config[section][param] or nil
end

local function git_prompt_filter()
    -- Check for Cmder configured Git Status Opt In/Out - See: https://github.com/cmderdev/cmder/issues/2484
    if cmderGitStatusOptIn == false then return false end  -- luacheck: globals cmderGitStatusOptIn

    local git_dir = gitutil.get_git_dir()
    if not git_dir then return false end

    -- if we're inside of git repo then try to detect current branch
    local branch = gitutil.get_git_branch(git_dir)
    if not branch then return false end

    -- for remote and ref resolution algorithm see https://git-scm.com/docs/git-push
    local git_config = load_git_config(git_dir)
    local remote_to_push = get_git_config_value(git_config, 'branch "'..branch..'"', 'remote') or ''
    local remote_ref = get_git_config_value(git_config, 'remote "'..remote_to_push..'"', 'push') or
        get_git_config_value(git_config, 'push', 'default')

    local text = remote_to_push
    if (remote_ref) then text = text..'/'..remote_ref end

    if (text == '') then
      clink.prompt.value = clink.prompt.value:gsub(escape('('..branch), '%1'..text)
    else
      clink.prompt.value = clink.prompt.value:gsub(escape('('..branch), '%1 -> '..text)
    end

    return false
end

-- Register filter with priority 60 which is greater than
-- Cmder's git prompt filters to override them
clink.prompt.register_filter(git_prompt_filter, 60)
