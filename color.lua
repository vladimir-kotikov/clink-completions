local function color(fore, back, fbold, bbold)

    local color_codes = {"black", "red", "green", "yellow",
                    "blue", "magenta", "cyan", "white"}

    local function parse_color(color_code)
        if type(color_code) == "number" and 0 <= color_code <= 9 then
            return color_code
        elseif type(color_code) == "string" then
            for code, name in pairs(color_codes) do
                if color_code == name then
                    return code - 1
                end
            end
        end
        return 9 -- default color_code
    end

    local forecode = parse_color(fore)
    local backcode = parse_color(back)
    local fboldcode = fbold and 1 or 22 -- some kind of ternary operator
    local bboldcode = bbold and 1 or 22 -- some kind of ternary operator

    return "\x1b[3"..forecode..";"..fboldcode..";".."4"..backcode..";"..bboldcode.."m"
end

function color_text(text, fore, back, fbold, bbold)
    return color(fore, back, fbold, bbold)..text..color()
end
