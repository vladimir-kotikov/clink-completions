-- Rustc argmatcher for Rust.
local rh = require("rust_helper")
local rustc = rh.make_rust_argmatcher("rustc.exe")
rustc.rust_data.help_commands[rustc] = "--help"
