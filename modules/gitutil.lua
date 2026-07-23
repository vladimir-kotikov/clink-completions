local clink_version = require('clink_version')
local color = require('color')
local file_matches = require('matchers').files
local path_module = require('path')
local w = require('tables').wrap
-- luacheck: globals matchicons

--------------------------------------------------------------------------------
local color_git = "38;2;217;93;59" -- the git orange

--------------------------------------------------------------------------------
local function can_take_optional_locks(command) -- luacheck: no unused
    local var = string.lower(os.getenv("GITUTIL_TAKE_OPTIONAL_LOCKS") or "")
    if var == "" then
        return false
    end

    if var == "true" or var == "1" then
        return true
    end

    var = " " .. var:gsub("[ ;,]", " ") .. " "

    local words = string.explode(string.lower(command))
    if not words or not words[1] then
        return false
    end

    local commands = string.explode(var)
    for _, c in ipairs(commands) do
        if words[1] == c then
            return true
        end
    end

    return false
end

---
 -- Return a command line string to run the specified git command.  It will
 -- include relevant global flags such as "--no-optional-locks", and also
 -- "2>nul" to suppress stderr.
 --
 -- Currently it is just "git", but this function makes it possible in the
 -- future to specify "git.exe" (bypass any git.bat or git.cmd scripts) and/or
 -- add a fully qualified path.
local function make_command(command, dont_suppress_stderr)
    command = command or ""

    if not can_take_optional_locks(command) then
        command = "--no-optional-locks " .. command
    end

    command = "git " .. command

    if not dont_suppress_stderr then
        command = "2>nul " .. command
    end

    return command
end

---
 -- Resolves closest .git directory location.
 -- Navigates subsequently up one level and tries to find .git directory
 -- @param  {string} path Path to directory will be checked. If not provided
 --                       current directory will be used
 -- @return {string} Path to .git directory or nil if such dir not found
local function get_git_dir(start_dir)

    -- Checks if provided directory contains '.git' directory
    -- and returns path to that directory
    local function has_git_dir(dir)
        return #clink.find_dirs(dir..'/.git') > 0 and dir..'/.git'
    end

    -- checks if directory contains '.git' _file_ and if it does
    -- parses it and returns a path to git directory from that file
    local function has_git_file(dir)
        local gitfile = io.open(dir..'/.git')
        if not gitfile then return false end

        local git_dir = gitfile:read():match('gitdir: (.*)')
        gitfile:close()

        if not git_dir then return false end
        -- If found path is absolute don't prepend initial
        -- directory - return absolute path value
        return path_module.is_absolute(git_dir) and git_dir
            or dir..'/'..git_dir
    end

    -- Set default path to current directory
    if not start_dir or start_dir == '.' then start_dir = clink.get_cwd() end

    -- Calculate parent path now otherwise we won't be
    -- able to do that inside of logical operator
    local parent_path = path_module.pathname(start_dir)

    return has_git_dir(start_dir)
        or has_git_file(start_dir)
        -- Otherwise go up one level and make a recursive call
        or (parent_path ~= '' and parent_path ~= start_dir and get_git_dir(parent_path) or nil)
end

local function get_git_common_dir(start_dir)
    local git_dir = get_git_dir(start_dir)
    if not git_dir then return git_dir end
    local commondirfile = io.open(git_dir..'/commondir')
    if commondirfile then
        -- If there's a commondir file, we're in a git worktree
        local commondir = commondirfile:read()
        commondirfile.close()
        return path_module.is_absolute(commondir) and commondir
            or git_dir..'/'..commondir
    end
    return git_dir
end

--------------------------------------------------------------------------------
local function extract_sgr(c)
    return c and c:match("^\x1b%[(.*)m$") or c
end

local function addicon(m, icon, c)
    if matchicons and matchicons.addicontomatch then
        if not c and m.type and m.type:find("file") then
            if rl.getmatchcolor then
                c = extract_sgr(rl.getmatchcolor(m.match, m.type))
            end
        end
        return matchicons.addicontomatch(m, icon, c)
    else
        return m
    end
end

local function addicons(matches)
    if matchicons and matchicons.addicontomatch then
        for _, m in ipairs(matches) do
            local old_type = m.type
            m.type = "file"
            addicon(m)
            m.type = old_type
        end
    end
    return matches
end

local map_file
if rl and rl.getmatchcolor then
    map_file = function (file)
        if type(file) == "table" then
            return file
        else
            return { match=file, display='\x1b[m'..rl.getmatchcolor(file, 'file')..file, type='arg' }
        end
    end
else
    map_file = function (file)
        if type(file) == "table" then
            return file
        else
            return { match=file, display='\x1b[m'..file, type='arg' }
        end
    end
end

local function has_dot_dirs(token)
    for _, t in ipairs(string.explode(token, '/\\')) do
        if t == '.' or t == '..' then
            return true
        end
    end
end

local function get_relative_prefix(git_dir)
    local cwd = clink.lower(path.join(os.getcwd(), ''))
    git_dir = clink.lower(path.join(path.toparent(git_dir), ''))
    return cwd:sub(#git_dir + 1)
end

local function adjust_relative_prefix(dir, rel)
    local len = string.matchlen(dir, rel)
    if len < 0 then
        return ''
    end
    return dir:sub(len + 1)
end

local function make_indexed_table(input)
    local output = {}
    for _, value in ipairs(input) do
        output[value] = true
    end
    return output
end

local function filter_refs(refs, kind, dummy)
    assert(not dummy) -- Unsupported usage.

    local result = w()
    for _, r in ipairs(refs) do
        local m = r:match('refs/'..kind..'/(.*)')
        if m then
            table.insert(result, m)
        end
    end
    return result
end

---
 -- Lists all refs, optionally filtered by kind
 -- @param string [dir]  Directory where to search file for
 -- @param string [kind [,kind [,...]]]  Filter by kinds
 -- @return table  List of filtered refs
local function list_refs(dir, kind, kind2, dummy)
    assert(not dummy) -- Unsupported usage.

    local result = w()
    local git_dir = dir or get_git_common_dir()
    if not git_dir then return result end

    local filter
    if kind2 then
        filter = function (text)
            return text:match('refs/'..kind..'/(.*)') or
                    text:match('refs/'..kind2..'/(.*)')
        end
    elseif kind then
        filter = function (text)
            return text:match('refs/'..kind..'/(.*)')
        end
    else
        filter = function (text)
            return text
        end
    end

    local refs = io.popen(make_command('show-ref'))
    if refs == nil then return {} end

    for line in refs:lines() do
        -- SHA is 40 char length + 1 char for space
        if #line > 41 then
            local match = filter(line:sub(41))
            if match then table.insert(result, match) end
        end
    end

    refs:close()
    return result
end

local function list_git_status_files(token, flags) -- luacheck: no unused args
    local result = w()
    local git_dir = get_git_common_dir()
    if git_dir then
        local rel_pfx = get_relative_prefix(git_dir)
        local f = io.popen(make_command("status --porcelain "..(flags or "").." **"))
        if f then
            if string.matchlen then -- luacheck: no global
                --[[
                token = path.normalise(token)
                --]]
                for line in f:lines() do
                    line = line:match("^.[^ ] (.+)$")
                    if line then
                        line = path.normalise(line)
                        --[[
                        -- TODO: Maybe use match display filtering to show the number of files in each dir?
                        local mlen = string.matchlen(line, token) -- luacheck: no global
                        if mlen < 0 then
                            table.insert(result, { match = line, type = "file" })
                        else
                            local dir = path.getdirectory(line:sub(1, mlen))
                            local child = line:sub(mlen + 1):match("^([^/\\]*[/\\]?)")
                            local m = dir and path.join(dir, child) or child
                            local isdir = m:sub(-1):find("[/\\]")
                            table.insert(result, { match = m, type = (isdir and "dir" or "file") })
                        end
                        --]]
                        table.insert(result, adjust_relative_prefix(line, rel_pfx))
                    end
                end
            else
                for line in f:lines() do
                    table.insert(result, adjust_relative_prefix(line:sub(4), rel_pfx))
                end
            end
            f:close()
        end
    end
    return result
end

--------------------------------------------------------------------------------
local function __common_spec_generator_049(token, mode)
    local function is_token_match(value)
        return clink.is_match(token, value)
    end

    local git_dir = get_git_common_dir()

    local files = mode:find("checkout") and list_git_status_files(token, "-uno"):filter(is_token_match) or w()
    local refs = list_refs(git_dir)
    local local_branches = filter_refs(refs, 'heads'):filter(is_token_match)
    local local_branches_idx = make_indexed_table(local_branches)
    local remote_branches = filter_refs(refs, 'remotes'):filter(is_token_match)

    local predicted_branches = filter_refs(refs, 'remotes')
        :map(function (remote_branch)
            return remote_branch:match('.-/(.+)')
        end)
        :filter(function(branch)
            return branch
                and clink.is_match(token, branch)
                -- Filter out those predictions which are already exists as local branches
                and not local_branches_idx[branch]
        end)

    if (#local_branches + #remote_branches + #predicted_branches) == 0 then return files end

    -- if there is any refspec that matches token then:
    --   * disable readline's filename completion, otherwise we'll get a list of these specs
    --     treated as list of files (without 'path' part), ie. 'some_branch' instead of 'my_remote/some_branch'
    --   * create display filter for completion table to append path separator to each directory entry
    --     since it is not added automatically by readline (see previous point)
    clink.matches_are_files(0)
    clink.match_display_filter = function ()
        local star = '*'
        if clink_version.supports_query_rl_var and rl.isvariabletrue('colored-stats') then
            star = color.get_clink_color('color.git.star')..star..color.get_clink_color('color.filtered')
        end
        return files:map(function(file)
            return clink.is_dir(file) and file..'\\' or file
        end)
        :concat(local_branches)
        :concat(predicted_branches:map(function(branch) return star..branch end))
        :concat(remote_branches)
    end

    return files
        :concat(local_branches)
        :concat(predicted_branches)
        :concat(remote_branches)
end

local function __common_spec_generator_usedisplay(token, mode)
    -- NOTE:  The only reason this needs to use clink.is_match() is because the
    -- match_display_filter function defined here ignores the list of matches it
    -- receives, which is already filtered correctly and has had duplicates
    -- removed.
    local function is_token_match(value)
        return clink.is_match(token, value)
    end

    local git_dir = get_git_common_dir()

    local files = mode:find("checkout") and list_git_status_files(token, "-uno"):filter(is_token_match) or w()
    local refs = list_refs(git_dir)
    local local_branches = filter_refs(refs, 'heads'):filter(is_token_match)
    local local_branches_idx = make_indexed_table(local_branches)
    local remote_branches = filter_refs(refs, 'remotes'):filter(is_token_match)

    local predicted_branches = filter_refs(refs, 'remotes')
        :map(function (remote_branch)
            return remote_branch:match('.-/(.+)')
        end)
        :filter(function(branch)
            return branch
                and clink.is_match(token, branch)
                -- Filter out those predictions which are already exists as local branches
                and not local_branches_idx[branch]
        end)

    -- if there is any refspec that matches token then:
    --   * disable readline's filename completion, otherwise we'll get a list of these specs
    --     treated as list of files (without 'path' part), ie. 'some_branch' instead of 'my_remote/some_branch'
    --   * create display filter for completion table to append path separator to each directory entry
    --     since it is not added automatically by readline (see previous point)
    clink.match_display_filter = function ()
        local star = '*'
        if clink_version.supports_query_rl_var and rl.isvariabletrue('colored-stats') then
            star = color.get_clink_color('color.git.star')..star..color.get_clink_color('color.filtered')
        end
        local matches
        if clink_version.supports_display_filter_description then
            matches = files:map(function(file)
                return addicon({ match=file, display='\x1b[m'..file }, "", color_git)
            end)
        else
            matches = files:map(function(file) return '\x1b[m'..file end)
        end
        return matches
            :concat(local_branches:map(function(branch)
                return addicon({ match=branch }, "", color_git)
            end))
            :concat(predicted_branches:map(function(branch)
                return addicon({ match=branch, display=star..branch }, "", color_git)
            end))
            :concat(remote_branches:map(function(branch)
                return addicon({ match=branch }, "", color_git)
            end))
    end

    return files
        :concat(local_branches)
        :concat(predicted_branches)
        :concat(remote_branches)
end

-- This generator can simply return matches and rely on nosort, instead of
-- needing to use match display filtering to prevent sorting.
local function __common_spec_generator_nosort(token, mode)
    local git_dir = get_git_common_dir()

    -- Get branch names.

    local refs = list_refs(git_dir)
    local local_branches = filter_refs(refs, 'heads')
    local local_branches_idx = make_indexed_table(local_branches)
    local remote_branches = filter_refs(refs, 'remotes')
    local remote_branches_idx = make_indexed_table(remote_branches)

    local predicted_branches = filter_refs(refs, 'remotes')
        :map(function (remote_branch)
            return remote_branch:match('.-/(.+)')
        end)
        :filter(function(name)
            -- Filter out predictions that already exist as local branches.
            return not local_branches_idx[name]
        end)
    local predicted_branches_idx = make_indexed_table(predicted_branches)

    -- Collect the matches.

    local filtered_color = color.get_clink_color('color.filtered')
    local local_pre = filtered_color
    local remote_pre = filtered_color

    local mapped = {}

    if mode:find("status") then
        local function files_filter(name)
            name = path.normalise(name, '/')
            return not predicted_branches_idx[name] and not remote_branches_idx[name] and not local_branches_idx[name]
        end

        local files = list_git_status_files(token, "-uno"):filter(files_filter)
        table.insert(mapped, files:map(map_file):map(function (match)
            return addicon(match, "", color_git)
        end))
    end

    table.insert(mapped, local_branches:map(function(branch)
        return addicon({ match=branch, display=local_pre..branch, type='arg' }, "", color_git)
    end))

    if mode:find("predicted") then
        local predicted_pre = '*'
        if clink_version.supports_query_rl_var and rl.isvariabletrue('colored-stats') then
            predicted_pre = color.get_clink_color('color.git.star')..predicted_pre..filtered_color
        end
        table.insert(mapped, predicted_branches:map(function(branch)
            return addicon({ match=branch, display=predicted_pre..branch, type='arg' }, "", color_git)
        end))
    end

    table.insert(mapped, remote_branches:map(function(branch)
        return addicon({ match=branch, display=remote_pre..branch, type='arg' }, "", color_git)
    end))

    if mode:find("tags") then
        local tag_names = filter_refs(refs, 'tags')
        if string.comparematches then
            tag_names:sort(string.comparematches)
        end

        local tag_pre = color.get_clink_color('color.doskey')
        table.insert(mapped, tag_names:map(function(tag)
            return addicon({ match=tag, display=tag_pre..tag, type='arg' }, "", extract_sgr(tag_pre))
        end))
    end

    return w():concat(mapped)
end

local function common_spec_generator(token, mode)
    local result
    local need_nosort = clink_version.supports_argmatcher_nosort

    mode = mode or ""

    if mode:find("add") then
        if has_dot_dirs(token) then
            result = addicons(file_matches(token))
        else
            result = addicons(list_git_status_files(token, "-uall"):map(map_file))
        end
        need_nosort = false
    elseif not has_dot_dirs(token) then
        if clink_version.supports_argmatcher_nosort then
            result = __common_spec_generator_nosort(token, mode)
        elseif clink_version.supports_display_filter_description then
            result = __common_spec_generator_usedisplay(token, mode)
        else
            result = __common_spec_generator_049(token, mode)
        end
    end

    result = result or w()

    if mode:find("files") then
        result = result:concat(file_matches(token))
    end

    if need_nosort then
        result.nosort = true
    end
    return result
end

--------------------------------------------------------------------------------
local exports = {}

exports.make_command = make_command
exports.get_git_dir = get_git_dir
exports.get_git_common_dir = get_git_common_dir
exports.has_dot_dirs = has_dot_dirs
exports.list_git_status_files = list_git_status_files
exports.filter_refs = filter_refs
exports.list_refs = list_refs
exports.common_spec_generator = common_spec_generator

-- WARNING:  DEPRECATED -- IS NOT COMPATIBLE WITH GIT REFTABLE!
exports.get_git_branch = function (dir)
    local git_dir = dir or get_git_dir()

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

return exports
