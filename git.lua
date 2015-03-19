-- preamble: common routines

local function basename(path)
    local prefix = path
    local i = path:find("[\\/:][^\\/:]*$")
    if i then
        prefix = path:sub(i + 1)
    end
    return prefix
end

local function pathname(path)
    local prefix = ""
    local i = path:find("[\\/:][^\\/:]*$")
    if i then
        prefix = path:sub(1, i-1)
    end
    return prefix
end

local function files(word)

    local prefix = pathname(word)

    local matches = {}
    local mask = word.."*"

    -- Find matches.
    for _, dir in ipairs(clink.find_files(mask, true)) do
        local file = prefix..dir
        if clink.is_match(word, file) then
            table.insert(matches, prefix..dir)
        end
    end

    -- If there was no matches but text is a dir then use it as the single match.
    -- Otherwise tell readline that matches are files and it will do magic.
    if #matches == 0 then
        if clink.is_dir(rl_state.word) then
            table.insert(matches, rl_state.text)
        end
    else
        clink.matches_are_files()
    end

    return matches
end

---
 -- Resolves closest .git directory location.
 -- Navigates subsequently up one level and tries to find .git directory
 -- @param  {string} path Path to directory will be checked. If not provided
 --                       current directory will be used
 -- @return {string} Path to .git directory or nil if such dir not found
local function get_git_dir(path)

    -- Navigates up one level
    local function up_one_level(path)
        if path == nil then path = '.' end
        if path == '.' then path = clink.get_cwd() end
        return pathname(path)
    end

    -- Checks if provided directory contains git directory
    local function has_git_dir(path)
        if path == nil then path = '.' end
        local found_dirs = clink.find_dirs(path..'/.git')
        if #found_dirs > 0 then return true end
        return false
    end

    -- Set default path to current directory
    if path == nil then path = '.' end

    -- If we're already have .git directory here, then return current path
    if has_git_dir(path) then
        return path..'/.git'
    else
        -- Otherwise go up one level and make a recursive call
        local parent_path = up_one_level(path)
        if parent_path == path then
            return nil
        else
            return get_git_dir(parent_path)
        end
    end
end

-- end preamble

local function branches(token)
    local res = {}

    -- Try to resolve .git directory location
    local git_dir = get_git_dir()

    if git_dir == nil then return res end
    
    -- If we're found it, then scan it for branches available
    local branches = clink.find_files(git_dir .. "/refs/heads/*")
    for _,branch in ipairs(branches) do
        local start = branch:find(token, 1, true)
        if start and start == 1 then
            table.insert(res, branch)
        end
    end

    return res
end

local function remotes(token)
    local res = {}

    -- Try to resolve .git directory location
    local git_dir = get_git_dir()

    if git_dir == nil then return res end

    -- If we're found it, then scan it for branches available
    local remotes = clink.find_dirs(git_dir.."/refs/remotes/*")
    for _,remote in ipairs(remotes) do
        local start = remote:find(token, 1, true)
        if start and start == 1 then
            table.insert(res, remote)
        end
    end

    return res
end

local function checkout_spec_generator(token)

    local res = {}
    local res_filter = {}

    for _,branch in ipairs(branches(token)) do
        table.insert(res, branch)
        table.insert(res_filter, '*' .. branch)
    end

    for _,file in ipairs(files(token)) do
        table.insert(res, file)
        -- TODO: lines, inserted here contains all path, not only last segmentP

        local prefix = basename(file)
        if clink.is_dir(file) then
            prefix = prefix..'\\'
        end

        table.insert(res_filter, prefix)
    end

    clink.match_display_filter = function (matches)
        return res_filter
    end

    return res
end

local parser = clink.arg.new_parser

local merge_recursive_options = parser({
    "ours",
    "theirs",
    "renormalize",
    "no-renormalize",
    "diff-algorithm="..parser({
        "patience",
        "minimal",
        "histogram",
        "myers"
    }),
    "patience",
    "ignore-space-change",
    "ignore-all-space",
    "ignore-space-at-eol",
    "rename-threshold=",
    -- "subtree="..parser(),
    "subtree"
})

local merge_strategies = parser({
    "resolve",
    "recursive",
    "ours",
    "octopus",
    "subtree"
})

local git_parser = parser(
    {
        "add" .. parser({files},
            "-n", "--dry-run",
            "-v", "--verbose",
            "-f", "--force",
            "-i", "--interactive",
            "-p", "--patch",
            "-e", "--edit",
            "-u", "--update",
            "-A", "--all",
            "--no-all",
            "--ignore-removal",
            "--no-ignore-removal",
            "-N", "--intent-to-add",
            "--refresh",
            "--ignore-errors",
            "--ignore-missing"
            ),
        "add--interactive",
        "am",
        "annotate" .. parser({files},
            "-b",
            "--root",
            "--show-stats",
            "-L",
            "-l",
            "-t",
            "-S",
            "--reverse",
            "-p",
            "--porcelain",
            "--line-porcelain",
            "--incremental",
            "--encoding=",
            "--contents",
            "--date",
            "-M",
            "-C",
            "-h"
            ),
        "apply" .. parser(
            "--stat",
            "--numstat",
            "--summary",
            "--check",
            "--index",
            "--cached",
            "-3", "--3way",
            "--build-fake-ancestor=",
            "-R", "--reverse",
            "--reject",
            "-z",
            "-p",
            "-C",
            "--unidiff-zero",
            "--apply",
            "--no-add",
            "--allow-binary-replacement", "--binary",
            "--exclude=",
            "--include=",
            "--ignore-space-change", "--ignore-whitespace",
            "--whitespace=",
            "--inaccurate-eof",
            "-v", "--verbose",
            "--recount",
            "--directory="
            ),
        "archive",
        "bisect",
        "bisect--helper",
        "blame",
        "branch" .. parser(
            "-v", "--verbose",
            "-q", "--quiet",
            "-t", "--track",
            "--set-upstream",
            "-u", "--set-upstream-to",
            "--unset-upstream",
            "--color",
            "-r", "--remotes",
            "--contains" ,
            "--abbrev",
            "-a", "--all",
            "-d" .. parser({branches}),
            "--delete" .. parser({branches}),
            "-D" .. parser({branches}),
            "-m", "--move",
            "-M",
            "--list",
            "-l", "--create-reflog",
            "--edit-description",
            "-f", "--force",
            "--no-merged",
            "--merged",
            "--column"
        ),
        "bundle",
        "cat-file",
        "check-attr",
        "check-ignore",
        "check-mailmap",
        "check-ref-format",
        "checkout" .. parser({checkout_spec_generator},
            "-q", "--quiet",
            "-b",
            "-B",
            "-l",
            "--detach",
            "-t", "--track",
            "--orphan",
            "-2", "--ours",
            "-3", "--theirs",
            "-f", "--force",
            "-m", "--merge",
            "--overwrite-ignore",
            "--conflict",
            "-p", "--patch",
            "--ignore-skip-worktree-bits"
        ),
        "checkout-index",
        "cherry",
        "cherry-pick",
        "citool",
        "clean",
        "clone",
        "column",
        "commit" .. parser(
            "-a", "--all",
            "-p", "--patch",
            "-C", "--reuse-message=",
            "-c", "--reedit-message=",
            "--fixup=",
            "--squash=",
            "--reset-author",
            "--short",
            "--branch",
            "--porcelain",
            "--long",
            "-z",
            "--null",
            "-F", "--file=",
            "--author=",
            "--date=",
            "-m", "--message=",
            "-t", "--template=",
            "-s", "--signoff",
            "-n", "--no-verify",
            "--allow-empty",
            "--allow-empty-message",
            "--cleanup", -- .. parser({"strip", "whitespace", "verbatim", "default"}),
            "-e", "--edit",
            "--no-edit",
            "--amend",
            "--no-post-rewrite",
            "-i", "--include",
            "-o", "--only",
            "-u", "--untracked-files", "--untracked-files=", -- .. parser({"no", "normal", "all"}),
            "-v", "--verbose",
            "-q", "--quiet",
            "--dry-run",
            "--status",
            "--no-status",
            "-S", "--gpg-sign", "--gpg-sign=",
            "--"
        ),
        "commit-tree",
        "config",
        "count-objects",
        "credential",
        "credential-store",
        "credential-wincred",
        "daemon",
        "describe",
        "diff",
        "diff-files",
        "diff-index",
        "diff-tree",
        "difftool",
        "difftool--helper",
        "fast-export",
        "fast-import",
        "fetch" .. parser({remotes}),
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
        "help",
        "http-backend",
        "http-fetch",
        "http-push",
        "imap-send",
        "index-pack",
        "init",
        "init-db",
        "log",
        "lost-found",
        "ls-files",
        "ls-remote",
        "ls-tree",
        "mailinfo",
        "mailsplit",
        "merge" .. parser({branches},
            "--commit", "--no-commit",
            "--edit", "-e", "--no-edit",
            "--ff", "--no-ff", "--ff-only",
            "--log", "--no-log",
            "--stat", "-n", "--no-stat",
            "--squash", "--no-squash",
            "-s" .. merge_strategies,
            -- "--strategy=" .. merge_strategies,
            "-X" .. merge_recursive_options,
            -- "--strategy-option=" .. merge_recursive_options,
            "--verify-signatures", "--no-verify-signatures",
            "-q", "--quiet", "-v", "--verbose",
            "--progress", "--no-progress",
            "-S", "--gpg-sign",
            "-m",
            "--rerere-autoupdate", "--no-rerere-autoupdate",
            "--abort"
        ),
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
        "pull" .. parser(
            {remotes}, {branches}, 
            "-q", "--quiet",
            "-v", "--verbose",
            "--recurse-submodules", --[no-]recurse-submodules[=yes|on-demand|no]
            "--no-recurse-submodules",
            "--commit", "--no-commit",
            "-e", "--edit", "--no-edit",
            "--ff", "--no-ff", "--ff-only",
            "--log", "--no-log",
            "--stat", "-n", "--no-stat",
            "--squash", "--no-squash",
            "-s", "--strategy=",
            "-X", "--strategy-option",
            "--verify-signatures", "--no-verify-signatures",
            "--summary", "--no-summary",
            "-r", "--rebase", "--no-rebase",
            "--all",
            "-a", "--append",
            "--depth", "--unshallow", "--update-shallow",
            "-f", "--force",
            "-k", "--keep",
            "--no-tags",
            "-u", "--update-head-ok",
            "--upload-pack",
            "--progress"
        ),
        "push" .. parser(
            {remotes},
            {branches},
            "-v", "--verbose",
            "-q", "--quiet",
            "--repo",
            "--all",
            "--mirror",
            "--delete",
            "--tags",
            "-n", "--dry-run",
            "--porcelain",
            "-f", "--force",
            "--force-with-lease",
            "--recurse-submodules",
            "--thin",
            "--receive-pack",
            "--exec",
            "-u", "--set-upstream",
            "--progress",
            "--prune",
            "--no-verify",
            "--follow-tags"
        ),
        "quiltimport",
        "read-tree",
        "rebase" .. parser({branches}, {branches},
            "-i", "--interactive",
            "--onto" .. parser({branches}),
            "--continue",
            "--abort",
            "--keep-empty",
            "--skip",
            "--edit-todo",
            "-m", "--merge",
            "-s" .. merge_strategies,
            -- "--strategy=<strategy>",
            "-X" .. merge_recursive_options,
            -- "--strategy-option=<strategy-option>",
            "-S", "--gpg-sign",
            "-q", "--quiet",
            "-v", "--verbose",
            "--stat", "-n", "--no-stat",
            "--no-verify", "--verify",
            "-C",
            "-f", "--force-rebase",
            "--fork-point", "--no-fork-point",
            "--ignore-whitespace", "--whitespace",
            "--committer-date-is-author-date", "--ignore-date",
            "-i", "--interactive",
            "-p", "--preserve-merges",
            "-x", "--exec",
            "--root",
            "--autosquash", "--no-autosquash",
            "--autostash", "--no-autostash",
            "--no-ff"
            ),
        "rebase--am",
        "rebase--interactive",
        "rebase--merge",
        "receive-pack",
        "reflog",
        "remote",
        "remote-ext",
        "remote-fd",
        "remote-ftp",
        "remote-ftps",
        "remote-hg",
        "remote-http",
        "remote-https",
        "remote-testgit",
        "remote-testpy",
        "remote-testsvn",
        "repack",
        "replace",
        "repo-config",
        "request-pull",
        "rerere",
        "reset",
        "rev-list",
        "rev-parse",
        "revert",
        "rm",
        "send-email",
        "send-pack",
        "sh-i18n",
        "sh-i18n--envsubst",
        "sh-setup",
        "shortlog",
        "show",
        "show-branch",
        "show-index",
        "show-ref",
        "stage",
        "stash",
        "status",
        "stripspace",
        "submodule",
        "subtree",
        "svn",
        "symbolic-ref",
        "tag",
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
    },
    "--version",
    "--help",
    "-c",
    "--exec-path",
    "--html-path",
    "--man-path",
    "--info-path",
    "-p", "--paginate", "--no-pager",
    "--no-replace-objects",
    "--bare",
    "--git-dir=",
    "--work-tree=",
    "--namespace="
)

clink.arg.register_parser("git", git_parser)
