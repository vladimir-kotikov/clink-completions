-- This is a shim script for allowing legacy clink-completions completion
-- parsers to load on demand instead of being preloaded.
--
-- Or, you can force preloading:
--
--      set CLINK_COMPLETIONS_PRELOAD=1

local clink_version = require("clink_version")

local deferred = {}

local function new_deferred(name)
    local d = deferred[name]
    local existed = d and true or nil
    if not d then
        d = {}
        deferred[name] = d
    end
    return d, existed
end

local function need_preload()
    -- Clink v1.3.23 and newer can load scripts on demand from the completions\
    -- directory, but older versions need to preload them.
    if not clink_version.supports_completions_directory then
        return true
    end

    local env = os.getenv("CLINK_COMPLETIONS_PRELOAD") or ""
    local num = tonumber(env) or 0
    if num > 0 then
        return true
    end
end

local function argmatcher(...)
    local t = {...}
    if not t[1] then
        error("Missing command name.")
    elseif t[2] then
        error("Too many command names.")
    end
    local name = t[1]

    if need_preload() then
        return clink.argmatcher(name)
    end

    local d, existed = new_deferred(name)
    if existed then
        if not d.argmatcher then
            error("Can't mix defer.argmatcher() and defer.register_parser() for the same name.")
        else
            error("Deferred argmatcher already exists for '"..name.."'.")
        end
    end

    d.argmatcher = clink.argmatcher()
    return d.argmatcher
end

local function register_parser(name, parser)
    if need_preload() then
        clink.arg.register_parser(name, parser)
        return
    end

    local d = new_deferred(name)
    if d.argmatcher then
        error("Can't mix defer.argmatcher() and defer.register_parser() for the same name.")
    end

    table.insert(d, parser)
end

local function realize(name)
    local d = deferred[name]        -- Get the deferred entry.
    if d.argmatcher then
        local a = clink.argmatcher(name)
        -- Empty the new argmatcher completely.
        for n in pairs(a) do
            a[n] = nil
        end
        -- Overlay it with the contents from the deferred argmatcher.
        for n, v in pairs(d.argmatcher) do
            a[n] = v
        end
    else
        -- Register the deferred parsers.
        for _, p in ipairs(d) do
            clink.arg.register_parser(name, p)
        end
    end
    deferred[name] = nil            -- Free the deferred entry.
end

local exports = {
    argmatcher = argmatcher,
    register_parser = register_parser,
    realize = realize,
}

return exports
