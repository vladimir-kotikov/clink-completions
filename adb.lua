local parser = clink.arg.new_parser

local forward_reverse_parser = parser(
  "--list",
  "--no-rebind",
  "--remove",
  "--remove-all"
)

local sync_parser = parser(
  {
    "all",
    "data",
    "odm",
    "oem",
    "product_services",
    "product",
    "system",
    "vendor"
  },
  "-l"
)

local install_parser = parser()

local install_multiple_parser = parser("-p")

local install_multi_package_parser = parser(
  "-p",
  "--no-streaming",
  "--streaming",
  "--fastdeploy",
  "--no-fastdeploy",
  "--force-agent",
  "--date-check-agent",
  "--version-check-agent"
)

for _, flag in pairs({ "-l", "-r", "-t", "-s", "-d", "-g", "--instant" }) do
  install_parser:add_flags(flag)
  install_multiple_parser:add_flags(flag)
  install_multi_package_parser:add_flags(flag)
end

local adb_parser = parser(
  {
    -- general --
    "devices"..parser("-l"),
    "help",
    "version",

    -- networking --
    "connect",
    "disconnect",
    "forward"..forward_reverse_parser,
    "ppp",
    "reverse"..forward_reverse_parser,

    -- file transfer --
    "push"..parser("--sync"),
    "pull"..parser("-a"),
    "sync"..sync_parser,

    -- shell --
    "shell"..parser("-e", "-T", "-t", "-x"),
    "emu",

    -- app installation --
    "install"..install_parser,
    "install-multiple"..install_multiple_parser,
    "install-multi-package"..install_multi_package_parser,
    "uninstall"..parser("-k"),

    -- debugging --
    "bugreport",
    "jdwp",
    "logcat",

    -- security --
    "disable-verity",
    "enable-verity",
    "keygen",

    -- scripting --
    "wait-for-device",
    "wait-for-recovery",
    "wait-for-sideload",
    "wait-for-bootloader",
    "wait-for-local-device",
    "wait-for-local-recovery",
    "wait-for-local-sideload",
    "wait-for-local-bootloader",
    "get-state",
    "get-serialno",
    "get-devpath",
    "remount"..parser("-R"),
    "reboot"..parser({ "bootloader", "recovery", "sideload", "sideload-auto-reboot" }),
    "sideload",
    "root",
    "unroot",
    "usb",
    "tcpip",

    -- internal debugging --
    "start-server",
    "kill-server",
    "reconnect"..parser({ "device", "offline" })
  },
  "-a",
  "-d",
  "-e",
  "-s",
  "-t",
  "-H",
  "-P",
  "-L"
)

clink.arg.register_parser("adb", adb_parser)
