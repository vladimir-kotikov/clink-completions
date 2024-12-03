require("arghelper")

-- luacheck: no max line length

local cols = clink.argmatcher():addarg({fromhistory=true})
local field = clink.argmatcher():addarg("all", "age", "size")
local levels = clink.argmatcher():addarg({fromhistory=true, "1", "2", "3", "4"})
local mode = clink.argmatcher():addarg("gradient", "fixed")
local sortfield = clink.argmatcher():addarg("name", "Name", "extension", "Extension", "size", "type", "modified", "accessed", "created", "inode", "none", "date", "time", "old", "new")
local timefield = clink.argmatcher():addarg("modified", "accessed", "created")
local timestyles = clink.argmatcher():addarg({nosort=true, "default", "iso", "long-iso", "full-iso", "relative", '"+%Y-%m-%d %H:%M"'})
local when = clink.argmatcher():addarg("always", "auto", "never")

clink.argmatcher("eza")
:_addexflags({
    -- META OPTIONS
    { "-?",                             "show help" },
    { "--help",                         "show help" },
    { "-v",                             "show version of eza" },
    { "--version",                      "show version of eza" },

    -- DISPLAY OPTIONS
    { "-1",                             "display one entry per line" },
    { "--oneline",                      "display one entry per line" },
    { "-l",                             "display extended file metadata as a table" },
    { "--long",                         "display extended file metadata as a table" },
    { "-G",                             "display entries as a grid (default)" },
    { "--grid",                         "display entries as a grid (default)" },
    { "-x",                             "sort the grid across, rather than downwards" },
    { "--across",                       "sort the grid across, rather than downwards" },
    { "-R",                             "recurse into directories" },
    { "--recurse",                      "recurse into directories" },
    { "-T",                             "recurse into directories as a tree" },
    { "--tree",                         "recurse into directories as a tree" },
    { "-X",                             "dereference symbolic links when displaying information" },
    { "--dereference",                  "dereference symbolic links when displaying information" },
    { "-F",                             "display type indicator by file names" },
    { "--classify",                     "display type indicator by file names" },
    { "-F="..when, "WHEN",              "when to display type indicator by file names" },
    { "--classify="..when, "WHEN",      "when to display type indicator by file names" },
    { "--color",                        "use terminal colors" },
    { "--color="..when, "WHEN",         "when to use terminal colors" },
    { hide=true, "--colour" },
    { hide=true, "--colour="..when },
    { "--color-scale",                  "highlight levels of all fields distinctly" },
    { "--color-scale="..field, "FIELD", "highlight levels of FIELD distinctly" },
    { hide=true, "--colour-scale" },
    { hide=true, "--colour-scale="..field },
    { opteq=true, "--color-scale-mode="..mode, "MODE", "use gradient or fixed colors in --color-scale" },
    { hide=true, opteq=true, "--colour-scale-mode="..mode },
    { "--icons",                        "display icons" },
    { "--icons="..when, "WHEN",         "when to display icons" },
    { "--no-quotes",                    "don't quote file names with spaces" },
    { "--hyperlink",                    "display entries as hyperlinks" },
    { "--follow-symlinks",              "drill down into symbolic links that point to directories" },
    { "--absolute",                     "display entries with their absolute path" },
    { opteq=true, "-w="..cols, "COLS",  "set screen width in columns" },
    { hide=true, "-w"..cols },
    { opteq=true, "--width="..cols, "COLS", "set screen width in columns" },
    { hide=true, "--width"..cols },

    -- FILTERING AND SORTING OPTIONS
    { "-a",                             "show hidden and 'dot' files" },
    { "--all",                          "show hidden and 'dot' files" },
    { "-aa",                            "also show the '.' and '..' directories" },
    { hide=true, "-A" },                    --"equivalent to --all; included for compatibility with `ls -A`"
    { hide=true, "--almost-all" },
    { "-d",                             "list directories as files; don't list their contents" },
    { "--list-dirs",                    "list directories as files; don't list their contents" },
    { opteq=true, "-L"..levels, " DEPTH",      "limit the depth of recursion" },
    { opteq=true, "--level="..levels, "DEPTH", "limit the depth of recursion" },
    { "-r",                             "reverse the sort order" },
    { "--reverse",                      "reverse the sort order" },
    { opteq=true, "-s="..sortfield, "SORT_FIELD",     "which field to sort by" },
    { opteq=true, "--sort="..sortfield, "SORT_FIELD", "which field to sort by" },
    { "--group-directories-first",      "list directories before other files" },
    { "--group-directories-last",       "list directories after other files" },
    { "-D",                             "list only directories" },
    { "--only-dirs",                    "list only directories" },
    { "-f",                             "list only files" },
    { "--only-files",                   "list only files" },
    { "--show-symlinks",                "explicitly show symbolic links (for use with --only-dirs | --only-files)" },
    { "--no-symlinks",                  "do not show symbolic links" },
    -- -I, --ignore-glob GLOBS          glob patterns (pipe-separated) of files to ignore
    { "--git-ignore",                   "ignore files mentioned in '.gitignore'" },

    -- LONG VIEW OPTIONS
    { "-b",                             "list file sizes with binary prefixes" },
    { "--binary",                       "list file sizes with binary prefixes" },
    { "-B",                             "list file sizes in bytes, without any prefixes" },
    { "--bytes",                        "list file sizes in bytes, without any prefixes" },
    -- -g, --group                      list each file's group
    -- --smart-group                    only show group if it has a different name from owner
    { "-h",                             "add a header row to each column" },
    { "--header",                       "add a header row to each column" },
    -- -H, --links                      list each file's number of hard links
    -- -i, --inode                      list each file's inode number
    -- -m, --modified                   use the modified timestamp field
    -- -M, --mounts                     show mount details (Linux and Mac only)
    -- -n, --numeric                    list numeric user and group IDs
    { "-O",                             "list file flags (Mac, BSD, and Windows only)" },
    { "--flags",                        "list file flags (Mac, BSD, and Windows only)" },
    { "-S",                             "show size of allocated file system blocks" },
    { "--blocksize",                    "show size of allocated file system blocks" },
    { opteq=true, "-t"..timefield, " FIELD", "which timestamp field to list" },
    { opteq=true, "--time="..timefield, "FIELD", "" },
    { "-m",                             "use the modified timestamp field" },
    { "--modified",                     "use the modified timestamp field" },
    { "-u",                             "use the accessed timestamp field" },
    { "--accessed",                     "use the accessed timestamp field" },
    { "-U",                             "use the created timestamp field" },
    { "--created",                      "use the created timestamp field" },
    { "--changed",                      "use the changed timestamp field" },
    { opteq=true, "--time-style="..timestyles, "STYLE", "how to format timestamps" },
    -- --total-size                     show the size of a directory as the size of all files and directories inside (unix only)
    { "--no-permissions",               "suppress the permissions field" },
    -- -o, --octal-permissions          list each file's permission in octal format
    { "--no-filesize",                  "suppress the filesize field" },
    -- --no-user                        suppress the user field
    { "--no-time",                      "suppress the time field" },
    -- --stdin                          read file names from stdin, one per line or other separator specified in environment
    { "--git",                          "list each file's Git status, if tracked or ignored" },
    { "--no-git",                       "suppress Git status" },
    { "--git-repos",                    "list root of git-tree status" },
    { "--git-repos-no-status",          "list each git-repos branch name (much faster)" },
})
