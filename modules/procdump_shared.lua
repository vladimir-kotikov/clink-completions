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
        {"-mm",                         "写入 'Mini' 转储文件（默认）"},
        {"-ma",                         "写入 'Full' 转储文件"},
        {"-mp",                         "写入 'MiniPlus' 转储文件"},
        {"-mc"..custom_mask, " Mask",   "写入由指定 MINIDUMP_TYPE 掩码（十六进制）定义的 'Custom' 转储文件"},
        {"-md"..dll_files, " Callback_DLL", "写入 'Callback' 转储文件"},
        {"-mk",                         "同时写入 'Kernel' 转储文件"},
        {"-a",                          "避免中断（需要 -r）"},
        {"-at"..timeouts, " Timeout",   "在超时时避免中断。在 N 秒后取消触发器的收集"},
        {"-b",                          "将调试断点视为异常（否则忽略它们）"},
        {"-c"..cpu_usage, " CPU_Usage", "CPU 高于此阈值时创建进程转储"},
        {"-cl"..cpu_usage, " CPU_Usage", "CPU 低于此阈值时创建进程转储"},
        {"-e"..e_arg, " [1]",           "当进程遇到未处理的异常时写入转储（包含 1 则在首次异常时创建转储）"},
--   -f      Filter (include) on the content of exceptions and debug logging.
--           Wildcards (*) are supported.
--           [-f  Include_Filter, ...]
--   -fx     Filter (exclude) on the content of exceptions and debug logging.
--           Wildcards (*) are supported.
--           [-fx Exclude_Filter, ...]
        {"-g",                          "作为托管进程中的本机调试器运行"},
        {"-h",                          "如果进程有挂起的窗口则写入转储"},
        {"-i"..folders, " Dump_Folder", "将 ProcDump 安装为 AeDebug 事后调试器（单独使用 -u 卸载）"},
        {"-k",                          "克隆后（-r）或转储收集结束时终止进程"},
        {"-l",                          "显示进程的调试日志"},
        {"-m"..commit_usage, " Commit_Usage", "创建转储的内存提交阈值（MB）"},
        {"-ml"..commit_usage, " Commit_Usage", "当内存提交低于指定 MB 值时触发"},
        {"-n"..num_dumps, " Count",     "退出前要写入的转储数量"},
        {"-o",                          "覆盖现有的转储文件"},
        {"-p"..perf_counter, " Counter_Threshold", "当超过阈值时触发指定的性能计数器"},
        {"-pl"..perf_counter, " Counter_Threshold", "当性能计数器低于指定值时触发"},
        {"-r"..clone_limit, " [Limit]", "使用克隆进行转储。并发限制可选（默认 1，最大 5）"},
        {"-s"..consecutive, " Seconds", "写入转储前的连续秒数（默认为 10）"},
        {"-t",                          "当进程终止时写入转储"},
        {"-u",                          "相对于单个核心计算 CPU 使用率（与 -c 配合使用）（单独使用 -u 卸载 ProcDump 作为事后调试器）"},
        {"-w",                          "如果指定的进程未运行，则等待其启动"},
        {"-wer",                        "将（最大的）转储加入 Windows 错误报告队列"},
        {"-x"..launch_image, " Dump_Folder Image_File [Argument, ...]", "使用可选参数启动指定的映像"},
        {"-64",                         "在 64 位 Windows 上，即使对于 32 位进程也捕获 64 位转储"},
        {"-accepteula",                 "自动接受许可协议"},
        {"-cancel"..pid_parser, " PID", "优雅终止对指定 PID 的任何活动监控"},
        -- luacheck: pop
        ----------------------------------------------------------------------
    })
end

local exports = {
    init_procdump = init_procdump,
}

return exports
