--------------------------------------------------------------------------------
-- Clink argmatcher for Spicetify
--------------------------------------------------------------------------------

function split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

function get_extension_names()
    local handle = io.popen("2>nul spicetify.exe path -e")
    local result = handle:read("*a")
    handle:close()
    local paths = split(result, "\n")
    local names = {}
    for _, path in ipairs(paths) do
        local name = path:match("([^\\]+)$")
        table.insert(names, name)
    end
    return names
end

function get_app_names()
    local handle = io.popen("2>nul spicetify.exe path -a")
    local result = handle:read("*a")
    handle:close()
    local paths = split(result, "\n")
    local names = {}
    for _, path in ipairs(paths) do
        local name = path:match("([^\\]+)$")
        table.insert(names, name)
    end
    return names
end

local function create_arg(name)
    return clink.argmatcher():addarg(name):nofiles()
end

local empty_parser = clink.argmatcher()

local backup_parser = clink.argmatcher()
    :addarg("apply")

local refresh_parser = clink.argmatcher()
    :addarg("-e")

local help_parser = clink.argmatcher()
    :addarg("config")

local watch_parser = clink.argmatcher()
    :addarg("-e", "-a", "-s", "-l")

local path_a_flag_parser = clink.argmatcher()
    :addarg("root", get_app_names)

local path_e_flag_parser = clink.argmatcher()
    :addarg("root", get_extension_names)

local path_s_flag_parser = clink.argmatcher()
    :addarg("root", "folder", "color", "css", "js", "assets")

local path_parser = clink.argmatcher()
    :addarg(
        "userdata",
        "all",
        "-e" .. path_e_flag_parser,
        "-a" .. path_a_flag_parser,
        "-s" .. path_s_flag_parser,
        "-c" .. empty_parser
    )
    :nofiles()
    
local config_parser = clink.argmatcher()
    :addarg(
        create_arg("disable_sentry"),
        create_arg("disable_ui_logging"),
        create_arg("remove_rtl_rule"),
        create_arg("expose_apis"),
        create_arg("disable_upgrade_check"),
        create_arg("extensions"),
        create_arg("custom_apps"),
        create_arg("sidebar_config"),
        create_arg("home_config"),
        create_arg("experimental_features"),
        create_arg("inject_css"),
        create_arg("replace_colors"),
        create_arg("overwrite_assets"),
        create_arg("spotify_launch_flags"),
        create_arg("prefs_path"),
        create_arg("current_theme"),
        create_arg("color_scheme"),
        create_arg("check_spicetify_upgrade"),
        create_arg("spotify_path"),
        create_arg("xpui.js_find_8008"),
        create_arg("xpui.js_repl_8008"),
        create_arg("inject_theme_js"),
        create_arg("check_spicetify_update"),
        create_arg("always_enable_devtools")
    )
    :loop(1)
    :nofiles()

local color_parser = clink.argmatcher()
    :addarg(
        create_arg("text"),
        create_arg("subtext"),
        create_arg("main"),
        create_arg("main-elevated"),
        create_arg("highlight"),
        create_arg("highlight-elevated"),
        create_arg("sidebar"),
        create_arg("player"),
        create_arg("card"),
        create_arg("shadow"),
        create_arg("selected-row"),
        create_arg("button"),
        create_arg("button-active"),
        create_arg("button-disabled"),
        create_arg("tab-active"),
        create_arg("notification"),
        create_arg("notification-error"),
        create_arg("misc")
    )
    :loop(1)
    :nofiles()

local spicetify_parser = clink.argmatcher("spicetify")
    :addflags(
        "-a", "--app",
        "-e", "--extension",
        "-h" .. help_parser, "--help" .. help_parser,
        "-l", "--live-refresh",
        "-n", "--no-restart",
        "-q", "--quiet",
        "-s", "--style",
        "-v", "--version"
    )
    :addarg(
        "apply" .. empty_parser,
        "backup" .. backup_parser,
        "config" .. config_parser,
        "refresh" .. refresh_parser,
        "restore" .. empty_parser,
        "clear" .. empty_parser,
        "enable-devtools" .. empty_parser,
        "watch" .. watch_parser,
        "restart" .. empty_parser,
        "path" .. path_parser,
        "color" .. color_parser,
        "config-dir" .. empty_parser,
        "upgrade" .. empty_parser,
        "update" .. empty_parser
    )