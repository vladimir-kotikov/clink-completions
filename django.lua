local parser = clink.arg.new_parser

local function register_parser(dj_parser)
    dj_parser:disable_file_matching()
    local manage_parser = parser({ 'manage.py'..dj_parser })
    clink.arg.register_parser('django', dj_parser)
    clink.arg.register_parser('python', manage_parser)
    clink.arg.register_parser('python3', manage_parser)
end

local function is_django_project()
    local manage_file = io.open(clink.get_cwd()..'/manage.py', 'r')
    if manage_file ~= nil then
        manage_file:close()
        return true
    end

    return false
end

local commands = {
    'changepassword',
    'createsuperuser',
    'remove_stale_contenttypes',
    'check',
    'compilemessages',
    'createcachetable',
    'dbshell',
    'diffsettings',
    'dumpdata',
    'flush',
    'inspectdb',
    'loaddata',
    'makemessages',
    'makemigrations',
    'migrate',
    'sendtestemail',
    'shell',
    'showmigrations',
    'sqlflush',
    'sqlmigrate',
    'sqlsequencereset',
    'squashmigrations',
    'startapp',
    'startproject',
    'test',
    'testserver',
    'clearsessions',
    'collectstatic',
    'findstatic',
    'runserver'
}

local function parse_args(word)
    if not is_django_project() then return end
    return commands
end

register_parser( parser({ parse_args }) )
register_parser( parser({ 'help'..parser({ commands }) }) )
