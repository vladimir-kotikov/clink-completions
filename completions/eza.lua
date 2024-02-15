require("arghelper")

-- luacheck: no max line length

local cols = clink.argmatcher():addarg({fromhistory=true})
local field = clink.argmatcher():addarg("all", "age", "size")
local mode = clink.argmatcher():addarg("gradient", "fixed")
local sort_field = clink.argmatcher():addarg("name", "Name", "extension", "Extension", "size", "type", "modified", "accessed", "created", "inode", "none", "date", "time", "old", "new")
local when = clink.argmatcher():addarg("always", "auto", "never")

clink.argmatcher("eza")
:_addexflags({
    -- META OPTIONS
    { "-?",                             "show help" },
    { "--help" },
    { "-v",                             "show version of eza" },
    { "--version" },

    -- DISPLAY OPTIONS
    { "-1",                             "display one entry per line" },
    { "--oneline" },
    { "-l",                             "display extended file metadata as a table" },
    { "--long" },
    { "-G",                             "display entries as a grid (default)" },
    { "--grid" },
    { "-x",                             "sort the grid across, rather than downwards" },
    { "--across" },
    { "-R",                             "recurse into directories" },
    { "--recurse" },
    { "-T",                             "recurse into directories as a tree" },
    { "--tree" },
    { "-X",                             "dereference symbolic links when displaying information" },
    { "--dereference" },
    { "-F",                             "display type indicator by file names" },
    { "-F="..when, "WHEN",              "when to display type indicator by file names" },
    { "--classify" },
    { "--classify="..when, "WHEN", "" },
    { "--color" },                          --"use terminal colors"
    { "--color="..when, "WHEN", "" },       --"when to use terminal colors"
    { hide=true, "--colour" },
    { hide=true, "--colour="..when },
    { "--color-scale" },                    --"highlight levels of all fields distinctly"
    { "--color-scale="..field, "FIELD", "" }, --"highlight levels of FIELD distinctly"
    { hide=true, "--colour-scale" },
    { hide=true, "--colour-scale="..field },
    { opteq=true, "--color-scale-mode="..mode, "MODE", "" }, --"use gradient or fixed colors in --color-scale"
    { hide=true, opteq=true, "--colour-scale-mode="..mode },
    { "--icons" },                          --"display icons"
    { "--icons="..when, "WHEN", "" },       --"when to display icons"
    { "--no-quotes" },                      --"don't quote file names with spaces"
    { "--hyperlink" },                      --"display entries as hyperlinks"
    { opteq=true, "-w="..cols, "COLS",      "set screen width in columns" },
    { hide=true, "-w"..cols },
    { opteq=true, "--width="..cols, "COLS", "" }, --"set screen width in columns"
    { hide=true, "--width"..cols },

    -- FILTERING AND SORTING OPTIONS
    { "-a",                             "show hidden and 'dot' files" },
    { "--all" },
    { "-aa",                            "also show the '.' and '..' directories" },
    { hide=true, "-A" },                    --"equivalent to --all; included for compatibility with `ls -A`"
    { hide=true, "--almost-all" },
    { "-d",                             "list directories as files; don't list their contents" },
    { "--list-dirs" },
    -- -L, --level DEPTH                limit the depth of recursion
    { "-r",                             "reverse the sort order" },
    { "--reverse" },
    { opteq=true, "-s="..sort_field, "SORT_FIELD", "which field to sort by" },
    { opteq=true, "--sort="..sort_field, "SORT_FIELD", "" },
    { "--group-directories-first" },        --"list directories before other files"
    { "-D",                             "list only directories" },
    { "--only-dirs" },
    { "-f",                             "list only files" },
    { "--only-files" },
    -- -I, --ignore-glob GLOBS          glob patterns (pipe-separated) of files to ignore
    { "--git-ignore" },                     --"ignore files mentioned in '.gitignore'"

    -- LONG VIEW OPTIONS
    { "-b",                             "list file sizes with binary prefixes" },
    { "--binary" },
    { "-B",                             "list file sizes in bytes, without any prefixes" },
    { "--bytes" },
    -- -g, --group                      list each file's group
    -- --smart-group                    only show group if it has a different name from owner
    { "-h",                             "add a header row to each column" },
    { "--header" },
    -- -H, --links                      list each file's number of hard links
    -- -i, --inode                      list each file's inode number
    -- -m, --modified                   use the modified timestamp field
    -- -M, --mounts                     show mount details (Linux and Mac only)
    -- -n, --numeric                    list numeric user and group IDs
    -- -O, --flags                      list file flags (Mac, BSD, and Windows only)
    -- -S, --blocksize                  show size of allocated file system blocks
    -- -t, --time FIELD                 which timestamp field to list (modified, accessed, created)
    -- -u, --accessed                   use the accessed timestamp field
    -- -U, --created                    use the created timestamp field
    -- --changed                        use the changed timestamp field
    -- --time-style                     how to format timestamps (default, iso, long-iso, full-iso, relative, or a custom style '+<FORMAT>' like '+%Y-%m-%d %H:%M')
    -- --total-size                     show the size of a directory as the size of all files and directories inside (unix only)
    -- --no-permissions                 suppress the permissions field
    -- -o, --octal-permissions          list each file's permission in octal format
    -- --no-filesize                    suppress the filesize field
    -- --no-user                        suppress the user field
    -- --no-time                        suppress the time field
    -- --stdin                          read file names from stdin, one per line or other separator specified in environment
    { "--git" },                            --"list each file's Git status, if tracked or ignored"
    { "--no-git" },                         --"suppress Git status"
    { "--git-repos" },                      --"list root of git-tree status"
})
