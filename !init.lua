-- Note: This happens in both .init.lua and !init.lua because older Cmder
-- versions don't know about !init.lua.

-- Get the parent path of this script.
local parent_path = debug.getinfo(1, "S").source:match[[^@?(.*[\/])[^\/]-$]]

-- Extend package.path with modules directory, if not already present, to allow
-- using require() with them.
local modules_path = parent_path.."modules/?.lua"
if not package.path:find(modules_path, 1, true--[[plain]]) then
    package.path = modules_path..";"..package.path
end

-- Do shared initialization work.  The require() ensures it happens only once.
require("init_clink_completions")
