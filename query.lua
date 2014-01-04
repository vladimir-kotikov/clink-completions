local function parser( ... )
    
    local arguments = {}
    local flags = {}
    
    for _, word in ipairs({...}) do
        if type(word) == "string" then
            table.insert(flags, word)
        elseif type(word) == "table" then
            table.insert(arguments, word)
        end
    end
    
    local p = clink.arg.new_parser()
    p:disable_file_matching()
    p:set_arguments(arguments)
    p:set_flags(flags)

    return p
end

local query_parser = parser({
	"process" .. parser({}, "/server:"),
	"session" .. parser({}, "/server:"),
	"termserver" .. parser({}, "/domain:", "/address", "/continue"),
	"user" .. parser({}, "/server:")
}, "/?")

clink.arg.register_parser("query", query_parser)