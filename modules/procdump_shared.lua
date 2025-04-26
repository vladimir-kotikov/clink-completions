require("arghelper")

local pid_complete = require("pid_complete")
local pid_parser = pid_complete.argmatcher

local function dll_file_matches(word)
    if clink.filematchesexact then
        local matches = clink.dirmatches(word)
        local files = clink.filematchesexact(word.."*.dll")
        for _, f in ipairs(files) do
            table.insert(matches, f)
        end
        return matches
    else
        return clink.filematches(word)
    end
end

local function get_word_direct(line_state, word_index)
    local word
    if word_index == line_state:getwordcount() and line_state:getword(word_index) == "" then
        local line = line_state:getline()
        local info = line_state:getwordinfo(word_index)
        word = line:sub(info.offset, line_state:getcursor() - 1)
    else
        word = line_state:getword(word_index)
    end
    return word
end

local function onadvance__clone_limit(_, word, word_index, line_state, _)
    if word then
        word = get_word_direct(line_state, word_index)
        if word ~= "" and not word:match("^[1-5]$") then
            return 1
        end
    end
end

local function onadvance__e_arg(_, word, word_index, line_state, _)
    if word then
        word = get_word_direct(line_state, word_index)
        if word ~= "" and word ~= "1" then
            return 1
        end
    end
end

local custom_mask = clink.argmatcher():addarg({fromhistory=true})
local dll_files = clink.argmatcher():addarg(dll_file_matches)
local folders = clink.argmatcher():addarg(clink.dirmatches)
local num_dumps = clink.argmatcher():addarg({"1", "2", "3", "5", "10", "20"})
local cpu_usage = clink.argmatcher():addarg({"10", "25", "50", "75", "90"})
local consecutive = clink.argmatcher():addarg({"5", "10", "15", "20", "30", "60"})
local timeouts = consecutive
local clone_limit = clink.argmatcher():addarg({onadvance=onadvance__clone_limit, "1", "2", "3", "4", "5"})
local e_arg = clink.argmatcher():addarg({onadvance=onadvance__e_arg, "1"})
local launch_image = clink.argmatcher():addarg(clink.dirmatches):chaincommand()
local commit_usage = clink.argmatcher():addarg({fromhistory=true})
local perf_counter = clink.argmatcher():addarg({fromhistory=true})

local initialized

local function init_procdump()
    if initialized then
        return
    end
    initialized = true

    local pd = clink.argmatcher("procdump", "procdump64")

    pd:addarg(pid_parser)
    pd:addarg(clink.filematches)
    pd:nofiles()
    pd:_addexflags({
        nosort=true,
        ----------------------------------------------------------------------
        -- luacheck: push
        -- luacheck: no max line length
        {"-mm",                         "Write a 'Mini' dump file (default)"},
        {"-ma",                         "Write a 'Full' dump file"},
        {"-mp",                         "Write a 'MiniPlus' dump file"},
        {"-mc"..custom_mask, " Mask",   "Write a 'Custom' dump file defined by the specified MINIDUMP_TYPE mask (Hex)"},
        {"-md"..dll_files, " Callback_DLL", "Write a 'Callback' dump file"},
        {"-mk",                         "Also write a 'Kernel' dump file"},
        {"-a",                          "Avoid outage (requires -r)"},
        {"-at"..timeouts, " Timeout",   "Avoid outage at Timeout. Cancel the trigger's collection at N seconds"},
        {"-b",                          "Treat debug breakpoints as exceptions (otherwise ignore them)"},
        {"-c"..cpu_usage, " CPU_Usage", "CPU threshold above which to create a dump of the process"},
        {"-cl"..cpu_usage, " CPU_Usage", "CPU threshold below which to create a dump of the process"},
        {"-e"..e_arg, " [1]",           "Write a dump when the process encounters an unhandled exception (include the 1 to create dump on first chance exceptions)"},
--   -f      Filter (include) on the content of exceptions and debug logging.
--           Wildcards (*) are supported.
--           [-f  Include_Filter, ...]
--   -fx     Filter (exclude) on the content of exceptions and debug logging.
--           Wildcards (*) are supported.
--           [-fx Exclude_Filter, ...]
        {"-g",                          "Run as a native debugger in a managed process"},
        {"-h",                          "Write dump if process has a hung window"},
        {"-i"..folders, " Dump_Folder", "Install ProcDump as the AeDebug postmortem debugger (-u by itself to uninstall)"},
        {"-k",                          "Kill the process after cloning (-r), or at end of dump collection"},
        {"-l",                          "Display the debug logging of the process"},
        {"-m"..commit_usage, " Commit_Usage", "Memory commit threshold in MB at which to create a dump"},
        {"-ml"..commit_usage, " Commit_Usage", "Trigger when memory commit drops below specified MB value"},
        {"-n"..num_dumps, " Count",     "Number of dumps to write before exiting"},
        {"-o",                          "Overwrite an existing dump file"},
        {"-p"..perf_counter, " Counter_Threshold", "Trigger on the specified performance counter when the threshold is exceeded"},
        {"-pl"..perf_counter, " Counter_Threshold", "Trigger when performance counter falls below the specified value"},
        {"-r"..clone_limit, " [Limit]", "Dump using a clone. Concurrent limit is optional (default 1, max 5)"},
        {"-s"..consecutive, " Seconds", "Consecutive seconds before dump is written (default is 10)"},
        {"-t",                          "Write a dump when the process terminates"},
        {"-u",                          "Treat CPU usage relative to a single core (used with -c) (-u by itself to uninstall ProcDump as the postmortem debugger)"},
        {"-w",                          "Wait for the specified process to launch if it's not running"},
        {"-wer",                        "Queue the (largest) dump to Windows Error Reporting"},
        {"-x"..launch_image, " Dump_Folder Image_File [Argument, ...]", "Launch the specified image with optional arguments"},
        {"-64",                         "On 64-bit Windows, capture 64-bit dumps even for 32-bit processes"},
        {"-accepteula",                 "Automatically accept the license agreement"},
        {"-cancel"..pid_parser, " PID", "Gracefully terminate any active monitoring of the specified PID"},
        -- luacheck: pop
        ----------------------------------------------------------------------
    })
end

local exports = {
    init_procdump = init_procdump,
}

return exports
