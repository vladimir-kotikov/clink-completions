local clink_version = require('clink_version')
if not clink_version.supports_argmatcher_delayinit then
    log.info("xcopy.lua argmatcher requires a newer version of Clink; please upgrade.")
    return
end

local function closure(parser)
    -- This is a dirty hack.  I don't want to invest in a reusable clean
    -- mechanism right now.
    if parser._flags and parser._flags._args and parser._flags._args[1] then
        local tbl = { concat_one_letter_flags=true }
        if parser._flags._args[1]._links["/d:"] then
            table.insert(tbl, { hide=true, "/d" })
        end
        if parser._flags._args[1]._links["/D:"] then
            local desc = parser._descriptions["/D:"]
            table.insert(tbl, { "/D", desc[#desc] })
        end
        if tbl[1] then
            parser:_addexflags(tbl)
        end
    end
end

require('help_parser').make('xcopy', '/?', nil, {concat=true}, closure)
