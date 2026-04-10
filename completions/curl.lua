local clink_version = require('clink_version')
if not clink_version.supports_argmatcher_delayinit then
    log.info("curl.lua argmatcher requires a newer version of Clink; please upgrade.")
    return
end

local help_parser = require('help_parser')
if not help_parser then
    return
end

help_parser.make('curl', '--help all', 'curl')
