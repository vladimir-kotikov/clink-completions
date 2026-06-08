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
