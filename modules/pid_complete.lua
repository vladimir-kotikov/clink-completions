local export = {}

local generated_matches
local use_popuplist = (clink.version_encoded or 0) >= 10050001

local function filter_matches(matches, completion_type)
    if completion_type ~= "?" then
        local indexed = {}
        for _, m in ipairs(generated_matches) do
            indexed[m.match] = m
        end
        local items = {}
        for _, m in ipairs(matches) do
            m = indexed[m.match]
            if m then
                table.insert(items, {value=m.match, description=m.description})
            end
        end
        local selected = clink.popuplist("Process ID", items)
        return selected and {selected} or {}
    end
end

local function run_tlist()
    local p = io.popen("2>nul tlist.exe")
    if not p then
        return
    end

    local matches = {}
    local name_len = 0
    for line in p:lines() do
        local pid, info = line:match("^([0-9]+) (.*)$")
        if pid then
            local executable, title = info:match("^(.*[^ ])   +(.*)$")
            if title and title ~= "" then
                if executable:lower() ~= "tlist.exe" then
                    local len
                    if not use_popuplist then
                        len = console.cellcount(executable)
                    end
                    table.insert(matches, {match=pid, description=executable, title=title, len=len})
                    if len and name_len < len then
                        name_len = len
                    end
                end
            else
                if info:lower() ~= "tlist.exe" then
                    local len
                    if not use_popuplist then
                        len = console.cellcount(info)
                    end
                    table.insert(matches, {match=pid, description=info, len=len})
                    if len and name_len < len then
                        name_len = len
                    end
                end
            end
        end
    end

    p:close()
    return matches, name_len
end

local function make_file_at_path(root, rhs)
    if root and rhs then
        if root ~= "" and rhs ~= "" then
            local ret = path.join(root, rhs)
            if os.isfile(ret) then
                return '"' .. ret .. '"'
            end
        end
    end
end

local function run_powershell_get_process()
    local root = os.getenv("systemroot")
    local child = "System32\\WindowsPowerShell\\v1.0\\powershell.exe"
    local powershell_exe = make_file_at_path(root, child)
    if not powershell_exe then
        return
    end

    local command = '2>&1 '..powershell_exe..' -Command "'..
        '$OutputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false); '..
        'get-process | format-list Id, Name, MainWindowTitle"'

    local matches = {}
    local name_len = 0

    local f = io.popen(command, 'r')
    if f then
        local m
        local function finish_pending()
            if m then
                local len
                if not use_popuplist then
                    len = console.cellcount(m["Name"])
                    if name_len < len then
                        name_len = len
                    end
                end
                table.insert(matches, { match=m["Id"], description=m["Name"], title=m["MainWindowTitle"], len=len })
                m = nil
            end
        end
        for line in f:lines() do
            local field, value = line:match("^(%w+)%s+:%s*(.*)$")
            if field == "Id" then
                finish_pending()
            end
            if field and value and value ~= "" then
                m = m or {}
                m[field] = value
            end
        end
        finish_pending()
        f:close()
    end

    return matches, name_len
end

local function pid_matches()
    generated_matches = nil

    local matches
    local name_len
    if os.getenv("CLINK_PID_COMPLETE_TLIST") then
        matches, name_len = run_tlist()
    else
        matches, name_len = run_powershell_get_process()
    end
    if not matches or not name_len then
        return {}
    end

    matches.nosort = true
    table.sort(matches, function (a, b)
        if string.comparematches(a.description, b.description) then
            return true
        elseif string.comparematches(b.description, a.description) then
            return false
        end
        if string.comparematches(a.title or "", b.title or "") then
            return true
        elseif string.comparematches(b.title or "", a.title or "") then
            return false
        end
        if tonumber(a.match) < tonumber(b.match) then
            return true
        else
            return false
        end
    end)

    local screeninfo = os.getscreeninfo()
    if name_len > screeninfo.bufwidth / 3 then
        name_len = screeninfo.bufwidth / 3
    end
    if name_len > 32 then
        name_len = 32
    end

    for _, m in ipairs(matches) do
        if m.title then
            if use_popuplist then
                m.description = m.description.."\t\""..m.title.."\""
            else
                local pad = string.rep(" ", name_len - m.len)
                m.description = m.description..pad.."    "..m.title
            end
        end
    end

    if #matches > 1 and use_popuplist then
        generated_matches = matches
        clink.onfiltermatches(filter_matches)
    end

    return matches, name_len
end

export.argmatcher = clink.argmatcher():addarg(pid_matches)
export.matches = pid_matches

return export
