local path = require('path')

local exports = {}

---
 -- Resolves closest .git directory location.
 -- Navigates subsequently up one level and tries to find .git directory
 -- @param  {string} path Path to directory will be checked. If not provided
 --                       current directory will be used
 -- @return {string} Path to .git directory or nil if such dir not found
exports.get_git_dir = function (start_dir)
    local git_dir_output = io.popen("git rev-parse --git-dir 2>nul")
    if git_dir_output == nil then return nil end
    return git_dir_output:read()
end

---
 -- Find out current branch
 -- @return {nil|git branch name}
---
exports.get_git_branch = function (dir)
    local git_dir = dir or exports.get_git_dir()

    -- If git directory not found then we're probably outside of repo
    -- or something went wrong. The same is when head_file is nil
    local head_file = git_dir and io.open(git_dir..'/HEAD')
    if not head_file then return end

    local HEAD = head_file:read()
    head_file:close()

    -- if HEAD matches branch expression, then we're on named branch
    -- otherwise it is a detached commit
    local branch_name = HEAD:match('ref: refs/heads/(.+)')
    return branch_name or 'HEAD detached at '..HEAD:sub(1, 7)
end

exports.get_common_dir = function()
    local git_common_dir_output = io.popen("git rev-parse --git-common-dir 2>nul")
    if git_common_dir_output == nil then return nil end
    return git_common_dir_output:read()
end

return exports
