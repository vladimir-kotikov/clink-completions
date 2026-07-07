local clink_version = require('clink_version')
if not clink_version.supports_argmatcher_chaincommand then
    log.info("sudo.lua argmatcher requires a newer version of Clink; please upgrade.")
    return
end

require("arghelper")
-- luacheck: globals os

--------------------------------------------------------------------------------
-- Microsoft's sudo command.

local function init_microsoft_sudo(argmatcher)
    local subcommands = {
        ["help"] = true,
        ["run"] = true,
        ["config"] = true,
    }

    local function onadvance_run(_, word)
        if not subcommands[word] then
            return -1
        end
    end

    local dirs = clink.argmatcher():addarg({clink.dirmatches})

    local helps = clink.argmatcher():addarg({"help", "config", "run"}):nofiles()
    local enables = clink.argmatcher():addarg({"disable", "enable", "forceNewWindow", "disableInput", "normal", "default"}) -- luacheck: no max line length
    local configs = clink.argmatcher():_addexflags({
        {"--enable"..enables, " <value>", ""},
    }):nofiles()

    local ex_run_flags = {
        {"-E", "将当前环境变量传递给命令"},
        {"--preserve-env"},
        {"-N", "使用新窗口运行命令"},
        {"--new-window"},
        {"--disable-input"},
        {"--inline"},
        {"-D"..dirs, " dir", "运行命令前更改工作目录"},
        {"--chdir"..dirs, " dir", ""},
    }
    local runs = clink.argmatcher():_addexflags(ex_run_flags):chaincommand()

    argmatcher
    :_addexflags({
        ex_run_flags,
        {"-h", "打印帮助（使用 '--help' 查看更多）"},
        {"--help"},
        {"-V", "打印版本"},
        {"--version"},
    })
    :_addexarg({
        onadvance=onadvance_run,
        {"help"..helps, " [subcommand]", "打印帮助"},
        {"run"..runs, " [commandline]", "以管理员身份运行命令"},
        {"config"..configs, "获取或设置 sudo 的当前配置信息"},
    })
    :nofiles()
end

--------------------------------------------------------------------------------
-- Chrisant996 sudo command (https://github.com/chrisant996/sudo-windows).

local function init_chrisant996_sudo(argmatcher)
    local dir = clink.argmatcher():addarg({clink.dirmatches})
    local prompt = clink.argmatcher():addarg({fromhistory=true})
    local user = clink.argmatcher():addarg({fromhistory=true})

    argmatcher
    :_addexflags({
        {"-?", "显示简短帮助消息并退出"},
        {"-b", "在后台运行命令"},
        {"-D"..dir, " dir", "在指定目录中运行命令"},
        {"-h", "显示简短帮助消息并退出"},
        {"-n", "避免显示任何 UI"},
        {"-p"..prompt, " text", "使用自定义密码提示"},
        {"-S", "将提示写入 stderr 并从 stdin 读取密码，而不是使用控制台"},
        {"-u"..user, " user", "以指定用户身份运行命令"},
        {"-V", "打印 sudo 版本字符串"},
        {"--", "停止处理命令行中的选项"},
        {"--background", "在后台运行命令"},
        {opteq=true, "--chdir="..dir, "dir", "在指定目录中运行命令"},
        {"--help", "显示简短帮助消息并退出"},
        {"--non-interactive", "避免显示任何 UI"},
        {opteq=true, "--prompt="..prompt, "text", "使用自定义密码提示"},
        {"--stdin", "将提示写入 stderr 并从 stdin 读取密码，而不是使用控制台"},
        {opteq=true, "--user=", "user", "以指定用户身份运行命令"},
        {"--version", "打印 sudo 版本字符串"},
    })
    :chaincommand()
end

--------------------------------------------------------------------------------
-- Detect sudo command version.

local fullname = ... -- Full command path.

if fullname then
    if string.lower(path.getname(fullname)) == "sudo.exe" then
        local windir = os.getenv("windir")
        if windir then
            local cdir = clink.lower(path.getdirectory(fullname))
            local wdir = clink.lower(path.join(windir, "system32"))
            if cdir == wdir then
                local sudo = clink.argmatcher(fullname)
                init_microsoft_sudo(sudo)
                return
            end
        end
        if os.getfileversion then
            local info = os.getfileversion(fullname)
            if info and info.companyname == "Christopher Antos" then
                local sudo = clink.argmatcher(fullname)
                init_chrisant996_sudo(sudo)
                return
            end
        end
    end
else
    -- Alternative initialization in case the script is not located in a
    -- completions\ directory, in which case ... will be nil.
    local sysroot = os.getenv("windir") or os.getenv("systemroot")
    if sysroot then
        local system32 = clink.lower(path.join(sysroot, "system32"))
        local sudo = clink.argmatcher(path.join(system32, "sudo.exe"))
        init_microsoft_sudo(sudo)
    end
end

clink.argmatcher("sudo"):chaincommand()
