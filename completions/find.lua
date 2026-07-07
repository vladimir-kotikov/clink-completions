--------------------------------------------------------------------------------
-- Clink argmatcher for find (uutils / GNU findutils)
--

local num_arg = clink.argmatcher():addarg({fromhistory=true})
local type_matcher = clink.argmatcher():addarg({"f", "d", "l", "b", "c", "p", "s"})
local size_matcher = clink.argmatcher():addarg({fromhistory=true})

clink.argmatcher("find")
:addarg(clink.dirmatches)
:addflags({
    -- Global options (must appear before paths)
    "-P", "-L", "-H",
    "-D"..clink.argmatcher():addarg({"help", "tree", "search", "stat", "rates", "opt", "exec"}),
    "-O"..clink.argmatcher():addarg({"0", "1", "2", "3"}),
})
:adddescriptions({
    -- Global
    ["-P"] = { "绝不跟随符号链接（默认）" },
    ["-L"] = { "跟随符号链接" },
    ["-H"] = { "不跟随符号链接（命令行上的除外）" },
    ["-D"] = { " debug", "打印调试信息" },
    ["-O"] = { " level", "启用查询优化（0-3）" },
    -- Tests: name/path matching
    ["-name"] = { " pattern", "按文件名匹配（区分大小写），支持通配符" },
    ["-iname"] = { " pattern", "按文件名匹配（不区分大小写），支持通配符" },
    ["-path"] = { " pattern", "按完整路径匹配（区分大小写）" },
    ["-ipath"] = { " pattern", "按完整路径匹配（不区分大小写）" },
    ["-regex"] = { " pattern", "用正则表达式匹配路径（区分大小写）" },
    ["-iregex"] = { " pattern", "用正则表达式匹配路径（不区分大小写）" },
    -- Tests: file type
    ["-type"] = { " type", "按文件类型筛选：f=文件 d=目录 l=符号链接 b=块设备 c=字符设备 p=管道 s=套接字" },
    ["-xtype"] = { " type", "检查符号链接解引用后的类型" },
    -- Tests: file size
    ["-size"] = { " n[cwbkMG]", "按文件大小筛选。+n=大于 -n=小于 n=精确；c=字节 w=2字节 b=512字节 k=KB M=MB G=GB" },
    ["-empty"] = { "文件为空（普通文件大小为0或目录为空）" },
    -- Tests: time
    ["-amin"] = { " n", "文件 n 分钟前被访问" },
    ["-atime"] = { " n", "文件 n 天前被访问" },
    ["-cmin"] = { " n", "文件状态 n 分钟前被更改" },
    ["-ctime"] = { " n", "文件状态 n 天前被更改" },
    ["-mmin"] = { " n", "文件数据 n 分钟前被修改" },
    ["-mtime"] = { " n", "文件数据 n 天前被修改" },
    ["-newer"] = { " file", "比指定文件更新的文件" },
    ["-newerXY"] = { " ref", "比较文件时间戳，X/Y=a=atime c=ctime m=mtime B=birth" },
    ["-used"] = { " n", "文件在 n 天前被访问并修改过" },
    -- Tests: permissions
    ["-perm"] = { " mode", "按权限位筛选。-/mode=任一位匹配 mode=精确匹配 /mode=任意位匹配" },
    ["-readable"] = { "当前用户可读" },
    ["-writable"] = { "当前用户可写" },
    ["-executable"] = { "当前用户可执行" },
    -- Tests: ownership
    ["-user"] = { " name", "按用户名筛选" },
    ["-nouser"] = { "文件不属于任何已知用户" },
    ["-group"] = { " name", "按组名筛选" },
    ["-nogroup"] = { "文件不属于任何已知组" },
    -- Tests: links
    ["-links"] = { " n", "链接数为 n 的文件" },
    -- Tests: content
    ["-samefile"] = { " file", "与指定文件指向相同 inode 的文件（硬链接）" },
    -- Tests: depth
    ["-maxdepth"] = { " n", "最大搜索深度（从1开始）" },
    ["-mindepth"] = { " n", "最小搜索深度（从0开始）" },
    -- Tests: multiple criteria
    ["-a"] = { "与运算（默认，可省略）" },
    ["-and"] = { "与运算（默认，可省略）" },
    ["-o"] = { "或运算" },
    ["-or"] = { "或运算" },
    ["-not"] = { "非运算" },
    ["-!"] = { "非运算" },
    ["("] = { "分组开始" },
    [")"] = { "分组结束" },
    -- Actions
    ["-print"] = { "打印文件名，每行一个（默认动作）" },
    ["-print0"] = { "打印文件名，以 NUL 分隔" },
    ["-printf"] = { " format", "按自定义格式打印" },
    ["-fprintf"] = { " file", " format", "将格式化输出写入文件" },
    ["-ls"] = { "以 ls -dils 格式列出文件" },
    ["-fls"] = { " file", "以 ls -dils 格式列出文件并写入文件" },
    ["-delete"] = { "删除匹配的文件（自动启用 -depth）" },
    ["-exec"] = { " cmd ;", "对每个匹配文件执行命令（以 ; 结尾）" },
    ["-execdir"] = { " cmd ;", "在匹配文件所在目录执行命令（以 ; 结尾）" },
    ["-ok"] = { " cmd ;", "执行命令前询问确认（以 ; 结尾）" },
    ["-okdir"] = { " cmd ;", "在文件目录执行命令前询问确认（以 ; 结尾）" },
    ["-prune"] = { "不进入当前目录（配合 -path 使用以排除目录）" },
    ["-quit"] = { "立即退出" },
    -- Help
    ["--help"] = { "显示帮助并退出" },
    ["--version"] = { "输出版本信息并退出" },
})
