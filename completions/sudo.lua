local clink_version = require('clink_version')
if not clink_version.supports_argmatcher_chaincommand then
    print("sudo.lua argmatcher requires a newer version of Clink; please upgrade.")
    return
end

clink.argmatcher("sudo"):chaincommand()
