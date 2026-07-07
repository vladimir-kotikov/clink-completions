require('arghelper')

local deadend = clink.argmatcher():nofiles()
local placeholder = clink.argmatcher():addarg()
local users = clink.argmatcher():addarg({fromhistory=true})

local add_flags = {
    {"/user:"..users, "username",           "指定用户名"},
    {"/pass:"..placeholder, "password",     "指定密码"},
    {"/pass",                               "提示输入密码"},
    {"/smartcard",                          "从智能卡检索凭据"},
}

local function existing_targets(_, _, _, builder)
    local targets = {}
    local pending
    local f = io.popen("2>nul cmdkey.exe /list")
    if f then
        for line in f:lines() do
            local a,b = line:match("^ +Target: ([^=:]+):target=(.*)$")
            if a and b then
                pending = {type=a, target=b}
            elseif pending then
                local u = line:match("^ +User: (.+)$")
                if u then
                    table.insert(targets, {match=pending.target, type="arg", description=u.." ("..pending.type..")"})
                    pending = nil
                end
            end
        end
        f:close()
        if builder.setforcequoting then
            builder:setforcequoting()
        end
    end
    return targets
end

local list_targets = clink.argmatcher():addarg({fromhistory=true}):nofiles()
local domain_targets = clink.argmatcher():addarg({fromhistory=true}):_addexflags(add_flags):nofiles()
local generic_targets = clink.argmatcher():addarg({fromhistory=true}):_addexflags(add_flags):nofiles()
local delete_targets = clink.argmatcher():addarg({existing_targets}):nofiles()

clink.argmatcher("cmdkey")
:_addexflags({
    {"/list"..deadend,                      "列出可用凭据"},
    {"/list:"..list_targets, "targetname",  "列出 targetname 的可用凭据"},
    {"/add:"..domain_targets, "targetname", "创建域凭据"},
    {"/generic:"..generic_targets, "targetname", "创建通用凭据"},
    {"/delete /ras"..deadend,               "删除 RAS 凭据"},
    {"/delete:"..delete_targets, "targetname", "删除现有凭据"},
    {"/?",                                  "显示帮助"},
    {hide=true, "/delete"},
    {hide=true, "/ras"},
    {hide=true, "/user:"..users},
    {hide=true, "/pass:"..placeholder},
    {hide=true, "/pass"},
    {hide=true, "/smartcard"},
})
:nofiles()

