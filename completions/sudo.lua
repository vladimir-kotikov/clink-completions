local clink_version = require('clink_version')
if not clink_version.supports_argmatcher_chaincommand then
    log.info("sudo.lua argmatcher requires a newer version of Clink; please upgrade.")
    return
end

require("arghelper")
-- luacheck: globals os

local fullname = ...

--------------------------------------------------------------------------------
-- Microsoft's sudo command.

local function init_microsoft_sudo()
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
        {"-E", "Pass the current environment variables to the command"},
        {"--preserve-env"},
        {"-N", "Use a new window for the command"},
        {"--new-window"},
        {"--disable-input"},
        {"--inline"},
        {"-D"..dirs, " dir", "Change the working directory before running the command"},
        {"--chdir"..dirs, " dir", ""},
    }
    local runs = clink.argmatcher():_addexflags(ex_run_flags):chaincommand()

    clink.argmatcher(fullname)
    :_addexflags({
        ex_run_flags,
        {"-h", "Print help (see more with '--help')"},
        {"--help"},
        {"-V", "Print version"},
        {"--version"},
    })
    :_addexarg({
        onadvance=onadvance_run,
        {"help"..helps, " [subcommand]", "Print help"},
        {"run"..runs, " [commandline]", "Run a command as admin"},
        {"config"..configs, "Get or set current configuration information of sudo"},
    })
    :nofiles()
end

--------------------------------------------------------------------------------
-- Chrisant996 sudo command (https://github.com/chrisant996/sudo-windows).

local function init_chrisant996_sudo()
    local dir = clink.argmatcher():addarg({clink.dirmatches})
    local prompt = clink.argmatcher():addarg({fromhistory=true})
    local user = clink.argmatcher():addarg({fromhistory=true})

    clink.argmatcher(fullname)
    :_addexarg({
        {"-?", "Display a short help message and exit"},
        {"-b", "Run the command in the background"},
        {"-D"..dir, " dir", "Run the command in the specified directory"},
        {"-h", "Display a short help message and exit"},
        {"-n", "Avoid showing any UI"},
        {"-p"..prompt, " text", "Use a custom password prompt"},
        {"-S", "Write the prompt to stderr and read the password from stdin instead of using the console"},
        {"-u"..user, " user", "Run the command as the specified user"},
        {"-V", "Print the sudo version string"},
        {"--", "Stop processing options in the command line"},
        {"--background", "Run the command in the background"},
        {opteq=true, "--chdir="..dir, "dir", "Run the command in the specified directory"},
        {"--help", "Display a short help message and exit"},
        {"--non-interactive", "Avoid showing any UI"},
        {opteq=true, "--prompt="..prompt, "text", "Use a custom password prompt"},
        {"--stdin", "Write the prompt to stderr and read the password from stdin instead of using the console"},
        {opteq=true, "--user=", "user", "Run the command as the specified user"},
        {"--version", "Print the sudo version string"},
    })
    :chaincommand()
end

--------------------------------------------------------------------------------
-- Detect sudo command version.

if string.lower(path.getname(fullname)) == "sudo.exe" then
    local windir = os.getenv("windir")
    if windir then
        local cdir = clink.lower(path.getdirectory(fullname))
        local wdir = clink.lower(path.join(windir, "system32"))
        if cdir == wdir then
            init_microsoft_sudo()
            return
        end
    elseif os.getfileversion then
        local info = os.getfileversion(fullname)
        if info and info.companyname == "Christopher Antos" then
            init_chrisant996_sudo()
            return
        end
    end
end

clink.argmatcher("sudo"):chaincommand()
