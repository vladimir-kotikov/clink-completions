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
    { "-j", "--json", "将命令行中的数据项序列化为 JSON 对象（默认）" },
    { "-f", "--form", "将命令行中的数据项序列化为表单字段" },
    { nil, "--multipart", "类似 --form，但始终发送 multipart/form-data 请求" },
    { nil, "--boundary", boundary_matcher, " BOUNDARY", "为 multipart/form-data 请求指定自定义边界字符串" },
    { nil, "--raw", raw_matcher, " RAW", "传递原始请求数据，不做额外处理" },

    -- Content processing
    { "-x", "--compress", "使用 Deflate 算法压缩（编码）内容" },

    -- Output processing
    { nil, "--pretty", pretty_matcher, " {all,colors,format,none}", "控制输出处理" },
    { "-s", "--style", style_matcher, " STYLE", "输出着色样式" },
    { nil, "--unsorted", "格式化输出时禁用所有排序" },
    { nil, "--sorted", "格式化输出时重新启用所有排序选项" },
    { nil, "--response-charset", charset_matcher, " ENCODING", "覆盖用于终端显示的响应编码" },
    { nil, "--response-mime", mime_matcher, " MIME_TYPE", "覆盖用于着色和格式化的响应 MIME 类型" },
    { nil, "--format-options", format_opts_matcher, " FORMAT_OPTIONS", "控制输出格式化选项" },

    -- Output options
    { "-p", "--print", print_matcher, " WHAT", "指定输出应包含内容的字符串" },
    { "-h", "--headers", "仅打印响应头" },
    { "-m", "--meta", "仅打印响应元数据" },
    { "-b", "--body", "仅打印响应体" },
    { "-v", "--verbose", "详细输出（请求和响应）" },
    { nil, "--all", "显示所有中间请求/响应" },
    { "-S", "--stream", "始终按行流式传输响应体" },
    { "-o", "--output", file_matcher, " FILE", "将输出保存到文件而不是标准输出" },
    { "-d", "--download", "将响应体下载到文件" },
    { "-c", "--continue", "恢复中断的下载" },
    { "-q", "--quiet", "不输出到标准输出或标准错误" },

    -- Sessions
    { nil, "--session", session_matcher, " SESSION_NAME_OR_PATH", "创建或重用并更新会话" },
    { nil, "--session-read-only", session_matcher, " SESSION_NAME_OR_PATH", "创建或读取会话但不更新它" },

    -- Authentication
    { "-a", "--auth", auth_matcher, " USER[:PASS] | TOKEN", "基于用户名/密码或令牌的身份验证" },
    { "-A", "--auth-type", auth_type_matcher, " {basic,bearer,digest}", "要使用的身份验证机制" },
    { nil, "--ignore-netrc", "忽略 .netrc 中的凭据" },

    -- Network
    { nil, "--offline", "构建请求并打印但不实际发送" },
    { nil, "--proxy", proxy_matcher, " PROTOCOL:PROXY_URL", "将协议映射到代理 URL 的字符串" },
    { "-F", "--follow", "跟随 30x Location 重定向" },
    { nil, "--max-redirects", timeout_matcher, " MAX_REDIRECTS", "最大重定向次数（默认 30）" },
    { nil, "--max-headers", timeout_matcher, " MAX_HEADERS", "要读取的最大响应头数量" },
    { nil, "--timeout", timeout_matcher, " SECONDS", "请求的连接超时时间（秒）" },
    { nil, "--check-status", "如果 HTTP 状态表示错误则退出并报错" },
    { nil, "--path-as-is", "绕过点段 URL 压缩" },
    { nil, "--chunked", "通过分块传输编码启用流式传输" },

    -- SSL
    { nil, "--verify", verify_matcher, " VERIFY", "设置为 'no' 跳过 SSL 证书检查" },
    { nil, "--ssl", ssl_matcher, " {ssl2.3,tls1,tls1.1,tls1.2}", "要使用的协议版本" },
    { nil, "--ciphers", boundary_matcher, " CIPHERS", "OpenSSL 密码列表格式的字符串" },
    { nil, "--cert", cert_matcher, " CERT", "用作客户端 SSL 证书的本地证书" },
    { nil, "--cert-key", cert_key_matcher, " CERT_KEY", "与 SSL 一起使用的私钥" },
    { nil, "--cert-key-pass", cert_key_pass_matcher, " CERT_KEY_PASS", "给定私钥的密码短语" },

    -- Troubleshooting
    { "-I", "--ignore-stdin", "不尝试读取标准输入" },
    { nil, "--help", "显示此帮助消息并退出" },
    { nil, "--manual", "显示完整手册" },
    { nil, "--version", "显示版本并退出" },
    { nil, "--traceback", "如果发生异常则打印异常回溯" },
    { nil, "--default-scheme", scheme_matcher, " DEFAULT_SCHEME", "URL 中未指定时使用的默认 scheme" },
    { nil, "--debug", "打印异常回溯和其他调试信息" },
})
-- luacheck: pop

clink.argmatcher("http", "https"):_addexflags(http_flags)
