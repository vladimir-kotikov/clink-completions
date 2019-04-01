local parser = clink.arg.new_parser


-- General parsers --

local platforms = parser({
  "android",
  "ios"
}):disable_file_matching()

local status_parser = parser({
  "status",
  "enable",
  "disable"
}):disable_file_matching()


-- appstore --

local appstore_parser = parser(
  {
    "upload"..parser("--ipa")
  },
  "--team-id"
):disable_file_matching()


-- build --

local build_android_parser = parser(
  "--aab",
  "--clean",
  "--compileSdk",
  "--key-store-alias-password",
  "--key-store-alias",
  "--key-store-password",
  "--key-store-path"
)

local build_ios_parser = parser(
  "--for-device",
  "--provision",
  "--team-id"
)

for _, flag in pairs({
  "--bundle",
  "--copy-to",
  "--env.aot",
  "--env.snapshot",
  "--env.uglify",
  "--release"
}) do
  build_android_parser:add_flags(flag)
  build_ios_parser:add_flags(flag)
end

local build_parser = parser({
  "android"..build_android_parser,
  "ios"..build_ios_parser
}):disable_file_matching()


-- create --

local create_parser = parser(
  "--path",
  "--appid",
  "--template"..parser({
    "tns-template-hello-world",
    "tns-template-drawer-navigation",
    "tns-template-tab-navigation",
    "tns-template-hello-world-ts",
    "tns-template-drawer-navigation-ts",
    "tns-template-tab-navigation-ts",
    "tns-template-hello-world-ng",
    "tns-template-drawer-navigation-ng",
    "tns-template-tab-navigation-ng",
    "tns-template-blank-vue"
  }):disable_file_matching(),
  "--js", "--javascript",
  "--ts", "--tsc", "--typescript",
  "--ng", "--angular",
  "--vue", "--vuejs"
)


-- debug --

local debug_android_parser = parser():disable_file_matching()

local debug_ios_parser = parser(
  "--no-client",
  "--chrome",
  "--inspector"
):disable_file_matching()

for _, flag in pairs({
  "--device",
  "--emulator",
  "--debug-brk",
  "--start",
  "--timeout",
  "--no-watch",
  "--clean",
  "--bundle",
  "--hmr",
  "--syncAllFiles"
}) do
  debug_android_parser:add_flags(flag)
  debug_ios_parser:add_flags(flag)
end

local debug_parser = parser({
  "android"..debug_android_parser,
  "ios"..debug_ios_parser
}):disable_file_matching()


-- deploy --

local deploy_parser = parser({
  "android"..parser(
    "--device",
    "--clean",
    "--release",
    "--key-store-path",
    "--key-store-password",
    "--key-store-alias",
    "--key-store-alias-password"
  ),
  "ios"..parser(
    "--device",
    "--release"
  )
})


-- device --

local device_platform_flags = parser("--available-devices", "--timeout")

local device_flags = parser("--device")

local device_parser = parser({
  "android"..device_platform_flags,
  "ios"..device_platform_flags,
  "log"..device_flags,
  "run"..device_flags,
  "list-applications"..device_flags
}):disable_file_matching()


-- platform --

local platform_add_parser = parser({
  "android"..parser("--framework-path", "--symlink", "--sdk", "--platform-template"),
  "ios"..parser("--framework-path", "--symlink", "--platform-template")
})

local platform_parser = parser({
  "add"..platform_add_parser,
  "list",
  "remove"..platforms,
  "update"..platforms
}):disable_file_matching()


-- plugin --

local plugin_parser = parser({
  "add",
  "remove",
  "update",
  "build",
  "create"..parser("--path", "--username", "--pluginName", "--template")
})


-- proxy --

local proxy_parser = parser({
  "set"..parser("--insecure"):disable_file_matching(),
  "clear"
}):disable_file_matching()


-- resources --

local resources_parser = parser({
  "update",
  "generate"..parser({
    "splashes"..parser("--background"),
    "icons"
  })
}):disable_file_matching()


-- run --

local run_parser = parser():disable_file_matching()

local run_android_parser = parser(
  "--clean",
  "--emulator",
  "--key-store-alias-password",
  "--key-store-alias",
  "--key-store-password",
  "--key-store-path",
  "--no-watch"
)

local run_ios_parser = parser(
  "--clean",
  "--emulator",
  "--no-watch",
  "--sdk"
):disable_file_matching()

for _, flag in pairs({
  "--bundle",
  "--device",
  "--env.aot",
  "--env.snapshot",
  "--env.uglify",
  "--hmr",
  "--justlaunch",
  "--release",
  "--syncAllFiles"
}) do
  run_parser:add_flags(flag)
  run_android_parser:add_flags(flag)
  run_ios_parser:add_flags(flag)
end

run_parser:add_arguments({
  "android"..run_android_parser,
  "ios"..run_android_parser
})


-- test --

local test_android_parser = parser():disable_file_matching()
local test_ios_parser = parser("--emulator"):disable_file_matching()

for _, flag in pairs({ "--watch", "--device", "--debug-brk" }) do
  test_android_parser:add_flags(flag)
  test_ios_parser:add_flags(flag)
end

local test_parser = parser({
  "init"..parser("--framework"),
  "android"..test_android_parser,
  "ios"..test_ios_parser
}):disable_file_matching()


-- MAIN PARSER --

local tns_parser = parser()

tns_parser:set_arguments({
  "appstore"..appstore_parser,
  "autocomplete"..status_parser,
  "build"..build_parser,
  "create"..create_parser,
  "debug"..debug_parser,
  "deploy"..deploy_parser,
  "device"..device_parser, "devices"..device_parser,
  "doctor",
  "error-reporting"..status_parser,
  "help"..tns_parser,
  "info",
  "init"..parser("--path", "--force"),
  "install"..parser("--path"),
  "package-manager"..parser({ "get", "set" }):disable_file_matching(),
  "platform"..platform_parser,
  "plugin"..plugin_parser,
  "prepare"..platforms,
  "preview"..parser("--bundle", "--hmr"):disable_file_matching(),
  "proxy"..proxy_parser,
  "resources"..resources_parser,
  "run"..run_parser,
  "setup"..parser({ "cloud" }):disable_file_matching(),
  "test"..test_parser,
  "update"..parser({ "next" }):disable_file_matching(),
  "usage-reporting"..status_parser
})

tns_parser:set_flags(
  "--help", "-h", "/?",
  "--path",
  "--version",
  "--log"
)

tns_parser:disable_file_matching()

clink.arg.register_parser("tns", tns_parser)
clink.arg.register_parser("nativescript", tns_parser)
