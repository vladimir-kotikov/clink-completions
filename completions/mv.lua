--------------------------------------------------------------------------------
-- Clink argmatcher for mv (GNU coreutils)
--

clink.argmatcher("mv")
:adddescriptions({
    ["-f"] = { "Do not prompt before overwriting" },
    ["--force"] = { "Do not prompt before overwriting" },
    ["-i"] = { "Prompt before overwrite" },
    ["--interactive"] = { "Prompt before overwrite" },
    ["-n"] = { "Do not overwrite an existing file" },
    ["--no-clobber"] = { "Do not overwrite an existing file" },
    ["-v"] = { "Explain what is being done" },
    ["--verbose"] = { "Explain what is being done" },
    ["-u"] = { "Move only when the source is newer than the destination" },
    ["--update"] = { "Move only when the source is newer than the destination" },
    ["-T"] = { "Treat destination as a normal file" },
    ["--no-target-directory"] = { "Treat destination as a normal file" },
    ["-t"] = { " arg", "Move all sources into DIRECTORY" },
    ["--target-directory"] = { " arg", "Move all sources into DIRECTORY" },
    ["-b"] = { "Make a backup of each existing destination file" },
    ["--backup"] = { "Make a backup of each existing destination file" },
    ["--strip-trailing-slashes"] = { "Remove any trailing slashes from each source argument" },
    ["--help"] = { "Display help and exit" },
    ["--version"] = { "Output version information and exit" },
})
:addflags({
    "-f", "--force",
    "-i", "--interactive",
    "-n", "--no-clobber",
    "-v", "--verbose",
    "-u", "--update",
    "-T", "--no-target-directory",
    "-t"..(clink.argmatcher():addarg(clink.dirmatches)),
    "--target-directory="..(clink.argmatcher():addarg(clink.dirmatches)),
    "-b", "--backup",
    "--strip-trailing-slashes",
    "--help", "--version",
})
