function color(fore, back, fbold, bbold)

    local colors = {"black", "red", "green", "yellow",
                    "blue", "magenta", "cyan", "white"}

    local function parse_color(color)
        if type(color) == "number" and 0 <= color <= 9 then
            return color
        elseif type(color) == "string" then
            for code, name in pairs(colors) do
                if color == name then
                    return code-1
                end
            end
        end
        return 9 -- default color
    end

    local forecode = parse_color(fore)
    local backcode = parse_color(back)
    local fboldcode = bold and 1 or 22 -- some kind of ternary operator
    local bboldcode = bold and 1 or 22 -- some kind of ternary operator

    return "\x1b[3"..forecode..";"..fboldcode..";".."4"..backcode..";"..bboldcode.."m"
end

function color_text(text, fore, back, fbold, bbold)
    return color(fore, back, fbold, bbold)..text..color()
end