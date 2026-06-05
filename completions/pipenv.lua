local matchers = require("matchers")
local w = require("tables").wrap

local parser = clink.arg.new_parser

local function pipenv_libs_list(token)
    local result = ""
    local handle = io.popen('2>nul python -c "import sys; print(\\";\\".join(sys.path))"')
    if handle then
        result = handle:read("*a")
        handle:close()
    end

    -- trim spaces
    result = clink.get_cwd() .. result:gsub("^%s*(.-)%s*$", "%1")

    local lib_paths = clink.split(result, ";")

    local list = w()
    for _,lib_path in ipairs(lib_paths) do
        lib_path = lib_path .. "\\"
        local finder = matchers.create_files_matcher(lib_path .. "*")
        local libs = finder(token)
        for _,v in ipairs(libs) do
            local ext = path.getextension(v):lower()
            if ext == ".py" then
                v = v:sub(1, #v - #ext)
                table.insert(list, v)
            elseif ext == ".dist-info" then
                if clink.is_dir(lib_path .. "/" .. v) then
                    local tmp = v:sub(1, #v - #ext)
                    if tmp:match("%-%d[%d%.]+$") then
                        v = tmp:gsub("%-%d[%d%.]+$", "")
                        table.insert(list, v)
                    end
                end
            end
        end
    end

    return list
end

local pipenv_default_flags = {
    "--python",
    "--three",
    "--two",
    "--clear",
    "--verbose",
    "-v",
    "--pypi-mirror",
    "--help",
    "-h"
}

local pipenv_check_parser = parser():add_flags(pipenv_default_flags, "--unused", "--ignore", "-i", "--system"):loop(1)

local pipenv_clean_parser = parser():add_flags(pipenv_default_flags, "--bare", "--dry-run")

local pipenv_graph_parser = parser():add_flags(pipenv_default_flags, "--bare", "--json", "--json-tree", "--reverse")

local pipenv_install_parser =
    parser():add_flags(
    pipenv_default_flags,
    "--system",
    "--code",
    "-c",
    "--deploy",
    "--skip-lock",
    "--editable",
    "-e",
    "--ignore-pipfile",
    "--selective-upgrade",
    "--pre",
    "--requirements" .. parser({clink.matches_are_files}),
    "-r" .. parser({clink.matches_are_files}),
    "--extra-index-url",
    "--index",
    "-i",
    "--sequential",
    "--keep-outdated",
    "--dev",
    "-d"
):loop(1)

local pipenv_lock_parser =
    parser():add_flags(pipenv_default_flags, "--requirements", "-r", "--keep-outdated", "--pre", "--dev", "-d")

local pipenv_open_parser = parser({pipenv_libs_list}):add_flags(pipenv_default_flags)

local pipenv_run_parser = parser():add_flags(pipenv_default_flags)

local pipenv_shell_parser = parser():add_flags("--fancy", "--anyway", pipenv_default_flags)

local pipenv_sync_parser =
    parser():add_flags("--bare", "--sequential", "--keep-outdated", "--pre", "--dev", "-d", pipenv_default_flags)

local pipenv_uninstall_parser =
    parser():add_flags(
    "--skip-lock",
    "--lock",
    "--all-dev",
    "--all",
    "--editable",
    "-e",
    "--keep-outdated",
    "--pre",
    "--dev",
    "-d",
    pipenv_default_flags
)

local pipenv_update_parser =
    parser():add_flags(
    "--bare",
    "--outdated",
    "--dry-run",
    "--editable",
    "-e",
    "--ignore-pipfile",
    "--selective-upgrade",
    "--pre",
    "--requirements",
    "-r",
    "--extra-index-url",
    "--index",
    "-i",
    "--sequential",
    "--keep-outdated",
    "--dev",
    "-d",
    pipenv_default_flags
)

local pipenv_parser =
    parser(
    {
        "check" .. pipenv_check_parser,
        "clean" .. pipenv_clean_parser,
        "graph" .. pipenv_graph_parser,
        "install" .. pipenv_install_parser,
        "lock" .. pipenv_lock_parser,
        "open" .. pipenv_open_parser,
        "run" .. pipenv_run_parser,
        "shell" .. pipenv_shell_parser,
        "sync" .. pipenv_sync_parser,
        "uninstall" .. pipenv_uninstall_parser,
        "update" .. pipenv_update_parser
    }
):add_flags(
    pipenv_default_flags,
    "--where",
    "--venv",
    "--py",
    "--envs",
    "--rm",
    "--bare",
    "--completion",
    "--man",
    "--support",
    "--site-packages",
    "--version"
)

clink.arg.register_parser("pipenv", pipenv_parser)
