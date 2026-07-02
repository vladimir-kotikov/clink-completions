--------------------------------------------------------------------------------
-- Clink argmatcher for rm (GNU coreutils)
--

clink.argmatcher("rm")
:adddescriptions({
    ["-r"] = { "Remove directories and their contents recursively" },
    ["-R"] = { "Remove directories and their contents recursively" },
    ["--recursive"] = { "Remove directories and their contents recursively" },
    ["-f"] = { "Ignore nonexistent files, never prompt" },
    ["--force"] = { "Ignore nonexistent files, never prompt" },
    ["-i"] = { "Prompt before every removal" },
    ["-I"] = { "Prompt once before removing more than three files" },
    ["--interactive"] = { " arg", "Prompt according to WHEN: always, once, never" },
    ["-v"] = { "Explain what is being done" },
    ["--verbose"] = { "Explain what is being done" },
    ["-d"] = { "Remove empty directories" },
    ["--dir"] = { "Remove empty directories" },
    ["--one-file-system"] = { "Stay on this file system when recursive" },
    ["--no-preserve-root"] = { "Do not treat '/' specially" },
    ["--preserve-root"] = { "Do not remove '/' (default)" },
    ["--help"] = { "Display help and exit" },
    ["--version"] = { "Output version information and exit" },
})
:addflags({
    "-r", "-R", "--recursive",
    "-f", "--force",
    "-i",
    "-I",
    "--interactive="..(clink.argmatcher():addarg({"always", "once", "never"})),
    "-v", "--verbose",
    "-d", "--dir",
    "--one-file-system",
    "--no-preserve-root",
    "--preserve-root",
    "--help", "--version",
})
