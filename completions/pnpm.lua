-- Completions for pnpm.
-- luacheck: ignore clink

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
local bool_color_flags = {"--color", "--no-color"}

local function scripts()
    local package_json = io.open('package.json')
    if package_json == nil then return w() end
    local contents = package_json:read('*a')
    package_json:close()
    local pkg = JSON:decode(contents)
    if not pkg or not pkg.scripts then return w() end

    local matches = {}
    for name, cmd in pairs(pkg.scripts) do
        local description = type(cmd) == "string" and cmd or tostring(cmd)
        description = description:gsub("[\r\n]+", " "):gsub("%s+", " ")
        table.insert(matches, { match=name, description=description, type="none" })
    end
    table.sort(matches, function(a, b) return a.match < b.match end)
    return matches
end

local function add_flags(matcher, flags)
    matcher:addflags(table.unpack(flags))
    return matcher
end

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
add_flags(install_matcher, bool_color_flags)
add_flags(install_matcher, shared_flags)
add_flags(install_matcher, store_flags)
add_flags(install_matcher, recursive_flags)
add_flags(install_matcher, install_output_flags)
:addflags(
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
add_flags(add_matcher, bool_color_flags)
add_flags(add_matcher, shared_flags)
add_flags(add_matcher, store_flags)
add_flags(add_matcher, recursive_flags)
:addflags(
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
add_flags(dedupe_matcher, bool_color_flags)
add_flags(dedupe_matcher, shared_flags)
add_flags(dedupe_matcher, store_flags)
:addflags(
    "--check",
    "--ignore-scripts",
    "--offline",
    "--prefer-offline",
    "--virtual-store-dir" .. dir_arg,
    "-w", "--workspace-root"
)

local fetch_matcher = clink.argmatcher()
add_flags(fetch_matcher, bool_color_flags)
add_flags(fetch_matcher, shared_flags)
:addflags(
    "-D", "--dev",
    "-P", "--prod",
    "-w", "--workspace-root"
)

local import_matcher = clink.argmatcher():addflags("-h", "--help")

local install_test_matcher = clink.argmatcher()
add_flags(install_test_matcher, bool_color_flags)
add_flags(install_test_matcher, shared_flags)
add_flags(install_test_matcher, store_flags)
add_flags(install_test_matcher, recursive_flags)
add_flags(install_test_matcher, install_output_flags)

local link_matcher = clink.argmatcher():addarg({matchers.dirs, modules_arg}):loop(1)
add_flags(link_matcher, bool_color_flags)
add_flags(link_matcher, shared_flags)
:addflags("-w", "--workspace-root")

local prune_matcher = clink.argmatcher()
add_flags(prune_matcher, bool_color_flags)
add_flags(prune_matcher, shared_flags)
:addflags(
    "--ignore-scripts",
    "--no-optional",
    "--prod",
    "-w", "--workspace-root"
)

local rebuild_matcher = clink.argmatcher():addarg(modules_arg):loop(1)
add_flags(rebuild_matcher, bool_color_flags)
add_flags(rebuild_matcher, shared_flags)
add_flags(rebuild_matcher, recursive_flags)
:addflags(
    "--pending",
    "--store-dir" .. dir_arg
)

local remove_matcher = clink.argmatcher():addarg(modules_arg):loop(1)
add_flags(remove_matcher, bool_color_flags)
add_flags(remove_matcher, shared_flags)
add_flags(remove_matcher, recursive_flags)
:addflags(
    "--global-dir" .. dir_arg,
    "-D", "--save-dev",
    "-O", "--save-optional",
    "-P", "--save-prod"
)

local unlink_matcher = clink.argmatcher():addarg(modules_arg):loop(1)
add_flags(unlink_matcher, bool_color_flags)
add_flags(unlink_matcher, shared_flags)
add_flags(unlink_matcher, recursive_flags)

local update_matcher = clink.argmatcher():addarg(modules_arg):loop(1)
add_flags(update_matcher, bool_color_flags)
add_flags(update_matcher, shared_flags)
add_flags(update_matcher, recursive_flags)
:addflags(
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
add_flags(licenses_matcher, recursive_flags)
:addflags(
    "-D", "--dev",
    "--json",
    "--long",
    "--no-optional",
    "-P", "--prod"
)

local list_matcher = clink.argmatcher():addarg(modules_arg):loop(1)
add_flags(list_matcher, bool_color_flags)
add_flags(list_matcher, shared_flags)
add_flags(list_matcher, recursive_flags)
:addflags(
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
add_flags(outdated_matcher, bool_color_flags)
add_flags(outdated_matcher, shared_flags)
add_flags(outdated_matcher, recursive_flags)
:addflags(
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
add_flags(why_matcher, bool_color_flags)
add_flags(why_matcher, shared_flags)
add_flags(why_matcher, recursive_flags)
:addflags(
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
add_flags(exec_matcher, bool_color_flags)
add_flags(exec_matcher, shared_flags)
:addflags(
    "-c", "--shell-mode",
    "--no-reporter-hide-prefix",
    "--parallel",
    "--report-summary",
    "--resume-from" .. empty_arg,
    "-w", "--workspace-root"
)

local ignored_builds_matcher = clink.argmatcher()

local run_matcher = clink.argmatcher():addarg({scripts}):addarg(empty_arg):loop(1)
add_flags(run_matcher, bool_color_flags)
add_flags(run_matcher, shared_flags)
add_flags(run_matcher, recursive_flags)
:addflags(
    "--if-present",
    "--no-bail",
    "--parallel",
    "--report-summary",
    "--reporter-hide-prefix",
    "--resume-from" .. empty_arg,
    "--sequential"
)

local function top_level_scripts()
    local matches = {}
    local scripts_matches = scripts()
    for i = 1, #scripts_matches do
        table.insert(matches, scripts_matches[i])
    end
    return matches
end

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
add_flags(deploy_matcher, recursive_flags)
:addflags("-D", "--dev", "--legacy", "--no-optional", "-P", "--prod")

local doctor_matcher = clink.argmatcher()
local init_matcher = clink.argmatcher():addflags(
    "--bare",
    "--init-package-manager",
    "--init-type" .. clink.argmatcher():addarg({"commonjs", "module"})
)

local pack_matcher = clink.argmatcher()
add_flags(pack_matcher, recursive_flags)
:addflags(
    "--dry-run",
    "--json",
    "--out" .. file_arg,
    "--pack-destination" .. dir_arg,
    "--workspace-concurrency" .. empty_arg
)

local publish_matcher = clink.argmatcher():addarg({file_arg, dir_arg})
add_flags(publish_matcher, recursive_flags)
:addflags(
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
    { "add", description="Install a package and its dependencies" } .. add_matcher,
    { "dedupe", description="Perform an install removing older lockfile entries" } .. dedupe_matcher,
    { "fetch", description="Fetch packages from lockfile into virtual store" } .. fetch_matcher,
    { "import", description="Generate pnpm-lock.yaml from another lockfile" } .. import_matcher,
    { "i", "install", description="Install project dependencies" } .. install_matcher,
    { "it", "install-test", description="Run pnpm install then pnpm test" } .. install_test_matcher,
    { "ln", "link", description="Connect the local project to another one" } .. link_matcher,
    { "prune", description="Remove extraneous packages" } .. prune_matcher,
    { "rb", "rebuild", description="Rebuild a package" } .. rebuild_matcher,
    { "rm", "remove", description="Remove packages from node_modules and package.json" } .. remove_matcher,
    { "unlink", description="Unlink a package and reinstall saved dep" } .. unlink_matcher,
    { "up", "update", description="Update packages to latest matching versions" } .. update_matcher,
    { "patch", description="Prepare a package for patching" } .. patch_matcher,
    { "patch-commit", description="Generate a patch from a directory" } .. patch_commit_matcher,
    { "patch-remove", description="Remove existing patch files" } .. patch_remove_matcher,
    { "audit", description="Check for security issues" } .. audit_matcher,
    { "licenses", description="Check licenses in consumed packages" } .. licenses_matcher,
    { "ls", "list", description="List installed packages and dependencies" } .. list_matcher,
    { "outdated", description="Check for outdated packages" } .. outdated_matcher,
    { "why", description="Show packages that depend on the specified package" } .. why_matcher,
    { "approve-builds", description="Approve dependencies for running install scripts" } .. approve_builds_matcher,
    { "create", description="Create a project from a create-* starter kit" } .. create_matcher,
    { "dlx", description="Run a package in a temporary environment" } .. dlx_matcher,
    { "exec", description="Execute a shell command in project scope" } .. exec_matcher,
    { "ignored-builds", description="Print packages with blocked build scripts" } .. ignored_builds_matcher,
    { "run", description="Run a package.json script" } .. run_matcher,
    { "start", description="Run the start script" } .. start_matcher,
    { "t", "test", description="Run the test script" } .. test_matcher,
    { "bin", description="Print the pnpm executables directory" } .. bin_matcher,
    { "c", "config", description="Manage pnpm configuration" } .. config_matcher,
    { "deploy", description="Deploy a package from a workspace" } .. deploy_matcher,
    { "doctor", description="Check for common pnpm issues" } .. doctor_matcher,
    { "init", description="Create a package.json file" } .. init_matcher,
    { "pack", description="Create a tarball from a package" } .. pack_matcher,
    { "publish", description="Publish a package to the npm registry" } .. publish_matcher,
    { "root", description="Print the effective node_modules directory" } .. root_matcher,
    { "self-update", description="Update pnpm to the latest version" } .. self_update_matcher,
    { "env", description="Manage Node.js versions" } .. env_matcher,
    { "cat-file", description="Print the contents of a store file by hash" } .. cat_file_matcher,
    { "cat-index", description="Print a package index file from the store" } .. cat_index_matcher,
    { "find-hash", description="List packages that include the specified hash" } .. find_hash_matcher,
    { "store", description="Inspect and manage the pnpm store" } .. store_matcher,
    { "cache", description="Inspect and manage the metadata cache" } .. cache_matcher,
    { top_level_scripts },
})
:addflags(
    "-h", "--help",
    "-v", "--version",
    "-r", "--recursive"
)