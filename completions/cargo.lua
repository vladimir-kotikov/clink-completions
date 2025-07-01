-- Cargo argmatcher for Rust.
local rh = require("rust_helper")
if rh then
    local cargo = rh.make_rust_argmatcher("cargo.exe")
    cargo.rust_data.dashdashlist = true
end
