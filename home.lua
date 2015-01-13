local function tilde_match (text, f, l)
    if text == '~' then
        clink.add_match(clink.get_env('userprofile')..'\\')
        return true
    end
end

clink.register_match_generator(tilde_match, 1)