local function get_parent_path(s)
    local parent = s:match("^@?(.*[/\\])[^/\\]-$")
    return parent:gsub("[/\\]+$", "")
end

-- Get the parent path of this script.
local this_file = debug.getinfo(1, "S").source
local modules_path = get_parent_path(this_file)
local root_path = get_parent_path(modules_path)
local completions_path = root_path.."\\completions"

-- Explicitly set the completions dir, in case something (such as Cmder)
-- manually loads completion scripts with them being in a Clink script path.
if os.setenv then
    local env = os.getenv("CLINK_COMPLETIONS_DIR") or ""
    if not env:find(completions_path, 1, true--[[plain]]) then
        os.setenv("CLINK_COMPLETIONS_DIR", env..(#env > 0 and ";" or "")..completions_path)
    end
end

-- Clink v1.3.23 and newer can load scripts on demand from the completions\
-- directory, but older versions need to preload them.
local clink_version = require("clink_version")
if not clink_version.supports_completions_directory then
    -- Function to preload a completion script.
    local function preload(name)
        local full = completions_path.."\\"..name..".lua"
        local chunk = loadfile(full)
        if not chunk then
            print("Failed to preload "..name.." completions.")
            return
        end
        chunk()
    end

    -- List of completion scripts that used to be always preloaded.  Continue to
    -- make sure they're preloaded when using a version of Clink that doesn't
    -- support completions\ directories.
    local list = {
        "angular-cli",
        "chocolatey", "choco", "cinst", "clist", "cuninst", "cup",
        "coho",
        "cordova", "cordova-dev",
        "dotnet",
        "kubectl", "oc",
        "msbuild",
        "net",
        "npm",
        "nvm",
        "pip",
        "pipenv",
        "scoop",
        "ssh",
        "vagrant",
        "yarn",
    }

    -- Preload the scripts.
    for _, name in ipairs(list) do
        preload(name)
    end
end
