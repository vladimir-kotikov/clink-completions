--------------------------------------------------------------------------------
-- Docker CLI completions for Clink.
--
-- https://docs.docker.com/reference/cli/docker/

-- luacheck: no max line length

local empty_arg = clink.argmatcher():addarg()
local file_arg = clink.argmatcher():addarg(clink.filematches)
local dir_arg = clink.argmatcher():addarg(clink.dirmatches)

--------------------------------------------------------------------------------
-- Dynamic completions via docker commands.

local cached_containers
local cached_running_containers
local cached_images
local cached_volumes
local cached_networks
local cached_contexts
local cached_compose_services = {}

local function reset_cache()
    cached_containers = nil
    cached_running_containers = nil
    cached_images = nil
    cached_volumes = nil
    cached_networks = nil
    cached_contexts = nil
    cached_compose_services = {}
end

if clink.onbeginedit then
    clink.onbeginedit(reset_cache)
end

local function exec_docker(args)
    local f = io.popen("2>nul docker " .. args)
    if not f then return {} end
    local result = {}
    for line in f:lines() do
        if line and line ~= "" then
            table.insert(result, line)
        end
    end
    f:close()
    return result
end

-- Compose-global flags accepted before the subcommand.
-- Values: false = boolean flag, true = takes a value but not forwarded to
-- `config --services`, "forward" = takes a value and forwarded.
local compose_global_flags = {
    ["--all-resources"] = false,
    ["--ansi"] = true,
    ["--compatibility"] = false,
    ["--dry-run"] = false,
    ["--env-file"] = "forward",
    ["-f"] = "forward",
    ["--file"] = "forward",
    ["--parallel"] = true,
    ["--profile"] = "forward",
    ["--progress"] = true,
    ["-p"] = "forward",
    ["--project-name"] = "forward",
    ["--project-directory"] = "forward",
}

local function quote_arg(arg)
    arg = arg:gsub('"', '\\"')
    if arg:sub(-1) == "\\" then
        arg = arg .. "\\"
    end
    return '"' .. arg .. '"'
end

local function parse_compose_global_flag(word)
    if compose_global_flags[word] ~= nil then
        return word
    end

    local long_flag, long_value = word:match("^(%-%-[%w%-]+)=(.*)$")
    if long_flag and compose_global_flags[long_flag] then
        return long_flag, long_value
    end

    local short_flag, short_value = word:match("^(%-[fp])=(.*)$")
    if short_flag and compose_global_flags[short_flag] then
        return short_flag, short_value
    end

    short_flag = word:sub(1, 2)
    if compose_global_flags[short_flag] and #word > 2 then
        return short_flag, word:sub(3)
    end
end

local function get_compose_config_args(line_state)
    local cwi = line_state:getcommandwordindex()
    if not cwi then
        return {}
    end

    local compose_word = line_state:getword(cwi + 1)
    if not compose_word or compose_word:lower() ~= "compose" then
        return {}
    end

    local args = {}
    local pending_flag
    for i = cwi + 2, line_state:getwordcount() do
        local info = line_state:getwordinfo(i)
        if info and not info.redir then
            local word = line_state:getword(i)
            if pending_flag then
                if compose_global_flags[pending_flag] == "forward" then
                    table.insert(args, pending_flag)
                    table.insert(args, word)
                end
                pending_flag = nil
            else
                local flag, value = parse_compose_global_flag(word)
                if flag then
                    local flag_type = compose_global_flags[flag]
                    if flag_type then
                        if value ~= nil then
                            if flag_type == "forward" then
                                table.insert(args, flag)
                                table.insert(args, value)
                            end
                        else
                            pending_flag = flag
                        end
                    end
                else
                    break
                end
            end
        end
    end

    return args
end

local function get_containers()
    if not cached_containers then
        cached_containers = exec_docker('ps -a --format "{{.Names}}"')
    end
    return cached_containers
end

local function get_running_containers()
    if not cached_running_containers then
        cached_running_containers = exec_docker('ps --format "{{.Names}}"')
    end
    return cached_running_containers
end

local function get_images()
    if not cached_images then
        cached_images = {}
        local lines = exec_docker('images --format "{{.Repository}}:{{.Tag}}"')
        for _, line in ipairs(lines) do
            if line ~= "<none>:<none>" then
                table.insert(cached_images, line)
            end
        end
    end
    return cached_images
end

local function get_volumes()
    if not cached_volumes then
        cached_volumes = exec_docker('volume ls --format "{{.Name}}"')
    end
    return cached_volumes
end

local function get_networks()
    if not cached_networks then
        cached_networks = exec_docker('network ls --format "{{.Name}}"')
    end
    return cached_networks
end

local function get_contexts()
    if not cached_contexts then
        cached_contexts = exec_docker('context ls --format "{{.Name}}"')
    end
    return cached_contexts
end

local function get_compose_services(_, _, line_state) -- luacheck: no unused args
    local docker_args = { "compose" }
    local compose_args = get_compose_config_args(line_state)
    local cache_key = table.concat(compose_args, "\n")

    if not cached_compose_services[cache_key] then
        for _, arg in ipairs(compose_args) do
            table.insert(docker_args, arg)
        end
        table.insert(docker_args, "config")
        table.insert(docker_args, "--services")

        local quoted_args = {}
        for i, arg in ipairs(docker_args) do
            quoted_args[i] = quote_arg(arg)
        end
        cached_compose_services[cache_key] = exec_docker(table.concat(quoted_args, " "))
    end

    return cached_compose_services[cache_key]
end

--------------------------------------------------------------------------------
-- Reusable value matchers.

local log_drivers = clink.argmatcher():addarg({
    "none", "local", "json-file", "syslog", "journald", "gelf",
    "fluentd", "awslogs", "splunk", "etwlogs", "gcplogs", "logentries",
})

local log_levels = clink.argmatcher():addarg({
    "debug", "info", "warn", "error", "fatal",
})

local restart_policies = clink.argmatcher():addarg({
    "no", "always", "on-failure", "unless-stopped",
})

local network_drivers = clink.argmatcher():addarg({
    "bridge", "host", "overlay", "macvlan", "none",
})

local pull_policies = clink.argmatcher():addarg({
    "always", "missing", "never",
})

local signal_matcher = clink.argmatcher():addarg({
    "SIGHUP", "SIGINT", "SIGQUIT", "SIGTERM", "SIGKILL",
    "SIGUSR1", "SIGUSR2", "SIGSTOP", "SIGCONT",
})

local format_matcher = clink.argmatcher():addarg({
    "table", "json",
})

local platform_matcher = clink.argmatcher():addarg({
    "linux/amd64", "linux/arm64", "linux/arm/v7",
})

local isolation_matcher = clink.argmatcher():addarg({
    "default", "process", "hyperv",
})

local containers_matcher = clink.argmatcher():addarg(get_containers)
local running_containers_matcher = clink.argmatcher():addarg(get_running_containers)
local networks_matcher = clink.argmatcher():addarg(get_networks)
local contexts_matcher = clink.argmatcher():addarg(get_contexts)
local compose_services_matcher = clink.argmatcher():addarg(get_compose_services)

--------------------------------------------------------------------------------
-- Subcommand parsers.

-- docker container
local container_attach = clink.argmatcher()
    :addarg(get_running_containers)
    :addflags("--detach-keys", "--no-stdin", "--sig-proxy")

local container_commit = clink.argmatcher()
    :addarg(get_containers)
    :addflags("-a" .. empty_arg, "--author" .. empty_arg,
              "-c" .. empty_arg, "--change" .. empty_arg,
              "-m" .. empty_arg, "--message" .. empty_arg,
              "-p", "--pause")

local container_cp = clink.argmatcher()
    :addarg(get_containers)
    :addflags("-a", "--archive", "-L", "--follow-link", "-q", "--quiet")

local container_create = clink.argmatcher()
    :addarg(get_images)
    :addflags({
        "--add-host" .. empty_arg,
        "--annotation" .. empty_arg,
        "--attach", "-a",
        "--blkio-weight" .. empty_arg,
        "--cap-add" .. empty_arg,
        "--cap-drop" .. empty_arg,
        "--cgroup-parent" .. empty_arg,
        "--cgroupns" .. clink.argmatcher():addarg("host", "private"),
        "--cidfile" .. file_arg,
        "--cpu-count" .. empty_arg,
        "--cpu-percent" .. empty_arg,
        "--cpu-period" .. empty_arg,
        "--cpu-quota" .. empty_arg,
        "--cpu-rt-period" .. empty_arg,
        "--cpu-rt-runtime" .. empty_arg,
        "--cpu-shares", "-c",
        "--cpus" .. empty_arg,
        "--cpuset-cpus" .. empty_arg,
        "--cpuset-mems" .. empty_arg,
        "--device" .. empty_arg,
        "--device-cgroup-rule" .. empty_arg,
        "--device-read-bps" .. empty_arg,
        "--device-read-iops" .. empty_arg,
        "--device-write-bps" .. empty_arg,
        "--device-write-iops" .. empty_arg,
        "--disable-content-trust",
        "--dns" .. empty_arg,
        "--dns-option" .. empty_arg,
        "--dns-search" .. empty_arg,
        "--domainname" .. empty_arg,
        "--entrypoint" .. empty_arg,
        "-e" .. empty_arg, "--env" .. empty_arg,
        "--env-file" .. file_arg,
        "--expose" .. empty_arg,
        "--gpus" .. clink.argmatcher():addarg("all"),
        "--group-add" .. empty_arg,
        "--health-cmd" .. empty_arg,
        "--health-interval" .. empty_arg,
        "--health-retries" .. empty_arg,
        "--health-start-interval" .. empty_arg,
        "--health-start-period" .. empty_arg,
        "--health-timeout" .. empty_arg,
        "-h" .. empty_arg, "--hostname" .. empty_arg,
        "--init",
        "-i", "--interactive",
        "--io-maxbandwidth" .. empty_arg,
        "--io-maxiops" .. empty_arg,
        "--ip" .. empty_arg,
        "--ip6" .. empty_arg,
        "--ipc" .. empty_arg,
        "--isolation" .. isolation_matcher,
        "--kernel-memory" .. empty_arg,
        "-l" .. empty_arg, "--label" .. empty_arg,
        "--label-file" .. file_arg,
        "--link" .. containers_matcher,
        "--link-local-ip" .. empty_arg,
        "--log-driver" .. log_drivers,
        "--log-opt" .. empty_arg,
        "--mac-address" .. empty_arg,
        "-m" .. empty_arg, "--memory" .. empty_arg,
        "--memory-reservation" .. empty_arg,
        "--memory-swap" .. empty_arg,
        "--memory-swappiness" .. empty_arg,
        "--mount" .. empty_arg,
        "--name" .. empty_arg,
        "--network" .. networks_matcher,
        "--network-alias" .. empty_arg,
        "--no-healthcheck",
        "--oom-kill-disable",
        "--oom-score-adj" .. empty_arg,
        "--pid" .. clink.argmatcher():addarg("host"),
        "--pids-limit" .. empty_arg,
        "--platform" .. platform_matcher,
        "--privileged",
        "-p" .. empty_arg, "--publish" .. empty_arg,
        "-P", "--publish-all",
        "--pull" .. pull_policies,
        "--quiet", "-q",
        "--read-only",
        "--restart" .. restart_policies,
        "--rm",
        "--runtime" .. empty_arg,
        "--security-opt" .. empty_arg,
        "--shm-size" .. empty_arg,
        "--sig-proxy",
        "--stop-signal" .. signal_matcher,
        "--stop-timeout" .. empty_arg,
        "--storage-opt" .. empty_arg,
        "--sysctl" .. empty_arg,
        "--tmpfs" .. empty_arg,
        "-t", "--tty",
        "--ulimit" .. empty_arg,
        "-u" .. empty_arg, "--user" .. empty_arg,
        "--userns" .. clink.argmatcher():addarg("host"),
        "--uts" .. empty_arg,
        "-v" .. empty_arg, "--volume" .. empty_arg,
        "--volume-driver" .. empty_arg,
        "--volumes-from" .. containers_matcher,
        "-w" .. empty_arg, "--workdir" .. empty_arg,
    })

-- docker run reuses container_create flags plus -d/--detach
local container_run = clink.argmatcher()
    :addarg(get_images)
    :addflags({
        "-d", "--detach",
        "--add-host" .. empty_arg,
        "--annotation" .. empty_arg,
        "--attach", "-a",
        "--blkio-weight" .. empty_arg,
        "--cap-add" .. empty_arg,
        "--cap-drop" .. empty_arg,
        "--cgroup-parent" .. empty_arg,
        "--cgroupns" .. clink.argmatcher():addarg("host", "private"),
        "--cidfile" .. file_arg,
        "--cpu-count" .. empty_arg,
        "--cpu-percent" .. empty_arg,
        "--cpu-period" .. empty_arg,
        "--cpu-quota" .. empty_arg,
        "--cpu-rt-period" .. empty_arg,
        "--cpu-rt-runtime" .. empty_arg,
        "--cpu-shares", "-c",
        "--cpus" .. empty_arg,
        "--cpuset-cpus" .. empty_arg,
        "--cpuset-mems" .. empty_arg,
        "--device" .. empty_arg,
        "--device-cgroup-rule" .. empty_arg,
        "--device-read-bps" .. empty_arg,
        "--device-read-iops" .. empty_arg,
        "--device-write-bps" .. empty_arg,
        "--device-write-iops" .. empty_arg,
        "--disable-content-trust",
        "--dns" .. empty_arg,
        "--dns-option" .. empty_arg,
        "--dns-search" .. empty_arg,
        "--domainname" .. empty_arg,
        "--entrypoint" .. empty_arg,
        "-e" .. empty_arg, "--env" .. empty_arg,
        "--env-file" .. file_arg,
        "--expose" .. empty_arg,
        "--gpus" .. clink.argmatcher():addarg("all"),
        "--group-add" .. empty_arg,
        "--health-cmd" .. empty_arg,
        "--health-interval" .. empty_arg,
        "--health-retries" .. empty_arg,
        "--health-start-interval" .. empty_arg,
        "--health-start-period" .. empty_arg,
        "--health-timeout" .. empty_arg,
        "-h" .. empty_arg, "--hostname" .. empty_arg,
        "--init",
        "-i", "--interactive",
        "--io-maxbandwidth" .. empty_arg,
        "--io-maxiops" .. empty_arg,
        "--ip" .. empty_arg,
        "--ip6" .. empty_arg,
        "--ipc" .. empty_arg,
        "--isolation" .. isolation_matcher,
        "--kernel-memory" .. empty_arg,
        "-l" .. empty_arg, "--label" .. empty_arg,
        "--label-file" .. file_arg,
        "--link" .. containers_matcher,
        "--link-local-ip" .. empty_arg,
        "--log-driver" .. log_drivers,
        "--log-opt" .. empty_arg,
        "--mac-address" .. empty_arg,
        "-m" .. empty_arg, "--memory" .. empty_arg,
        "--memory-reservation" .. empty_arg,
        "--memory-swap" .. empty_arg,
        "--memory-swappiness" .. empty_arg,
        "--mount" .. empty_arg,
        "--name" .. empty_arg,
        "--network" .. networks_matcher,
        "--network-alias" .. empty_arg,
        "--no-healthcheck",
        "--oom-kill-disable",
        "--oom-score-adj" .. empty_arg,
        "--pid" .. clink.argmatcher():addarg("host"),
        "--pids-limit" .. empty_arg,
        "--platform" .. platform_matcher,
        "--privileged",
        "-p" .. empty_arg, "--publish" .. empty_arg,
        "-P", "--publish-all",
        "--pull" .. pull_policies,
        "--quiet", "-q",
        "--read-only",
        "--restart" .. restart_policies,
        "--rm",
        "--runtime" .. empty_arg,
        "--security-opt" .. empty_arg,
        "--shm-size" .. empty_arg,
        "--sig-proxy",
        "--stop-signal" .. signal_matcher,
        "--stop-timeout" .. empty_arg,
        "--storage-opt" .. empty_arg,
        "--sysctl" .. empty_arg,
        "--tmpfs" .. empty_arg,
        "-t", "--tty",
        "--ulimit" .. empty_arg,
        "-u" .. empty_arg, "--user" .. empty_arg,
        "--userns" .. clink.argmatcher():addarg("host"),
        "--uts" .. empty_arg,
        "-v" .. empty_arg, "--volume" .. empty_arg,
        "--volume-driver" .. empty_arg,
        "--volumes-from" .. containers_matcher,
        "-w" .. empty_arg, "--workdir" .. empty_arg,
    })

local container_diff = containers_matcher
local container_export = clink.argmatcher()
    :addarg(get_containers)
    :addflags("-o" .. file_arg, "--output" .. file_arg)

local container_exec = clink.argmatcher()
    :addarg(get_running_containers)
    :addflags({
        "-d", "--detach",
        "--detach-keys" .. empty_arg,
        "-e" .. empty_arg, "--env" .. empty_arg,
        "--env-file" .. file_arg,
        "-i", "--interactive",
        "--privileged",
        "-t", "--tty",
        "-u" .. empty_arg, "--user" .. empty_arg,
        "-w" .. empty_arg, "--workdir" .. empty_arg,
    })

local container_inspect = clink.argmatcher()
    :addarg(get_containers)
    :addflags({
        "-f" .. empty_arg, "--format" .. empty_arg,
        "-s", "--size",
    })

local container_kill = clink.argmatcher()
    :addarg(get_running_containers)
    :addflags("-s" .. signal_matcher, "--signal" .. signal_matcher)

local container_logs = clink.argmatcher()
    :addarg(get_containers)
    :addflags({
        "--details",
        "-f", "--follow",
        "--since" .. empty_arg,
        "--until" .. empty_arg,
        "-n" .. empty_arg, "--tail" .. empty_arg,
        "-t", "--timestamps",
    })

local container_ls = clink.argmatcher()
    :addflags({
        "-a", "--all",
        "-f" .. empty_arg, "--filter" .. empty_arg,
        "--format" .. empty_arg,
        "-n" .. empty_arg, "--last" .. empty_arg,
        "-l", "--latest",
        "--no-trunc",
        "-q", "--quiet",
        "-s", "--size",
    })

local container_pause = running_containers_matcher
local container_unpause = containers_matcher

local container_port = containers_matcher

local container_rename = clink.argmatcher()
    :addarg(get_containers)
    :addarg()

local container_restart = clink.argmatcher()
    :addarg(get_containers)
    :addflags({
        "-s" .. signal_matcher, "--signal" .. signal_matcher,
        "-t" .. empty_arg, "--time" .. empty_arg,
    })

local container_rm = clink.argmatcher()
    :addarg(get_containers)
    :addflags("-f", "--force", "-l", "--link", "-v", "--volumes")
    :loop(1)

local container_start = clink.argmatcher()
    :addarg(get_containers)
    :addflags({
        "-a", "--attach",
        "--detach-keys" .. empty_arg,
        "-i", "--interactive",
    })
    :loop(1)

local container_stats = clink.argmatcher()
    :addarg(get_running_containers)
    :addflags({
        "-a", "--all",
        "--format" .. empty_arg,
        "--no-stream",
        "--no-trunc",
    })

local container_stop = clink.argmatcher()
    :addarg(get_running_containers)
    :addflags({
        "-s" .. signal_matcher, "--signal" .. signal_matcher,
        "-t" .. empty_arg, "--time" .. empty_arg,
    })
    :loop(1)

local container_top = running_containers_matcher

local container_update = clink.argmatcher()
    :addarg(get_containers)
    :addflags({
        "--blkio-weight" .. empty_arg,
        "--cpu-period" .. empty_arg,
        "--cpu-quota" .. empty_arg,
        "--cpu-rt-period" .. empty_arg,
        "--cpu-rt-runtime" .. empty_arg,
        "--cpu-shares", "-c",
        "--cpus" .. empty_arg,
        "--cpuset-cpus" .. empty_arg,
        "--cpuset-mems" .. empty_arg,
        "-m" .. empty_arg, "--memory" .. empty_arg,
        "--memory-reservation" .. empty_arg,
        "--memory-swap" .. empty_arg,
        "--pids-limit" .. empty_arg,
        "--restart" .. restart_policies,
    })

local container_wait = clink.argmatcher():addarg(get_containers):loop(1)

local container_prune = clink.argmatcher()
    :addflags({
        "-f", "--force",
        "--filter" .. empty_arg,
    })

-- docker container
local container_parser = clink.argmatcher()
    :addarg({
        "attach"    .. container_attach,
        "commit"    .. container_commit,
        "cp"        .. container_cp,
        "create"    .. container_create,
        "diff"      .. container_diff,
        "exec"      .. container_exec,
        "export"    .. container_export,
        "inspect"   .. container_inspect,
        "kill"      .. container_kill,
        "logs"      .. container_logs,
        "ls"        .. container_ls,
        "pause"     .. container_pause,
        "port"      .. container_port,
        "prune"     .. container_prune,
        "rename"    .. container_rename,
        "restart"   .. container_restart,
        "rm"        .. container_rm,
        "run"       .. container_run,
        "start"     .. container_start,
        "stats"     .. container_stats,
        "stop"      .. container_stop,
        "top"       .. container_top,
        "unpause"   .. container_unpause,
        "update"    .. container_update,
        "wait"      .. container_wait,
    })

--------------------------------------------------------------------------------
-- docker image

local image_build = clink.argmatcher()
    :addarg(clink.dirmatches)
    :addflags({
        "--add-host" .. empty_arg,
        "--build-arg" .. empty_arg,
        "--cache-from" .. empty_arg,
        "--cgroup-parent" .. empty_arg,
        "--compress",
        "--cpu-period" .. empty_arg,
        "--cpu-quota" .. empty_arg,
        "--cpu-shares", "-c",
        "--cpuset-cpus" .. empty_arg,
        "--cpuset-mems" .. empty_arg,
        "--disable-content-trust",
        "-f" .. file_arg, "--file" .. file_arg,
        "--force-rm",
        "--iidfile" .. file_arg,
        "--isolation" .. isolation_matcher,
        "--label" .. empty_arg,
        "-m" .. empty_arg, "--memory" .. empty_arg,
        "--memory-swap" .. empty_arg,
        "--network" .. networks_matcher,
        "--no-cache",
        "-o" .. empty_arg, "--output" .. empty_arg,
        "--platform" .. platform_matcher,
        "--progress" .. clink.argmatcher():addarg("auto", "plain", "tty", "rawjson"),
        "--pull",
        "-q", "--quiet",
        "--rm",
        "--secret" .. empty_arg,
        "--shm-size" .. empty_arg,
        "--squash",
        "--ssh" .. empty_arg,
        "-t" .. empty_arg, "--tag" .. empty_arg,
        "--target" .. empty_arg,
        "--ulimit" .. empty_arg,
    })

local image_history = clink.argmatcher()
    :addarg(get_images)
    :addflags({
        "--format" .. empty_arg,
        "-H", "--human",
        "--no-trunc",
        "-q", "--quiet",
    })

local image_import = clink.argmatcher()
    :addarg(clink.filematches)
    :addflags({
        "-c" .. empty_arg, "--change" .. empty_arg,
        "-m" .. empty_arg, "--message" .. empty_arg,
        "--platform" .. platform_matcher,
    })

local image_inspect = clink.argmatcher()
    :addarg(get_images)
    :addflags("-f" .. empty_arg, "--format" .. empty_arg)

local image_load = clink.argmatcher()
    :addflags({
        "-i" .. file_arg, "--input" .. file_arg,
        "-q", "--quiet",
    })

local image_ls = clink.argmatcher()
    :addarg(get_images)
    :addflags({
        "-a", "--all",
        "--digests",
        "-f" .. empty_arg, "--filter" .. empty_arg,
        "--format" .. empty_arg,
        "--no-trunc",
        "-q", "--quiet",
    })

local image_prune = clink.argmatcher()
    :addflags({
        "-a", "--all",
        "-f", "--force",
        "--filter" .. empty_arg,
    })

local image_pull = clink.argmatcher()
    :addarg(get_images)
    :addflags({
        "-a", "--all-tags",
        "--disable-content-trust",
        "--platform" .. platform_matcher,
        "-q", "--quiet",
    })

local image_push = clink.argmatcher()
    :addarg(get_images)
    :addflags({
        "-a", "--all-tags",
        "--disable-content-trust",
        "-q", "--quiet",
    })

local image_rm = clink.argmatcher()
    :addarg(get_images)
    :addflags("-f", "--force", "--no-prune")
    :loop(1)

local image_save = clink.argmatcher()
    :addarg(get_images)
    :addflags("-o" .. file_arg, "--output" .. file_arg)

local image_tag = clink.argmatcher()
    :addarg(get_images)
    :addarg()

local image_parser = clink.argmatcher()
    :addarg({
        "build"     .. image_build,
        "history"   .. image_history,
        "import"    .. image_import,
        "inspect"   .. image_inspect,
        "load"      .. image_load,
        "ls"        .. image_ls,
        "prune"     .. image_prune,
        "pull"      .. image_pull,
        "push"      .. image_push,
        "rm"        .. image_rm,
        "save"      .. image_save,
        "tag"       .. image_tag,
    })

--------------------------------------------------------------------------------
-- docker volume

local volume_create = clink.argmatcher()
    :addflags({
        "-d" .. clink.argmatcher():addarg("local"), "--driver" .. clink.argmatcher():addarg("local"),
        "--label" .. empty_arg,
        "-o" .. empty_arg, "--opt" .. empty_arg,
        "--name" .. empty_arg,
    })

local volume_inspect = clink.argmatcher()
    :addarg(get_volumes)
    :addflags("-f" .. empty_arg, "--format" .. empty_arg)

local volume_ls = clink.argmatcher()
    :addflags({
        "-f" .. empty_arg, "--filter" .. empty_arg,
        "--format" .. empty_arg,
        "-q", "--quiet",
    })

local volume_prune = clink.argmatcher()
    :addflags({
        "-a", "--all",
        "-f", "--force",
        "--filter" .. empty_arg,
    })

local volume_rm = clink.argmatcher()
    :addarg(get_volumes)
    :addflags("-f", "--force")
    :loop(1)

local volume_parser = clink.argmatcher()
    :addarg({
        "create"    .. volume_create,
        "inspect"   .. volume_inspect,
        "ls"        .. volume_ls,
        "prune"     .. volume_prune,
        "rm"        .. volume_rm,
    })

--------------------------------------------------------------------------------
-- docker network

local network_connect = clink.argmatcher()
    :addarg(get_networks)
    :addarg(get_containers)
    :addflags({
        "--alias" .. empty_arg,
        "--driver-opt" .. empty_arg,
        "--ip" .. empty_arg,
        "--ip6" .. empty_arg,
        "--link" .. containers_matcher,
        "--link-local-ip" .. empty_arg,
    })

local network_create = clink.argmatcher()
    :addflags({
        "--attachable",
        "--aux-address" .. empty_arg,
        "-d" .. network_drivers,
        "--driver" .. network_drivers,
        "--gateway" .. empty_arg,
        "--ingress",
        "--internal",
        "--ip-range" .. empty_arg,
        "--ipam-driver" .. empty_arg,
        "--ipam-opt" .. empty_arg,
        "--ipv6",
        "--label" .. empty_arg,
        "-o" .. empty_arg, "--opt" .. empty_arg,
        "--scope" .. clink.argmatcher():addarg("local", "swarm"),
        "--subnet" .. empty_arg,
    })

local network_disconnect = clink.argmatcher()
    :addarg(get_networks)
    :addarg(get_containers)
    :addflags("-f", "--force")

local network_inspect = clink.argmatcher()
    :addarg(get_networks)
    :addflags({
        "-f" .. empty_arg, "--format" .. empty_arg,
        "-v", "--verbose",
    })

local network_ls = clink.argmatcher()
    :addflags({
        "-f" .. empty_arg, "--filter" .. empty_arg,
        "--format" .. empty_arg,
        "--no-trunc",
        "-q", "--quiet",
    })

local network_prune = clink.argmatcher()
    :addflags({
        "-f", "--force",
        "--filter" .. empty_arg,
    })

local network_rm = clink.argmatcher()
    :addarg(get_networks)
    :addflags("-f", "--force")
    :loop(1)

local network_parser = clink.argmatcher()
    :addarg({
        "connect"       .. network_connect,
        "create"        .. network_create,
        "disconnect"    .. network_disconnect,
        "inspect"       .. network_inspect,
        "ls"            .. network_ls,
        "prune"         .. network_prune,
        "rm"            .. network_rm,
    })

--------------------------------------------------------------------------------
-- docker system

local system_df = clink.argmatcher()
    :addflags({
        "--format" .. empty_arg,
        "-v", "--verbose",
    })

local system_events = clink.argmatcher()
    :addflags({
        "-f" .. empty_arg, "--filter" .. empty_arg,
        "--format" .. empty_arg,
        "--since" .. empty_arg,
        "--until" .. empty_arg,
    })

local system_info = clink.argmatcher()
    :addflags("-f" .. empty_arg, "--format" .. empty_arg)

local system_prune = clink.argmatcher()
    :addflags({
        "-a", "--all",
        "-f", "--force",
        "--filter" .. empty_arg,
        "--volumes",
    })

local system_parser = clink.argmatcher()
    :addarg({
        "df"        .. system_df,
        "events"    .. system_events,
        "info"      .. system_info,
        "prune"     .. system_prune,
    })

--------------------------------------------------------------------------------
-- docker buildx

local buildx_build = clink.argmatcher()
    :addarg(clink.dirmatches)
    :addflags({
        "--add-host" .. empty_arg,
        "--allow" .. empty_arg,
        "--attest" .. empty_arg,
        "--build-arg" .. empty_arg,
        "--build-context" .. empty_arg,
        "--builder" .. empty_arg,
        "--cache-from" .. empty_arg,
        "--cache-to" .. empty_arg,
        "--cgroup-parent" .. empty_arg,
        "-f" .. file_arg, "--file" .. file_arg,
        "--iidfile" .. file_arg,
        "--label" .. empty_arg,
        "--load",
        "--metadata-file" .. file_arg,
        "--network" .. networks_matcher,
        "--no-cache",
        "--no-cache-filter" .. empty_arg,
        "-o" .. empty_arg, "--output" .. empty_arg,
        "--platform" .. platform_matcher,
        "--progress" .. clink.argmatcher():addarg("auto", "plain", "tty", "rawjson"),
        "--provenance" .. empty_arg,
        "--pull",
        "--push",
        "-q", "--quiet",
        "--sbom" .. empty_arg,
        "--secret" .. empty_arg,
        "--shm-size" .. empty_arg,
        "--ssh" .. empty_arg,
        "-t" .. empty_arg, "--tag" .. empty_arg,
        "--target" .. empty_arg,
        "--ulimit" .. empty_arg,
    })

local buildx_parser = clink.argmatcher()
    :addarg({
        "bake",
        "build"     .. buildx_build,
        "create",
        "du",
        "inspect",
        "ls",
        "prune",
        "rm",
        "stop",
        "use",
        "version",
    })

--------------------------------------------------------------------------------
-- docker compose

local compose_build = clink.argmatcher()
    :addarg(get_compose_services)
    :addflags({
        "--build-arg" .. empty_arg,
        "--compress",
        "--force-rm",
        "-m" .. empty_arg, "--memory" .. empty_arg,
        "--no-cache",
        "--no-rm",
        "--parallel",
        "--progress" .. clink.argmatcher():addarg("auto", "plain", "tty", "quiet"),
        "--pull",
        "-q", "--quiet",
        "--ssh" .. empty_arg,
    })

local compose_config = clink.argmatcher()
    :addflags({
        "--format" .. clink.argmatcher():addarg("yaml", "json"),
        "--hash" .. empty_arg,
        "--images",
        "--no-interpolate",
        "--no-normalize",
        "--no-path-resolution",
        "-o" .. file_arg, "--output" .. file_arg,
        "--profiles",
        "-q", "--quiet",
        "--resolve-image-digests",
        "--services",
        "--volumes",
    })

local compose_down = clink.argmatcher()
    :addflags({
        "--remove-orphans",
        "--rmi" .. clink.argmatcher():addarg("all", "local"),
        "-t" .. empty_arg, "--timeout" .. empty_arg,
        "-v", "--volumes",
    })

local compose_exec = clink.argmatcher()
    :addarg(get_compose_services)
    :addflags({
        "-d", "--detach",
        "-e" .. empty_arg, "--env" .. empty_arg,
        "--index" .. empty_arg,
        "-T", "--no-TTY",
        "--privileged",
        "-u" .. empty_arg, "--user" .. empty_arg,
        "-w" .. empty_arg, "--workdir" .. empty_arg,
    })

local compose_kill = clink.argmatcher()
    :addarg(get_compose_services)
    :addflags({
        "-s" .. signal_matcher,
        "--signal" .. signal_matcher,
    })

local compose_logs = clink.argmatcher()
    :addarg(get_compose_services)
    :addflags({
        "-f", "--follow",
        "--no-color",
        "--no-log-prefix",
        "--since" .. empty_arg,
        "-n" .. empty_arg, "--tail" .. empty_arg,
        "-t", "--timestamps",
        "--until" .. empty_arg,
    })

local compose_ps = clink.argmatcher()
    :addarg(get_compose_services)
    :addflags({
        "-a", "--all",
        "--format" .. format_matcher,
        "--filter" .. empty_arg,
        "--no-trunc",
        "-q", "--quiet",
        "--services",
        "--status" .. clink.argmatcher():addarg("paused", "restarting", "removing", "running", "dead", "created", "exited"),
    })

local compose_pull = clink.argmatcher()
    :addarg(get_compose_services)
    :addflags({
        "--ignore-buildable",
        "--ignore-pull-failures",
        "--include-deps",
        "--policy" .. pull_policies,
        "-q", "--quiet",
    })

local compose_push = clink.argmatcher()
    :addarg(get_compose_services)
    :addflags({
        "--ignore-push-failures",
        "--include-deps",
        "-q", "--quiet",
    })

local compose_restart = clink.argmatcher()
    :addarg(get_compose_services)
    :addflags({
        "--no-deps",
        "-t" .. empty_arg, "--timeout" .. empty_arg,
    })

local compose_rm = clink.argmatcher()
    :addarg(get_compose_services)
    :addflags("-f", "--force", "-s", "--stop", "-v", "--volumes")

local compose_run = clink.argmatcher()
    :addarg(get_compose_services)
    :addflags({
        "--build",
        "-d", "--detach",
        "--entrypoint" .. empty_arg,
        "-e" .. empty_arg, "--env" .. empty_arg,
        "-i", "--interactive",
        "-l" .. empty_arg, "--label" .. empty_arg,
        "--name" .. empty_arg,
        "-T", "--no-TTY",
        "--no-deps",
        "-p" .. empty_arg, "--publish" .. empty_arg,
        "--quiet-pull",
        "--rm",
        "--service-ports",
        "--use-aliases",
        "-u" .. empty_arg, "--user" .. empty_arg,
        "-v" .. empty_arg, "--volume" .. empty_arg,
        "-w" .. empty_arg, "--workdir" .. empty_arg,
    })

local compose_stop = clink.argmatcher()
    :addarg(get_compose_services)
    :addflags("-t" .. empty_arg, "--timeout" .. empty_arg)

local compose_up = clink.argmatcher()
    :addarg(get_compose_services)
    :addflags({
        "--abort-on-container-exit",
        "--abort-on-container-failure",
        "--always-recreate-deps",
        "--attach" .. compose_services_matcher,
        "--attach-dependencies",
        "--build",
        "-d", "--detach",
        "--dry-run",
        "--exit-code-from" .. compose_services_matcher,
        "--force-recreate",
        "--no-attach" .. compose_services_matcher,
        "--no-build",
        "--no-color",
        "--no-deps",
        "--no-log-prefix",
        "--no-recreate",
        "--no-start",
        "--pull" .. pull_policies,
        "--quiet-pull",
        "--remove-orphans",
        "-V", "--renew-anon-volumes",
        "--scale" .. empty_arg,
        "-t" .. empty_arg, "--timeout" .. empty_arg,
        "--timestamps",
        "-w", "--wait",
        "--wait-timeout" .. empty_arg,
    })
    :loop(1)

local compose_parser = clink.argmatcher()
    :addflags({
        "--all-resources",
        "--ansi" .. clink.argmatcher():addarg("never", "always", "auto"),
        "--compatibility",
        "--dry-run",
        "--env-file" .. file_arg,
        "-f" .. file_arg, "--file" .. file_arg,
        "--parallel" .. empty_arg,
        "--profile" .. empty_arg,
        "--progress" .. clink.argmatcher():addarg("auto", "plain", "tty", "quiet"),
        "-p" .. empty_arg, "--project-name" .. empty_arg,
        "--project-directory" .. dir_arg,
    })
    :addarg({
        "attach"    .. compose_services_matcher,
        "build"     .. compose_build,
        "config"    .. compose_config,
        "cp",
        "create"    .. compose_services_matcher,
        "down"      .. compose_down,
        "events"    .. compose_services_matcher,
        "exec"      .. compose_exec,
        "images"    .. compose_services_matcher,
        "kill"      .. compose_kill,
        "logs"      .. compose_logs,
        "ls",
        "pause"     .. compose_services_matcher,
        "port"      .. compose_services_matcher,
        "ps"        .. compose_ps,
        "pull"      .. compose_pull,
        "push"      .. compose_push,
        "restart"   .. compose_restart,
        "rm"        .. compose_rm,
        "run"       .. compose_run,
        "start"     .. compose_services_matcher,
        "stop"      .. compose_stop,
        "top"       .. compose_services_matcher,
        "unpause"   .. compose_services_matcher,
        "up"        .. compose_up,
        "version",
        "wait"      .. compose_services_matcher,
        "watch",
    })

--------------------------------------------------------------------------------
-- docker context

local context_parser = clink.argmatcher()
    :addarg({
        "create"    .. clink.argmatcher():addflags({
                            "--description" .. empty_arg,
                            "--docker" .. empty_arg,
                            "--from" .. contexts_matcher,
                        }),
        "export"    .. contexts_matcher,
        "import",
        "inspect"   .. clink.argmatcher():addarg(get_contexts)
                        :addflags("-f" .. empty_arg, "--format" .. empty_arg),
        "ls"        .. clink.argmatcher():addflags({
                            "--format" .. empty_arg,
                            "-q", "--quiet",
                        }),
        "rm"        .. clink.argmatcher():addarg(get_contexts):addflags("-f", "--force"):loop(1),
        "show",
        "update"    .. clink.argmatcher():addarg(get_contexts)
                        :addflags({
                            "--description" .. empty_arg,
                            "--docker" .. empty_arg,
                        }),
        "use"       .. contexts_matcher,
    })

--------------------------------------------------------------------------------
-- docker plugin

local plugin_parser = clink.argmatcher()
    :addarg({
        "create",
        "disable",
        "enable",
        "inspect",
        "install",
        "ls"        .. clink.argmatcher():addflags({
                            "-f" .. empty_arg, "--filter" .. empty_arg,
                            "--format" .. empty_arg,
                            "--no-trunc",
                            "-q", "--quiet",
                        }),
        "push",
        "rm",
        "set",
        "upgrade",
    })

--------------------------------------------------------------------------------
-- docker trust

local trust_parser = clink.argmatcher()
    :addarg({
        "inspect",
        "key"       .. clink.argmatcher():addarg({
                            "generate",
                            "load" .. file_arg,
                        }),
        "revoke"    .. clink.argmatcher():addarg(get_images),
        "sign"      .. clink.argmatcher():addarg(get_images),
        "signer"    .. clink.argmatcher():addarg({
                            "add",
                            "remove",
                        }),
    })

--------------------------------------------------------------------------------
-- docker manifest

local manifest_parser = clink.argmatcher()
    :addarg({
        "annotate",
        "create"    .. clink.argmatcher():addflags("-a", "--amend", "--insecure"),
        "inspect"   .. clink.argmatcher():addflags("--insecure", "-v", "--verbose"),
        "push"      .. clink.argmatcher():addflags("--insecure", "-p", "--purge"),
        "rm",
    })

--------------------------------------------------------------------------------
-- docker scout

local scout_parser = clink.argmatcher()
    :addarg({
        "compare",
        "cves",
        "environment",
        "quickview",
        "recommendations",
        "repo",
        "stream",
        "watch",
    })

--------------------------------------------------------------------------------
-- Top-level docker shortcuts and descriptions.

clink.argmatcher("docker")
    :addflags({
        "--config" .. dir_arg,
        "-c" .. contexts_matcher, "--context" .. contexts_matcher,
        "-D", "--debug",
        "-H" .. empty_arg, "--host" .. empty_arg,
        "-l" .. log_levels,
        "--log-level" .. log_levels,
        "--tls",
        "--tlscacert" .. file_arg,
        "--tlscert" .. file_arg,
        "--tlskey" .. file_arg,
        "--tlsverify",
        "-v", "--version",
    })
    :addarg({
        -- Management commands
        "builder"   .. buildx_parser,
        "buildx"    .. buildx_parser,
        "compose"   .. compose_parser,
        "container" .. container_parser,
        "context"   .. context_parser,
        "image"     .. image_parser,
        "manifest"  .. manifest_parser,
        "network"   .. network_parser,
        "plugin"    .. plugin_parser,
        "scout"     .. scout_parser,
        "system"    .. system_parser,
        "trust"     .. trust_parser,
        "volume"    .. volume_parser,

        -- Top-level shortcut commands
        "attach"    .. container_attach,
        "build"     .. image_build,
        "commit"    .. container_commit,
        "cp"        .. container_cp,
        "create"    .. container_create,
        "diff"      .. container_diff,
        "events"    .. system_events,
        "exec"      .. container_exec,
        "export"    .. container_export,
        "history"   .. image_history,
        "images"    .. image_ls,
        "import"    .. image_import,
        "info"      .. system_info,
        "inspect"   .. container_inspect,
        "kill"      .. container_kill,
        "load"      .. image_load,
        "login"     .. clink.argmatcher():addflags({
                            "-p" .. empty_arg, "--password" .. empty_arg,
                            "--password-stdin",
                            "-u" .. empty_arg, "--username" .. empty_arg,
                        }),
        "logout",
        "logs"      .. container_logs,
        "pause"     .. container_pause,
        "port"      .. container_port,
        "ps"        .. container_ls,
        "pull"      .. image_pull,
        "push"      .. image_push,
        "rename"    .. container_rename,
        "restart"   .. container_restart,
        "rm"        .. container_rm,
        "rmi"       .. image_rm,
        "run"       .. container_run,
        "save"      .. image_save,
        "search"    .. clink.argmatcher():addflags({
                            "-f" .. empty_arg, "--filter" .. empty_arg,
                            "--format" .. empty_arg,
                            "--limit" .. empty_arg,
                            "--no-trunc",
                        }),
        "start"     .. container_start,
        "stats"     .. container_stats,
        "stop"      .. container_stop,
        "tag"       .. image_tag,
        "top"       .. container_top,
        "unpause"   .. container_unpause,
        "update"    .. container_update,
        "version"   .. clink.argmatcher():addflags({
                            "-f" .. empty_arg, "--format" .. empty_arg,
                            "--kubeconfig" .. file_arg,
                        }),
        "wait"      .. container_wait,
    })
