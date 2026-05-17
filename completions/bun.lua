-- Completions for Bun (https://bun.sh)
-- luacheck: ignore clink
-- luacheck: globals matchicons

local JSON = require("JSON")
-- silence JSON parsing errors
function JSON:assert () end  -- luacheck: no unused args

local w = require('tables').wrap
local matchers = require('matchers')

-- Matches installed node_modules for package-style subcommands.
local modules = matchers.create_dirs_matcher('node_modules/*')
local run_file_matches = matchers.ext_files(
    "*.js", "*.cjs", "*.mjs", "*.mts", "*.cts", "*.ts", "*.tsx", "*.jsx"
)

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
    local script_icon = ''

    local matches = {}
    for name, cmd in pairs(pkg.scripts) do
        local description = type(cmd) == "string" and cmd or tostring(cmd)
        description = description:gsub("[\r\n]+", " "):gsub("%s+", " ")
        table.insert(matches, addicon({ match=name, description=description, type="file" }, script_icon))
    end

    table.sort(matches, function(a, b)
        return a.match < b.match
    end)

    return matches
end

-- Combines `bun run` targets so scripts are suggested first, then files.
local function run_targets(word, word_index, line_state, builder) -- luacheck: no unused args
    local matches = {}
    local seen = {}

    if builder and builder.setnosort then
        builder:setnosort()
    end

    local script_matches = scripts()
    for _, m in ipairs(script_matches) do
        local key = type(m) == "table" and m.match or m
        if key and not seen[key] then
            seen[key] = true
            table.insert(matches, m)
        end
    end

    local file_matches = run_file_matches(word)
    for _, m in ipairs(file_matches) do
        local key = type(m) == "table" and m.match or m
        if key and not seen[key] then
            seen[key] = true
            table.insert(matches, m)
        end
    end

    if #file_matches > 0 and clink.matches_are_files then
        clink.matches_are_files()
    end

    return matches
end

--------------------------------------------------------------------------------
-- Shared package-manager flags.

local pm_flags = {
    "-c", "--config=",
    "-y", "--yarn",
    "-p", "--production",
    "--no-save",
    "--save",
    "--ca=",
    "--cafile=",
    "--dry-run",
    "--frozen-lockfile",
    "-f", "--force",
    "--cache-dir=",
    "--no-cache",
    "--silent",
    "--quiet",
    "--verbose",
    "--no-progress",
    "--no-summary",
    "--no-verify",
    "--ignore-scripts",
    "--trust",
    "-g", "--global",
    "--cwd=",
    "--backend=",
    "--registry=",
    "--concurrent-scripts=",
    "--network-concurrency=",
    "--save-text-lockfile",
    "--omit=",
    "--lockfile-only",
    "--linker=",
    "--minimum-release-age=",
    "--cpu=",
    "--os=",
    "-h", "--help",
}

local function new_pm_matcher()
    local m = clink.argmatcher()
    m:addflags(table.unpack(pm_flags))
    return m
end

local shared_runtime_flags = {
    "--watch",
    "--hot",
    "--no-clear-screen",
    "--smol",
    "-r", "--preload=",
    "--require=",
    "--import=",
    "--inspect=",
    "--inspect-wait=",
    "--inspect-brk=",
    "--cpu-prof",
    "--cpu-prof-name=",
    "--cpu-prof-dir=",
    "--cpu-prof-md",
    "--cpu-prof-interval=",
    "--heap-prof",
    "--heap-prof-name=",
    "--heap-prof-dir=",
    "--heap-prof-md",
    "--if-present",
    "--no-install",
    "--install=",
    "--install=auto",
    "--install=fallback",
    "--install=force",
    "-i",
    "-e", "--eval=",
    "-p", "--print=",
    "--prefer-offline",
    "--prefer-latest",
    "--port=",
    "--conditions=",
    "--fetch-preconnect=",
    "--max-http-header-size=",
    "--dns-result-order=",
    "--dns-result-order=verbatim",
    "--dns-result-order=ipv4first",
    "--dns-result-order=ipv6first",
    "--expose-gc",
    "--no-deprecation",
    "--throw-deprecation",
    "--title=",
    "--zero-fill-buffers",
    "--use-system-ca",
    "--use-openssl-ca",
    "--use-bundled-ca",
    "--redis-preconnect",
    "--sql-preconnect",
    "--no-addons",
    "--unhandled-rejections=",
    "--unhandled-rejections=strict",
    "--unhandled-rejections=throw",
    "--unhandled-rejections=warn",
    "--unhandled-rejections=none",
    "--unhandled-rejections=warn-with-error-code",
    "--console-depth=",
    "--user-agent=",
    "--cron-title=",
    "--cron-period=",
    "--silent",
    "--elide-lines=",
    "-F", "--filter=",
    "-b", "--bun",
    "--shell=",
    "--shell=bun",
    "--shell=system",
    "--workspaces",
    "--parallel",
    "--sequential",
    "--no-exit-on-error",
    "--env-file=",
    "--no-env-file",
    "--cwd=",
    "-c", "--config=",
    "-h", "--help",
}

local function add_runtime_flags(argmatcher, extra_flags)
    argmatcher:addflags(table.unpack(shared_runtime_flags))
    if extra_flags then
        argmatcher:addflags(table.unpack(extra_flags))
    end

    return argmatcher
end

--------------------------------------------------------------------------------
-- Runtime and build/test matchers.

local run_matcher = clink.argmatcher()
:addarg({run_targets})
add_runtime_flags(run_matcher, {
    "--main-fields=",
    "--preserve-symlinks",
    "--preserve-symlinks-main",
    "--extension-order=",
    "--tsconfig-override=",
    "-d", "--define=",
    "--drop=",
    "--feature=",
    "-l", "--loader=",
    "--no-macros",
    "--jsx-factory=",
    "--jsx-fragment=",
    "--jsx-import-source=",
    "--jsx-runtime=",
    "--jsx-runtime=automatic",
    "--jsx-runtime=classic",
    "--jsx-side-effects",
    "--ignore-dce-annotations",
})

local test_matcher = clink.argmatcher()
:addarg({clink.filematches}):loop(1)
:addflags(
    "--timeout=",
    "-u", "--update-snapshots",
    "--rerun-each=",
    "--retry=",
    "--todo",
    "--only",
    "--pass-with-no-tests",
    "--concurrent",
    "--randomize",
    "--seed=",
    "--coverage",
    "--coverage-reporter=",
    "--coverage-reporter=text",
    "--coverage-reporter=lcov",
    "--coverage-dir=",
    "--bail=",
    "-t", "--test-name-pattern=",
    "--reporter=",
    "--reporter=junit",
    "--reporter=dots",
    "--reporter-outfile=",
    "--dots",
    "--only-failures",
    "--max-concurrency=",
    "--path-ignore-patterns=",
    "--changed=",
    "--isolate",
    "--parallel=",
    "--parallel-delay=",
    "--shard=",
    "-h", "--help"
)

local build_matcher = clink.argmatcher()
:addarg({clink.filematches}):loop(1)
:addflags(
    "--production",
    "--compile",
    "--compile-exec-argv=",
    "--compile-autoload-dotenv",
    "--no-compile-autoload-dotenv",
    "--compile-autoload-bunfig",
    "--no-compile-autoload-bunfig",
    "--compile-autoload-tsconfig",
    "--no-compile-autoload-tsconfig",
    "--compile-autoload-package-json",
    "--no-compile-autoload-package-json",
    "--compile-executable-path=",
    "--bytecode",
    "--watch",
    "--no-clear-screen",
    "--target=",
    "--target=browser",
    "--target=bun",
    "--target=node",
    "--outdir=",
    "--outfile=",
    "--metafile=",
    "--metafile-md=",
    "--sourcemap=",
    "--sourcemap=linked",
    "--sourcemap=inline",
    "--sourcemap=external",
    "--sourcemap=none",
    "--banner=",
    "--footer=",
    "--format=",
    "--format=esm",
    "--format=cjs",
    "--format=iife",
    "--root=",
    "--splitting",
    "--public-path=",
    "-e", "--external=",
    "--allow-unresolved=",
    "--reject-unresolved",
    "--packages=",
    "--packages=external",
    "--packages=bundle",
    "--entry-naming=",
    "--chunk-naming=",
    "--asset-naming=",
    "--react-fast-refresh",
    "--no-bundle",
    "--emit-dce-annotations",
    "--minify",
    "--minify-syntax",
    "--minify-whitespace",
    "--minify-identifiers",
    "--keep-names",
    "--css-chunking",
    "--conditions=",
    "--app",
    "--server-components",
    "--env=",
    "--windows-hide-console",
    "--windows-icon=",
    "--windows-title=",
    "--windows-publisher=",
    "--windows-version=",
    "--windows-description=",
    "--windows-copyright=",
    "-h", "--help"
)

--------------------------------------------------------------------------------
-- Package-oriented subcommands.

local install_matcher = new_pm_matcher()
:addarg({matchers.dirs}):loop(1)
:addflags(
    "--filter=",
    "-d", "--dev",
    "--optional",
    "--peer",
    "-E", "--exact",
    "-a", "--analyze",
    "--only-missing"
)

local add_matcher = new_pm_matcher()
:addflags(
    "-d", "--dev",
    "--optional",
    "--peer",
    "-E", "--exact",
    "-a", "--analyze",
    "--only-missing"
)

local remove_matcher = new_pm_matcher()
:addarg({modules}):loop(1)

local update_matcher = new_pm_matcher()
:addarg({modules}):loop(1)
:addflags(
    "--latest",
    "-i", "--interactive",
    "--filter=",
    "-r", "--recursive"
)

local audit_matcher = clink.argmatcher()
:addflags(
    "--json",
    "--audit-level=",
    "--ignore=",
    "-h", "--help"
)

local info_matcher = new_pm_matcher()
:addflags("--json")

local outdated_matcher = new_pm_matcher()
:addflags(
    "-F", "--filter=",
    "-r", "--recursive"
)

local link_matcher = new_pm_matcher()
:addarg({modules}):loop(1)

local unlink_matcher = new_pm_matcher()

local publish_matcher = new_pm_matcher()
:addarg({clink.filematches}):loop(1)
:addflags(
    "--access=",
    "--tag=",
    "--otp=",
    "--auth-type=",
    "--gzip-level=",
    "--tolerate-republish"
)

local patch_matcher = new_pm_matcher()
:addarg({modules, clink.filematches}):loop(1)
:addflags(
    "--commit",
    "--patches-dir="
)

--------------------------------------------------------------------------------
-- Other subcommands.

local why_matcher = clink.argmatcher()
:addflags("--top", "--depth")

local x_matcher = clink.argmatcher()
:addflags(
    "--bun",
    "-p", "--package",
    "--no-install",
    "--verbose",
    "--silent",
    "-h", "--help"
)

local init_matcher = clink.argmatcher()
:addarg({matchers.dirs}):loop(1)
:addflags(
    "--help",
    "-y", "--yes",
    "-m", "--minimal",
    "-r", "--react",
    "--react=tailwind",
    "--react=shadcn"
)

local feedback_matcher = clink.argmatcher()
:addarg({clink.filematches}):loop(1)
:addflags(
    "-e", "--email",
    "-h", "--help"
)

local upgrade_matcher = clink.argmatcher()
:addflags("--canary", "-h", "--help")

local pm_matcher = clink.argmatcher()
:addarg({
    "scan",
    "pack" .. clink.argmatcher():addflags(
        "--dry-run",
        "--destination",
        "--filename",
        "--ignore-scripts",
        "--gzip-level",
        "--quiet"
    ),
    "bin" .. clink.argmatcher():addflags("-g"),
    "list" .. clink.argmatcher():addflags("--all"),
    "why",
    "whoami",
    "view",
    "version" .. clink.argmatcher():addarg({
        "patch", "minor", "major", "prepatch",
        "preminor", "premajor", "prerelease", "from-git",
    }),
    "pkg" .. clink.argmatcher():addarg({"get", "set", "delete", "fix"}),
    "hash",
    "hash-string",
    "hash-print",
    "cache" .. clink.argmatcher():addarg({"rm"}),
    "migrate",
    "untrusted",
    "trust" .. clink.argmatcher():addflags("--all"),
    "default-trusted",
}):addflags("-h", "--help")

-- bun repl and bun exec currently report the same runtime option surface as bun run.
local repl_matcher = run_matcher
local exec_matcher = run_matcher

--------------------------------------------------------------------------------
-- Main bun argmatcher.

local bun_matcher = clink.argmatcher("bun")
:addarg({
    "add"      .. add_matcher,
    "a"        .. add_matcher,
    "audit"    .. audit_matcher,
    "build"    .. build_matcher,
    "create",
    "c",
    "exec"     .. exec_matcher,
    "feedback" .. feedback_matcher,
    "info"     .. info_matcher,
    "init"     .. init_matcher,
    "install"  .. install_matcher,
    "i"        .. install_matcher,
    "link"     .. link_matcher,
    "outdated" .. outdated_matcher,
    "patch"    .. patch_matcher,
    "pm"       .. pm_matcher,
    "publish"  .. publish_matcher,
    "remove"   .. remove_matcher,
    "rm"       .. remove_matcher,
    "r"        .. remove_matcher,
    "repl"     .. repl_matcher,
    "run"      .. run_matcher,
    "test"     .. test_matcher,
    "unlink"   .. unlink_matcher,
    "update"   .. update_matcher,
    "upgrade"  .. upgrade_matcher,
    "why"      .. why_matcher,
    "x"        .. x_matcher,
    run_targets,
})
add_runtime_flags(bun_matcher, {
    "-v", "--version",
    "--revision",
})
:adddescriptions(
    -- luacheck: push max line length 130
    { "add", "a", description = "Add a dependency to package.json" },
    { "audit", description = "Check installed packages for vulnerabilities" },
    { "build", description = "Bundle TypeScript & JavaScript into a single file" },
    { "create", "c", description = "Create a new project from a template" },
    { "exec", description = "Run a shell script directly with Bun" },
    { "feedback", description = "Send feedback to the Bun team" },
    { "info", description = "Show information about installed packages" },
    { "init", description = "Initialize a new project and create a package.json" },
    { "install", "i", description = "Install dependencies from package.json" },
    { "link", description = "Symlink a local package into node_modules" },
    { "outdated", description = "Check for outdated packages" },
    { "patch", description = "Apply a patch to a package in node_modules or create a patch from changes to it" },
    { "pm", description = "Run a package manager command without leaving Bun's context" },
    { "publish", description = "Publish a package to the npm registry" },
    { "remove", "rm", "r", description = "Remove packages from dependencies and node_modules" },
    { "repl", description = "Start an interactive REPL session with access to project modules" },
    { "run", description = "Execute a file with Bun" },
    { "test", description = "Run tests with the built-in test runner" },
    { "unlink", description = "Remove symlinked local packages from node_modules" },
    { "update", description = "Update dependencies to their most recent versions within the version range in package.json" },
    { "upgrade", description = "Upgrade Bun to the latest version, or optionally the latest canary version" },
    { "why", description = "Show the dependency chain that leads to a package" },
    { "x", description = "Execute a package binary (CLI), installing if needed" }
    -- luacheck: pop
)
