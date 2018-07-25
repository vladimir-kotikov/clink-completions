local parser = clink.arg.new_parser

local new_parser = parser(
    "--collection",
    "--directory",
    "--dryRun",
    "--force",
    "--inline-style",
    "--inline-template",
    "--new-project-root",
    "--prefix",
    "--routing",
    "--skip-git",
    "--skip-install",
    "--skip-tests",
    "--style",
    "--verbose",
    "--view-encapsulation",
    "-c",
    "-d",
    "-f",
    "-g",
    "-p",
    "-s",
    "-S",
    "-t",
    "-v"
)

local generate_application_parser = parser(
    "--dryRun",
    "--force",
    "--help",
    "--inline-style",
    "--inline-template",
    "--prefix",
    "--routing",
    "--skip-package-json",
    "--skip-tests",
    "--style",
    "--view-encapsulation",
    "-d",
    "-f",
    "-p",
    "-s",
    "-S",
    "-t"
)

local generate_appShell_parser = parser(
    "--dryRun",
    "--force",
    "--help",
    "--index",
    "--main",
    "--name",
    "--out-dir",
    "--root",
    "--root-module-class-name",
    "--root-module-file-name",
    "--route",
    "--source-dir ",
    "--test",
    "--test-tsconfig-file-name",
    "--tsconfig-file-name",
    "--universal-project",
    "-D",
    "-d",
    "-f"
)

local generate_class_parser = parser(
    "--dryRun",
    "--force",
    "--help",
    "--project",
    "--spec",
    "--type",
    "-d",
    "-f"
)

local generate_component_parser = parser(
    "--change-detection",
    "--dryRun",
    "--export",
    "--flat",
    "--force",
    "--help",
    "--inline-style",
    "--inline-template",
    "--module",
    "--prefix",
    "--project",
    "--selector",
    "--skip-import",
    "--spec",
    "--styleext",
    "--view-encapsulation",
    "-c",
    "-d",
    "-f",
    "-m",
    "-p",
    "-s",
    "-t",
    "-v"
)

local generate_directive_parser = parser(
    "--dryRun",
    "--export",
    "--flat",
    "--force",
    "--help",
    "--module",
    "--prefix",
    "--project",
    "--selector",
    "--skip-import",
    "--spec",
    "-d",
    "-f",
    "-m",
    "-p"
)

local generate_enum_parser = parser(
    "--dryRun",
    "--force",
    "--help",
    "--project",
    "-d",
    "-f"
)

local generate_guard_service_parser = parser(
    "--dryRun",
    "--flat",
    "--force",
    "--help",
    "--project",
    "--spec",
    "-d",
    "-f"
)

local generate_interface_parser = parser(
    "--dryRun",
    "--force",
    "--help",
    "--prefix",
    "--project",
    "-d",
    "-f"
)

local generate_library_parser = parser(
    "--dryRun",
    "--entry-file",
    "--force",
    "--help",
    "--prefix",
    "--skip-package-json",
    "--skip-ts-config",
    "-d",
    "-f",
    "-p"
)

local generate_module_parser = parser(
    "--dryRun",
    "--flat",
    "--force",
    "--help",
    "--module",
    "--project",
    "--routing",
    "--routing-scope",
    "--spec",
    "-d",
    "-f",
    "-m"
)

local generate_pipe_parser = parser(
    "--dryRun",
    "--export",
    "--flat",
    "--force",
    "--help",
    "--module",
    "--project",
    "--skip-import",
    "--spec",
    "-d",
    "-f",
    "-m"
)

local generate_serviceWorker_parser = parser(
    "--configuration",
    "--dryRun",
    "--force",
    "--help",
    "--project",
    "--target",
    "-d",
    "-f"
)

local generate_universal_parser = parser(
    "--app-dir",
    "--app-id",
    "--client-project",
    "--dryRun",
    "--force",
    "--help",
    "--main",
    "--root-module-class-name",
    "--root-module-file-name",
    "--skip-install",
    "--test",
    "--test-tsconfig-file-name",
    "--tsconfig-file-name",
    "-d",
    "-f"
)

local generate_parser = parser({
    "application"..generate_application_parser,
    "appShell"..generate_appShell_parser,
    "class"..generate_class_parser, "cl"..generate_class_parser,
    "component"..generate_component_parser, "c"..generate_component_parser,
    "directive"..generate_directive_parser, "d"..generate_directive_parser,
    "enum"..generate_enum_parser, "e"..generate_enum_parser,
    "guard"..generate_guard_service_parser, "g"..generate_guard_service_parser,
    "interface"..generate_interface_parser, "i"..generate_interface_parser,
    "library"..generate_library_parser,
    "module"..generate_module_parser, "m"..generate_module_parser,
    "pipe"..generate_pipe_parser, "p"..generate_pipe_parser,
    "service"..generate_guard_service_parser, "s"..generate_guard_service_parser,
    "serviceWorker"..generate_serviceWorker_parser,
    "universal"..generate_universal_parser
},
    "--dryRun",
    "--force",
    "--help",
    "-d",
    "-f",
)

local update_parser = parser(
    "--all",
    "--dryRun",
    "--force",
    "--from",
    "--migrate-only",
    "--next",
    "--registry",
    "--to",
    "-d"
)

local build_parser = parser(
    "--aot",
    "--base-href",
    "--build-optimizer",
    "--common-chunk",
    "--configuration",
    "--delete-output-path",
    "--deploy-url",
    "--eval-source-map",
    "--extract-css",
    "--extract-licenses",
    "--fork-type-checker",
    "--i18n-file",
    "--i18n-format",
    "--i18n-locale",
    "--i18n-missing-translation",
    "--index",
    "--main",
    "--named-chunks",
    "--ngsw-config-path",
    "--optimization",
    "--output-hashing",
    "--output-path",
    "--poll",
    "--polyfills",
    "--preserve-symlinks",
    "--prod",
    "--progress",
    "--service-worker",
    "--show-circular-dependencies",
    "--skip-app-shell",
    "--source-map",
    "--stats-json",
    "--subresource-integrity",
    "--ts-config",
    "--vendor-chunk",
    "--verbose",
    "--watch",
    "-c"
)

local serve_parser = parser(
    "--aot",
    "--base-href",
    "--browser-target",
    "--common-chunk",
    "--configuration",
    "--deploy-url",
    "--disable-host-check",
    "--eval-source-map",
    "--hmr",
    "--hmr-warning",
    "--host",
    "--live-reload",
    "--open",
    "--optimization",
    "--poll",
    "--port",
    "--prod",
    "--progress",
    "--proxy-config",
    "--public-host",
    "--serve-path",
    "--serve-path-default-warning",
    "--source-map",
    "--ssl",
    "--ssl-cert",
    "--ssl-key",
    "--vendor-chunk",
    "--watch",
    "-c",
    "-o"
)

local test_parser = parser(
    "--browsers",
    "--code-coverage",
    "--configuration",
    "--environment",
    "--karma-config",
    "--main",
    "--poll",
    "--polyfills",
    "--preserve-symlinks",
    "--prod",
    "--progress",
    "--source-map",
    "--ts-config",
    "--watch",
    "-c"
)

local e2e_parser = parser(
    "--base-url",
    "--configuration",
    "--dev-server-target",
    "--element-explorer",
    "--host",
    "--port",
    "--prod",
    "--protractor-config",
    "--suite",
    "--webdriver-update",
    "-c"
)

local xi18n_parser = parser(
    "--browser-target",
    "--configuration",
    "--i18n-format",
    "--i18n-locale",
    "--out-file",
    "--output-path",
    "-c"
)

local ng_parser = parser({
    "add",
    "new"..new_parser,
    "generate"..generate_parser, "g"..generate_parser,
    "update"..update_parser,
    "build"..build_parser, "b"..build_parser,
    "serve"..serve_parser, "s"..serve_parser,
    "test"..test_parser,
    "e2e"..e2e_parser,
    "lint"..parser("--configuration", "-c"),
    "xi18n"..xi18n_parser,
    "run",
    "eject",
    "config"..parser("--global", "-g"),
    "help",
    "version",
    "doc"..parser("--search", "-s")
},
    "--help"
)

clink.arg.register_parser("ng", ng_parser)
