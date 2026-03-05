local info = debug.getinfo(1, "S")
loadfile(path.join(path.getdirectory(info.source:gsub("^@", "")), "http.lua"))