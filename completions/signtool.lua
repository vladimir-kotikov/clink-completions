-- luacheck: no max line length
require('arghelper')

--------------------------------------------------------------------------------
-- Argument parsers.

local placeholder = clink.argmatcher():addarg()

local file = clink.argmatcher():addarg(clink.filematches)
local c_name = clink.argmatcher():addarg({fromhistory=true})
local i_name = clink.argmatcher():addarg({fromhistory=true})
local n_name = clink.argmatcher():addarg({fromhistory=true})
local passwd = placeholder
local r_name = clink.argmatcher():addarg({fromhistory=true})
local s_name = clink.argmatcher():addarg({fromhistory=true})
local hash = clink.argmatcher():addarg({fromhistory=true})
local usage = clink.argmatcher():addarg({fromhistory=true, "Code Signing"})
local csp_name = clink.argmatcher():addarg({fromhistory=true})
local kc_name = clink.argmatcher():addarg({fromhistory=true})
local desc = placeholder
local url = placeholder
local hash_alg = clink.argmatcher():addarg("SHA1", "SHA256")
local oidvalue = placeholder
local dir = clink.argmatcher():addarg(clink.dirmatches)
local oid = placeholder
local pkcs7_mode = clink.argmatcher():_addexarg({
    {"Embedded", "将已签名的内容嵌入 PKCS7（默认）"},
    {"DetachedSignedData", "生成分离 PKCS7 的签名数据部分"},
    {"Pkcs7DetachedSignedData", "生成完整的分离 PKCS7"},
})
local index = placeholder
local cat_guid = clink.argmatcher():addarg({fromhistory=true})

local common_flags = {
    {"/q",                          "成功时无输出，失败时输出最少信息"},
    {"/v",                          "打印详细的成功和状态消息"},
}

local timestamp_flags = {
    {"/t"..url, " url",             "指定时间戳服务器的 URL"},
    {"/tr"..url, " url",            "指定 RFC 3161 时间戳服务器的 URL"},
    {"/tseal"..url, " url",         "指定用于对密封文件添加时间戳的 RFC 3161 时间戳服务器 URL"},
    {"/td"..hash_alg, " alg",       "与 /tr 或 /tseal 一起使用，请求 RFC 3161 时间戳服务器使用的摘要算法"},
}

--------------------------------------------------------------------------------
-- Command parsers.

local sign_parser = clink.argmatcher()
:_addexflags({
    -- Certificate selection options:
    {"/a",                          "自动选择最佳签名证书"},
    {"/ac"..file, " file",          "将 <file> 中的附加证书添加到签名块"},
    {"/c"..c_name, " name",         "指定签名证书的证书模板名称（Microsoft 扩展）"},
    {"/f"..file, " file",           "指定文件中的签名证书"},
    {"/i"..i_name, " name",         "指定签名证书的颁发者，或子字符串"},
    {"/n"..n_name, " name",         "指定签名证书的主题名称，或子字符串"},
    {"/p"..passwd, " passwd",       "指定打开 PFX 文件时使用的密码"},
    {"/r"..r_name, " name",         "指定签名证书必须链接到的根证书的主题名称"},
    {"/s"..s_name, " name",         "指定打开以搜索证书的存储（默认为\"MY\"）"},
    {"/sm",                         "打开计算机存储而不是用户存储"},
    {"/sha1"..hash, " hash",        "指定签名证书的 SHA1 指纹"},
    {"/fd"..hash_alg, " alg",       "指定用于创建文件签名的文件摘要算法"},
    {"/u"..usage, " usage",         "指定证书中必须存在的增强密钥用法"},
    {"/uw",                         "指定使用\"Windows System Component Verification\""},
    {"/fdchw",                      "如果文件摘要和签名证书中的哈希算法不同，则生成警告"},
    -- Private Key selection options:
    {"/csp"..csp_name, " name",     "指定包含私钥容器的 CSP"},
    {"/kc"..kc_name, " name",       "指定私钥的密钥容器名称"},
    -- Signing parameter options:
    {"/as",                         "追加此签名"},
    {"/d"..desc, " desc",           "提供已签名内容的描述"},
    {"/du"..url, " url",            "提供带有更多签名内容信息的 URL"},
    --timestamp_flags,
    {"/sa"..oidvalue, " oid value", "指定一个 <OID> 和 <value>，作为签名中的已验证属性包含在内"},
    {"/seal",                       "如果文件格式支持，添加密封签名"},
    {"/itos",                       "创建带有 intent-to-seal 属性的主签名"},
    {"/force",                      "在现有签名或密封签名需要移除以支持密封的情况下继续密封或签名"},
    {"/nosealwarn",                 "密封相关的警告不影响 SignTool 的返回代码"},
    {"/tdchw",                      "如果时间戳服务器摘要算法和签名哈希算法不同，则生成警告"},
    -- Digest options:
    {"/dg"..dir, " dir",            "在 <dir> 中，生成待签名的摘要和未签名的 PKCS7 文件"},
    {"/ds",                         "仅对摘要进行签名"},
    {"/di"..dir, " dir",            "在 <dir> 中，通过将已签名的摘要导入到未签名的 PKCS7 文件来创建签名"},
    {"/dxml",                       "与 /dg 一起使用时，生成 XML 文件"},
    {"/dlib"..file, " dll",         "指定实现 AuthenticodeDigestSign[Ex] 函数的 DLL，用于对摘要进行签名"},
    {"/dmdf"..file, " file",        "与 /dlib 一起使用时，将文件内容原样传递给 AuthenticodeDigestSign[Ex] 函数"},
    -- PKCS7 options:
    {"/p7"..dir, " dir",            "在 <dir> 中，为每个指定的内容文件生成一个 PKCS7 文件"},
    {"/p7co"..oid, " oid",          "指定标识已签名内容的 <OID>"},
    {"/p7ce"..pkcs7_mode, " mode",  "PKCS7 执行模式"},
    -- Other options:
    {"/ph",                         "如果支持，生成可执行文件的页面哈希"},
    {"/nph",                        "如果支持，抑制可执行文件的页面哈希"},
    {"/rmc",                        "指定使用松弛标记检查语义对 PE 文件进行签名"},
    --common_flags,
    {"/?",                          "显示 sign 命令的帮助"},
})
:_addexflags(timestamp_flags)
:_addexflags(common_flags)
:addarg(clink.filematches)
:loop()

local timestamp_parser = clink.argmatcher()
:_addexflags({
    --timestamp_flags,
    {"/tp"..index, " index",        "为 <index> 处的签名添加时间戳"},
    {"/p7",                         "为 PKCS7 文件添加时间戳"},
    {"/force",                      "移除任何存在的密封签名以便添加时间戳"},
    {"/nosealwarn",                 "移除密封签名的警告不影响 SignTool 的返回代码"},
    --common_flags,
    {"/debug",                      "显示额外的调试信息"},
    {"/?",                          "显示 timestamp 命令的帮助"},
})
:_addexflags(timestamp_flags)
:_addexflags(common_flags)

local verify_parser = clink.argmatcher()
:_addexflags({
    -- Catalog options:
    {"/a",                          "自动尝试使用所有方法验证文件"},
    {"/ad",                         "使用默认目录数据库自动查找目录"},
    {"/as",                         "使用系统组件（驱动程序）目录数据库自动查找目录"},
    {"/ag"..cat_guid, " guid",      "在指定的目录数据库中自动查找目录"},
    {"/c"..file, " file",           "指定目录文件"},
    {"/o"..placeholder, " ver",     "当验证已签名目录中的文件时，验证该文件对指定平台是否有效"},
    {"/hash"..hash_alg, " alg",     "在目录中搜索文件时使用的可选哈希算法"},
    -- Verification Policy options:
    {"/pa",                         "使用\"默认 Authenticode\"验证策略"},
    {"/pg"..placeholder, " guid",   "通过 GUID（也称为 ActionID）指定验证策略"},
    -- Signature requirement options:
    {"/ca"..placeholder, " hash",   "验证文件是否由具有指定哈希值的中间 CA 证书签名"},
    {"/r"..r_name, " name",         "指定签名证书必须链接到的根证书的主题名称"},
    {"/sha1"..placeholder, " hash", "验证签名者证书具有指定的哈希值"},
    {"/tw",                         "如果签名未添加时间戳，则生成警告"},
    {"/u"..placeholder, " usage",   "如果指定的增强密钥用法未在证书中，则生成警告"},
    -- Other options:
    {"/all",                        "验证具有多个签名的文件中的所有签名"},
    {"/ds"..index, " index",        "验证 <index> 处的签名"},
    {"/ms",                         "使用多重验证语义"},
    {"/sl",                         "验证支持的签名文件类型的密封签名"},
    {"/p7",                         "验证 PKCS7 文件"},
    {"/bp",                         "使用生物识别模式签名策略执行验证"},
    {"/enclave",                    "使用 enclave 签名策略执行验证"},
    {"/kp",                         "使用内核模式驱动程序签名策略执行验证"},
    {"/ph",                         "打印并验证页面哈希值"},
    {"/d",                          "打印描述和描述 URL"},
    --common_flags,
    {"/debug",                      "显示额外的调试信息"},
    {"/?",                          "显示 verify 命令的帮助"},
    {"/p7content"..file, " file",   "提供 p7 内容文件，用于分离签名（使用 Pkcs7DetachedSignedData 签名的情况）"},
})
:_addexflags(common_flags)

local catdb_parser = clink.argmatcher()
:_addexflags({
    {"/d",                          "对默认目录数据库进行操作，而非系统组件（驱动程序）目录数据库"},
    {"/g"..cat_guid, " guid",       "对指定的目录数据库进行操作"},
    {"/r",                          "从目录数据库中移除指定的目录"},
    {"/u",                          "自动为添加的目录生成唯一名称"},
    --common_flags,
    {"/debug",                      "显示额外的调试信息"},
    {"/?",                          "显示 catdb 命令的帮助"},
})
:_addexflags(common_flags)

local remove_parser = clink.argmatcher()
:_addexflags({
    {"/c",                          "移除签名中除签名者证书之外的所有证书"},
    {"/s",                          "完全移除签名"},
    {"/u",                          "移除签名中未经身份验证的属性（例如双重签名和时间戳）"},
    --common_flags,
    {"/?",                          "显示 remove 命令的帮助"},
})
:_addexflags(common_flags)

--------------------------------------------------------------------------------
-- The SignTool parser.

clink.argmatcher("signtool")
:_addexflags({
    {"/?",                          "显示帮助"},
})
:_addexarg({
    {"sign"..sign_parser,           "使用嵌入签名为文件签名"},
    {"timestamp"..timestamp_parser, "对先前签名的文件添加时间戳"},
    {"verify"..verify_parser,       "验证嵌入签名或目录签名"},
    {"catdb"..catdb_parser,         "修改目录数据库"},
    {"remove"..remove_parser,       "移除嵌入的签名或减小嵌入签名文件的大小"},
})

