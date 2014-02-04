clink-completions
=================

Completion files to clink util

Note
====

For properly work of some plugins you should modify your clink.lua at clink dir
with this:

after

	local function parser_add_arguments(parser, ...)

place:

	local function parser_add_arguments(parser, ...)
	    
	    -- This string commented out to prevent clearing of parser.arguments table
	    -- With this, call of this function will add new arguments to parser
	    -- instead of replacing them

	    -- parser.arguments = {}

	    for _, i in ipairs({...}) do
	        -- Check all arguments are tables.
	        if type(i) ~= "table" then
	            error("All arguments to set_arguments() must be tables.", 2)
	        end

	        -- Only parsers are allowed to be specified without being wrapped in a
	        -- containing table.
	        if getmetatable(i) ~= nil then
	            if is_parser(i) then
	                table.insert(parser.arguments, i)
	            else
	                error("Tables can't have meta-tables.", 2)
	            end
	        else
	            -- Expand out nested tables and insert into object's arguments table.
	            local arguments = {}
	            unfold_table(i, arguments)
	            table.insert(parser.arguments, arguments)
	        end
	    end

	    return parser
	end

and add string

	parser.add_arguments = parser_add_arguments

to function `clink.arg.new_parser()`