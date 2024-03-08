------------------------------------------------------------------------------
-- FD

local function try_require(module)
    local r
    pcall(function() r = require(module) end)
    return r
end

try_require("arghelper")

local fd_exclude = clink.argmatcher():addarg({})
local fd_size = clink.argmatcher():addarg({})
local fd_mindepth = clink.argmatcher():addarg({})
local fd_extension = clink.argmatcher():addarg({})
local fd_maxdepth = clink.argmatcher():addarg({})
local fd_ignorefile = clink.argmatcher():addarg({})
local fd_exec = clink.argmatcher():addarg({})
local fd_color = clink.argmatcher():addarg({"auto", "always", "never"}):adddescriptions({
  ["auto"] = "show colors if the output goes to an interactive console (default)",
  ["always"] = "always use colorized output",
  ["never"] = "do not use colorized output",
})
local fd_changedbefore = clink.argmatcher():addarg({})
local fd_gencompletions = clink.argmatcher():addarg({"bash", "elvish", "fish", "powershell", "zsh"})
local fd_execbatch = clink.argmatcher():addarg({})
local fd_searchpath = clink.argmatcher():addarg({})
local fd_maxresults = clink.argmatcher():addarg({})
local fd_threads = clink.argmatcher():addarg({})
local fd_exactdepth = clink.argmatcher():addarg({})
local fd_and = clink.argmatcher():addarg({})
local fd_pathseparator = clink.argmatcher():addarg({})
local fd_basedirectory = clink.argmatcher():addarg({})
local fd_maxbuffertime = clink.argmatcher():addarg({})
local fd_changedwithin = clink.argmatcher():addarg({})
local fd_batchsize = clink.argmatcher():addarg({})
local fd_type = clink.argmatcher():addarg({"file", "directory", "symlink", "block-device", "char-device", "executable", "empty", "socket", "pipe"}):adddescriptions({
  ["executable"] = "A file which is executable by the current effective user",
})

clink.argmatcher("fd")
:adddescriptions({
  ["--changed-within"] = { " arg", "Filter by file modification time (newer than)" },
  ["--no-global-ignore-file"] = { "Do not respect the global ignore file" },
  ["--show-errors"] = { "Show filesystem errors" },
  ["--fixed-strings"] = { "Treat pattern as literal string stead of regex" },
  ["--no-ignore"] = { "Do not respect .(git|fd)ignore files" },
  ["--list-details"] = { "Use a long listing format with file metadata" },
  ["--gen-completions"] = { " arg", "" },
  ["-l"] = { "Use a long listing format with file metadata" },
  ["--unrestricted"] = { "Unrestricted search, alias for '--no-ignore --hidden'" },
  ["--max-results"] = { " arg", "Limit the number of search results" },
  ["-t"] = { " arg", "Filter by type: file (f), directory (d), symlink (l), executable (x), empty (e), socket (s), pipe (p), char-device (c), block-device (b)" },
  ["-h"] = { "Print help (see more with '--help')" },
  ["--case-sensitive"] = { "Case-sensitive search (default: smart case)" },
  ["-d"] = { " arg", "Set maximum search depth (default: none)" },
  ["--extension"] = { " arg", "Filter by file extension" },
  ["--ignore-vcs"] = { "Overrides --no-ignore-vcs" },
  ["-I"] = { "Do not respect .(git|fd)ignore files" },
  ["--base-directory"] = { " arg", "Change current working directory" },
  ["--absolute-path"] = { "Show absolute instead of relative paths" },
  ["--exec"] = { " arg", "Execute a command for each search result" },
  ["--max-depth"] = { " arg", "Set maximum search depth (default: none)" },
  ["-0"] = { "Separate search results by the null character" },
  ["--threads"] = { " arg", "Set number of threads to use for searching & executing (default: number of available CPU cores)" },
  ["--max-buffer-time"] = { " arg", "Milliseconds to buffer before streaming search results to console" },
  ["-a"] = { "Show absolute instead of relative paths" },
  ["--color"] = { " arg", "When to use colors" },
  ["--and"] = { " arg", "Additional search patterns that need to be matched" },
  ["-e"] = { " arg", "Filter by file extension" },
  ["-s"] = { "Case-sensitive search (default: smart case)" },
  ["--ignore-file"] = { " arg", "Add a custom ignore-file in '.gitignore' format" },
  ["--search-path"] = { " arg", "Provides paths to search as an alternative to the positional <path> argument" },
  ["--relative-path"] = { "Overrides --absolute-path" },
  ["--ignore-case"] = { "Case-insensitive search (default: smart case)" },
  ["-V"] = { "Print version" },
  ["--quiet"] = { "Print nothing, exit code 0 if match found, 1 otherwise" },
  ["-j"] = { " arg", "Set number of threads to use for searching & executing (default: number of available CPU cores)" },
  ["-S"] = { " arg", "Limit results based on the size of files" },
  ["--version"] = { "Print version" },
  ["--help"] = { "Print help (see more with '--help')" },
  ["--exact-depth"] = { " arg", "Only show search results at the exact given depth" },
  ["--regex"] = { "Regular-expression based search (default)" },
  ["--strip-cwd-prefix"] = { "By default, relative paths are prefixed with './' when -x/--exec, -X/--exec-batch, or -0/--print0 are given, to reduce the risk of a path starting with '-' being treated as a command line option. Use this flag to disable this behaviour" },
  ["--no-require-git"] = { "Do not require a git repository to respect gitignores. By default, fd will only respect global gitignore rules, .gitignore rules, and local exclude rules if fd detects that you are searching inside a git repository. This flag allows you to relax this restriction such that fd will respect all git related ignore rules regardless of whether you're searching in a git repository or not" },
  ["--path-separator"] = { " arg", "Set path separator when printing file paths" },
  ["--size"] = { " arg", "Limit results based on the size of files" },
  ["-1"] = { "Limit search to a single result" },
  ["--exclude"] = { " arg", "Exclude entries that match the given glob pattern" },
  ["--prune"] = { "Do not traverse into directories that match the search criteria. If you want to exclude specific directories, use the '--exclude=…' option" },
  ["-X"] = { " arg", "Execute a command with all search results at once" },
  ["--no-ignore-vcs"] = { "Do not respect .gitignore files" },
  ["--one-file-system"] = { "By default, fd will traverse the file system tree as far as other options dictate. With this flag, fd ensures that it does not descend into a different file system than the one it started in. Comparable to the -mount or -xdev filters of find(1)" },
  ["-p"] = { "Search full abs. path (default: filename only)" },
  ["--ignore"] = { "Overrides --no-ignore" },
  ["--follow"] = { "Follow symbolic links" },
  ["-g"] = { "Glob-based search (default: regular expression)" },
  ["--hidden"] = { "Search hidden files and directories" },
  ["--no-follow"] = { "Overrides --follow" },
  ["--min-depth"] = { " arg", "Only show search results starting at the given depth." },
  ["-x"] = { " arg", "Execute a command for each search result" },
  ["--exec-batch"] = { " arg", "Execute a command with all search results at once" },
  ["--print0"] = { "Separate search results by the null character" },
  ["-F"] = { "Treat pattern as literal string stead of regex" },
  ["-E"] = { " arg", "Exclude entries that match the given glob pattern" },
  ["--full-path"] = { "Search full abs. path (default: filename only)" },
  ["--changed-before"] = { " arg", "Filter by file modification time (older than)" },
  ["--glob"] = { "Glob-based search (default: regular expression)" },
  ["--type"] = { " arg", "Filter by type: file (f), directory (d), symlink (l), executable (x), empty (e), socket (s), pipe (p), char-device (c), block-device (b)" },
  ["-i"] = { "Case-insensitive search (default: smart case)" },
  ["-u"] = { "Unrestricted search, alias for '--no-ignore --hidden'" },
  ["-L"] = { "Follow symbolic links" },
  ["--batch-size"] = { " arg", "Max number of arguments to run as a batch size with -X" },
  ["-c"] = { " arg", "When to use colors" },
  ["--require-git"] = { "Overrides --no-require-git" },
  ["-q"] = { "Print nothing, exit code 0 if match found, 1 otherwise" },
  ["--no-hidden"] = { "Overrides --hidden" },
  ["--no-ignore-parent"] = { "Do not respect .(git|fd)ignore files in parent directories" },
  ["-H"] = { "Search hidden files and directories" },
})
:addflags({
  "--and"..fd_and,
  "-d"..fd_maxdepth,
  "--max-depth"..fd_maxdepth,
  "--min-depth"..fd_mindepth,
  "--exact-depth"..fd_exactdepth,
  "-E"..fd_exclude,
  "--exclude"..fd_exclude,
  "-t"..fd_type,
  "--type"..fd_type,
  "-e"..fd_extension,
  "--extension"..fd_extension,
  "-S"..fd_size,
  "--size"..fd_size,
  "--changed-within"..fd_changedwithin,
  "--changed-before"..fd_changedbefore,
  "-x"..fd_exec,
  "--exec"..fd_exec,
  "-X"..fd_execbatch,
  "--exec-batch"..fd_execbatch,
  "--batch-size"..fd_batchsize,
  "--ignore-file"..fd_ignorefile,
  "-c"..fd_color,
  "--color"..fd_color,
  "-j"..fd_threads,
  "--threads"..fd_threads,
  "--max-buffer-time"..fd_maxbuffertime,
  "--max-results"..fd_maxresults,
  "--base-directory"..fd_basedirectory,
  "--path-separator"..fd_pathseparator,
  "--search-path"..fd_searchpath,
  "--gen-completions"..fd_gencompletions,
  "-H",
  "--hidden",
  "--no-hidden",
  "-I",
  "--no-ignore",
  "--ignore",
  "--no-ignore-vcs",
  "--ignore-vcs",
  "--no-require-git",
  "--require-git",
  "--no-ignore-parent",
  "--no-global-ignore-file",
  "-u",
  "--unrestricted",
  "-s",
  "--case-sensitive",
  "-i",
  "--ignore-case",
  "-g",
  "--glob",
  "--regex",
  "-F",
  "--fixed-strings",
  "-a",
  "--absolute-path",
  "--relative-path",
  "-l",
  "--list-details",
  "-L",
  "--follow",
  "--no-follow",
  "-p",
  "--full-path",
  "-0",
  "--print0",
  "--prune",
  "-1",
  "-q",
  "--quiet",
  "--show-errors",
  "--strip-cwd-prefix",
  "--one-file-system",
  "-h",
  "--help",
  "-V",
  "--version",
})
