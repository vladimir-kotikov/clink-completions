--------------------------------------------------------------------------------
-- Usage:
--
-- This builds an argmatcher for MSBUILD.
--
-- It also defines a global msbuild_parser_data table which contains two tables
-- that other scripts can use to add MSBUILD flags to their own argmatchers:
--
--  msbuild_parser_data.exflags
--  msbuild_parser_data.hideflags
--      Table of flags for :_addexflags() and :hideflags(), to add all flag
--      forms (/, -, --) and hide short form flags and all -- flags.
--
--  msbuild_parser_data.exflags_onlyslash
--  msbuild_parser_data.hideflags_onlyslash
--      Table of flags for :_addexflags() and :hideflags(), to add only / flags
--      and hide short form flags.
--
--  msbuild_parser_data.exflags_onlyminus
--  msbuild_parser_data.hideflags_onlyminus
--      Table of flags for :_addexflags() and :hideflags(), to add only - flags
--      and hide short form flags.
--
--  msbuild_parser_data.exflags_onlyminusminus
--  msbuild_parser_data.hideflags_onlyminusminus
--      Table of flags for :_addexflags() and :hideflags(), to add only -- flags
--      and hide short form flags.
--
-- Because of the global msbuild_parser_data table, this script should be
-- located in a normal script directory, not in a completions subdirectory.

local clink_version = require('clink_version')
if not clink_version.new_api then
    return
end

--[[
// vim: set et:
--]]
local defer = require('defer_completions')
require('arghelper')

-- luacheck: no max line length

-- This is a global so that other scripts can add the tables into their own
-- argmatchers, e.g. for use with scripts that wrap msbuild with additional
-- functionality.

-- luacheck: globals msbuild_parser_data
msbuild_parser_data = {}

local binlog = clink.argmatcher():addarg({ fromhistory=true })
local codes = clink.argmatcher():addarg({ fromhistory=true })
local clparams = clink.argmatcher():_addexarg({
    { 'PerformanceSummary', '显示任务、目标和项目所花费的时间' },
    { 'Summary', '在末尾显示错误和警告摘要' },
    { 'NoSummary', '不在末尾显示错误和警告摘要' },
    { 'ErrorsOnly', '仅显示错误' },
    { 'WarningsOnly', '仅显示警告' },
    { 'NoItemAndPropertyList', '不在每个项目构建开始时显示项目和属性列表' },
    { 'ShowCommandLine', '显示任务命令行事件消息' },
    { 'ShowTimestamp', '在每条消息前显示时间戳' },
    { 'ShowEventId', '显示启动事件、完成事件和消息的 eventId' },
    { 'ForceNoAlign', '不将文本对齐到控制台缓冲区大小（适用于 Konsole 等终端）' },
    { 'DisableConsoleColor', '对所有日志消息使用默认控制台颜色' },
    { 'DisableMPLogging', '在非多处理器模式下运行时禁用多处理器日志输出样式' },
    { 'EnableMPLogging', '即使在非多处理器模式下运行也启用多处理器日志样式。此日志样式默认开启' },
    { 'ForceConsoleColor', '即使控制台不支持也强制使用 ANSI 控制台颜色' },
    { 'Verbosity', '覆盖此记录器的详细程度设置' },
})
local cpus = clink.argmatcher():addarg({ fromhistory=true, '2', '3', '4', '6', '8', '10' })
local dlparams = clink.argmatcher():addarg({ fromhistory=true })
local flparams = clink.argmatcher():addarg({ fromhistory=true })
local exts = clink.argmatcher():addarg({ fromhistory=true })
local filelist = clink.argmatcher():addarg(clink.filematches)
local files = clink.argmatcher():addarg(clink.filematches)
local logger = clink.argmatcher():addarg({ fromhistory=true })
local neqv = clink.argmatcher():addarg({ fromhistory=true })
local schema = clink.argmatcher():addarg({ fromhistory=true })
local targets = clink.argmatcher():addarg({ fromhistory=true, "clean" })
local tf = clink.argmatcher():addarg({ 'true', 'false' })
local tver = clink.argmatcher():addarg({ fromhistory=true })
local vlevel = clink.argmatcher():addarg({
    'q', 'm', 'n', 'd', 'diag',
    'quiet', 'minimal', 'normal', 'detailed', 'diagnostic',
}):hideflags({
    'q', 'm', 'n', 'd', 'diag',
})

local displays = {
    [binlog] = 'params',
    [codes] = 'code[;...]',
    [clparams] = 'params',
    [cpus] = 'num',
    [dlparams] = 'params',
    [flparams] = 'params',
    [exts] = '.ext[;...]',
    [filelist] = 'file[;...]',
    [files] = 'file',
    [logger] = 'logger',
    [neqv] = 'n=v[;...]',
    [schema] = 'schema',
    [targets] = 'target[;...]',
    [tf] = 'True|False',
    [tver] = 'version',
    [vlevel] = 'level',
}

local source = {
    { { 't:', 'target:', targets },                     '构建此项目中的这些目标' },
    { { 'p:', 'property:', neqv },                      '设置或覆盖项目级属性' },
    { { 'm', 'maxCpuCount' },                           '使用并发进程构建，最多不超过计算机上的处理器数量' },
    { { 'm:', 'maxCpuCount:', cpus },                   '指定构建时使用的最大并发进程数' },
    { { 'tv:', 'toolsVersion:', tver },                 '覆盖构建期间使用的 MSBuild 工具集版本' },
    { { 'v:', 'verbosity:', vlevel },                   '向事件日志显示详细信息级别' },
    { { 'clp:', 'consoleLoggerParameters:', clparams }, '控制台记录器参数' },
    { { 'noConLog', 'noConsoleLogger' },                '禁用默认控制台记录器，不将事件记录到控制台' },
    { { 'fl1', 'fileLogger1',
        'fl2', 'fileLogger2',
        'fl3', 'fileLogger3',
        'fl4', 'fileLogger4',
        'fl5', 'fileLogger5',
        'fl6', 'fileLogger6',
        'fl7', 'fileLogger7',
        'fl8', 'fileLogger8',
        'fl9', 'fileLogger9',
        'fl', 'fileLogger' },                           '将构建输出记录到文件中' },
    { { 'flp1', 'fileLoggerParameters1',
        'flp2', 'fileLoggerParameters2',
        'flp3', 'fileLoggerParameters3',
        'flp4', 'fileLoggerParameters4',
        'flp5', 'fileLoggerParameters5',
        'flp6', 'fileLoggerParameters6',
        'flp7', 'fileLoggerParameters7',
        'flp8', 'fileLoggerParameters8',
        'flp9', 'fileLoggerParameters9',
        'flp', 'fileLoggerParameters', flparams },      '为文件记录器提供额外参数' },
    { { 'dl:', 'distributedLogger:', dlparams },        '使用此记录器记录 MSBuild 的事件，每个节点一个实例' },
    { { 'distributedFileLogger' },                      '将构建输出记录到每个 MSBuild 节点一个日志文件' },
    { { 'l:', 'logger:', logger },                      '使用此记录器记录 MSBuild 的事件' },
    { { 'bl', 'binaryLogger' },                         '使用压缩的二进制日志文件（参见 https://aka.ms/msbuild/binlog）' },
    { { 'bl:', 'binaryLogger:', binlog },               '使用压缩的二进制日志文件（参见 https://aka.ms/msbuild/binlog）' },
    { { 'err', 'warnAsError' },                         '将警告代码视为错误' },
    { { 'err:', 'warnAsError:', codes },                '要视为错误的警告代码列表' },
    { { 'noWarn', 'warnAsMessage' },                    '将警告代码视为低重要性消息' },
    { { 'noWarn:', 'warnAsMessage:', codes },           '要视为低重要性消息的警告代码列表' },
    { { 'val', 'validate' },                            '根据默认架构验证项目' },
    { { 'val:', 'validate:', schema },                  '根据指定的架构验证项目（例如 xsd 文件）' },
    { { 'ignore:', 'ignoreProjectExtensions:', exts },  '确定要构建的项目文件时忽略的扩展名列表' },
    { { 'nr:', 'nodeReuse:', tf },                      '启用或禁用在构建完成后重用 MSBuild 节点' },
    { { 'pp', 'preprocess' },                           '将聚合项目文件写入标准输出，内联所有将被导入的文件，并标记边界' },
    { { 'pp:', 'preprocess:', files },                  '写入聚合项目文件，内联所有将被导入的文件，并标记边界' },
    { { 'ts', 'targets' },                              '列出可用目标，不执行实际构建过程' },
    { { 'ts:', 'targets:', files },                     '将可用目标列表写入指定文件，不执行实际构建过程' },
    { { 'ds', 'detailedSummary' },                      '在构建结束时显示详细信息' },
    { { 'ds:', 'detailedSummary:', tf },                '指示是否在构建结束时显示详细信息' },
    { { 'r', 'restore' },                               '在构建其他目标之前运行名为 Restore 的目标，并使用最新的还原构建逻辑' },
    { { 'r:', 'restore:', tf },                         '指示是否在构建其他目标之前运行名为 Restore 的目标，并使用最新的还原构建逻辑' },
    { { 'rp:', 'restoreProperty:', neqv },              '仅在还原期间设置或覆盖项目级属性，不使用 -property 指定的属性' },
    { { 'profileEvaluation:', files },                  '分析 MSBuild 评估并将结果写入指定文件（.md 扩展名表示 markdown 格式）' },
    { { 'interactive' },                                '允许构建中的操作与用户交互' },
    { { 'interactive:', tf },                           '指示是否允许构建中的操作与用户交互' },
    { { 'isolate', 'isolateProjects' },                 '隔离构建每个项目' },
    { { 'isolate:', 'isolateProjects:', tf },           '指示是否隔离构建每个项目' },
    { { 'irc:', 'inputResultsCaches:', filelist },      '以分号分隔的输入缓存文件列表，MSBuild 从中读取构建结果' },
    { { 'orc:', 'outputResultsCache:', files },         '输出缓存文件，MSBuild 在构建结束时将构建结果缓存写入其中' },
    { { 'graph', 'graphBuild' },                        '构建项目图' },
    { { 'graph:', 'graphBuild:', tf },                  '指示是否构建项目图' },
    { { 'low', 'lowPriority' },                         '以低进程优先级运行 MSBuild' },
    { { 'low:', 'lowPriority:', tf },                   '设置是否以低进程优先级运行 MSBuild' },
    { { 'noAutoRsp', 'noAutoResponse' },                '不自动包含 MSBuild.rsp 文件' },
    { { 'noLogo' },                                     '不显示启动横幅和版权信息' },
    { { 'ver', 'version' },                             '仅显示版本信息' },
    { { 'h', 'help' },                                  '显示帮助' },
    { { '?' },                                          '显示帮助' },
}

msbuild_parser_data.exflags = {}
msbuild_parser_data.exflags_onlyslash = {}
msbuild_parser_data.exflags_onlyminus = {}
msbuild_parser_data.exflags_onlyminusminus = {}
msbuild_parser_data.hideflags = {}
msbuild_parser_data.hideflags_onlyslash = {}
msbuild_parser_data.hideflags_onlyminus = {}
msbuild_parser_data.hideflags_onlyminusminus = {}

local function make_exflag(flag, linked, desc)
    local exflag = {}

    -- Flag.
    if flag:sub(-1) ~= ':' then
        linked = nil
    end
    table.insert(exflag, linked and flag..linked or flag)

    -- Arg info.
    local display = linked and displays[linked]
    if display then
        desc = desc or ''
        table.insert(exflag, display)
    end

    -- Description.
    if desc then
        table.insert(exflag, desc)
    end

    return exflag
end

for _,e in ipairs(source) do
    local flags = e[1]
    local desc = e[2]

    local num = #flags
    local linked = type(flags[num]) == 'table' and flags[num]
    if linked then
        num = num - 1
    end

    local hidenum = num - 1
    for i = 1, hidenum do
        table.insert(msbuild_parser_data.hideflags, '/'..flags[i])
        table.insert(msbuild_parser_data.hideflags_onlyslash, '/'..flags[i])
        table.insert(msbuild_parser_data.hideflags, '-'..flags[i])
        table.insert(msbuild_parser_data.hideflags_onlyminus, '-'..flags[i])
        table.insert(msbuild_parser_data.hideflags, '--'..flags[i])
        table.insert(msbuild_parser_data.hideflags_onlyminusminus, '--'..flags[i])
    end
    table.insert(msbuild_parser_data.hideflags, '--'..flags[num])

    local exflag
    for i = 1, num do
        exflag = make_exflag('/'..flags[i], linked, desc)
        table.insert(msbuild_parser_data.exflags, exflag)
        table.insert(msbuild_parser_data.exflags_onlyslash, exflag)
        exflag = make_exflag('-'..flags[i], linked, desc)
        table.insert(msbuild_parser_data.exflags, exflag)
        table.insert(msbuild_parser_data.exflags_onlyminus, exflag)
        exflag = make_exflag('--'..flags[i], linked, desc)
        table.insert(msbuild_parser_data.exflags, exflag)
        table.insert(msbuild_parser_data.exflags_onlyminusminus, exflag)
    end
end

defer.argmatcher('msbuild')
:_addexflags(msbuild_parser_data.exflags)
:hideflags(msbuild_parser_data.hideflags)
