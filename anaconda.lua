local w = require('tables').wrap

local parser = clink.arg.new_parser

local function find_environment_txt()
    local reltive_path = ".conda\\environments.txt"
    local environment_txt_path

    local home_path = os.getenv("HOME")
    if home_path then
		environment_txt_path = home_path .. "\\" .. reltive_path
    else
		environment_txt_path = clink.get_env("HOMEDRIVE")
	    .. clink.get_env("HOMEPATH") .. "\\" .. reltive_path
	end

	return environment_txt_path:gsub("\\\\", "\\")
end

local function all_envs()
    -- base
    local res = w({"base"})

    -- find the .conda/environments.txt
	local environment_path = find_environment_txt()
    local f = io.open(environment_path)
    if not f then return res end

    local environment_txt = f:read('*all')
    f:close()

    -- plus envs from environments.txt if found
    for env in environment_txt:gmatch("envs\\(%S+)") do
	table.insert(res, env)
    end

    return res
end

local function other_envs()
    local current_environment = clink.get_env("CONDA_DEFAULT_ENV")

    return all_envs()
	:filter(function(env)
		return env ~= current_environment
	       end)
end


local anaconda_parser = parser(
	"--help",
	"-h",
    {
	"clean" .. parser(
		"-h", "--help",
		"-a", "--all",
		"-i", "--index-cache",
		"-p", "--packages",
		"-t", "--tarballs",
		"-f", "--force-pkgs-dirs",
		"-c", "--tempfiles",
		"-d", "--dry-run",
		"--json",
		"-q", "--quiet",
		"-v", "--verbose",
		"-y", "--yes"),
	"config" .. parser(
		"-h", "--help",
		"--json",
		"-v", "--verbose",
		"-q", "--quiet",
		"--system",
		"--env",
		"--file",
		"--show",
		"--show-sources",
		"--validate",
		"--describe",
		"--write-default",
		"--get",
		"--append",
		"--prepend", "--add",
		"--set",
		"--remove",
		"--remove-key",
		"--stdin"),
	"create" .. parser(
		"-h", "--help",
		"--clone",
		"--file",
		"-n", "--name",
		"-p", "--prefix",
		"-c", "--channel",
		"--use-local",
		"--override-channels",
		"--repodata-fn",
		"--strict-channel-priorit",
		"--no-channel-priorit",
		"--no-deps",
		"--only-deps",
		"--no-pin",
		"--no-default-package",
		"--copy",
		"--no-shortcuts",
		"-C", "--use-index-cach",
		"-k", "--insecure",
		"--offline",
		"-d", "--dry-run",
		"--json",
		"-q", "--quiet",
		"-v", "--verbose",
		"-y", "--yes",
		"--download-only",
		"--show-channel-urls"),
	"help",
	"info" .. parser(
		"-h", "--help",
		"-a", "--all",
		"--base",
		"-e", "--envs",
		"-s", "--system",
		"--unsafe-channels",
		"--json",
		"-v", "--verbose",
		"-q", "--quiet"),
	"init" .. parser(
		"-h", "--help",
		"--all",
		"--anaconda-prompt",
		"-d", "--dry-run",
		"--reverse",
		"--json",
		"-v", "--verbose",
		"-q", "--quiet"),
	"install" .. parser(
		"-h", "--help",
		"--revision",
		"--file",
		"--dev",
		"-n" .. parser({all_envs}),
		"--name" .. parser({all_envs}),
		"-p", "--prefix",
		"-c", "--channel",
		"--use-local",
		"--override-channels",
		"--repodata-fn",
		"--strict-channel-priority",
		"--no-channel-priority",
		"--no-deps",
		"--only-deps",
		"--no-pin",
		"--force-reinstall",
		"--freeze-installed", "--no-update-deps",
		"--update-deps",
		"-S", "--satisfied-skip-solve",
		"--update-all", "--all",
		"--update-specs",
		"--copy",
		"--no-shortcuts",
		"-m", "--mkdir",
		"--clobber",
		"-C", "--use-index-cache",
		"-k", "--insecure",
		"--offline",
		"-d", "--dry-run",
		"--json",
		"-q", "--quiet",
		"-v", "--verbose",
		"-y", "--yes",
		"--download-only",
		"--show-channel-urls"),
	"list" .. parser(
		"-h", "--help",
		"--show-channel-urls",
		"-c", "--canonical",
		"-f", "--full-name",
		"--explicit",
		"--md5",
		"-e", "--export",
		"-r", "--revisions",
		"--no-pip",
		"-n" .. parser({all_envs}),
		"--name" .. parser({all_envs}),
		"-p PATH", "--prefix PATH",
		"--json",
		"-v", "--verbose",
		"-q", "--quiet"),
	"package" .. parser(
		"-h", "--help",
		"-w", "--which",
		"-r", "--reset",
		"-u", "--untracked",
		"--pkg-name",
		"--pkg-version",
		"--pkg-build",
		"-n" .. parser({all_envs}),
		"--name" .. parser({all_envs}),
		"-p", "--prefix"),
	"remove" .. parser(
		"-h", "--help",
		"--dev",
		"-n" .. parser({all_envs}),
		"--name" .. parser({all_envs}),
		"-p", "--prefix",
		"-c", "--channel",
		"--use-local",
		"--override-channels",
		"--repodata-fn",
		"--all",
		"--features",
		"--force-remove", "--force",
		"--no-pin",
		"-C", "--use-index-cache",
		"-k", "--insecure",
		"--offline",
		"-d", "--dry-run",
		"--json",
		"-q", "--quiet",
		"-v", "--verbose",
		"-y", "--yes"),
	"uninstall" .. parser(
		"-h", "--help",
		"--dev",
		"-n" .. parser({all_envs}),
		"--name" .. parser({all_envs}),
		"-p", "--prefix",
		"-c", "--channel",
		"--use-local",
		"--override-channels",
		"--repodata-fn",
		"--all",
		"--features",
		"--force-remove", "--force",
		"--no-pin",
		"-C", "--use-index-cache",
		"-k", "--insecure",
		"--offline",
		"-d", "--dry-run",
		"--json",
		"-q", "--quiet",
		"-v", "--verbose",
		"-y", "--yes"),
	"run" .. parser(
		"-h", "--help",
		"-v", "--verbose",
		"--dev",
		"--debug-wrapper-scripts",
		"--cwd",
		"-n" .. parser({all_envs}),
		"--name" .. parser({all_envs}),
		"-p", "--prefix"),
	"search" .. parser(
		"-h", "--help",
		"--envs",
		"-i", "--info",
		"--subdir", "--platform",
		"-c", "--channel",
		"--use-local",
		"--override-channels",
		"--repodata-fn",
		"-C", "--use-index-cache",
		"-k", "--insecure",
		"--offline",
		"--json",
		"-v", "--verbose",
		"-q", "--quiet"),
	"update" .. parser(
		"-h", "--help",
		"--file",
		"-n" .. parser({all_envs}),
		"--name" .. parser({all_envs}),
		"-p", "--prefix",
		"-c", "--channel",
		"--use-local",
		"--override-channels",
		"--repodata-fn",
		"--strict-channel-priority",
		"--no-channel-priority",
		"--no-deps",
		"--only-deps",
		"--no-pin",
		"--force-reinstall",
		"--freeze-installed", "--no-update-deps",
		"--update-deps",
		"-S", "--satisfied-skip-solve",
		"--update-all", "--all",
		"--update-specs",
		"--copy",
		"--no-shortcuts",
		"--clobber",
		"-C", "--use-index-cache",
		"-k", "--insecure",
		"--offline",
		"-d", "--dry-run",
		"--json",
		"-q", "--quiet",
		"-v", "--verbose",
		"-y", "--yes",
		"--download-only",
		"--show-channel-urls"),
	"upgrade" .. parser(
		"-h", "--help",
		"--file FILE",
		"-n" .. parser({all_envs}),
		"--name" .. parser({all_envs}),
		"-p", "--prefix",
		"-c", "--channel",
		"--use-local",
		"--override-channels",
		"--repodata-fn",
		"--strict-channel-priority",
		"--no-channel-priority",
		"--no-deps",
		"--only-deps",
		"--no-pin",
		"--force-reinstall",
		"--freeze-installed", "--no-update-deps",
		"--update-deps",
		"-S", "--satisfied-skip-solve",
		"--update-all", "--all",
		"--update-specs",
		"--copy",
		"--no-shortcuts",
		"--clobber",
		"-C", "--use-index-cache",
		"-k", "--insecure",
		"--offline",
		"-d", "--dry-run",
		"--json",
		"-q", "--quiet",
		"-v", "--verbose",
		"-y", "--yes",
		"--download-only",
		"--show-channel-urls"),
	"env" .. parser({
		"create" .. parser(
			"-h", "--help",
			"-f", "--file",
			"--force",
			"-n", "--name",
			"-p", "--prefix",
			"-C", "--use-index-cache",
			"-k", "--insecure",
			"--offline",
			"--json",
			"-v", "--verbose",
			"-q", "--quiet"),
		"export" .. parser(
			"-h", "--help",
			"-c", "--channel",
			"--override-channels",
			"-f", "--file",
			"--no-builds",
			"--ignore-channels",
			"--from-history",
			"-n" .. parser({all_envs}),
			"--name" .. parser({all_envs}),
			"-p", "--prefix",
			"--json",
			"-v", "--verbose",
			"-q", "--quiet"),

		"list" .. parser(
			"-h", "--help",
			"--json",
			"-v", "--verbose",
			"-q", "--quiet"),

		"remove" .. parser(
			"-h", "--help",
			"-n" .. parser({other_envs}),
			"--name" .. parser({other_envs}), "-p",
			"--prefix", "-d", "--dry-run", "--json",
			"-q", "--quiet",
			"-v", "--verbose",
			"-y", "--yes"),

		"update" .. parser(
			"-h", "--help",
			"-f", "--file",
			"--prune",
			"-n" .. parser({all_envs}),
			"--name" .. parser({all_envs}),
			"-p", "--prefix",
			"--json",
			"-v", "--verbose",
			"-q", "--quiet"),

		"config" .. parser({"-h", "--help"}),
		"--help",
		"-h"
		       }),
	"activate" .. parser({other_envs}, "-h", "--help", "--stack", "--no-stack"),
	"deactivate" .. parser("-h", "--help")
    }
)

clink.arg.register_parser("conda", anaconda_parser)

