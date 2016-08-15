@echo off
chcp 65001 1>nul
set LUA_PATH=%~dp0modules/?.lua;%~dp0lua_modules/share/lua/5.1/?.lua;%~dp0lua_modules/share/lua/5.1/?/init.lua
%~dp0lua_modules\bin\busted -c -v --pattern=spec.lua spec
