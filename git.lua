function dir_match_generator_impl(text)
    -- Strip off any path components that may be on text.
    local prefix = ""
    local i = text:find("[\\/:][^\\/:]*$")
    if i then
        prefix = text:sub(1, i)
    end

    local matches = {}
    local mask = text.."*"

    -- Find matches.
    for _, dir in ipairs(clink.find_dirs(mask, true)) do
        local file = prefix..dir
        if clink.is_match(text, file) then
            table.insert(matches, prefix..dir)
        end
    end

    return matches
end

local function dir_match_generator(word)
    local matches = dir_match_generator_impl(word)

    -- If there was no matches but text is a dir then use it as the single match.
    -- Otherwise tell readline that matches are files and it will do magic.
    if #matches == 0 then
        if clink.is_dir(rl_state.text) then
            table.insert(matches, rl_state.text)
        end
    else
        clink.matches_are_files()
    end

    return matches
end

function file_match_generator_impl(text)
    -- Strip off any path components that may be on text.
    local prefix = ""
    local i = text:find("[\\/:][^\\/:]*$")
    if i then
        prefix = text:sub(1, i)
    end

    local matches = {}
    local mask = text.."*"

    -- Find matches.
    for _, dir in ipairs(clink.find_files(mask, true)) do
        local file = prefix..dir
        if clink.is_match(text, file) then
            table.insert(matches, prefix..dir)
        end
    end

    return matches
end

local function file_match_generator(word)
    local matches = file_match_generator_impl(word)

    -- If there was no matches but text is a dir then use it as the single match.
    -- Otherwise tell readline that matches are files and it will do magic.
    if #matches == 0 then
        if clink.is_dir(rl_state.text) then
            -- table.insert(matches, rl_state.text)
        end
    else
        clink.matches_are_files()
    end

    return matches
end

local function branches(token)
    local res = {}
    local branches = clink.find_files(".git/refs/heads/*")
    for _,branch in ipairs(branches) do
        if string.match(branch, token) then
            table.insert(res, branch)
        end
    end
    return res
end

local function remotes(token)
    local res = {}
    local remotes = clink.find_dirs(".git/refs/remotes/*")
    for _,remote in ipairs(remotes) do
        if string.match(remote, token) then
            table.insert(res, remote)
        end
    end
    return res
end

local parser = clink.arg.new_parser

local git_parser = parser(
    {
        "add" .. parser({file_match_generator},
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
        "annotate" .. parser({file_match_generator},
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
            "-D",
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
        "checkout" .. parser(
            {branches},
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
        "merge",
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
        "pull",
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
        "rebase" .. parser(
            "-i", "--interactive",
            "--onto" .. parser({branches})
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