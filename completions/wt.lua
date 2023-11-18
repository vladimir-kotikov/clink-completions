require("arghelper")

local pos_args = clink.argmatcher():addarg({fromhistory=true, loopchars=","})
local size_args = clink.argmatcher():addarg({fromhistory=true, loopchars=","})
local window_args = clink.argmatcher():addarg({fromhistory=true})

local subcommands = {
    ["nt"]=true, ["new-tab"]=true,
    ["sp"]=true, ["split-pane"]=true,
    ["ft"]=true, ["focus-tab"]=true,
    ["mf"]=true, ["move-focus"]=true,
    ["mp"]=true, ["move-pane"]=true,
                 ["swap-pane"]=true,
    ["fp"]=true, ["focus-pane"]=true,
}

local function classify_but_never_generate(arg_index, word, word_index, line_state)
    if arg_index == 1 and not subcommands[word] then
        return 1 -- Ignore this arg index.
    end
end

local single_char_flags = { "-?", "-h", "-v", "-M", "-F", "-f" }

clink.argmatcher("wt")
:addflags(single_char_flags, "-w"..window_args)
:hideflags(single_char_flags, "-w")
:_addexflags({
    { "--help",                         "Show command line help" },
    { "--version",                      "Display the application version" },
    { "--maximized",                    "Launch the window maximized" },
    { "--fullscreen",                   "Launch the window in fullscreen mode" },
    { "--focus",                        "Launch the window in focus mode" },
    { "--pos"..pos_args, " x,y",        "Specify the position for the terminal" },
    { "--size"..size_args, " cols,rows", "Specify the number of columns and rows for the terminal" },
    { "--window"..window_args, " num",  "Specify a terminal window to run the commandline in ('0' for current)" },
})

if (clink.version_encoded or 0) >= 10050014 then
    argmatcher:_addexarg({
        onadvance=classify_but_never_generate,
        { hide=true, "nt" },
        { "new-tab",                        "Create a new tab" },
        { hide=true, "sp" },
        { "split-pane",                     "Create a new split pane" },
        { hide=true, "ft" },
        { "focus-tab",                      "Move focus to another tab" },
        { hide=true, "mf" },
        { "move-focus",                     "Move focus to the adjacent pane in the specified direction" },
        { hide=true, "mp" },
        { "move-pane",                      "Move focused pane to another tab" },
        -- No alias for swap-pane.
        { "swap-pane",                      "Swap the focused pane with the adjacent pane in the specified direction" },
        { hide=true, "fp" },
        { "focus-pane",                     "Move focus to another pane" },
    })
end

if argmatcher.chaincommand then
    argmatcher:chaincommand()
end
