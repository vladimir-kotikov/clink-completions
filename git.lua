local path_module = require('path')
local git = require('gitutil')
local matchers = require('matchers')
local w = require('tables').wrap
local clink_version = require('clink_version')
local color = require('color')
local defer = require('defer_completions')
require('arghelper')
local parser = function (...)
    local p = clink.arg.new_parser(...)
    p._deprecated = nil
    return p
end

-- luacheck: globals matchicons

local argexpected = "Argument expected:  "
local argoptional = "Optional argument:  "
local function hintpfx(optional)
    return optional and argoptional or argexpected
end
local function inc_num_args(user_data, word_index)
    user_data.num_args = (user_data.num_args or 0) + 1
    user_data.word_index = word_index
end
local function is_optional(user_data, word_index)
    local u_num_args = user_data.num_args or 0
    local u_word_index = user_data.word_index
    return (u_num_args > 1) or (u_word_index and u_word_index < word_index)
end

if clink_version.supports_color_settings then
    settings.add('color.git.star', 'bright green', '首选分支补全的颜色')
end

local file_matches = matchers.files
local dir_matches = matchers.dirs
local files_parser = parser({file_matches})
local dirs_parser = parser({dir_matches})

local looping_files_parser = clink.argmatcher and clink.argmatcher():addarg(file_matches):loop()

local function extract_sgr(c)
    return c and c:match("^\x1b%[(.*)m$") or c
end

local color_git = "38;2;217;93;59" -- the git orange

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
    local git_dir = dir or git.get_git_common_dir()
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

    local refs = io.popen(git.make_command('show-ref'))
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
    local git_dir = git.get_git_common_dir()
    if git_dir then
        local rel_pfx = get_relative_prefix(git_dir)
        local f = io.popen(git.make_command("status --porcelain "..(flags or "").." **"))
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

local function branches()
    local git_dir = git.get_git_common_dir()
    if not git_dir then return w() end

    return list_refs(git_dir, 'heads')
end

-- Function to get the list of git aliases.
local function get_git_aliases()
    local res = w()

    local f = io.popen(git.make_command("config --get-regexp alias"))
    if f == nil then return res end

    for line in f:lines() do
        local name, command = line:match("^alias.([^ ]+) +(.+)$")
        if name then
            table.insert(res, { name=name, command=command })
        end
    end

    f:close()

    return res
end

-- Function to generate completions for alias
local cached_aliases
local index_aliases = {}
local function alias(token) -- luacheck: no unused args
    if cached_aliases then
        return cached_aliases
    end

    local res = w()

    local aliases = get_git_aliases()
    if clink_version.supports_display_filter_description then
        for _, a in ipairs(aliases) do
            table.insert(res, { match=a.name, description="Alias: "..a.command })
        end
    else
        for _, a in ipairs(aliases) do
            table.insert(res, a.name)
        end
    end

    index_aliases = {}
    for _, a in ipairs(aliases) do
        index_aliases[a.name] = true
    end

    if clink.onbeginedit then
        cached_aliases = res
    end
    return res
end

-- Function to generate completions for all command names
local cached_commands
local function catchall(token) -- luacheck: no unused args
    if cached_commands then
        return cached_commands
    end

    local res = w()

    local f = io.popen(git.make_command("help -a --no-aliases"))
    if f then
        for line in f:lines() do
            local name, desc = line:match("^   ([^ ]+) *(.*)$") -- luacheck: no unused
            if name then
                -- Currently the descriptions are discarded; only the main
                -- commands will list descriptions, so that more columns can
                -- fit on the screen.
                table.insert(res, name)
            end
        end
        f:close()
    end

    res:sort()

    if clink.onbeginedit then
        cached_commands = res
    end
    return res
end

local function remotes(token)  -- luacheck: no unused args
    local result = w()
    local git_dir = git.get_git_common_dir()
    if not git_dir then return result end

    local git_config = io.open(git_dir..'/config')
    -- if there is no gitconfig file (WAT?!), return empty list
    if git_config == nil then return result end

    for line in git_config:lines() do
        local remote = line:match('%[remote "(.*)"%]')
        if (remote) then
            table.insert(result, remote)
        end
    end

    git_config:close()
    return result
end

local function add_spec_generator(token)
    if has_dot_dirs(token) then
        return addicons(file_matches(token))
    end
    return addicons(list_git_status_files(token, "-uall"):map(map_file))
end

local function __common_spec_generator_049(token, mode)
    local function is_token_match(value)
        return clink.is_match(token, value)
    end

    local git_dir = git.get_git_common_dir()

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

    local git_dir = git.get_git_common_dir()

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
    local git_dir = git.get_git_common_dir()

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

local function __common_spec_generator(token, mode)
    local result
    mode = mode or ""
    if not has_dot_dirs(token) then
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
    if clink_version.supports_argmatcher_nosort then
        result.nosort = true
    end
    return result
end

local function checkout_spec_generator(token)
    return __common_spec_generator(token, "status predicted tags files")
end

local function log_spec_generator(token)
    return __common_spec_generator(token, "tags files")
end

local function switch_spec_generator(token)
    return __common_spec_generator(token, "predicted")
end

local function local_or_remote_branches(token)
    if clink_version.supports_argmatcher_nosort then
        return __common_spec_generator(token)
    else
        -- Try to resolve .git directory location
        local git_dir = git.get_git_common_dir()
        if not git_dir then return w() end

        return list_refs(git_dir, 'heads', 'remotes')
        :filter(function(branch)
            return clink.is_match(token, branch)
        end)
    end
end

local function checkout_dashdash(token, _, _, _, user_data)
    if user_data and user_data.shared_user_data and user_data.shared_user_data.has_arg1 then
        return file_matches(token)
    end

    if has_dot_dirs(token) then
        return file_matches(token)
    end

    local status_files = list_git_status_files(token, "-uno")
    if clink_version.supports_display_filter_description then
        return status_files:map(function(file) return { match=file, display='\x1b[m'..file, type='arg' } end)
    else
        clink.matches_are_files(false)
        return status_files
    end
end

local function push_branch_spec(token)
    local git_dir = git.get_git_common_dir()
    if not git_dir then return w() end

    local plus_prefix = token:sub(0, 1) == '+'
    -- cut out leading '+' symbol as it is a part of branch spec
    local branch_spec = plus_prefix and token:sub(2) or token
    -- check if there a local/remote branch separator
    local s, e = branch_spec:find(':')

    -- starting from here we have 2 options:
    -- * if there is no branch separator complete word with local branches
    if not s then
        -- setup display filter to prevent display '+' symbol in completion list
        local refs = list_refs(git_dir)
        if clink_version.supports_display_filter_description then
            local b = filter_refs(refs, 'heads'):map(function(branch)
                -- append '+' to results if it was specified
                return { match=plus_prefix and '+'..branch or branch, display=branch }
            end)
            clink.ondisplaymatches(function ()
                return b
            end)
            return b
        else
            local b = filter_refs(refs, 'heads')
            clink.match_display_filter = function ()
                return b
            end
            return b:map(function(branch)
                -- append '+' to results if it was specified
                return plus_prefix and '+'..branch or branch
            end)
        end
    else
    -- * if there is ':' separator then we need to complete remote branch
        local local_branch_spec = branch_spec:sub(1, s - 1)
        local remote_branch_spec = branch_spec:sub(e + 1)

        -- TODO: show remote branches only for remote that has been specified as previous argument
        local b = w(clink.find_dirs(git_dir..'/refs/remotes/*'))
        :filter(function(remote) return path_module.is_real_dir(remote) end)
        :reduce({}, function(result, remote)
            return w(path_module.list_files(git_dir..'/refs/remotes/'..remote, '/*',
                --[[recursive=]]true, --[[reverse_separator=]]true))
            :filter(function(remote_branch)
                return clink.is_match(remote_branch_spec, remote_branch)
            end)
            :concat(result)
        end)

        -- setup display filter to prevent display '+' symbol in completion list
        if clink_version.supports_display_filter_description then
            b = b:map(function(branch)
                return {
                    match=(plus_prefix and '+'..local_branch_spec or local_branch_spec)..':'..branch,
                    display=branch
                }
            end)
            clink.ondisplaymatches(function ()
                return b
            end)
            return b
        else
            clink.match_display_filter = function ()
                return b
            end
            return b:map(function(branch)
                return (plus_prefix and '+'..local_branch_spec or local_branch_spec)..':'..branch
            end)
        end
    end
end

local stashes = function(token, _, _, builder)  -- luacheck: no unused args

    local git_dir = git.get_git_dir()
    if not git_dir then return w() end

    local stash_file = io.open(git_dir..'/logs/refs/stash')
    -- if there is no stash file, return empty list
    if stash_file == nil then return w() end

    local stashes = {}
    -- make a dictionary of stash time and stash comment to
    -- be able to sort stashes by date/time created
    for stash in stash_file:lines() do
        local stash_time, stash_name = stash:match('(%d%d%d%d%d%d%d%d%d%d) [+-]%d%d%d%d%s+(.*)')
        if (stash_name and stash_name) then
            stashes[stash_time] = stash_name
        end
    end

    stash_file:close()

    -- get times for available stashes into separate table and sort it
    -- from newest to oldest. This is required because of stash@{0}
    -- represents _latest_ stash, not the last one in file
    local stash_times = {}
    for k in pairs(stashes) do
        table.insert(stash_times, k)
    end

    table.sort(stash_times, function (a, b)
        return a > b
    end)

    -- generate matches and match filter table
    local ret = {}
    local ret_filter = {}
    for i,v in ipairs(stash_times) do
        local match = "stash@{"..(i-1).."}"
        table.insert(ret, match)
        if clink_version.supports_display_filter_description then
            -- Clink now has a richer match interface.  By returning a table,
            -- the script is able to provide the stash name separately from the
            -- description.  If the script does so, then the popup completion
            -- window is able to show the stash name plus a dimmed description,
            -- but only insert the stash name.
            table.insert(ret_filter, { match=match, type="none", description=stashes[v] })
        else
            table.insert(ret_filter, match.."    "..stashes[v])
        end
    end

    local function filter()
        return ret_filter
    end

    if builder and builder.setforcequoting then
        builder:setforcequoting()
    end

    if clink_version.supports_display_filter_description then
        clink.ondisplaymatches(filter)
    else
        clink.match_display_filter = filter
    end

    return ret
end

local function tags()
    local tag_names = list_refs(nil, 'tags')
    local tag_pre = color.get_clink_color('color.doskey')
    return tag_names:map(function(tag) return { match=tag, display=tag_pre..tag, type='arg' } end)
end

local cached_guides
local function concept_guides()
    if cached_guides then
        return cached_guides
    end

    local matches = {}
    local r = io.popen(git.make_command("help -g"))
    if r then
        local sgr = "\x1b[m"
        local mark = " \x1b[22;32m*"
        for line in r:lines() do
            local guide, desc = line:match("^   ([^ ]+) *(.*)$")
            if guide then
                if clink_version.supports_display_filter_description then
                    table.insert(matches, { match=guide, display=sgr..guide..mark, description="Guide: "..desc } )
                else
                    table.insert(matches, guide)
                end
            end
        end
        r:close()
    end

    if clink.onbeginedit then
        cached_guides = matches
    end
    return matches
end

local cached_all_commands
local index_main_commands = {}
local function all_commands()
    if cached_all_commands then
        return cached_all_commands
    end

    local matches = {}
    local r = io.popen(git.make_command("help -a"))
    if r then
        local prefix = "Command: "
        local mode = {}
        for line in r:lines() do
            local command, desc = line:match("^   ([^ ]+) *(.*)$")
            if command then
                if clink_version.supports_display_filter_description then
                    local mtype = (mode.aliases and "alias") or (index_main_commands[command] and "cmd")
                    table.insert(matches, { match=command, description=prefix..desc, type=mtype } )
                else
                    table.insert(matches, command)
                end
            elseif line == "Command aliases" then
                prefix = "Alias: "
                mode = { aliases=true }
            elseif line == "External commands" then
                prefix = "External command"
                mode = { external=true }
            end
        end
        r:close()
    end

    if clink.onbeginedit then
        cached_all_commands = matches
    end
    return matches
end

-- luacheck: push
-- luacheck: no max line length

local mergesubtree_arg = parser({dir_matches})
local placeholder_required_arg = parser({})
-- Note: All these separate fromhistory parsers are necessary in order to
-- collect from history separately.
local abbrev_lengths = parser({5, 6, 8, 10, 12, 16, 20, 24, 32, 40})
local batch_format_arg = parser({fromhistory=true, "%(objectname)", "%(objecttype)", "%(objectsize)", "%(objectsize:disk)", "%(deltabase)", "%(rest)"})
local branches_args = parser({branches, argexpected.."branch"}):loop(1)
local clone_filter_arg = parser({fromhistory=true})
local color_opts = parser({"true", "false", "always"})
local commit_trailer_arg = parser({fromhistory=true})
local config_arg = parser({fromhistory=true})
local config_types = parser({"bool", "int", "bool-or-int", "path", "expiry-date", "color"})
local contextlines_arg = parser({fromhistory=true})
local depth_arg = parser({fromhistory=true})
local diff_filter_arg = parser({fromhistory=true})
local difftool_extcmd_arg = parser({fromhistory=true})
local gpg_keyid_arg = parser({fromhistory=true})
local merge_recursive_options = parser():_addexarg({
    --ort and recursive
    "ours", "theirs",
    "ignore-space-change", "ignore-all-space", "ignore-space-at-eol", "ignore-cr-at-eol",
    "renormalize", "no-renormalize",
    "find-renames",
    { "find-renames="..placeholder_required_arg, "n", "" },
    { "rename-threshold="..placeholder_required_arg, "n", "" },
    "subtree",
    { "subtree="..mergesubtree_arg, "path", "" },
    --recursive
    "patience",
    { "diff-algorithm="..parser({"patience", "minimal", "histogram", "myers"}), "algorithm", "" },
    "no-renames",
})
local merge_strategies = parser({"resolve", "recursive", "ours", "octopus", "subtree"})
local number_commits_arg = parser({"10", "25", "50"})
local origin_arg = parser({fromhistory=true})
local person_arg = parser({fromhistory=true})
local pretty_formats_parser = parser({"oneline", "short", "medium", "full", "fuller", "reference", "email", "mboxrd", "raw", "format:"})
local receive_pack_arg = parser({fromhistory=true})
local regex_ignorelines_arg = parser({fromhistory=true})
local regex_refs_arg = parser({fromhistory=true})
local regex_worddiff_arg = parser({fromhistory=true})
local repo_arg = parser({fromhistory=true})
local shallow_since_arg = parser({fromhistory=true})
local summary_limit_arg = parser({fromhistory=true})
local untracked_files_arg = parser({"no", "normal", "all"})
local x_cmd_arg = parser({fromhistory=true})

local flag__colorequals = "--color="..parser({"always", "auto", "never"})
local flag__columnequals = "--column="..parser({"always", "auto", "never", "column", "row", "plain", "dense", "nodense"})
local flag__conflictequals = '--conflict='..parser({'merge', 'diff3', 'zdiff3'})
local flag__dateequals = "--date="..parser({"relative", "local", "iso", "iso-strict", "rfc", "short", "raw", "human", "unix", "default", "format:", "format-local:"})
local flag__ignore_submodules = "--ignore-submodules="..parser({"none", "untracked", "dirty", "all"})
local flag__whitespaceequals = "--whitespace="..parser({"nowarn", "warn", "fix", "error", "error-all"})

local flagex__abbrevequals = { '--abbrev='..abbrev_lengths, 'n', '' }
local flagex__cleanupequals = { opteq=true, "--cleanup="..parser({"strip", "whitespace", "verbatim", "scissors", "default"}), 'option', '' }
local flagex_c_config = { '-c'..config_arg, ' key=value', '设置配置变量' }
local flagex__config = { '--config'..config_arg, ' key=value', '' }
local flagex__depthdepth = { opteq=true, '--depth'..depth_arg, ' depth', '' }
local flagex__encoding = { opteq=true, '--encoding='..parser({fromhistory=true, "ASCII", "UTF-8", "UTF-16", "UTF-16BE", "UTF-16LE", "UTF-32", "UTF-32BE", "UTF-32LE"}), 'encoding', '' }
local flagex__gpgsignequals = { '--gpg-sign='..gpg_keyid_arg, 'keyid', '' }
local flagex_s_mergestrategy = { '-s'..merge_strategies, ' strategy', '使用给定的合并策略' }
local flagex__strategy = { opteq=true, '--strategy'..merge_strategies, ' strategy', '' }
local flagex_u_uploadpack = { '-u'..placeholder_required_arg, ' upload-pack', '--upload-pack 的快捷方式' }
local flagex__uploadpack = { opteq=true, '--upload-pack'..placeholder_required_arg, ' upload-pack', '' }
local flagex_X_strategyoption = { '-X'..merge_recursive_options, ' option', '将选项传递给合并策略' }
local flagex__strategyoption = { opteq=true, '--strategy-option'..merge_recursive_options, ' option', '' }

local custom_config_vars = {
    ["core.autocrlf"] = parser({"true", "false", "input"}),
    ["core.trustctime"] = parser({"true", "false"}),
    ["core.whitespace"] = parser({
        "cr-at-eol",
        "-cr-at-eol",
        "indent-with-non-tab",
        "-indent-with-non-tab",
        "space-before-tab",
        "-space-before-tab",
        "trailing-space",
        "-trailing-space"
    }),
    ["color."] = color_opts,
    ["mergetool.*.cmd"] = true,
    ["mergetool.trustExitCode"] = parser({"true", "false"}),
}

local function join_config_var_parser(name)
    local link_parser = custom_config_vars[name] or custom_config_vars[name:match("^([^.]+)%.$")]
    if type(link_parser) == "table" then
        return name..link_parser
    end
    return name
end

local cached_config_vars
local function get_cached_config_vars()
    if not cached_config_vars then
        cached_config_vars = {}

        local seen = {}

        local f = io.popen(git.make_command("help --config-for-completion"))
        if f then
            for line in f:lines() do
                if line and #line > 0 and line[-1] ~= "." then
                    local m = join_config_var_parser(line)
                    table.insert(cached_config_vars, m)
                    seen[line] = true
                end
            end
            f:close()
        end

        for m, value in pairs(custom_config_vars) do
            if value == true then -- Only when exact match!
                if not seen[m] then
                    table.insert(cached_config_vars, m)
                end
            end
        end

        table.sort(cached_config_vars, function(a, b)
            local an = (type(a) == "table") and a._key or a
            local bn = (type(b) == "table") and b._key or b
            return an < bn
        end)
    end
    return cached_config_vars
end

local function get_config_vars(_, _, _, _, user_data)
    local matches = w()
    local seen = {}

    local shared_data = user_data and user_data.shared_user_data or {}
    if shared_data.all or not shared_data.existing then
        for _, m in ipairs(get_cached_config_vars()) do
            table.insert(matches, m)
        end

        if shared_data.section then
            matches:map(function(name)
                name = name:match("^([^.]+)")
                if not seen[name] then
                    seen[name] = true
                    return name
                end
            end)
        end
    else
        local file_flags = shared_data.file_flags or ""
        local f = io.popen(git.make_command("config --list --name-only "..file_flags))
        if f then
            for line in f:lines() do
                if line and #line > 0 then
                    if shared_data.section then
                        line = line:match("^([^.]+)")
                    end
                    if line and not seen[line] then
                        local m = join_config_var_parser(line)
                        table.insert(matches, m)
                        seen[line] = true
                    end
                end
            end
            f:close()
        end
    end

    matches.nosort = true

    return matches
end

--------------------------------------------------------------------------------
-- Reusable groups of flags.

local help_flags = {
    "--help",
}

local log_flags = {
    concat_one_letter_flags=true,
    "--decorate", "--decorate="..parser({"short", "full", "auto", "no"}), "--no-decorate",
    "--decorate-refs="..regex_refs_arg, "--decorate-refs-exclude="..regex_refs_arg,
    "--source",
    "--mailmap", "--no-mailmap",
    "--full-diff",
    "--log-size",
    { "-n"..placeholder_required_arg, " number", "限制输出的提交数量" },
    { opteq=true, "--max-count="..placeholder_required_arg, "number", "" },
    { opteq=true, "--skip="..placeholder_required_arg, "number", "" },
    { opteq=true, "--since="..placeholder_required_arg, "date", "" },
    { opteq=true, "--after="..placeholder_required_arg, "date", "" },
    { opteq=true, "--until="..placeholder_required_arg, "date", "" },
    { opteq=true, "--before="..placeholder_required_arg, "date", "" },
    { opteq=true, "--author="..person_arg, "pattern", "" },
    { opteq=true, "--committer="..person_arg, "pattern", "" },
    { opteq=true, "--grep="..placeholder_required_arg, "pattern", "" },
    "--all-match",
    "--invert-grep",
    { "-i", "不区分大小写的正则匹配" },
    "--regexp-ignore-case",
    "--basic-regexp",
    { "-E", "使用扩展正则模式" },
    "--extended-regexp",
    { "-F", "使用固定字符串（不使用正则模式）" },
    "--fixed-strings",
    { "-P", "使用 Perl 兼容的正则模式" },
    "--perl-regexp",
    "--merges", "--no-merges",
    { opteq=true, "--min-parents="..placeholder_required_arg, "number", "" }, "--no-min-parents",
    { opteq=true, "--max-parents="..placeholder_required_arg, "number", "" }, "--no-max-parents",
    "--first-parent",
    "--not",
    "--all",
    { opteq=true, "--glob="..placeholder_required_arg, "glob", "" },
    { opteq=true, "--exclude="..placeholder_required_arg, "glob", "" },
    "--single-worktree",
    "--ignore-missing",
    "--merge",
}

local log_history_flags = {
    concat_one_letter_flags=true,
    "--follow",
    { "-L"..parser({fromhistory=true}), " start,end:file", "跟踪范围的演变" },
    { "-L:"..parser({fromhistory=true}), "funcname:file", "跟踪函数的演变" },
    { opteq=true, "--grep-reflog="..placeholder_required_arg, "pattern", "" },
    "--remove-empty",
    --"--reflog",
    --"--alternate-refs",
    "--bisect",
    "--stdin",
    "--cherry-mark",
    "--cherry-pick",
    "--left-only",
    "--right-only",
    "--cherry",
    { "-g", "遍历 reflog，而非提交祖先" },
    "--walk-reflogs",
    "--boundary",
    "--simplify-by-decoration",
    "--show-pulls",
    "--full-history",
    "--dense",
    "--sparse",
    "--simplify-merges",
    "--ancestry-path",
    "--date-order",
    "--author-date-order",
    "--topo-order",
    "--reverse",
}

local commit_formatting_flags = {
    concat_one_letter_flags=true,
    "--pretty",
    "--pretty="..pretty_formats_parser,
    "--format="..pretty_formats_parser,
    "--oneline",
    "--abbrev-commit",
    "--no-abbrev-commit",
    flagex__encoding,
    { "--expand-tabs="..placeholder_required_arg, "n", "" },
    "--expand-tabs",
    "--no-expand-tabs",
    "--notes",
    { "--notes="..placeholder_required_arg, "ref", "" },
    "--no-notes",
    "--first-parent",
    flag__dateequals,
    "--parents",
    "--children",
    "--left-right",
    "--graph",
    "--show-linear-break",
    { "--show-linear-break="..placeholder_required_arg, "barrier", "" },
}

local diff_flags = {
    concat_one_letter_flags=true,
    "--no-index",
    "--cached",
    "--staged",
    "--merge-base",
    { "-p", "生成补丁（这是默认行为）" },
    { "-u", "生成补丁（这是默认行为）" },
    "--patch",
    { "-s", "抑制差异输出" },
    "--no-patch",
    { "-U", "n", "生成包含 <n> 行上下文的差异" },
    "--unified",
    { opteq=true, "--output="..files_parser },
    { opteq=true, "--output-indicator-new="..placeholder_required_arg, "char", "" },
    { opteq=true, "--output-indicator-old="..placeholder_required_arg, "char", "" },
    { opteq=true, "--output-indicator-context="..placeholder_required_arg, "char", "" },
    "--raw",
    "--patch-with-raw",
    "--indent-heuristic",
    "--no-indent-heuristic",
    "--minimal",
    "--patience",
    "--histogram",
    { opteq=true, "--anchored="..placeholder_required_arg, "text", "" },
    { opteq=true, "--diff-algorithm="..parser({"patience", "minimal", "histogram", "default", "myers"}) },
    "--stat",
    { "--stat="..placeholder_required_arg, "width[,name-width[,count]]", "" },
    "--compact-summary",
    "--numstat",
    "--shortstat",
    { "-X", "--dirstat 的快捷方式" },
    "--dirstat",
    "--dirstat="..parser({"changes", "lines", "files", "cumulative", "noncumulative", "{LIMIT_PERCENT}"}),
    "--cumulative",
    "--dirstat-by-file",
    "--dirstat-by-file="..parser({"cumulative", "noncumulative", "{LIMIT_PERCENT}"}),
    "--summary",
    "--patch-with-stat",
    { "-z", "使用 NUL 作为输出字段终止符" },
    "--name-only",
    "--name-status",
    "--color",
    flag__colorequals,
    "--no-color",
    "--color-moved",
    "--color-moved="..parser({"no", "default", "plain", "blocks", "zebra", "dimmed-zebra"}),
    "--no-color-moved",
    "--color-moved-ws="..parser({"no", "ignore-space-at-eol", "ignore-space-change", "ignore-all-space", "allow-indentation-change"}),
    "--no-color-moved-ws",
    "--word-diff",
    "--word-diff="..parser({"color", "plain", "porcelain", "none"}),
    { opteq=true, "--word-diff-regex="..regex_worddiff_arg },
    "--color-words", --"--color-words="..regex_worddiff_arg,
    "--no-renames",
    "--rename-empty",
    "--no-rename-empty",
    "--check",
    "--ws-error-highlight="..parser({"context", "old", "new", "all", "default"}),
    "--full-index",
    "--binary",
    "--abbrev",
    flagex__abbrevequals,
    { "-B", "[n][/m]", "将重写分解为删除+创建" },
    "--break-rewrites",
    { "--break-rewrites="..placeholder_required_arg, "[n]/[/m]", "" },
    { "-M", "[n]", "检测重命名；<n> 是阈值百分比" },
    "--find-renames",
    { "--find-renames="..placeholder_required_arg, "n", "" },
    { "-C", "[n]", "检测复制；<n> 是阈值百分比" },
    "--find-copies",
    { "--find-copies="..placeholder_required_arg, "n", "" },
    "--find-copies-harder",
    { "-D", "--irreversible-delete 的快捷方式" },
    "--irreversible-delete",
    { "-l"..placeholder_required_arg, " n", "限制昂贵的重命名/复制检查" },
    { opteq=true, "--diff-filter="..diff_filter_arg, "[ACDMRTUXB...*]", "" },
    --{ "-S", "string", "" },
    --{ "-G", "regex", "" },
    { opteq=true, "--find-object="..placeholder_required_arg, "objid", "" },
    "--pickaxe-all", "--pickaxe-regex",
    { "-O", " file", "控制输出中文件的顺序" },
    { opteq=true, "--skip-to="..files_parser },
    { opteq=true, "--rotate-to="..files_parser },
    { "-R", "反转差异输入" },
    "--relative",
    "--relative="..dirs_parser,
    "--no-relative",
    { "-a", "将所有文件视为文本" },
    "--text",
    "--ignore-cr-at-eol",
    "--ignore-space-at-eol",
    { "-b", "忽略空白数量的变化" },
    "--ignore-space-change",
    { "-w", "比较文件时忽略空白" },
    "--ignore-all-space",
    "--ignore-blank-lines",
    { "-I", " regex", "忽略所有行中匹配正则的更改" },
    { "--ignore-matching-lines="..regex_ignorelines_arg, "regex", "" },
    { "--inter-hunk-context="..contextlines_arg, "numlines", "" },
    { "-W", "将整个函数显示为上下文行" },
    "--function-context",
    "--exit-code",
    "--quiet",
    "--ext-diff", "--no-ext-diff",
    "--text-conv", "--no-text-conv",
    "--ignore-submodules",
    flag__ignore_submodules,
    "--submodule", "--submodule="..parser({"short", "log", "diff"}),
    { opteq=true, "--src-prefix="..parser({fromhistory=true}), "prefix", "" },
    { opteq=true, "--dst-prefix="..parser({fromhistory=true}), "prefix", "" },
    "--no-prefix",
    { opteq=true, "--line-prefix="..parser({fromhistory=true}), "prefix", "" },
    "--ita-invisible-in-index",
    { "-1", "将工作树与 'base' 比较" },
    "--base",
    { "-2", "将工作树与 'our branch' 比较" },
    "--ours",
    { "-3", "将工作树与 'their branch' 比较" },
    "--theirs",
    { "-0", "省略未合并条目的差异输出" },
    { opteq=true, "--diff-merges="..parser({"off", "none", "on", "first-parent", "1", "separate", "m", "combined", "c", "dense-combined", "cc"}) },
    "--no-diff-merges",
    { "-c", "显示合并差异" },
    "--cc",
    "-m",
    "-t",
    "--combined-all-paths",
}

local fetch_flags = {
    concat_one_letter_flags=true,
    '--all',
    { '-a', '--append 的同义词' },
    '--append',
    '--atomic',
    { opteq=true, '--depth='..placeholder_required_arg, 'depth', '' },
    { opteq=true, '--deepen='..placeholder_required_arg, 'depth', '' },
    { opteq=true, '--shallow-since='..shallow_since_arg, 'date', '' },
    { opteq=true, '--shallow-exclude='..placeholder_required_arg, 'rev', '' },
    '--unshallow',
    '--update-shallow',
    { opteq=true, '--negotiation-tip='..placeholder_required_arg, 'commit|glob', '' },
    '--negotiate-only',
    '--dry-run',
    { '-f', '--force 的同义词' },
    '--force',
    { '-k', '保留下载的 pack' },
    '--keep',
    '--prefetch',
    { '-p', '--prune 的同义词' },
    '--prune',
    '--no-tags',
    { opteq=true, '--refmap='..placeholder_required_arg, 'refspec', '' },
    { '-t', '同时获取标签' },
    '--tags',
    { '-j', '获取的并行作业数' },
    { opteq=true, '--jobs='..placeholder_required_arg, 'n', '' },
    '--set-upstream',
    flagex__uploadpack,
    --'--progress',
    '--no-progress',
    --'-o'..placeholder_required_arg, '--server-option='..placeholder_required_arg,
    '--show-forced-updates',
    '--no-show-forced-updates',
    { '-4', '仅使用 IPv4 地址' },
    '--ipv4',
    { '-6', '仅使用 IPv6 地址' },
    '--ipv6',
}

local merge_flags_common = {
    concat_one_letter_flags=true,
    flagex_s_mergestrategy,
    flagex__strategy,
    flagex_X_strategyoption,
    flagex__strategyoption,
    { "-S", "GPG 签名合并结果提交" },
    "--gpg-sign", "--no-gpg-sign",
    flagex__gpgsignequals,
    --"--verify",
    "--no-verify",
    "--verify-signatures", "--no-verify-signatures",
    --"--progress",
    "--no-progress",
    "--autostash", "--no-autostash",
    { "-n", "合并结束时显示差异统计" },
    "--stat", "--no-stat",
}

local merge_flags = {
    concat_one_letter_flags=true,
    "--continue",
    "--abort",
    "--quit",
    { "-i", "--interactive 的快捷方式" },
    "--interactive",
    { "-q", "静默" },
    "--quiet",
    { "-v", "详细输出" },
    "--verbose",
    "--rerere-autoupdate", "--no-rerere-autoupdate",
}

local stash_save_flags = {
    concat_one_letter_flags=true,
    { "-p", "交互式从差异中选择代码块" },
    "--patch",
    { "-S", "仅暂存当前已暂存的更改" },
    "--staged",
    { "-k", "保留已添加到索引的更改" },
    "--no-keep-index", "--keep-index",
    { "-u", "同时暂存所有未跟踪的文件" },
    "--include-untracked",
    { "-a", "同时暂存所有被忽略和未跟踪的文件" },
    "--all",
    { "-m"..placeholder_required_arg, " msg", "使用给定的消息作为暂存描述" },
    { opteq=true, "--message"..placeholder_required_arg, " msg", "" },
    { "-q", "静默" },
    "--quiet",
}

local track_flags = {
    concat_one_letter_flags=true,
    { '-t', '为新分支设置上游跟踪' },
    '--track',
    '--track='..parser({'direct', 'inherit'}),
    '--no-track',
}

local untracked_flags = {
    { "-u", "[mode]", "递归显示未跟踪的文件" },
    { "-uno", "不显示未跟踪的文件" },
    { "-unormal", "显示未跟踪的文件和目录" },
    { "-uall", "递归显示未跟踪的文件" },
    "--untracked-files",
    "--untracked-files="..untracked_files_arg,
}

--------------------------------------------------------------------------------
-- Command parsers.

local add_parser = parser()
:setendofflags()
:addarg({add_spec_generator, hint=argexpected.."pathspec"}):loop()
:_addexflags({
    concat_one_letter_flags=true,
    help_flags,
    { "-n", "不实际添加文件" },
    "--dry-run",
    { "-v", "详细输出" },
    "--verbose",
    { "-i", "交互式添加文件" },
    "--interactive",
    { "-p", "交互式从差异中选择代码块" },
    "--patch",
    { "-e", "在编辑器中打开与索引的差异，然后应用" },
    "--edit",
    { "-f", "强制添加被忽略的文件" },
    "--force",
    { "-u", "更新已存在的索引条目" },
    "--update",
    "--renormalize",
    { "-N", "记录索引条目但不含内容" },
    "--intent-to-add",
    { "-A", "更新全部；添加、修改和删除索引条目以匹配工作树" },
    "--all",
    "--no-all",
    "--ignore-removal",
    "--no-ignore-removal",
    "--refresh",
    "--ignore-errors",
    "--ignore-missing",
    "--sparse",
    { opteq=true, "--chmod="..parser({"+x", "-x"}) },
    { opteq=true, "--pathspec-from-file="..files_parser, "file", "" },
    "--pathspec-file-nul",
})

local apply_parser = parser()
:setendofflags()
:_addexflags({
    concat_one_letter_flags=true,
    help_flags,
    "--stat",
    "--numstat",
    "--summary",
    "--check",
    "--index",
    "--cached",
    "--intent-to-add",
    { "-3", "尝试三路合并" },
    "--3way",
    { opteq=true, "--build-fake-ancestor="..files_parser, "tmpfile", "" },
    { "-R", "反向应用补丁" },
    "--reverse",
    "--reject",
    { "-z", "使用 NUL 终止格式配合 --numstat" },
    { "-p", "n", "移除 <n> 个前导路径组件" },
    { "-C", "n", "确保至少 <n> 行上下文" },
    "--unidiff-zero",
    "--apply",
    "--no-add",
    "--allow-binary-replacement", "--binary",
    { opteq=true, "--exclude="..files_parser, "glob", "" },
    { opteq=true, "--include="..files_parser, "glob", "" },
    "--ignore-space-change", "--ignore-whitespace",
    flag__whitespaceequals,
    "--inaccurate-eof",
    { "-v", "详细输出" },
    "--verbose",
    { "-q", "静默；抑制 stderr（无状态或进度）" },
    "--quiet",
    "--recount",
    { opteq=true, "--directory="..dirs_parser, "dir", "" },
    "--unsafe-paths",
    "--allow-empty",
})

local blame_parser = parser()
:setendofflags()
:addarg({file_matches, hint=argexpected.."file"})
:_addexflags({
    concat_one_letter_flags=true,
    help_flags,
    "--incremental",
    { "-b", "为边界提交显示空白 SHA1" },
    "--root",
    "--show-stats",
    --"--progress",
    "--no-progress",
    "--score-debug",
    { "-f", "在原始提交中显示文件名" },
    "--show-name",
    { "-n", "在原始提交中显示行号" },
    "--show-number",
    { "-p", "使用 porcelain 格式" },
    "--porcelain",
    "--line-porcelain",
    { "-c", "使用 'git annotate' 输出格式" },
    { "-s", "抑制作者名称和时间戳" },
    { "-e", "显示作者邮箱而非名称" },
    "--show-email",
    { "-w", "比较文件时忽略空白" },
    "--ignore-rev",
    { opteq=true, "--ignore-revs-file="..files_parser, "file", "" },
    "--color-lines",
    "--color-by-age",
    "--minimal",
    { "-S"..files_parser, " revs-file", "使用 revs-file 中的修订版本" },
    { opteq=true, "--contents="..files_parser, "file", "" },
    { "-C", "[n]", "检测复制；<n> 是阈值百分比" },
    { "-M", "[n]", "检测重命名；<n> 是阈值百分比" },
    { "-L"..parser({fromhistory=true}), " start,end", "仅注释范围" },
    { "-L:"..parser({fromhistory=true}), "funcname", "仅注释函数" },
    "--abbrev",
    flagex__abbrevequals,
    { "-l", "显示长修订版本" },
    { "-t", "显示原始时间戳" },
    { opteq=true, "--reverse="..placeholder_required_arg, "rev..rev", "" },
})
:_addexflags(commit_formatting_flags)

local branch_parser = parser()
:setendofflags()
:_addexflags({
    concat_one_letter_flags=true,
    help_flags,
    { "-v", "详细输出" },
    "--verbose",
    { "-vv", "额外详细输出" },
    { "-q", "静默；抑制非错误消息" },
    "--quiet",
    track_flags,
    "--set-upstream",
    { "-u", "设置上游跟踪信息" },
    "--set-upstream-to", "--set-upstream-to="..placeholder_required_arg,
    "--unset-upstream",
    "--color", flag__colorequals, "--no-color",
    { "-r", "列出或删除远程跟踪分支" },
    "--remotes",
    { opteq=true, "--contains"..placeholder_required_arg, " commit", "" },
    { opteq=true, "--no-contains"..placeholder_required_arg, " commit", "" },
    "--abbrev", flagex__abbrevequals, "--no-abbrev",
    { "-a", "列出本地和远程跟踪分支" },
    "--all",
    { "-d"..branches_args, " branch [...]", "删除一个或多个命名分支" },
    { opteq=true, "--delete"..parser({branches}):loop(1), " branch [...]", "" },
    { "-D"..branches_args, " branch [...]", "--delete --force 的快捷方式" },
    { "-m", "移动或重命名分支" },
    "--move",
    { "-M", "--move --force 的快捷方式" },
    { "-c", "复制分支及其配置和 reflog" },
    "--copy",
    { "-C", "--copy --force 的快捷方式" },
    { "-i", "不区分大小写的排序/筛选" },
    "--ignore-case",
    { "-l", "列出分支" },
    "--list",
    "--show-current",
    "--create-reflog",
    "--edit-description",
    { "-f", "强制；参见 --force 的帮助" },
    "--force",
    { opteq=true, "--merged"..placeholder_required_arg, " commit", "" },
    { opteq=true, "--no-merged"..placeholder_required_arg, " commit", "" },
    "--column",
    flag__columnequals,
    "--no-column",
    { "--sort="..placeholder_required_arg, "key", "" },
    { opteq=true, "--points-at", " object", "" },
    { opteq=true, "--format"..placeholder_required_arg, " format", "" },
})

local catfile_parser = parser()
:setendofflags()
:_addexflags({
    concat_one_letter_flags=true,
    help_flags,
    { '-t', '显示对象类型而非内容' },
    { '-s', '显示对象大小而非内容' },
    { '-e', '如果对象存在且有效则退出码为 0' },
    { '-p', '根据类型美化打印对象内容' },
    '--textconv',
    '--filters',
    { opteq=true, '--path='..files_parser, 'path', '' },
    '--batch',
    { '--batch='..batch_format_arg, 'format', '' },
    '--batch-check',
    { '--batch-check='..batch_format_arg, 'format', '' },
    '--batch-all-objects',
    '--buffer',
    '--unordered',
    '--allow-unknown-type',
    '--follow-symlinks',
})

local checkout_arg_hints_new_branch = {"start-point"}
local checkout_arg_hints_normal = {"branch", "pathspec"}
local function checkout_onarg1(_, _, _, _, user_data)
    if user_data and user_data.shared_user_data then
        user_data.shared_user_data.has_arg1 = true
    end
end
local function checkout_onflag(arg_index, word, _, _, user_data)
    if user_data and arg_index == 0 then
        if word == "-b" or word == "-B" or word == "--orphan" then
            user_data.new_branch = true
        end
    end
end
local function checkout_arg_hint(arg_index, _, _, _, user_data)
    local h
    if user_data and user_data.new_branch then
        h = checkout_arg_hints_new_branch[arg_index]
    else
        h = checkout_arg_hints_normal[arg_index]
    end
    if h then
        return hintpfx(arg_index ~= 1)..h
    end
end

local checkout_parser = parser()
:setendofflags()
:addarg({checkout_spec_generator, hint=checkout_arg_hint, onarg=checkout_onarg1})
:addarg({file_matches, hint=checkout_arg_hint}):loop(2)
:_addexflags({
    concat_one_letter_flags=true,
    onarg=checkout_onflag,
    help_flags,
    { '-q', '静默；抑制反馈消息' },
    '--quiet',
    --'--progress',
    '--no-progress',
    { '-b'..placeholder_required_arg, ' new-branch', '创建新分支' },
    { '-B'..placeholder_required_arg, ' new-branch', '创建或重置分支' },
    { '-l', '创建新分支的 reflog'},
    { '-d', '检出一个提交（分离头指针）' },
    '--detach',
    track_flags,
    '--guess', '--no-guess',
    { opteq=true, '--orphan'..placeholder_required_arg, ' new-branch', '' },
    { '-2', '检出我们版本的未合并文件' },
    '--ours',
    { '-3', '检出他们版本的未合并文件' },
    '--theirs',
    { '-f', '即使存在本地更改也强制切换' },
    '--force',
    { '-m', '合并本地更改' },
    '--merge',
    --'--overwrite-ignore',
    '--no-overwrite-ignore',
    '--recurse-submodules', '--no-recurse-submodules',
    --'--overlay',
    '--no-overlay',
    flag__conflictequals,
    { '-p', '交互式从差异中选择代码块' },
    '--patch',
    '--ignore-skip-worktree-bits',
    '--ignore-other-worktrees',
    { '--pathspec-from-file='..files_parser, "file", "" },
    '--pathspec-file-nul',
    { '--'..parser({checkout_dashdash}):loop(), " pathspec", "" },
})

local cherrypick_parser = parser()
:setendofflags()
:_addexflags({
    concat_one_letter_flags=true,
    help_flags,
    { "-e", "提交前编辑消息" },
    "--edit",
    flagex__cleanupequals,
    { "-x", "追加面包屑消息" },
    { hide=true, "-r" },
    { "-m"..placeholder_required_arg, " parent-num", "--mainline 的同义词" },
    { opteq=true, "--mainline"..placeholder_required_arg, " parent-num", "" },
    { "-n", "--no-commit 的同义词" },
    "--no-commit",
    { "-s", "添加 'Signed-off-by' 结尾" },
    "--signoff",
    { "-S", "GPG-sign commits" },
    "--gpg-sign", "--no-gpg-sign",
    flagex__gpgsignequals,
    "--ff",
    "--allow-empty",
    "--allow-empty-message",
    "--keep-redundant-commits",
    flagex_s_mergestrategy,
    flagex__strategy,
    flagex_X_strategyoption,
    flagex__strategyoption,
    "--rerere-autoupdate", "--no-rerere-autoupdate",
    "--continue",
    "--skip",
    "--quit",
    "--abort",
})

local clone_parser = parser()
:setendofflags()
:addarg({file_matches, hint=argexpected.."repository"})
:addarg({file_matches, hint=argoptional.."directory"})
:_addexflags({
    concat_one_letter_flags=true,
    help_flags,
    { opteq=true, '--template'..dirs_parser, ' dir', '' },
    { '-l', '从本地仓库克隆（通过符号链接）' },
    '--local',
    { '-s', '从本地仓库克隆（通过 alternates）' },
    '--shared',
    '--no-hardlinks',
    { '-q', '静默；抑制进度反馈' },
    '--quiet',
    { '-v', '详细输出' },
    '--verbose',
    { '-n', '克隆后不检出 HEAD' },
    '--no-checkout',
    --'--progress',
    --'--server-option='..placeholder_required_arg,
    '--reject-shallow', '--no-reject-shallow',
    '--bare',
    '--sparse',
    { opteq=true, '--filter='..clone_filter_arg, 'filter-spec', '' },
    '--mirror',
    { '-o'..origin_arg, '设置 origin 名称' },
    { opteq=true, '--origin='..origin_arg },
    { '-b'..placeholder_required_arg, ' name', '克隆后检出名称' },
    { opteq=true, '--branch'..placeholder_required_arg, ' name', '' },
    flagex_u_uploadpack,
    flagex__uploadpack,
    { opteq=true, '--reference'..files_parser, ' repo', '' },
    { opteq=true, '--reference-if-able'..files_parser, 'repo', '' },
    '--dissociate',
    '--remote-submodules', '--no-remote-submodules',
    { opteq=true, '--separate-git-dir='..dirs_parser, 'dir', '' },
    flagex_c_config,
    flagex__config,
    flagex__depthdepth,
    { opteq=true, '--shallow-since='..shallow_since_arg, 'date', '' },
    { opteq=true, '--shallow-exclude='..placeholder_required_arg, 'rev', '' },
    '--single-branch', '--no-single-branch',
    '--no-tags',
    '--recurse-submodules',
    { '--recurse-submodules='..files_parser, 'pathspec', '' },
    '--shallow-submodules', '--no-shallow-submodules',
    { '-j'..placeholder_required_arg, ' n', '子模块的获取作业数' },
    { opteq=true, '--jobs'..placeholder_required_arg, ' n', '' },
})

local commit_parser = parser()
:setendofflags()
:_addexflags({
    concat_one_letter_flags=true,
    help_flags,
    { "-a", "自动暂存已修改/删除的文件" },
    "--all",
    { "-p", "交互式从差异中选择代码块" },
    "--patch",
    { "-C"..placeholder_required_arg, " commit", "重用现有提交的消息/信息" },
    { opteq=true, "--reuse-message="..placeholder_required_arg, "commit", "" },
    { "-c"..placeholder_required_arg, " commit", "重用并编辑现有提交的消息/信息" },
    { opteq=true, "--reedit-message="..placeholder_required_arg, "commit", "" },
    { opteq=true, "--fixup="..parser({'amend:', 'reword:'}) },
    { opteq=true, "--squash="..placeholder_required_arg, 'commit', '' },
    "--reset-author",
    "--short",
    "--branch",
    "--porcelain",
    "--long",
    { "-z", "使用 NUL 而非 LF 终止条目" },
    "--null",
    { "-F"..files_parser, " file", "从给定文件获取提交消息" },
    { opteq=true, "--file="..files_parser, "file", "" },
    { opteq=true, "--author="..person_arg, "author", "" },
    { opteq=true, "--date="..placeholder_required_arg, "date", "" },
    { "-m"..placeholder_required_arg, " msg", "使用给定的消息作为提交消息" },
    { opteq=true, "--message="..placeholder_required_arg, "msg", "" },
    { "-t"..files_parser, " file", "指定提交消息模板文件" },
    { opteq=true, "--template="..files_parser, "file", "" },
    { "-s", "添加 'Signed-off-by' 结尾" },
    "--signoff", "--no-signoff",
    { opteq=true, "--trailer"..commit_trailer_arg, " token[:value]", "" },
    --"--verify",
    { "-n", "绕过验证钩子" },
    "--no-verify",
    "--allow-empty",
    "--allow-empty-message",
    flagex__cleanupequals,
    { "-e", "交互式编辑提交消息" },
    "--edit", "--no-edit",
    "--amend",
    "--no-post-rewrite",
    { "-i", "--include 的快捷方式" },
    "--include",
    { "-o", "--only 的快捷方式" },
    "--only",
    { opteq=true, '--pathspec-from-file='..files_parser, 'file', '' },
    '--pathspec-file-nul',
    untracked_flags,
    { "-v", "详细输出；显示暂存的差异" },
    { "-vv", "额外详细输出；包含工作差异" },
    "--verbose",
    { "-q", "静默；抑制摘要消息" },
    "--quiet",
    "--dry-run",
    "--status",
    "--no-status",
    { "-S", "GPG-sign commits" },
    "--gpg-sign",
    flagex__gpgsignequals,
    "--no-gpg-sign",
    "--",
})

local config_parser
do -- Mitigate "too many local variables" Lua error.
    local function config_subcommand_onarg(arg_index, word, word_index, line_state, user_data)
        local shared_data = user_data and user_data.shared_user_data or {}
        if arg_index == 0 then
            if word == "--global" or word == "--no-global" or
                    word == "--system" or word == "--no-system" or
                    word == "--local" or word == "--no-local" or
                    word == "--worktree" or word == "--no-worktree" or
                    word == "-f" or word == "--file" or word == "--no-file" or
                    word == "--blob" or word == "--no-file" then
                local ff = shared_data.file_flags or ""
                if word == "-f" or word == "--file" or word == "--blob" then
                    local next_word = line_state:getword(word_index + 1)
                    if next_word and next_word ~= "" then
                        ff = ff..string.format(' %s "%s"', word, next_word)
                    end
                else
                    ff = ff.." "..word
                end
                shared_data.file_flags = ff
            end
        elseif arg_index == 1 then
            if word == "set" then
                shared_data.all = true
            elseif word == "get" or
                    word == "unset" or
                    word == "rename-section" or
                    word == "remove-section" then
                shared_data.existing = true
            end
            if word == "rename-section" or
                    word == "remove-section" then
                shared_data.section = true
            end
        end
    end

    local function config_onarg(arg_index, word, word_index, line_state, user_data)
        if arg_index == 0 then
            local shared_data = user_data and user_data.shared_user_data or {}
            if word == "--add" then
                shared_data.all = true
            elseif word:match("^%-%-get") or
                    word:match("^%-%-unset") or
                    word == "--replace-all" or
                    word == "--rename-section" or
                    word == "--remove-section" then
                shared_data.existing = true
            end
            if word == "--rename-section" or word == "--remove-section" then
                shared_data.section = true
            end
        end
        config_subcommand_onarg(arg_index, word, word_index, line_state, user_data)
    end

    local config_file_flags = {
        { "--global" },
        { "--no-global" },
        { "--system" },
        { "--no-system" },
        { "--local" },
        { "--no-local" },
        { "--worktree" },
        { "--no-worktree" },
        { "-f"..files_parser, " config-file", "使用给定的配置文件" },
        { opteq=true, "--file"..files_parser, " config-file", "" },
        { "--no-file" },
        { opteq=true, "--blob"..placeholder_required_arg, " blob", "" },
        { "--no-blob" },
    }

    local config_display_flags = {
        { "-z", "使用 NUL 分隔值" },
        { "--null" },
        { "--no-null" },
        { "--name-only" },
        { "--no-name-only" },
        { "--show-origin" },
        { "--no-show-origin" },
        { "--show-scope" },
        { "--no-show-scope" },
        { "--show-names" },
        { "--no-show-names" },
    }

    local config_default_flag = {
        { opteq=true, "--default"..placeholder_required_arg, " value", "" },
        { "--no-default" },
    }

    local config_comment_flag = {
        { opteq=true, "--comment"..placeholder_required_arg, " value", "" },
        { "--no-comment" },
    }

    local config_value_flag = {
        { opteq=true, "--value"..placeholder_required_arg, " value", "" },
        { "--fixed-value" },
    }

    local config_type_flag = {
        { "-t"..config_types, " type", "值为给定类型" },
        { opteq=true, "--type="..config_types, "type", "" },
        -- TODO:  should the --bool and etc flags go here as well?
    }

    local config_list_parser = parser()
    :_addexflags({
        onarg=config_subcommand_onarg,
        help_flags,
        config_file_flags,
        config_display_flags,
        "--includes", "--no-includes",
    })
    :nofiles()

    local config_get_parser = parser()
    :_addexflags({
        onarg=config_subcommand_onarg,
        help_flags,
        config_file_flags,
        config_display_flags,
        "--includes", "--no-includes",
        "--all",
        "--regexp",
        config_value_flag,
        config_default_flag,
    })
    :addarg(get_config_vars)
    :nofiles()

    local config_set_parser = parser()
    :_addexflags({
        onarg=config_subcommand_onarg,
        help_flags,
        config_file_flags,
        config_type_flag,
        "--all",
        config_value_flag,
    })
    :addarg(get_config_vars)
    :addarg()
    :nofiles()

    local config_unset_parser = parser()
    :_addexflags({
        onarg=config_subcommand_onarg,
        help_flags,
        config_file_flags,
        "--all",
        config_value_flag,
    })
    :addarg(get_config_vars)
    :nofiles()

    local config_rename_section_parser = parser()
    :_addexflags({
        onarg=config_subcommand_onarg,
        help_flags,
        config_file_flags,
    })
    :addarg(get_config_vars)
    :addarg()
    :nofiles()

    local config_remove_section_parser = parser()
    :_addexflags({
        onarg=config_subcommand_onarg,
        help_flags,
        config_file_flags,
    })
    :addarg(get_config_vars)
    :nofiles()

    local config_edit_parser = parser()
    :_addexflags({
        help_flags,
        config_file_flags,
    })
    :nofiles()

    local config_subcommands_index = { "list", "get", "set", "unset", "rename-section", "remove-section", "edit" }
    for _, name in ipairs(config_subcommands_index) do
        config_subcommands_index[name] = true
    end

    local function config_display_filter()
        if clink.ondisplaymatches then
            clink.ondisplaymatches(function(matches)
                for _, m in ipairs(matches) do
                    if config_subcommands_index[m.match] then
                        m.type = "cmd"
                    end
                end
                return matches
            end)
        end
        return {}
    end

    config_parser = parser()
    :setendofflags()
    :_addexarg({
        onarg=config_onarg,
        config_display_filter,
        { "list"..config_list_parser, "列出配置变量" },
        { "get"..config_get_parser, " name", "获取配置变量" },
        { "set"..config_set_parser, " name value", "设置配置变量" },
        { "unset"..config_unset_parser, " name", "取消设置配置变量" },
        { "rename-section"..config_rename_section_parser, " old-name new-name", "重命名节" },
        { "remove-section"..config_remove_section_parser, " name", "移除节" },
        { "edit"..config_edit_parser, "在编辑器中打开" },
        get_config_vars,
        hint=argexpected.."name",
    })
    :_addexflags({
        concat_one_letter_flags=true,
        onarg=config_onarg,
        help_flags,
        config_file_flags,
        config_display_flags,
        -- Action
        { "--get", " name [value-pattern]", "" },
        { "--get-all", " key [value-pattern]", "" },
        { "--get-regexp", " name-regex [value-pattern]", "" },
        { "--get-urlmatch", " section[.var] URL", "" },
        { "--replace-all", " name value [value-pattern]", "" },
        { "--add", " name value", "" },
        { "--unset", " name [value-pattern]", "" },
        { "--unset-all", " name [value-pattern]", "" },
        { "--rename-section", " old-name new-name", "" },
        { "--remove-section", " name", "" },
        { "-l", "列出变量及其值" },
        "--list",
        { "-e", "为指定配置文件打开编辑器" },
        "--edit",
        { "--get-color", " slot [default]", "" },
        { "--get-colorbool", " slot [stdout-is-tty]", "" },
        -- Type
        config_type_flag,
        "--no-type",
        "--bool",
        "--int",
        "--bool-or-int",
        "--bool-or-str",
        "--path",
        "--expiry-date",
        -- Other
        config_default_flag,
        config_comment_flag,
        "--fixed-value", "--no-fixed-value",
        "--includes", "--no-includes",
    })
end

local diff_parser = parser()
:setendofflags()
:addarg({log_spec_generator, hint=argoptional.."commit or path"}):loop()
:_addexflags(diff_flags)
:_addexflags(help_flags)
:_addexflags({"--"..parser({file_matches, hint=argoptional.."pathspec"}):loop()})

local difftool_parser = parser()
:setendofflags()
:addarg({file_matches, hint=argoptional.."commit or path"}):loop()
:_addexflags({
    concat_one_letter_flags=true,
    help_flags,
    '-d', '--dir-diff',
    '-y', '--no-prompt', '--prompt',
    { '--rotate-to='..files_parser, 'file', '' },
    { '--skip-to='..files_parser, 'file', '' },
    { '-t'..placeholder_required_arg, ' tool', '' },                    -- TODO: complete tool (take from config)
    { opteq=true, '--tool='..placeholder_required_arg, 'tool', '' },    -- TODO: complete tool (take from config)
    '--tool-help',
    '--symlinks', '--no-symlinks',
    { '-x'..difftool_extcmd_arg, ' command', '' },
    { opteq=true, '--extcmd='..difftool_extcmd_arg, 'command', '' },
    '-g', '--gui', '--no-gui',
    '--trust-exit-code', '--no-trust-exit-code',
})
:_addexflags({"--"..parser({file_matches, hint=argoptional.."pathspec"}):loop()})

local fetch_parser = parser()
:setendofflags()
:addarg({remotes, hint=argoptional.."repository" })
:_addexflags({
    concat_one_letter_flags=true,
    help_flags,
    '--write-fetch-head', '--no-write-fetch-head',
    '--multiple',
    '--auto-maintenance', '--no-auto-maintenance',
    --'--auto-gc', '--no-auto-gc',
    '--no-write-commit-graph',
    { '-P', '--prune-tags 的同义词' },
    '--prune-tags',
    { '-n', '--no-tags 的同义词' },
    '--recurse-submodules',
    '--recurse-submodules='..parser({'yes', 'on-demand', 'no'}),
    '--no-recurse-submodules',
    { opteq=true, '--submodule-prefix='..placeholder_required_arg, 'prefix', '' },
    --'--recurse-submodules-default='..parser({'yes', 'on-demand'}),
    { hide=true, '-u' },                -- Only for internal use by git itself.
    { hide=true, '--update-head-ok' },  -- Only for internal use by git itself.
    { '-q', '静默；抑制反馈消息' },
    '--quiet',
    { '-v', '详细输出' },
    '--verbose',
    '--stdin',
})
:_addexflags(fetch_flags)

local help_parser = parser()
:setendofflags()
:_addexflags({
    concat_one_letter_flags=true,
    help_flags,
    { "-a",                             "打印所有可用命令" },
    { "--all",                          "打印所有可用命令" },
    --"--verbose",
    { "-c",                             "列出所有可用的配置变量" },
    { "--config",                       "列出所有可用的配置变量" },
    { "-g",                             "打印 git 概念指南列表" },
    { "--guides",                       "打印 git 概念指南列表" },
    --"-i",
    --"--info",
    { "-m",                             "以 man 格式显示命令的手册页" },
    { "--man",                          "以 man 格式显示命令的手册页" },
    { "-w",                             "以 HTML 格式显示命令的手册页" },
    { "--web",                          "以 HTML 格式显示命令的手册页" },
    { "--aliases",                      "在 --all 中显示别名（默认行为）" },
    { "--no-aliases",                   "不在 --all 中显示别名" },
    { "--external-commands",            "在 --all 中显示外部命令（默认行为）" },
    { "--no-external-commands",         "不在 --all 中显示外部命令" },
    { "--user-interfaces",              "打印面向用户的仓库、命令和文件接口列表" },
    { "--developer-interfaces",         "打印文件格式、协议和其他开发者接口列表" },
})
if help_parser.setdelayinit then
    help_parser:addarg({delayinit=function (argmatcher) -- luacheck: no unused args
        local matches = all_commands() or {}
        local guides = concept_guides() or {}
        for _,g in ipairs(guides) do
            table.insert(matches, g)
        end
        return matches
    end})
else
    help_parser:addarg(concept_guides, all_commands)
end

local log_parser = parser()
:setendofflags()
:addarg({log_spec_generator, hint=argoptional.."revision-range or pathspec"})
:addarg({file_matches, hint=argoptional.."pathspec"}):loop(2)
:_addexflags(log_flags)
:_addexflags(log_history_flags)
:_addexflags(diff_flags)
:_addexflags(commit_formatting_flags)
:_addexflags(help_flags)
:_addexflags({"--"..parser({file_matches, hint=argoptional.."pathspec"}):loop()})

local function merge_onarg(arg_index, word, word_index, _, user_data)
    if user_data then
        if arg_index > 0 then
            inc_num_args(user_data, word_index)
        elseif word == "--continue" or word == "--abort" or word == "--quit" then
            user_data.merge_in_progress = true
        end
    end
end
local function merge_arg_hint(_, _, word_index, _, user_data)
    if user_data and not user_data.merge_in_progress then
        return hintpfx(is_optional(user_data, word_index)).."commit"
    end
end

local merge_parser = parser()
:setendofflags()
:addarg({local_or_remote_branches, onarg=merge_onarg, hint=merge_arg_hint}):loop()
:_addexflags({
    concat_one_letter_flags=true,
    onarg=merge_onarg,
    help_flags,
    "--commit", "--no-commit",
    { "-e", "提交前编辑生成的消息" },
    "--edit",
    "--no-edit",
    flagex__cleanupequals,
    "--ff", "--no-ff", "--ff-only",
    "--log", "--no-log",
    { "--log="..placeholder_required_arg, "n", "" },
    "--signoff", "--no-signoff",
    "--squash", "--no-squash",
    "--summary", "--no-summary",
    "--allow-unrelated-histories",
    { "-m"..placeholder_required_arg, ' message', '设置提交消息' },
    { opteq=true, "--into-name"..parser({branches}), ' branch', '' },
    { "-F"..files_parser, ' file', '从文件读取提交消息' },
    { opteq=true, "--file="..files_parser, 'file', '' },
    "--overwrite-ignore", "--no-overwrite-ignore",
})
:_addexflags(merge_flags_common)
:_addexflags(merge_flags)

local pull_parser = parser()
:setendofflags()
:addarg({remotes, hint=argoptional.."repository"})
:addarg({branches, hint=argoptional.."refspec"})
:_addexflags({
    concat_one_letter_flags=true,
    help_flags,
    { "-q", "静默；仅报告错误" },
    "--quiet",
    { "-v", "详细输出" },
    "--verbose",
    "--recurse-submodules",
    "--recurse-submodules="..parser({'yes', 'on-demand', 'no'}),
    "--no-recurse-submodules",
        -- Options related to merging...
    "--commit", "--no-commit",
    { "-e", "编辑合并提交消息" },
    "--edit", "--no-edit",
    flagex__cleanupequals,
    "--ff", "--no-ff", "--ff-only",
    "--log", "--no-log",
    { "--log="..placeholder_required_arg, "n", "" },
    "--signoff", "--no-signoff",
    "--squash", "--no-squash",
    "--summary", "--no-summary",
    "--allow-unrelated-histories",
    { "-r", "--rebase=true 的同义词" },
    "--no-rebase",
    { opteq=true, "--rebase="..parser({'false', 'true', 'merges', 'interactive'}) },
})
:_addexflags(merge_flags_common)
:_addexflags(fetch_flags)

local push_parser = parser()
:setendofflags()
:addarg({remotes, hint=argoptional.."repository"})
:addarg({push_branch_spec, hint=argoptional.."refspec"})
:_addexflags({
    concat_one_letter_flags=true,
    help_flags,
    '--all',
    '--prune',
    '--mirror',
    { '-n', "不实际发送更新" },
    '--dry-run',
    '--porcelain',
    { '-d', '--delete 的同义词' },
    '--delete',
    '--tags',
    '--follow-tags',
    '--signed', '--signed='..parser({'true', 'false', 'if-asked'}), '--no-signed',
    '--atomic', '--no-atomic',
    --'-o'..placeholder_required_arg, '--server-option='..placeholder_required_arg,
    { opteq=true, '--receive-pack='..receive_pack_arg, 'git-receive-pack', '' },
    { opteq=true, '--exec='..receive_pack_arg, 'git-receive-pack', '' },
    '--force-with-lease', '--no-force-with-lease',
    { '--force-with-lease='..placeholder_required_arg, 'refname[:expect]', '' },
    { '-f', '--force 的同义词' },
    '--force',
    '--force-if-includes', '--no-force-if-includes',
    { opteq=true, '--repo='..repo_arg, 'repo', '' },
    { '-u', '添加上游跟踪引用' },
    '--set-upstream',
    '--thin', '--no-thin',
    { '-q', '静默；仅报告错误' },
    '--quiet',
    { '-v', '详细输出' },
    '--verbose',
    --'--progress',
    '--no-recurse-submodules',
    { opteq=true, '--recurse-submodules='..parser({'check', 'on-demand', 'only', 'no'}) },
    --'--verify',
    '--no-verify',
    { '-4', '仅使用 IPv4 地址' },
    '--ipv4',
    { '-6', '仅使用 IPv6 地址' },
    '--ipv6',
})

local rebase_arg_hints_normal = {"upstream repository", "branch"}
local rebase_arg_no_args = {
    ["--continue"] = true,
    ["--skip"] = true,
    ["--abort"] = true,
    ["--quit"] = true,
    ["--edit-todo"] = true,
}
local function rebase_onarg(arg_index, word, _, _, user_data)
    if user_data and arg_index == 0 then
        if rebase_arg_no_args[word] then
            user_data.no_args = true
        end
    end
end
local function rebase_arg_hint(arg_index, _, _, _, user_data)
    local h
    if user_data and not user_data.no_args then
        h = rebase_arg_hints_normal[arg_index]
    end
    if h then
        return argoptional..h
    end
end

local rebase_parser = parser()
:setendofflags()
:addarg({local_or_remote_branches, hint=rebase_arg_hint})
:addarg({branches, hint=rebase_arg_hint})
:_addexflags({
    concat_one_letter_flags=true,
    onarg=rebase_onarg,
    help_flags,
    { opteq=true, '--onto'..parser({branches}), ' newbase', '' },
    '--keep-base',
    '--continue',
    '--abort',
    '--quit',
    '--apply',
    { opteq=true, '--empty='..parser({'drop', 'keep', 'ask'}) },
    '--keep-empty', '--no-keep-empty',
    '--reapply-cherry-picks', '--no-reapply-cherry-picks',
    '--allow-empty-message',
    '--skip',
    '--edit-todo',
    '--show-current-patch',
    { '-m', '使用合并策略进行变基' },
    '--merge',
    { '-C', 'n', '确保至少 <n> 行上下文' },
    '--no-ff',
    { '-f', '逐个重放变基的提交' },
    '--force-rebase',
    '--fork-point', '--no-fork-point',
    '--ignore-whitespace',
    flag__whitespaceequals,
    '--committer-date-is-author-date',
    '--ignore-date', '--reset-author-date',
    '--signoff',
    { '-r', '--rebase-merges 的快捷方式' },
    { opteq=true, '--rebase-merges='..parser({'rebase-cousins', 'no-rebase-cousins'}) },
    { '-x'..x_cmd_arg, ' command', '' },
    { opteq=true, '--exec='..x_cmd_arg, 'command', '' },
    '--root',
    '--autosquash', '--no-autosquash',
    '--reschedule-failed-exec', '--no-reschedule-failed-exec',
})
:_addexflags(merge_flags_common)
:_addexflags(merge_flags)

local remote_parser = parser()
:setendofflags()
:addarg(
    "add" ..parser(
        {hint=argexpected.."name"},
        {hint=argexpected.."URL"},
        "-t"..parser({branches}),
        "-m"..placeholder_required_arg,
        "-f",
        "--mirror="..parser({"fetch", "push"}),
        "--tags", "--no-tags"
    ),
    "rename"..parser(
        {remotes, hint=argexpected.."old name"},
        {hint=argexpected.."new name"}
    ),
    "remove"..parser({remotes, hint=argexpected.."name"}),
    "rm"..parser({remotes, hint=argexpected.."name"}),
    "set-head"..parser(
        {remotes, hint=argexpected.."name"},
        {branches, hint=argoptional.."branch"},
        "-a", "--auto",
        "-d", "--delete"
    ),
    "set-branches"..parser(
        {remotes, hint=argexpected.."name"},
        {branches, hint=argexpected.."branch"},
        {branches, hint=argoptional.."branch"},
        "--add"
    ):loop(3),
    "get-url"..parser(
        {remotes, hint=argexpected.."name"},
        "--push", "--all"
    ),
    "set-url"..parser(
        {remotes, hint=argexpected.."name"},
        {hint=argexpected.."new URL"},
        {hint=argoptional.."old URL"},
        "--add"..parser("--push", {remotes, hint=argexpected.."name"}, {hint=argexpected.."new URL"}),
        "--delete"..parser("--push", {remotes, hint=argexpected.."name"}, {hint=argexpected.."URL"})
    ),
    "show"..parser(
        {remotes, hint=argexpected.."name"},
        {remotes, hint=argoptional.."name"},
        "-n"
    ):loop(2),
    "prune"..parser(
        {remotes, hint=argexpected.."name"},
        {remotes, hint=argoptional.."name"},
        "-n", "--dry-run"
    ):loop(2),
    "update"..parser(
        {remotes, hint=argexpected.."group or remote name"},
        {remotes, hint=argoptional.."group or remote name"},
        "-p", "--prune"
    ):loop(2)
)
:_addexflags({
    concat_one_letter_flags=true,
    help_flags,
    { "-v", "详细输出" },
    "--verbose",
})

local reset_parser = parser()
:setendofflags()
:addarg({local_or_remote_branches, hint=argoptional.."tree-ish"})   -- TODO: Add commit completions
:addarg({file_matches, hint=argoptional.."path"}):loop(2)
:_addexflags({
    concat_one_letter_flags=true,
    help_flags,
    { "-q", "静默；仅报告错误" },
    { "-p", "交互式从差异中选择代码块" },
    "--patch",
    { opteq=true, "--pathspec-from-file="..files_parser, "file", "" }, --"--stdin",
    "--pathspec-file-nul", --"-z",
    "--soft", "--mixed", "--hard",
    "--merge", "--keep", "--no-recurse-submodules"
})
:_addexflags({"--"..parser({file_matches, hint=argoptional.."pathspec"}):loop()})

local restore_parser = parser()
:setendofflags()
:addarg({file_matches, hint=argoptional.."pathspec"}):loop()
:_addexflags({
    concat_one_letter_flags=true,
    help_flags,
    { "-s"..files_parser, " tree", "--source 的同义词" },
    { opteq=true, "--source"..files_parser, " tree", "" },
    { "-p", "交互式从差异中选择代码块" },
    "--patch",
    { "-W", "恢复工作树" },
    "--worktree",
    { "-S", "恢复索引" },
    "--staged",
    { "-q", "静默；抑制反馈消息" },
    "--quiet",
    --"--progress",
    "--no-progress",
    "--ours", "--theirs",
    { "-m", "重建冲突合并" },
    "--merge",
    flag__conflictequals,
    "--ignore-unmerged",
    "--ignore-skip-worktree-bits",
    "--recurse-submodules", "--no-recurse-submodules",
    "--overlay",
     --"--no-overlay",
    { opteq=true, "--pathspec-from-file="..files_parser, "file", "" },
    "--pathspec-file-nul"
})

local revparse_parser = parser()
:setendofflags()
:addarg({file_matches, hint=argexpected.."arg"})
:addarg({file_matches, hint=argoptional.."arg"}):loop(2)
:_addexflags({
    concat_one_letter_flags=true,
    { "--parseopt", "使用选项解析模式" },
    { "--sq-quote", "使用 shell 引用模式" },
    { "--keep-dashdash", "配合 --parseopt，回显首个 -- 而非跳过它" },
    { "--stop-at-non-option", "配合 --parseopt，在第一个非选项参数处停止" },
    { "--stuck-long", "配合 --parseopt，以长选项形式输出选项，且附着其参数" },
    { "--revs-only", "不输出非用于 git rev-list 的标志和参数" },
    { "--no-revs", "不输出用于 git rev-list 的标志和参数" },
    { "--flags", "不输出非标志参数" },
    { "--no-flags", "不输出标志参数" },
    { opteq=true, "--default"..placeholder_required_arg, " arg", "如果没有给定参数，则使用 arg 替代" },
    { opteq=true, "--prefix"..dirs_parser, " arg", "表现得如同从工作树的 arg 子目录中调用" },
    { "--verify", "验证恰好提供一个参数，且该参数可以转换为对象数据库中的 SHA1" },
    { "-q", "配合 --verify，当参数不是有效对象名称时不输出错误消息（以非零状态退出）" },
    { "--quiet", "配合 --verify，当参数不是有效对象名称时不输出错误消息（以非零状态退出）" },
    { "--sq", "输出单行，用引号包装以供 shell 使用" },
    { "--short", "同 --verify，但将对象名称缩短为至少 4 个字符的唯一前缀" },
    { "--short="..abbrev_lengths, "len", "同 --verify，但将对象名称缩短为至少 len 个字符的唯一前缀" },
    { "--not", "显示对象名称时，为其添加 ^ 前缀，并去除已有 ^ 前缀的名称" },
    { "--abbrev-ref", "对象名称的非歧义短名称" },
    { "--abbrev-ref="..parser({"strict", "loose"}), "mode", "对象名称的非歧义短名称" },
    { "--symbolic", "以尽可能接近原始输入的形式输出对象名称" },
    { "--symbolic-full-name", "类似 --symbolic，但省略非引用的输入" },
    { "--all", "显示 refs/ 中的所有引用" },
    { "--branches", "显示所有分支（refs/heads 中的引用）" },
    { "--branches="..parser({fromhistory=true}), "pattern", "显示匹配模式的所有分支（refs/heads 中的引用）" },
    { "--tags", "显示所有标签（refs/tags 中的引用）" },
    { "--tags="..parser({fromhistory=true}), "pattern", "显示匹配模式的所有标签（refs/tags 中的引用）" },
    { "--remotes", "显示所有远程跟踪分支（refs/remotes 中的引用）" },
    { "--remotes="..parser({fromhistory=true}), "pattern", "显示匹配模式的所有远程跟踪分支（refs/remotes 中的引用）" },
    { "--glob="..parser({fromhistory=true}), "pattern", "显示匹配 shell glob 模式的所有引用" },
    { "--exclude="..parser({fromhistory=true}), "pattern", "不包括匹配模式的引用" },
    { "--disambiguate="..parser({fromhistory=true}), "prefix", "显示名称以给定前缀开头的每个对象（前缀必须至少 4 个十六进制数字）" },
    { "--local-env-vars", "列出仓库本地化的 GIT_* 环境变量名称" },
    { "--path-format="..parser({"absolute", "relative"}), "behavior", "控制某些其他选项如何打印路径" },
    { "--git-dir", "如果定义了 $GIT_DIR 则显示之，否则显示 .git 目录路径" },
    { "--git-common-dir", "如果定义了 $GIT_COMMON_DIR 则显示之，否则显示 $GIT_DIR" },
    { opteq=true, "--resolve-git-dir", " path", "检查路径是否为有效仓库或指向仓库的 gitfile" },
    { opteq=true, "--git-path", " path", "解析 $GIT_DIR/path，考虑路径重定位环境变量" },
    { "--show-toplevel", "显示工作树顶级目录的路径" },
    { "--show-superproject-working-tree", "显示父项目工作树根目录的路径" },
    { "--shared-index-path", "显示拆分索引模式下共享索引文件的路径" },
    { "--absolute-git-dir", "类似 --git-dir，但始终输出规范化的绝对路径" },
    { "--is-inside-git-dir", "当前工作目录在仓库目录之下时，输出 true，否则输出 false" },
    { "--is-inside-work-tree", "当前工作目录在工作树内时，输出 true，否则输出 false" },
    { "--is-bare-repository", "当仓库是裸仓库时，输出 true，否则输出 false" },
    { "--is-shallow-repository", "当仓库是浅克隆时，输出 true，否则输出 false" },
    { "--show-cdup", "从子目录调用时，显示到顶级目录的相对路径" },
    { "--show-prefix", "从子目录调用时，显示从顶级目录的相对路径" },
    { "--show-object-format", "显示仓库用于存储的对象格式" },
    { "--show-object-format="..parser({"storage", "input", "output"}), "forwhat", "显示仓库用于存储、输入或输出的对象格式" },
    { opteq=true, "--since="..placeholder_required_arg, "date", "解析日期字符串并输出对应的 git rev-list --max-age= 参数" },
    { opteq=true, "--after="..placeholder_required_arg, "date", "解析日期字符串并输出对应的 git rev-list --max-age= 参数" },
    { opteq=true, "--until="..placeholder_required_arg, "date", "解析日期字符串并输出对应的 git rev-list --max-age= 参数" },
    { opteq=true, "--before="..placeholder_required_arg, "date", "解析日期字符串并输出对应的 git rev-list --max-age= 参数" },
})

local revert_arg_no_args = {
    ["--continue"] = true,
    ["--skip"] = true,
    ["--abort"] = true,
    ["--quit"] = true,
}
local function revert_onarg(arg_index, word, _, _, user_data)
    if user_data and arg_index == 0 then
        if revert_arg_no_args[word] then
            user_data.no_args = true
        end
    end
end
local function revert_arg_hint(_, _, _, _, user_data)
    if user_data and not user_data.no_args then
        return argoptional.."commit"
    end
end

local revert_parser = parser()
:setendofflags()
:addarg({onarg=revert_onarg, hint=revert_arg_hint}):loop()
:_addexflags({
    concat_one_letter_flags=true,
    onarg=revert_onarg,
    help_flags,
    { "-e", "提交前编辑消息" },
    "--edit",
    { "-m"..placeholder_required_arg, " parent-num", "--mainline 的同义词" },
    { "--mainline"..placeholder_required_arg, " parent-num", "" },
    "--no-edit",
    flagex__cleanupequals,
    { "-n", "--no-commit 的同义词" },
    "--no-commit",
    { "-S", "GPG-sign commits" },
    "--gpg-sign",
    "--no-gpg-sign",
    { "-s", "添加 'Signed-off-by' 结尾" },
    "--signoff",
    flagex__strategy,
    flagex_X_strategyoption,
    flagex__strategyoption,
    "--rerere-autoupdate",
    "--no-rerere-autoupdate",
    "--continue",
    "--skip",
    "--quit",
    "--abort",
})

local show_parser = parser()
:setendofflags()
:addarg({hint=argoptional.."object"}):loop()
:_addexflags(help_flags)
:_addexflags(diff_flags)
:_addexflags(commit_formatting_flags)
:_addexflags({"--"..parser({file_matches, hint=argoptional.."pathspec"}):loop()})

local stash_parser = parser()
:setendofflags()
:addarg(
    "push"..parser():_addexflags({
        stash_save_flags,
        { opteq=true, "--pathspec-from-file="..files_parser },
        "--pathspec-file-nul",
    }),
    "save"..parser():_addexflags({
        stash_save_flags,
    }),
    "list"..parser():_addexflags(commit_formatting_flags):_addexflags(diff_flags):_addexflags(log_flags),
    "show"..parser({stashes, hint=argoptional.."stash"}, "-u", "--include-untracked", "--only-untracked"):_addexflags(diff_flags),
    "pop"..parser({stashes, hint=argoptional.."stash"}, "--index", "-q", "--quiet"),
    "apply"..parser({stashes, hint=argoptional.."stash"}, "--index", "-q", "--quiet"),
    "branch"..parser({branches, hint=argexpected.."branch"}, {stashes, hint=argoptional.."stash"}),
    "clear",
    "drop"..parser({stashes, hint=argoptional.."stash"}, "-q", "--quiet")
)
:_addexflags({
    help_flags,
})

local status_parser = parser()
:setendofflags()
:addarg({file_matches, hint=argoptional.."pathspec"})
:_addexflags({
    concat_one_letter_flags=true,
    help_flags,
    { '-s', '以短格式输出' },
    '--short',
    { '-b', '在短格式中包含分支信息' },
    '--branch',
    '--show-stash',
    '--porcelain', '--porcelain='..parser({'v1', 'v2'}),
    --'--long',
    { '-v', 'Be verbose; show staged diffs' },
    { '-vv', 'Be extra verbose; include working diffs' },
    '--verbose',
    untracked_flags,
    "--ignore-submodules",
    flag__ignore_submodules,
    '--ignored',
    '--ignored='..parser({'traditional', 'no', 'matching'}),
    { '-z', '使用 NUL 而非 LF 终止条目' },
    '--column', '--no-column',
    flag__columnequals,
    '--ahead-behind', '--no-ahead-behind',
    '--renames', '--no-renames',
    --'--lock-index', '--no-lock-index',
    --'--find-renames='..placeholder_required_arg,
    { '-M', '[n]', 'Detect renames; <n> is threshold %' },
    '--find-renames',
    { '--find-renames='..placeholder_required_arg, 'n', '' },
})

local submodule_add_parser = parser()
:setendofflags()
:addarg({dir_matches, hint=argexpected.."repository"})
:addarg({file_matches, hint=argoptional.."path"})
:_addexflags({
    concat_one_letter_flags=true,
    { '-b'..placeholder_required_arg, ' branch', '' },
    '-f', '--force',
    { opteq=true, '--name'..placeholder_required_arg, ' name', '' },
    { opteq=true, '--reference'..placeholder_required_arg, ' repo_url', '' },
    { opteq=true, '--depth'..placeholder_required_arg, ' depth', '' },
})
:nofiles()

local submodule_status_parser = parser()
:setendofflags()
:addarg({file_matches, hint=argoptional.."path"}):loop()
:addflags('--cached', '--recursive')

local submodule_init_parser = parser()
:setendofflags()
:addarg({file_matches, hint=argoptional.."path"}):loop()

local submodule_deinit_parser = parser()
:setendofflags()
:addarg({
    file_matches,
    onarg=function(_, _, word_index, _, user_data)
        inc_num_args(user_data, word_index)
    end,
    hint=function(_, _, word_index, _, user_data)
        if not user_data or not user_data.all then
            return hintpfx(is_optional(user_data, word_index)).."path"
        end
    end,
}):loop()
:addflags({'-f', '--force', '--all', onarg=function(_, word, _, _, user_data)
    if user_data and word == "--all" then
        user_data.all = true
    end
end})

local submodule_update_parser = parser()
:setendofflags()
:addarg({file_matches, hint=argoptional.."path"}):loop()
:_addexflags({
    concat_one_letter_flags=true,
    '--init',
    '--remote',
    '-N', '--no-fetch',
    '--recommend-shallow', '--no-recommend-shallow',
    '-f', '--force',
    '--checkout', '--rebase', '--merge',
    { opteq=true, '--reference'..placeholder_required_arg, ' repo_url', '' },
    { opteq=true, '--depth'..placeholder_required_arg, ' depth', '' },
    '--recursive',
    { opteq=true, '--jobs'..placeholder_required_arg, ' n', '' },
    '--single-branch', '--no-single-branch',
})

local submodule_set_branch_parser = parser()
:setendofflags()
:addarg({file_matches, hint=argexpected.."path"})
:_addexflags({
    concat_one_letter_flags=true,
    { '-b'..placeholder_required_arg, ' branch', '' },
    { opteq=true, '--branch'..placeholder_required_arg, ' branch', '' },
    '-d', '--default',
})
:nofiles()

local submodule_set_url_parser = parser()
:setendofflags()
:addarg({file_matches, hint=argexpected.."path"})
:addarg({placeholder_required_arg, hint=argexpected.."URL"})
:nofiles()

local submodule_summary_parser = parser()
:setendofflags()
:addarg({file_matches, hint=argoptional.."commit or path"})
:addarg({file_matches, hint=argoptional.."path"}):loop(2)
:_addexflags({
    '--cached',
    '--files',
    { '-n'..summary_limit_arg, ' n', '' },
    { opteq=true, '--summary-limit'..summary_limit_arg, ' n', '' },
})

local submodule_foreach_parser = parser()
:setendofflags()
:addflags('--recursive')
:chaincommand()

local submodule_sync_parser = parser()
:setendofflags()
:addarg({file_matches, hint=argoptional.."path"}):loop()
:addflags('--recursive')

local submodule_parser = parser()
:setendofflags()
:_addexarg({
    'add'..submodule_add_parser,
    'status'..submodule_status_parser,
    'init'..submodule_init_parser,
    'deinit'..submodule_deinit_parser,
    'update'..submodule_update_parser,
    'set-branch'..submodule_set_branch_parser,
    'set-url'..submodule_set_url_parser,
    'summary'..submodule_summary_parser,
    { 'foreach'..submodule_foreach_parser, ' shell_command', '' },
    'sync'..submodule_sync_parser,
    'absorbgitdirs',
})
:_addexflags({
    help_flags,
    '--quiet',
})

local svn_parser = parser()
:setendofflags()
:addarg(
    "init"..parser("-T", "--trunk", "-t", "--tags", "-b", "--branches", "-s", "--stdlayout",
        "--no-metadata", "--use-svm-props", "--use-svnsync-props", "--rewrite-root",
        "--rewrite-uuid", "--username", "--prefix"..parser({"origin"}), "--ignore-paths",
        "--include-paths", "--no-minimize-url"),
        "fetch"..parser({remotes}, "--localtime", "--parent", "--ignore-paths", "--include-paths",
        "--log-window-size"),
        "clone"..parser("-T", "--trunk", "-t", "--tags", "-b", "--branches", "-s", "--stdlayout",
        "--no-metadata", "--use-svm-props", "--use-svnsync-props", "--rewrite-root",
        "--rewrite-uuid", "--username", "--prefix"..parser({"origin"}), "--ignore-paths",
        "--include-paths", "--no-minimize-url", "--preserve-empty-dirs",
        "--placeholder-filename"),
        "rebase"..parser({local_or_remote_branches}, {branches}),
    "dcommit"..parser("--no-rebase", "--commit-url", "--mergeinfo", "--interactive"),
    "branch"..parser("-m","--message","-t", "--tags", "-d", "--destination",
                     "--username", "--commit-url", "--parents"),
    "log"..parser("-r", "--revision", "-v", "--verbose", "--limit",
                  "--incremental", "--show-commit", "--oneline"),
    "find-rev"..parser("--before", "--after"),
    "reset"..parser("-r", "--revision", "-p", "--parent"),
    "tag",
    "blame",
    "set-tree",
    "create-ignore",
    "show-ignore",
    "mkdirs",
    "commit-diff",
    "info",
    "proplist",
    "propget",
    "show-externals",
    "gc"
)
:_addexflags({
    help_flags,
})

local function switch_onarg(arg_index, word, _, _, user_data)
    if user_data and arg_index == 0 then
        if word == "-c" or word == "-C" or word == "--create" or word == "--force-create" then
            user_data.switch_create_branch = true
        end
    end
end
local function switch_arg_hint(_, _, _, _, user_data)
    if user_data and not user_data.switch_create_branch then
        return argexpected.."branch"
    end
end

local switch_parser = parser()
:setendofflags()
:addarg({switch_spec_generator, hint=switch_arg_hint})
:_addexflags({
    concat_one_letter_flags=true,
    onarg=switch_onarg,
    help_flags,
    { '-c'..placeholder_required_arg, ' new-branch', '创建新分支' },
    { opteq=true, '--create'..placeholder_required_arg, ' new-branch', '' },
    { '-C'..placeholder_required_arg, ' new-branch', '创建或重置分支' },
    { opteq=true, '--force-create'..placeholder_required_arg, ' new-branch', '' },
    { '-d', '检出一个提交（分离头指针）' },
    '--detach',
    '--guess', '--no-guess',
    { '-f', '--discard-changes 的快捷方式' },
    '--force', '--discard-changes',
    { '-m', '切换时合并本地更改' },
    '--merge',
    flag__conflictequals,
    { '-q', '静默；抑制反馈消息' },
    '--quiet',
    --'--progress',
    '--no-progress',
    track_flags,
    { opteq=true, '--orphan'..placeholder_required_arg, ' new-branch', '' },
    '--ignore-other-worktrees',
    '--recurse-submodules', '--no-recurse-submodules',
})

local tag_d_parser = parser()
:setendofflags()
:addarg({tags, hint=argexpected.."tagname"})
:addarg({tags, hint=argoptional.."tagname"}):loop(2)

local tag_l_parser = parser()
:setendofflags()
:addarg({tags, hint=argexpected.."tagname"})
:addarg({tags, hint=argoptional.."tagname"}):loop(2)
:_addexflags({
    concat_one_letter_flags=true,
    { '--create-reflog' },
    { opteq=true, '--format='..pretty_formats_parser, 'format', '' },
    { '--color' },
    { '--color='..parser({"always", "auto", "never"}), 'when', '' },
    { opteq=true, '--sort='..placeholder_required_arg, 'key', '' },
    { '-i', '排序和筛选不区分大小写' },
    { '--ignore-case' },
    { opteq=true, '--contains'..placeholder_required_arg, ' commit', '' },
    { opteq=true, '--no-contains'..placeholder_required_arg, ' commit', '' },
    { opteq=true, '--points-at'..placeholder_required_arg, ' object', '' },
    { opteq=true, '--merged'..placeholder_required_arg, ' commit', '' },
    { opteq=true, '--no-merged'..placeholder_required_arg, ' commit', '' },
    { opteq=true, flag__columnequals, 'options', '' },
    { '--no-column' },
})

local tag_v_parser = parser()
:setendofflags()
:addarg({tags, hint=argexpected.."tagname"})
:addarg({tags, hint=argoptional.."tagname"}):loop(2)
:_addexflags({
    { opteq=true, '--format='..pretty_formats_parser, 'format', '' },
    { '--color' },
    { '--color='..parser({"always", "auto", "never"}), 'when', '' },
})

local tag_parser = parser()
:setendofflags()
:addarg({tags, hint=argexpected.."tagname"})                    -- tag
:addarg({file_matches, hint=argoptional.."commit or object"})   -- commit|object
:_addexflags({
    concat_one_letter_flags=true,
    help_flags,
    { '-a', '创建未签名的注释标签对象' },
    { '--annotate' },
    { '-s', '创建 GPG 签名的标签对象' },
    { '--sign' },
    { '--no-sign' },
    { '-u'..gpg_keyid_arg, ' keyid', '使用给定密钥创建 GPG 签名的标签' },
    { opteq=true, '--local-user='..gpg_keyid_arg, 'keyid', '' },
    { '-f', '替换现有标签（而非失败）' },
    { '--force' },
    { '-m'..placeholder_required_arg, ' msg', '使用给定的标签消息' },
    { opteq=true, '--message='..placeholder_required_arg, 'msg', '' },
    { '-F'..files_parser, ' file', '从给定文件获取标签消息' },
    { opteq=true, '--file='..files_parser, 'file', '' },
    { '-e', '编辑来自 -m 或 -F 的标签消息' },
    { '--edit' },
    { '-d'..tag_d_parser, '删除给定名称的现有标签' },
    { '--delete'..tag_d_parser },
    { '-l'..tag_l_parser, 'List tags' },
    { '--list'..tag_l_parser },
    { '-v'..tag_v_parser, '验证给定标签名称的 GPG 签名' },
    { '--verify'..tag_v_parser },
    { '-n', '<num>', 'Implies -l; print num lines from annotation' },
    { opteq=true, '--cleanup='..parser({'verbatim', 'whitespace', 'strip'}), 'mode', '' },
    { opteq=true, '--format='..pretty_formats_parser, 'format', '' },
    { '--color' },
    { '--color='..parser({"always", "auto", "never"}), 'when', '' },
})

local worktree_parser = parser()
:setendofflags()
:addarg(
    "add"..parser(
        {dir_matches, hint=argexpected.."path"},
        {branches, hint=argoptional.."commit-ish"}
    ):_addexflags({
        concat_one_letter_flags=true,
        "-f", "--force",
        "--detach",
        "--checkout",
        "--lock",
        { opteq=true, "--reason"..placeholder_required_arg, " string", "" },
        { "-b"..parser({branches}), " new-branch", "" },
    }),
    "list"..parser("-v", "--porcelain"),
    "lock"..parser():_addexflags({
        { opteq=true, "--reason"..placeholder_required_arg, " string", "" },
    }),
    "move",
    "prune"..parser():_addexflags({
        concat_one_letter_flags=true,
        "-n", "--dry-run",
        "-v", "--verbose",
        { "--expire", " expire", "" },
    }),
    "remove"..parser("-f", "--force"),
    "unlock"
)
:_addexflags({
    help_flags,
})

--------------------------------------------------------------------------------
-- The gitk command parser.
--
-- Optional revision range.
-- Followed by zero or more path patterns.
--
-- Note: gitk only supports "--flag=param" syntax; not "--flag param".

local disk_usage_parser = parser():addarg("human")

local gitk_parser = parser()
:setendofflags()
:addarg({file_matches, hint=argoptional.."revision-range or pathspec"})
:addarg({file_matches, hint=argoptional.."pathspec"}):loop(2)
:_addexflags({
    -- From gitk source code:
    { hide=true, "-d" },        -- ??
    "--date-order",
    { hide=true, "-p" },
    { hide=true, "--patch" },
    { hide=true, "-u" },        -- ??
    { hide=true, "-a" },        -- ??
    { hide=true, "-b" },        -- ??
    { hide=true, "-w" },        -- ??
    { hide=true, "-c" },        -- ??
    { hide=true, "-r" },        -- ??
    { hide=true, "-R" },        -- ??
    { hide=true, "-B" },        -- ??
    { hide=true, "-M" },        -- ??
    { hide=true, "-C" },        -- ??
    "--no-renames",
    "--full-index",
    "--binary",
    "--abbrev", flagex__abbrevequals, "--no-abbrev",
    "--find-copies-harder",
    --{ "-l", "n", "限制昂贵的重命名/复制检查" }, -- argmatcher parser can't handle no space between flag and its parameters.
    "--ext-diff",
    "--no-ext-diff",
    { "--src-prefix="..parser({fromhistory=true}), "prefix", "" },
    { "--dst-prefix="..parser({fromhistory=true}), "prefix", "" },
    "--no-prefix",
    -- -O*          ??
    "--text",
    "--full-diff",
    "--ignore-space-at-eol",
    "--ignore-space-change",
    -- -U*          ??
    -- --unified=*  ??
    { hide=true, "--raw" },     -- Seems to have no effect.
    { hide=true, "--patch-with-raw" },  -- Seems to have no effect.
    { hide=true, "--patch-with-stat" }, -- Seems to have no effect.
    "--name-only",
    "--name-status",
    "--color",
    "--log-size",
    { "--pretty="..pretty_formats_parser, "format", "" },
    "--decorate",
    "--abbrev-commit",
    "--cc",
    -- -z           ??
    "--header",
    "--parents",
    "--boundary",
    "--no-color",
    { "-g",                     "遍历 reflog，而非提交祖先" },
    "--walk-reflogs",
    "--no-walk",
    "--timestamp",
    "--relative-date",
    { "--date="..placeholder_required_arg, "date", "" },
    "--stdin",
    "--objects",
    "--objects-edge",
    "--reverse",
    -- --color-words=*
    -- --word-diff=color
    -- --word-diff*
    { "--stat="..placeholder_required_arg, "width[,name-width[,count]]", "" },
    --"--numstat",              -- gitk reports an error with this.
    "--shortstat",
    "--summary",
    --"--check",                -- gitk reports parse errors.
    "--exit-code",
    "--quiet",
    "--topo-order",
    "--full-history",
    "--left-right",
    flagex__encoding,
    { "--diff-filter="..diff_filter_arg, "[ACDMRTUXB...*]", "" },
    "--no-merges",
    "--unpacked",
    { "--max-count="..placeholder_required_arg, "n", "" },
    { "--skip="..placeholder_required_arg, "n", "" },
    { "--since="..placeholder_required_arg, "date", "" },
    { "--after="..placeholder_required_arg, "date", "" },
    { "--until="..placeholder_required_arg, "date", "" },
    { "--before="..placeholder_required_arg, "date", "" },
    -- --max-age=<epoch>
    -- --min-age=<epoch>
    { "--author="..person_arg, "pattern", "" },
    { "--committer="..person_arg, "pattern", "" },
    { "--grep="..placeholder_required_arg, "pattern", "" },
    { "-i",                     "不区分大小写的正则匹配" },
    { "-E",                     "使用扩展正则模式" },
    "--remove-empty",
    "--first-parent",
    "--cherry-pick",
    --{ "-S", "string", "" },
    --{ "-G", "regex", "" },
    "--pickaxe-all",
    "--pickaxe-regex",
    "--simplify-by-decoration",
    { "-L"..parser({fromhistory=true}), "start,end:file", "跟踪范围的演变" },
    { "-L:"..parser({fromhistory=true}), "funcname:file", "跟踪函数的演变" },
    { "-n"..number_commits_arg, " number", "限制输出的提交数量" },
    "--not",
    "--all",
    "--merge",
    "--no-replace-objects",

    -- Specific to gitk:
    { "--argscmd="..parser({fromhistory=true}), "command", "" },
    { "--select-commit="..placeholder_required_arg, "ref", "" },

    -- From gitk documentation:
    "--branches", { "--branches="..placeholder_required_arg, "glob", "" },
    "--tags", { "--tags="..placeholder_required_arg, "glob", "" },
    "--remotes", { "--remotes="..placeholder_required_arg, "glob", "" },
    "--simplify-merges",
    "--ancestry-path",

    -- From git rev-list help:
    "--sparse",
    { "--min-parents="..placeholder_required_arg, "n", "" }, "--no-min-parents",
    { "--max-parents="..placeholder_required_arg, "n", "" }, "--no-max-parents",
    -- --exclude-hidden=[receive|uploadpack]
    "--children",
    { hide=true, "--disk-usage" },
    { hide=true, "--disk-usage="..disk_usage_parser, "format", "" },
    "--pretty",
    "--object-names",
    "--no-object-names",
    "--count",
    "--bisect",
    "--bisect-vars",
    "--bisect-all",
    "--regexp-ignore-case",
    "--basic-regexp",
    "--extended-regexp",
    "--dirstat",
    -- TODO: add others from git rev-list documentation.
})
:_addexflags({"--"..parser({file_matches, hint=argoptional.."pathspec"}):loop()})

if clink.classifier then
    local gitk_classifier = clink.classifier()

    function gitk_classifier:classify(commands) -- luacheck: no unused
        local flag_color, input_color
        for i = 1, #commands do
            local line_state = commands[i].line_state
            local classifications = commands[i].classifications
            if line_state.getcommandwordindex then
                local cwi = line_state:getcommandwordindex()
                if path.getbasename(line_state:getword(cwi)) == "gitk" then
                    local word = line_state:getendword()
                    if word:find("^%-L[^%:]") then
                        local info = line_state:getwordinfo(line_state:getwordcount())
                        if not flag_color then
                            flag_color = settings.get("color.flag")
                        end
                        if not input_color then
                            input_color = settings.get("color.input")
                        end
                        if flag_color then
                            classifications:applycolor(info.offset, 2, flag_color)
                        end
                        if input_color then
                            classifications:applycolor(info.offset + 2, #word - 2, input_color)
                        end
                    end
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- The main git command parser.

-- This is the set of git commands with custom parsers.  It exists as a separate
-- table so that aliases can be linked to the associated parser for the command
-- they alias.
local linked_parsers = {
    ["add"]                 = add_parser,
    ["annotate"]            = blame_parser,
    ["apply"]               = apply_parser,
    ["blame"]               = blame_parser,
    ["branch"]              = branch_parser,
    ["cat-file"]            = catfile_parser,
    ["checkout"]            = checkout_parser,
    ["cherry-pick"]         = cherrypick_parser,
    ["clone"]               = clone_parser,
    ["commit"]              = commit_parser,
    ["config"]              = config_parser,
    ["diff"]                = diff_parser,
    ["difftool"]            = difftool_parser,
    ["fetch"]               = fetch_parser,
    ["help"]                = help_parser,
    ["log"]                 = log_parser,
    ["merge"]               = merge_parser,
    ["pull"]                = pull_parser,
    ["push"]                = push_parser,
    ["rebase"]              = rebase_parser,
    ["remote"]              = remote_parser,
    ["reset"]               = reset_parser,
    ["restore"]             = restore_parser,
    ["rev-parse"]           = revparse_parser,
    ["revert"]              = revert_parser,
    ["show"]                = show_parser,
    ["stash"]               = stash_parser,
    ["status"]              = status_parser,
    ["submodule"]           = submodule_parser,
    ["svn"]                 = svn_parser,
    ["switch"]              = switch_parser,
    ["tag"]                 = tag_parser,
    ["worktree"]            = worktree_parser,
}

-- Commands with descriptions.
-- Each entry must be a table containing two strings:  { command, description }.
--
-- NOTE:  These are added in the order listed; they are not auto-sorted.
local main_commands = {
    nosort=true,
    { "add",                "将文件内容添加到索引" },
    { "annotate",           "用提交信息注释文件行" },
    { "apply",              "将补丁应用到文件和/或索引" },
    { "blame",              "显示文件每行的最后修改信息" },
    { "branch",             "列出、创建或删除分支" },
    { "cat-file",           "提供仓库对象的内容或类型和大小信息" },
    { "checkout",           "切换分支或恢复工作树文件" },
    { "cherry-pick",        "应用某些现有提交引入的更改" },
    { "clone",              "将仓库克隆到新目录中" },
    { "commit",             "记录对仓库的更改" },
    { "config",             "获取和设置仓库或全局选项" },
    { "diff",               "显示提交、树、标签等之间的更改" },
    { "difftool",           "使用常用差异工具显示更改" },
    { "fetch",              "从另一个仓库下载对象和引用" },
    { "help",               "打印命令或主题的帮助" },
    { "log",                "显示提交日志" },
    { "merge",              "合并两个或多个开发历史" },
    { "pull",               "从另一个仓库或本地分支获取并集成" },
    { "push",               "更新远程引用及相关对象" },
    { "rebase",             "在另一个基准之上重新应用提交" },
    { "remote",             "管理已跟踪仓库的集合" },
    { "reset",              "将当前 HEAD 重置为指定状态" },
    { "restore",            "恢复工作树文件" },
    { "rev-parse",          "解析和处理参数" },
    { "revert",             "撤销一些现有提交" },
    { "show",               "显示各种类型的对象" },
    { "stash",              "暂存脏工作目录中的更改" },
    { "status",             "显示工作树状态" },
    { "submodule",          "初始化、更新或检查子模块" },
    { "switch",             "切换分支" },
    { "tag",                "创建、列出、删除或验证标签引用" },
    { "worktree",           "管理多个工作树" },
}

for _, c in ipairs(main_commands) do
    index_main_commands[c[1]] = true
end

-- Commands without descriptions.
-- This is a table of just command name strings.
--
-- NOTE:  These are added in the order listed; they are not auto-sorted.
local other_commands = {
    "add--interactive",
    "am",
    "archive",
    "bisect",
    "bisect--helper",
    "bundle",
    "check-attr",
    "check-ignore",
    "check-mailmap",
    "check-ref-format",
    "checkout-index",
    "cherry",
    "citool",
    "clean",
    "column",
    "commit-tree",
    "count-objects",
    "credential",
    "credential-store",
    "credential-wincred",
    "daemon",
    "describe",
    "diff-files",
    "diff-index",
    "diff-tree",
    "difftool--helper",
    "fast-export",
    "fast-import",
    "fetch-pack",
    "filter-branch",
    "fmt-merge-msg",
    "for-each-ref",
    "format-patch",
    "fsck",
    "fsck-objects",
    "gc",
    "get-tar-commit-id",
    "grep",
    "gui",
    "gui--askpass",
    "gui--askyesno",
    "gui.tcl",
    "hash-object",
    "http-backend",
    "http-fetch",
    "http-push",
    "imap-send",
    "index-pack",
    "init",
    "init-db",
    "lost-found",
    "ls-files",
    "ls-remote",
    "ls-tree",
    "mailinfo",
    "mailsplit",
    "merge-base",
    "merge-file",
    "merge-index",
    "merge-octopus",
    "merge-one-file",
    "merge-ours",
    "merge-recursive",
    "merge-resolve",
    "merge-subtree",
    "merge-tree",
    "mergetool",
    "mergetool--lib",
    "mktag",
    "mktree",
    "mv",
    "name-rev",
    "notes",
    "p4",
    "pack-objects",
    "pack-redundant",
    "pack-refs",
    "parse-remote",
    "patch-id",
    "peek-remote",
    "prune",
    "prune-packed",
    "quiltimport",
    "read-tree",
    "receive-pack",
    "reflog",
    "remote-ext",
    "remote-fd",
    "remote-ftp",
    "remote-ftps",
    "remote-hg",
    "remote-http",
    "remote-https",
    "remote-testsvn",
    "repack",
    "replace",
    "repo-config",
    "request-pull",
    "rerere",
    "rev-list",
    "rm",
    "send-email",
    "send-pack",
    "sh-i18n",
    "sh-i18n--envsubst",
    "sh-setup",
    "shortlog",
    "show-branch",
    "show-index",
    "show-ref",
    "stage",
    "stripspace",
    "subtree",
    "svn",
    "symbolic-ref",
    "tar-tree",
    "unpack-file",
    "unpack-objects",
    "update-index",
    "update-ref",
    "update-server-info",
    "upload-archive",
    "upload-pack",
    "var",
    "verify-pack",
    "verify-tag",
    "web--browse",
    "whatchanged",
    "write-tree",
}

-- This is the set of flags for git itself (versus flags for commands in git).
local git_flags = {
    concat_one_letter_flags=true,
    { "--version",                          "打印 git 套件版本" },
    { "--help"..help_parser, " [...]",      "打印常规帮助，或关于某个主题的帮助" },
    { "-C"..dirs_parser, " path",           "如同在 PATH 中启动 git 一样运行" },
    { "-c"..placeholder_required_arg, " name=value", "传递配置参数，覆盖配置文件" },
    { "--exec-path",                        "打印核心 git 程序的存储位置" },
    { "--exec-path="..dirs_parser, "path",  "覆盖核心 git 程序的路径" },
    { "--html-path",                        "打印 git 的 HTML 文档存储位置" },
    --"--man-path",
    --"--info-path",
    { "-p",                                 "将所有输出通过 less 分页" },
    { "--paginate",                         "将所有输出通过 less 分页" },
    { "--no-pager",                         "不将 git 输出传递给分页器" },
    { "--no-replace-objects",               "不使用替换引用来替换 git 对象" },
    { "--bare",                             "将仓库视为裸仓库" },
    { "--git-dir="..dirs_parser, "path",    "设置仓库路径（'.git' 目录）" },
    { "--work-tree="..dirs_parser, "path",  "设置工作树路径" },
    { "--namespace="..placeholder_required_arg, "path", "设置 git 命名空间" },
    { "--literal-pathspecs",                "按字面意思处理路径规范（不使用通配符、魔符等）" },
    { "--glob-pathspecs",                   "为所有路径规范应用 'glob' 魔符" },
    { "--no-glob-pathspecs",                "为所有路径规范添加 'literal' 魔符" },
    { "--icase-pathspecs",                  "为所有路径规范添加 'icase' 魔符" },
    { "--no-optional-locks",                "不执行需要锁的可选操作" },
}

-- luacheck: pop

local function command_display_filter()
    if clink.ondisplaymatches then
        clink.ondisplaymatches(function(matches)
            for _, m in ipairs(matches) do
                if index_aliases[m.match] then
                    m.type = "alias"
                elseif index_main_commands[m.match] then
                    m.type = "cmd"
                end
            end
            return matches
        end)
    end
    return {}
end

-- Initialize the argmatcher.  This may be called repeatedly.
local ever_inited
local function init(argmatcher, full_init)
    ever_inited = true

    -- When doing a full init, must reset in order to maintain the sort order.
    -- Full init is used from the setdelayinit callback function, for an alias
    -- to be able to parse arguments for the command it aliases.
    if full_init then
        argmatcher:reset()
    end

    -- Build a table that will be used to (re)initialize the git parser.
    local commands = { nosort=true, command_display_filter }

    -- First the main commands, with descriptions.
    for _,x in ipairs(main_commands) do
        local linked = linked_parsers[x[1]]
        if linked then
            table.insert(commands, { x[1]..linked, x[2] })
        elseif looping_files_parser then
            table.insert(commands, x..looping_files_parser)
        else
            table.insert(commands, x)
        end
    end

    -- Then the function to get all aliases.  This only affects generating
    -- completions; it doesn't affect input line parsing or coloring.
    table.insert(commands, alias)

    -- Then aliases with linked argmatchers.  By coming after the alias
    -- function, the sort order when displaying completions is defined by the
    -- alias function.  But these do affect input line parsing and coloring.
    local aliases = get_git_aliases()
    local complex, chain
    for _, a in ipairs(aliases) do
        local linked
        if not clink_version.supports_onalias then
            linked = linked_parsers[a.command]
        end
        if linked then
            table.insert(commands, a.name..linked)
        else
            local bang = a.command:match("^%!") and true or nil
            local command = a.command:sub(bang and 2 or 1)
            complex = complex or {}
            chain = chain or {}
            complex[a.name] = command
            chain[a.name] = bang
            table.insert(commands, a.name)
        end
    end

    if complex then
        commands.onalias = function(arg_index, word, word_index, line_state, user_data) -- luacheck: no unused
            if not user_data.did_onalias then
                user_data.did_onalias = true
                return complex[word], chain[word]
            end
        end
    end

    -- Finally other commands.
    for _,x in ipairs(other_commands) do
        local linked = linked_parsers[x]
        if linked then
            table.insert(commands, x..linked)
        elseif looping_files_parser then
            table.insert(commands, x..looping_files_parser)
        else
            table.insert(commands, x)
        end
    end
    table.insert(commands, catchall)

    -- Initialize the argmatcher.
    argmatcher:_addexarg(commands)
    argmatcher:_addexflags(git_flags)
end

local cached_cwd
local cached_repo

local git_parser = parser()
if git_parser.setdelayinit then
    git_parser:setdelayinit(function (argmatcher)
        local cwd = os.getcwd()
        if cached_cwd ~= cwd then               -- No-op unless cwd changes.
            cached_cwd = cwd
            local repo = git.get_git_dir()
            if cached_repo ~= repo then         -- No-op unless repo changes.
                cached_repo = repo
                if repo and repo ~= "" then     -- No-op unless in a repo.
                    init(argmatcher, true--[[full_init]])
                end
            end
            if not ever_inited then
                init(git_parser, false--[[full_init]])
            end
        end
    end)
else
    init(git_parser, false--[[full_init]])
end

defer.register_parser("git", git_parser)
defer.register_parser("gitk", gitk_parser)

if clink.onbeginedit then
    clink.onbeginedit(function()
        cached_aliases = nil
        cached_commands = nil
        cached_guides = nil
        cached_all_commands = nil
        cached_config_vars = nil
    end)
end
