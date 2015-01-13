local parser = clink.arg.new_parser

local function packages(token)
    local packagesDir = clink.get_env("chocolateyinstall")..'\\lib'
    local packages = clink.find_dirs(packagesDir.."/*")
    local res = {}
    for _,package in ipairs(packages) do
        if string.match(package:lower(), token:lower()) then
            table.insert(res, package)
        end
    end
    return res
end

local clist_parser = parser(
        "-all", "-allversions",
        "-lo", "-localonly",
        "-pre", "-prerelease",
        "-source")

local cinst_parser = parser(
        -- TODO: Path to packages config.
        -- See https://github.com/chocolatey/chocolatey/wiki/CommandsInstall#packagesconfig---v09813
        {"all", "packages.config"},
        "-ia", "-installArgs", "-installArguments",
        "-ignoreDependencies",
        "-notSilent",
        "-overrideArguments",
        "-params", "-parameters", "-packageparameters",
        "-pre", "-prerelease",
        "-source" .. parser({"ruby", "webpi", "cygwin", "python"}),
        "-version",
        "-x86", "-forcex86")

local cuninst_parser = parser({packages}, "-version")

local cup_parser = parser(
        {"all"},
        "-pre", "-prerelease",
        "-source" .. parser({"ruby", "webpi", "cygwin", "python"}))

local csources_parser=parser({
        "add"..parser("-name", "-source"),
        "disable",
        "enable",
        "list",
        "remove"})

local cver_parser=parser("-source", "-pre", "-prerelease", "-lo", "-localonly")

local chocolatey_parser = parser({
    "install"..cinst_parser,
    "installmissing",
    "update"..cup_parser,
    "list"..clist_parser,
    "search"..clist_parser,
    "sources"..csources_parser,
    "help",
    "version"..cver_parser,
    "gem"..parser("-version"),
    "python"..parser("-version"),
    "webpi",
    "windowsfeatures",
    "uninstall"
    }, "/?")

clink.arg.register_parser("choco", chocolatey_parser)
clink.arg.register_parser("chocolatey", chocolatey_parser)
clink.arg.register_parser("cinst", cinst_parser)
clink.arg.register_parser("clist", clist_parser)
clink.arg.register_parser("cuninst", cuninst_parser)
clink.arg.register_parser("cup", cup_parser)
clink.arg.register_parser("csources", csources_parser)
clink.arg.register_parser("cver", cver_parser)