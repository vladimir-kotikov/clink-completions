@set LUA_PATH=%~dp0lua_modules\share/lua/5.1/?.lua;%~dp0lua_modules/share/lua/5.1/?/init.lua
@%~dp0lua_modules\bin\busted -c -v --pattern=spec -- spec
