local arghelper = require('arghelper')

-- Argument matchers
local file_matcher = clink.argmatcher():addarg(clink.filematches)
local pretty_matcher = clink.argmatcher():addarg({nosort=true, "all", "colors", "format", "none"})
local style_matcher = clink.argmatcher():addarg({nosort=true,
    "abap", "algol", "algol_nu", "arduino", "auto", "autumn", "borland", "bw",
    "coffee", "colorful", "default", "dracula", "emacs", "friendly",
    "friendly_grayscale", "fruity", "github-dark", "gruvbox-dark",
    "gruvbox-light", "igor", "inkpot", "lightbulb", "lilypond", "lovelace",
    "manni", "material", "monokai", "murphy", "native", "nord", "nord-darker",
    "one-dark", "paraiso-dark", "paraiso-light", "pastie", "perldoc", "pie",
    "pie-dark", "pie-light", "rainbow_dash", "rrt", "sas", "solarized",
    "solarized-dark", "solarized-light", "staroffice", "stata-dark",
    "stata-light", "tango", "trac", "vim", "vs", "xcode", "zenburn"
})
local print_matcher = clink.argmatcher():addarg({fromhistory=true})
local auth_type_matcher = clink.argmatcher():addarg({nosort=true, "basic", "bearer", "digest"})
local ssl_matcher = clink.argmatcher():addarg({nosort=true, "ssl2.3", "tls1", "tls1.1", "tls1.2"})
local verify_matcher = clink.argmatcher():addarg({fromhistory=true})
local timeout_matcher = clink.argmatcher():addarg({fromhistory=true})
local scheme_matcher = clink.argmatcher():addarg({fromhistory=true})
local boundary_matcher = clink.argmatcher():addarg({fromhistory=true})
local raw_matcher = clink.argmatcher():addarg({fromhistory=true})
local session_matcher = clink.argmatcher():addarg({fromhistory=true})
local auth_matcher = clink.argmatcher():addarg({fromhistory=true})
local proxy_matcher = clink.argmatcher():addarg({fromhistory=true})
local charset_matcher = clink.argmatcher():addarg({fromhistory=true})
local mime_matcher = clink.argmatcher():addarg({fromhistory=true})
local format_opts_matcher = clink.argmatcher():addarg({fromhistory=true})
local cert_matcher = clink.argmatcher():addarg(clink.filematches)
local cert_key_matcher = clink.argmatcher():addarg(clink.filematches)
local cert_key_pass_matcher = clink.argmatcher():addarg({fromhistory=true})

-- luacheck: push max line length 130
local http_flags = arghelper.make_exflags({
    -- Content types
    { "-j", "--json", "Data items from the command line are serialized as a JSON object (default)" },
    { "-f", "--form", "Data items from the command line are serialized as form fields" },
    { nil, "--multipart", "Similar to --form, but always sends a multipart/form-data request" },
    { nil, "--boundary", boundary_matcher, " BOUNDARY", "Specify a custom boundary string for multipart/form-data requests" },
    { nil, "--raw", raw_matcher, " RAW", "Pass raw request data without extra processing" },

    -- Content processing
    { "-x", "--compress", "Content compressed (encoded) with Deflate algorithm" },

    -- Output processing
    { nil, "--pretty", pretty_matcher, " {all,colors,format,none}", "Controls output processing" },
    { "-s", "--style", style_matcher, " STYLE", "Output coloring style" },
    { nil, "--unsorted", "Disables all sorting while formatting output" },
    { nil, "--sorted", "Re-enables all sorting options while formatting output" },
    { nil, "--response-charset", charset_matcher, " ENCODING", "Override the response encoding for terminal display" },
    { nil, "--response-mime", mime_matcher, " MIME_TYPE", "Override the response mime type for coloring and formatting" },
    { nil, "--format-options", format_opts_matcher, " FORMAT_OPTIONS", "Controls output formatting options" },

    -- Output options
    { "-p", "--print", print_matcher, " WHAT", "String specifying what the output should contain" },
    { "-h", "--headers", "Print only the response headers" },
    { "-m", "--meta", "Print only the response metadata" },
    { "-b", "--body", "Print only the response body" },
    { "-v", "--verbose", "Verbose output (request and response)" },
    { nil, "--all", "Show any intermediary requests/responses" },
    { "-S", "--stream", "Always stream the response body by line" },
    { "-o", "--output", file_matcher, " FILE", "Save output to FILE instead of stdout" },
    { "-d", "--download", "Download response body to a file" },
    { "-c", "--continue", "Resume an interrupted download" },
    { "-q", "--quiet", "Do not print to stdout or stderr" },

    -- Sessions
    { nil, "--session", session_matcher, " SESSION_NAME_OR_PATH", "Create or reuse and update a session" },
    { nil, "--session-read-only", session_matcher, " SESSION_NAME_OR_PATH", "Create or read a session without updating it" },

    -- Authentication
    { "-a", "--auth", auth_matcher, " USER[:PASS] | TOKEN", "Username/password or token based authentication" },
    { "-A", "--auth-type", auth_type_matcher, " {basic,bearer,digest}", "The authentication mechanism to be used" },
    { nil, "--ignore-netrc", "Ignore credentials from .netrc" },

    -- Network
    { nil, "--offline", "Build the request and print it but don't actually send it" },
    { nil, "--proxy", proxy_matcher, " PROTOCOL:PROXY_URL", "String mapping protocol to the URL of the proxy" },
    { "-F", "--follow", "Follow 30x Location redirects" },
    { nil, "--max-redirects", timeout_matcher, " MAX_REDIRECTS", "Maximum number of redirects (default 30)" },
    { nil, "--max-headers", timeout_matcher, " MAX_HEADERS", "Maximum number of response headers to read" },
    { nil, "--timeout", timeout_matcher, " SECONDS", "The connection timeout of the request in seconds" },
    { nil, "--check-status", "Exit with an error if the HTTP status indicates one" },
    { nil, "--path-as-is", "Bypass dot segment URL squashing" },
    { nil, "--chunked", "Enable streaming via chunked transfer encoding" },

    -- SSL
    { nil, "--verify", verify_matcher, " VERIFY", "Set to 'no' to skip checking SSL certificate" },
    { nil, "--ssl", ssl_matcher, " {ssl2.3,tls1,tls1.1,tls1.2}", "The desired protocol version to use" },
    { nil, "--ciphers", boundary_matcher, " CIPHERS", "A string in the OpenSSL cipher list format" },
    { nil, "--cert", cert_matcher, " CERT", "Local cert to use as client side SSL certificate" },
    { nil, "--cert-key", cert_key_matcher, " CERT_KEY", "The private key to use with SSL" },
    { nil, "--cert-key-pass", cert_key_pass_matcher, " CERT_KEY_PASS", "The passphrase for the given private key" },

    -- Troubleshooting
    { "-I", "--ignore-stdin", "Do not attempt to read stdin" },
    { nil, "--help", "Show this help message and exit" },
    { nil, "--manual", "Show the full manual" },
    { nil, "--version", "Show version and exit" },
    { nil, "--traceback", "Prints the exception traceback should one occur" },
    { nil, "--default-scheme", scheme_matcher, " DEFAULT_SCHEME", "The default scheme to use if not specified in the URL" },
    { nil, "--debug", "Prints exception traceback and other debugging information" },
})
-- luacheck: pop

clink.argmatcher("http", "https"):_addexflags(http_flags)
