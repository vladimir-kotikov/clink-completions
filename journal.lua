
local main_parser

local function flags(...)
    local p = clink.arg.new_parser()
    p:disable_file_matching()
    p:set_flags(...)
    return p
end

local function arguments(...)
    local p = clink.arg.new_parser()
    p:disable_file_matching()
    p:set_arguments(...)
    return p
end

main_parser = clink.arg.new_parser()
main_parser:set_arguments({
    "done" .. flags(),
    "add" .. flags("-i", "--insert-into"),
    "del" .. flags(),
    "тест" .. flags("-f", "--bar"),
    "list" .. flags("-s", "--sort-by", "-d", "--desc")
})

clink.arg.register_parser("main", main_parser)

