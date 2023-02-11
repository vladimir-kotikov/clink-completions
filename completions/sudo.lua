local clink_version = require('clink_version')
if not clink_version.supports_argmatcher_chaincommand then
    print("sudo.lua argmatcher requires a newer version of Clink; please upgrade.")
    return
end

local sudo = clink.argmatcher("sudo"):chaincommand()

-- Detect when sudo from https://github.com/chrisant996/sudo-windows is being
-- used, and parse its help text to build a full argmatcher.
if os.getfileversion then

    local function delayinit(argmatcher, command_word)
        if string.lower(path.getname(command_word)) == "sudo.exe" then
            local info = os.getfileversion(command_word)
            if info and info.companyname == "Christopher Antos" then
                local help_parser = require("help_parser")
                if help_parser then
                    local function closure(argmatcher)
                        argmatcher:chaincommand()
                    end
                    help_parser.make(command_word, "-?", "gnu", nil, closure)
                end
            end
        end
    end

    sudo:setdelayinit(delayinit)

end
