-- Rustc argmatcher for Rust.
local rh = require("rust_helper")
if rh then
    local rustc = rh.make_rust_argmatcher("rustc.exe")
    rustc.rust_data.help_commands[rustc] = "--help"
end
