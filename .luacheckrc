return {
    exclude_files = { ".lua", "modules/JSON.lua" },
    files = {
        spec = { std = "+busted" },
    },
    globals = { "clink", "rl_state" }
}
