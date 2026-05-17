-- Completions for pnpm.
-- luacheck: ignore clink
-- luacheck: globals matchicons

local JSON = require("JSON")
function JSON:assert () end  -- luacheck: no unused args

local w = require('tables').wrap
local matchers = require('matchers')

local empty_arg = clink.argmatcher():addarg({fromhistory=true})
local dir_arg = clink.argmatcher():addarg(clink.dirmatches)
local file_arg = clink.argmatcher():addarg(clink.filematches)
local pkg_arg = clink.argmatcher():addarg({fromhistory=true})
local modules_arg = clink.argmatcher():addarg(matchers.create_dirs_matcher('node_modules/*'))
local level_arg = clink.argmatcher():addarg({"debug", "info", "warn", "error"})
local reporter_arg = clink.argmatcher():addarg({"append-only", "default", "ndjson", "silent"})

local function addicon(m, icon)
    if matchicons and matchicons.addicontomatch then
        return matchicons.addicontomatch(m, icon)
    else
        return m
    end
end

local function scripts()
    local package_json = io.open('package.json')
    if package_json == nil then return w() end
    local contents = package_json:read('*a')
    package_json:close()
    local pkg = JSON:decode(contents)
    if not pkg or not pkg.scripts then return w() end

    local matches = {}
    local script_icon = ''

    for name, cmd in pairs(pkg.scripts) do
        local description = type(cmd) == "string" and cmd or tostring(cmd)
        description = description:gsub("[\r\n]+", " "):gsub("%s+", " ")
        table.insert(matches, addicon({ match=name, description=description, type="file" }, script_icon))
    end
    table.sort(matches, function(a, b) return a.match < b.match end)
    return matches
end

local bool_color_flags = {
    "--color",
    "--no-color"
}

local shared_flags = {
    "--aggregate-output",
    "-C" .. dir_arg, "--dir" .. dir_arg,
    "-h", "--help",
    "--loglevel" .. level_arg,
    "--stream",
    "--use-stderr",
}

local store_flags = {
    "--global-dir" .. dir_arg,
    "--store-dir" .. dir_arg,
}

local recursive_flags = {
    "-r", "--recursive",
    "-w", "--workspace-root",
    "-F" .. empty_arg, "--filter" .. empty_arg,
    "--filter-prod" .. empty_arg,
    "--changed-files-ignore-pattern" .. empty_arg,
    "--fail-if-no-match",
    "--test-pattern" .. empty_arg,
}

local install_output_flags = {
    "--reporter" .. reporter_arg,
    "-s", "--silent",
}

local install_matcher = clink.argmatcher():addarg(pkg_arg):loop(1)
:addflags(
    bool_color_flags,
    shared_flags,
    store_flags,
    recursive_flags,
    install_output_flags,
    "--frozen-lockfile", "--no-frozen-lockfile",
    "--verify-store-integrity", "--no-verify-store-integrity",
    "-D", "--dev",
    "--fix-lockfile",
    "--force",
    "--hoist-pattern" .. empty_arg,
    "--ignore-pnpmfile",
    "--ignore-scripts",
    "--ignore-workspace",
    "--lockfile-dir" .. dir_arg,
    "--lockfile-only",
    "--merge-git-branch-lockfiles",
    "--modules-dir" .. dir_arg,
    "--network-concurrency" .. empty_arg,
    "--no-hoist",
    "--no-lockfile",
    "--no-optional",
    "--offline",
    "--optimistic-repeat-install",
    "--package-import-method" .. clink.argmatcher():addarg({"auto", "clone", "copy", "hardlink"}),
    "--prefer-frozen-lockfile",
    "--prefer-offline",
    "-P", "--prod",
    "--public-hoist-pattern" .. empty_arg,
    "--resolution-only",
    "--shamefully-hoist",
    "--side-effects-cache",
    "--side-effects-cache-readonly",
    "--strict-peer-dependencies",
    "--trust-policy" .. clink.argmatcher():addarg({"no-downgrade"}),
    "--trust-policy-exclude" .. empty_arg,
    "--trust-policy-ignore-after" .. empty_arg,
    "--use-running-store-server",
    "--use-store-server",
    "--virtual-store-dir" .. dir_arg
)

local add_matcher = clink.argmatcher():addarg(pkg_arg):loop(1)
:addflags(
    bool_color_flags,
    shared_flags,
    store_flags,
    recursive_flags,
    "-E", "--save-exact",
    "--no-save-exact",
    "--save-workspace-protocol",
    "--no-save-workspace-protocol",
    "--allow-build" .. empty_arg,
    "--config",
    "-g", "--global",
    "--ignore-scripts",
    "--offline",
    "--prefer-offline",
    "--save-catalog",
    "--save-catalog-name=" .. empty_arg,
    "-D", "--save-dev",
    "-O", "--save-optional",
    "--save-peer",
    "-P", "--save-prod",
    "--virtual-store-dir" .. dir_arg,
    "--workspace"
)

local dedupe_matcher = clink.argmatcher()
:addflags(
    bool_color_flags,
    shared_flags,
    store_flags,
    "--check",
    "--ignore-scripts",
    "--offline",
    "--prefer-offline",
    "--virtual-store-dir" .. dir_arg,
    "-w", "--workspace-root"
)

local fetch_matcher = clink.argmatcher()
:addflags(
    bool_color_flags,
    shared_flags,
    "-D", "--dev",
    "-P", "--prod",
    "-w", "--workspace-root"
)

local import_matcher = clink.argmatcher():addflags("-h", "--help")

local install_test_matcher = clink.argmatcher()
:addflags(
    bool_color_flags,
    shared_flags,
    store_flags,
    recursive_flags,
    install_output_flags
)

local link_matcher = clink.argmatcher():addarg({matchers.dirs, modules_arg}):loop(1)
:addflags(
    bool_color_flags,
    shared_flags,
    "-w", "--workspace-root"
)

local prune_matcher = clink.argmatcher()
:addflags(
    bool_color_flags,
    shared_flags,
    "--ignore-scripts",
    "--no-optional",
    "--prod",
    "-w", "--workspace-root"
)

local rebuild_matcher = clink.argmatcher():addarg(modules_arg):loop(1)
:addflags(
    bool_color_flags,
    shared_flags,
    recursive_flags,
    "--pending",
    "--store-dir" .. dir_arg
)

local remove_matcher = clink.argmatcher():addarg(modules_arg):loop(1)
:addflags(
    bool_color_flags,
    shared_flags,
    recursive_flags,
    "--global-dir" .. dir_arg,
    "-D", "--save-dev",
    "-O", "--save-optional",
    "-P", "--save-prod"
)

local unlink_matcher = clink.argmatcher():addarg(modules_arg):loop(1)
:addflags(
    bool_color_flags,
    shared_flags,
    recursive_flags
)

local update_matcher = clink.argmatcher():addarg(modules_arg):loop(1)
:addflags(
    bool_color_flags,
    shared_flags,
    recursive_flags,
    "--depth" .. empty_arg,
    "-D", "--dev",
    "-g", "--global",
    "--global-dir" .. dir_arg,
    "-i", "--interactive",
    "-L", "--latest",
    "--no-optional",
    "-P", "--prod",
    "--workspace"
)

local patch_matcher = clink.argmatcher():addarg(pkg_arg)
:addflags("--edit-dir" .. dir_arg, "--ignore-existing")

local patch_commit_matcher = clink.argmatcher():addarg(dir_arg):addflags("--patches-dir" .. dir_arg)
local patch_remove_matcher = clink.argmatcher():addarg(pkg_arg):loop(1)

local audit_matcher = clink.argmatcher()
:addflags(
    "--audit-level" .. clink.argmatcher():addarg({"low", "moderate", "high", "critical"}),
    "-D", "--dev",
    "--fix",
    "--ignore" .. empty_arg,
    "--ignore-registry-errors",
    "--ignore-unfixable",
    "--json",
    "--no-optional",
    "-P", "--prod"
)

local licenses_matcher = clink.argmatcher()
:addarg({"ls", "list"})
:addflags(
    recursive_flags,
    "-D", "--dev",
    "--json",
    "--long",
    "--no-optional",
    "-P", "--prod"
)

local list_matcher = clink.argmatcher():addarg(modules_arg):loop(1)
:addflags(
    bool_color_flags,
    shared_flags,
    recursive_flags,
    "--depth" .. empty_arg,
    "-D", "--dev",
    "--exclude-peers",
    "-g", "--global",
    "--global-dir" .. dir_arg,
    "--json",
    "--lockfile-only",
    "--long",
    "--no-optional",
    "--only-projects",
    "--parseable",
    "-P", "--prod"
)

local outdated_matcher = clink.argmatcher():addarg(modules_arg):loop(1)
:addflags(
    bool_color_flags,
    shared_flags,
    recursive_flags,
    "--compatible",
    "-D", "--dev",
    "--format" .. clink.argmatcher():addarg({"table", "list", "json"}),
    "--global-dir" .. dir_arg,
    "--long",
    "--no-optional",
    "--no-table",
    "-P", "--prod",
    "--sort-by" .. clink.argmatcher():addarg({"name"})
)

local why_matcher = clink.argmatcher():addarg(modules_arg):loop(1)
:addflags(
    bool_color_flags,
    shared_flags,
    recursive_flags,
    "--depth" .. empty_arg,
    "-D", "--dev",
    "--exclude-peers",
    "-g", "--global",
    "--global-dir" .. dir_arg,
    "--json",
    "--long",
    "--no-optional",
    "--parseable",
    "-P", "--prod"
)

local approve_builds_matcher = clink.argmatcher():addflags("--all", "-g", "--global")
local create_matcher = clink.argmatcher():addarg(pkg_arg):loop(1):addflags("--allow-build" .. empty_arg)
local dlx_matcher = clink.argmatcher():addarg(pkg_arg):loop(1)
:addflags(
    "--allow-build" .. empty_arg,
    "--package" .. pkg_arg,
    "-c", "--shell-mode",
    "--reporter" .. reporter_arg,
    "-s", "--silent"
)

local exec_matcher = clink.argmatcher():addarg(empty_arg):loop(1)
:addflags(
    bool_color_flags,
    shared_flags,
    "-c", "--shell-mode",
    "--no-reporter-hide-prefix",
    "--parallel",
    "--report-summary",
    "--resume-from" .. empty_arg,
    "-w", "--workspace-root"
)

local ignored_builds_matcher = clink.argmatcher()

local run_matcher = clink.argmatcher():addarg({scripts}):addarg(empty_arg):loop(1)
:addflags(
    bool_color_flags,
    shared_flags,
    recursive_flags,
    "--if-present",
    "--no-bail",
    "--parallel",
    "--report-summary",
    "--reporter-hide-prefix",
    "--resume-from" .. empty_arg,
    "--sequential"
)

local start_matcher = clink.argmatcher():addarg(empty_arg):loop(1)
local test_matcher = clink.argmatcher():addarg(empty_arg):loop(1)
local bin_matcher = clink.argmatcher():addflags("-g", "--global")

local config_matcher = clink.argmatcher()
:addarg({
    "set" .. clink.argmatcher():addarg(empty_arg):addarg(empty_arg),
    "get" .. clink.argmatcher():addarg(empty_arg),
    "delete" .. clink.argmatcher():addarg(empty_arg),
    "list",
})
:addflags(
    "-g", "--global",
    "--json",
    "--location" .. clink.argmatcher():addarg({"project", "global"})
)

local deploy_matcher = clink.argmatcher():addarg(dir_arg)
:addflags(
    recursive_flags,
    "-D", "--dev", "--legacy", "--no-optional", "-P", "--prod"
)

local doctor_matcher = clink.argmatcher()
local init_matcher = clink.argmatcher():addflags(
    "--bare",
    "--init-package-manager",
    "--init-type" .. clink.argmatcher():addarg({"commonjs", "module"})
)

local pack_matcher = clink.argmatcher()
:addflags(
    recursive_flags,
    "--dry-run",
    "--json",
    "--out" .. file_arg,
    "--pack-destination" .. dir_arg,
    "--workspace-concurrency" .. empty_arg
)

local publish_matcher = clink.argmatcher():addarg({file_arg, dir_arg})
:addflags(
    recursive_flags,
    "--access" .. clink.argmatcher():addarg({"public", "restricted"}),
    "--dry-run",
    "--force",
    "--ignore-scripts",
    "--json",
    "--no-git-checks",
    "--otp" .. empty_arg,
    "--publish-branch" .. empty_arg,
    "--report-summary",
    "--tag" .. empty_arg
)

local root_matcher = clink.argmatcher():addflags("-g", "--global")
local self_update_matcher = clink.argmatcher():addarg(empty_arg):loop(1)

local env_matcher = clink.argmatcher()
:addarg({
    "add" .. clink.argmatcher():addarg(empty_arg):loop(1),
    "ls",
    "list" .. clink.argmatcher():addarg(empty_arg):loop(1),
    "rm" .. clink.argmatcher():addarg(empty_arg):loop(1),
    "remove" .. clink.argmatcher():addarg(empty_arg):loop(1),
    "use" .. clink.argmatcher():addarg(empty_arg):loop(1),
})
:addflags(
    "-g", "--global",
    "--remote"
)

local cat_file_matcher = clink.argmatcher():addarg(empty_arg)
local cat_index_matcher = clink.argmatcher():addarg(pkg_arg)
local find_hash_matcher = clink.argmatcher():addarg(empty_arg)

local store_matcher = clink.argmatcher()
:addarg({
    "add" .. clink.argmatcher():addarg(pkg_arg):loop(1),
    "path",
    "prune" .. clink.argmatcher():addflags("--force"),
    "status",
})

local cache_matcher = clink.argmatcher()
:addarg({
    "delete" .. clink.argmatcher():addarg(pkg_arg):loop(1),
    "list" .. clink.argmatcher():addarg(pkg_arg):loop(1),
    "list-registries",
    "view" .. clink.argmatcher():addarg(pkg_arg):loop(1),
})

clink.argmatcher("pnpm")
:addarg({
    nosort=true,
    "add" .. add_matcher,
    "dedupe" .. dedupe_matcher,
    "fetch" .. fetch_matcher,
    "import" .. import_matcher,
    "install" .. install_matcher,
    "i" .. install_matcher,
    "install-test" .. install_test_matcher,
    "it" .. install_test_matcher,
    "link" .. link_matcher,
    "ln" .. link_matcher,
    "prune" .. prune_matcher,
    "rebuild" .. rebuild_matcher,
    "rb" .. rebuild_matcher,
    "remove" .. remove_matcher,
    "rm" .. remove_matcher,
    "unlink" .. unlink_matcher,
    "update" .. update_matcher,
    "up" .. update_matcher,
    "patch" .. patch_matcher,
    "patch-commit" .. patch_commit_matcher,
    "patch-remove" .. patch_remove_matcher,
    "audit" .. audit_matcher,
    "licenses" .. licenses_matcher,
    "list" .. list_matcher,
    "ls" .. list_matcher,
    "outdated" .. outdated_matcher,
    "why" .. why_matcher,
    "approve-builds" .. approve_builds_matcher,
    "create" .. create_matcher,
    "dlx" .. dlx_matcher,
    "exec" .. exec_matcher,
    "ignored-builds" .. ignored_builds_matcher,
    "run" .. run_matcher,
    "start" .. start_matcher,
    "t" .. test_matcher,
    "bin" .. bin_matcher,
    'config' .. config_matcher,
    "c" .. config_matcher,
    "deploy" .. deploy_matcher,
    "doctor" .. doctor_matcher,
    "init" .. init_matcher,
    "pack" .. pack_matcher,
    "publish" .. publish_matcher,
    "root" .. root_matcher,
    "self-update" .. self_update_matcher,
    "env" .. env_matcher,
    "cat-file" .. cat_file_matcher,
    "cat-index" .. cat_index_matcher,
    "find-hash" .. find_hash_matcher,
    "store" .. store_matcher,
    "cache" .. cache_matcher,
    { scripts },
})
:addflags(
    "-h", "--help",
    "-v", "--version",
    "-r", "--recursive"
)
:adddescriptions(
    {"add", description = "Install a package and its dependencies" },
    {"dedupe", description = "Perform an install removing older lockfile entries" },
    {"fetch", description = "Fetch packages from lockfile into virtual store" },
    {"import", description = "Generate pnpm-lock.yaml from another lockfile" },
    {"i", "install", description = "Install project dependencies" },
    {"it", "install-test", description = "Run pnpm install then pnpm test" },
    {"ln", "link", description = "Connect the local project to another one" },
    {"prune", description = "Remove extraneous packages" },
    {"rb", "rebuild", description = "Rebuild a package" },
    {"rm", "remove", description = "Remove packages from node_modules and package.json" },
    {"unlink", description = "Unlink a package and reinstall saved dep" },
    {"up", "update", description = "Update packages to latest matching versions" },
    {"patch", description = "Prepare a package for patching" },
    {"patch-commit", description = "Generate a patch from a directory" },
    {"patch-remove", description = "Remove existing patch files" },
    {"audit", description = "Check for security issues" },
    {"licenses", description = "Check licenses in consumed packages" },
    {"ls", "list", description = "List installed packages and dependencies" },
    {"outdated", description = "Check for outdated packages" },
    {"why", description = "Show packages that depend on the specified package" },
    {"approve-builds", description = "Approve dependencies for running install scripts" },
    {"create", description = "Create a project from a create-* starter kit" },
    {"dlx", description = "Run a package in a temporary environment" },
    {"exec", description = "Execute a shell command in project scope" },
    {"ignored-builds", description = "Print packages with blocked build scripts" },
    {"run", description = "Run a package.json script" },
    {"start", description = "Run the start script" },
    {"t", "test", description = "Run the test script" },
    {"bin", description = "Print the pnpm executables directory" },
    {"c", "config", description = "Manage pnpm configuration" },
    {"deploy", description = "Deploy a package from a workspace" },
    {"doctor", description = "Check for common pnpm issues" },
    {"init", description = "Create a package.json file" },
    {"pack", description = "Create a tarball from a package" },
    {"publish", description = "Publish a package to the npm registry" },
    {"root", description = "Print the effective node_modules directory" },
    {"self-update", description = "Update pnpm to the latest version" },
    {"env", description = "Manage Node.js versions" },
    {"cat-file", description = "Print the contents of a store file by hash" },
    {"cat-index", description = "Print a package index file from the store" },
    {"find-hash", description = "List packages that include the specified hash" },
    {"store", description = "Inspect and manage the pnpm store" },
    {"cache", description = "Inspect and manage the metadata cache" }
)
