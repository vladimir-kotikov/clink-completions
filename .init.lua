-- Extend package.path with modules directory, if not already present, to allow
-- using require() with them.
--
-- Note: This happens in both .init.lua and !init.lua because older Cmder
-- versions don't know about !init.lua.
local modules_path = debug.getinfo(1, "S").source:match[[^@?(.*[\/])[^\/]-$]] .."modules/?.lua"
if not package.path:find(modules_path, 1, true--[[plain]]) then
    package.path = modules_path..";"..package.path
end
