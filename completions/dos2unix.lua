require('arghelper')
local mcf = require('multicharflags')

local convmode = clink.argmatcher():addarg({"ascii", "7bit", "iso", "mac"})
local encoding = clink.argmatcher():addarg({"ansi", "unicode", "utf8"})
local info_flags = mcf.addcharflagsarg(clink.argmatcher(), {
    {"0",   "Print the file information lines followed by a null character instead of a newline character."},
            -- This enables correct interpretation of file names with spaces or quotes when flag c is used. Use this flag
            -- in combination with xargs option -0 or --null.
    {"d",   "Print number of DOS line breaks."},
    {"u",   "Print number of Unix line breaks."},
    {"m",   "Print number of Mac line breaks."},
    {"b",   "Print the byte order mark."},
    {"t",   "Print if file is text or binary."},
    {"e",   "Print the type of the line break of the last line, or noeol if there is none."},
    {"c",   "Print only the files that would be converted."},
            -- With the c flag dos2unix will print only the files that contain DOS line breaks, unix2dos will print only
            -- file names that have Unix line breaks. If in addition option -e or --add-eol is used also the files that
            -- lack a line break on the last line will be printed.
    {"h",   "Print a header."},
    {"p",   "Show file names without path."},
})

local flag_def_table = {
    {nil,   "-ascii",                           "default conversion mode"},
    {nil,   "-iso",                             "conversion between DOS and ISO-8859-1 character set"},
    {nil,   "-1252",                            "use Windows code page 1252 (Western European)"},
    {nil,   "-437",                             "use DOS code page 437 (US) (default)"},
    {nil,   "-850",                             "use DOS code page 850 (Western European)"},
    {nil,   "-860",                             "use DOS code page 860 (Portuguese)"},
    {nil,   "-863",                             "use DOS code page 863 (French Canadian)"},
    {nil,   "-865",                             "use DOS code page 865 (Nordic)"},
    {"-7",  nil,                                "convert 8 bit characters to 7 bit space"},
    {"-b",  "--keep-bom",                       "keep Byte Order Mark"},
    {"-c",  "--convmode", convmode, " CONVMODE", "conversion mode (default is ascii)"},
    {"-D",  "--display-enc", encoding, " ENCODING", "set encoding of displayed text messages (default is ansi)"},
    {"-e",  "--add-eol",                        "add a line break to the last line if there isn't one"},
    {"-f",  "--force",                          "force conversion of binary files"},
    {"-gb", "--gb18030",                        "convert UTF-16 to GB18030"},
    {"-h",  "--help",                           "display this help text"},
    {"-i", nil, nil, "[FLAGS] FILE ...", "display file information"},
    {nil,   "--info", nil, " FILE ...",         "display file information"},
    {nil,   "--info=", info_flags, "FLAGS FILE ...", "display file information"},
    {"-k",  "--keepdate",                       "keep output file date"},
    {"-L",  "--license",                        "display software license"},
    {"-l",  "--newline",                        "add additional newline"},
    {"-m",  "--add-bom",                        "add Byte Order Mark (default UTF-8)"},
    {"-n",  "--newfile", nil, " INFILE OUTFILE ...", "write to new file"},
    {nil,   "--no-add-eol",                     "don't add a line break to the last line if there isn't one (default)"},
    {"-O",  "--to-stdout", nil, " INFILE ...",  "write to standard output"},
    {"-o",  "--oldfile", nil, " FILE ...",      "write to old file (default)"},
    {"-q",  "--quiet",                          "quiet mode, suppress all warnings"},
    {"-r",  "--remove-bom",                     "remove Byte Order Mark (default)"},
    {"-s",  "--safe",                           "skip binary files (default)"},
    {"-u",  " --keep-utf16",                    "keep UTF-16 encoding"},
    {"-ul", "--assume-utf16le",                 "assume that the input format is UTF-16LE"},
    {"-ub", "--assume-utf16be",                 "assume that the input format is UTF-16BE"},
    {"-v",  " --verbose",                       "verbose operation"},
    {"-R",  "--replace-symlink",                "replace symbolic links with converted files"},
                                                -- (original target files remain unchanged)
    {"-S", "--skip-symlink",                    "keep symbolic links and targets unchanged (default)"},
    {"-V", "--version",                         "display version number"},
}

local flags = {}
for _,f in ipairs(flag_def_table) do
    if not f[4] then
        if f[1] then
            table.insert(flags, { f[1], f[3] })
        end
        if f[2] then
            table.insert(flags, { f[2], f[3] })
        end
    elseif f[3] then
        if f[1] then
            table.insert(flags, { f[1]..f[3], f[4], f[5] })
        end
        if f[2] then
            table.insert(flags, { f[2]..f[3], f[4], f[5] })
        end
    else
        if f[1] then
            table.insert(flags, { f[1], f[4], f[5] })
        end
        if f[2] then
            table.insert(flags, { f[2], f[4], f[5] })
        end
    end
end

-- luacheck: no max line length
local dos2unix = clink.argmatcher("dos2unix")
:setflagsanywhere(true)
:_addexflags(flags)

local old_classifier = dos2unix._classify_func
local custom_adjacent = {}
custom_adjacent["-i"] = true

local function custom_classifier(arg_index, word, word_index, line_state, classifications)
    if arg_index == 0 then
        local key = word:sub(1, 2)
        if custom_adjacent[key] then
            local info = line_state:getwordinfo(word_index)
            classifications:applycolor(info.offset, #key, settings.get("color.flag") or "", true)
            return
        end
    end
    if old_classifier then
        return old_classifier(arg_index, word, word_index, line_state, classifications)
    end
end

dos2unix:setclassifier(custom_classifier)
