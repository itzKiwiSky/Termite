function string.split(_string, _sep)
    _sep = _sep or "%s"
    local t = {}
    for str in string.gmatch(_string, "([^" .. _sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

-- Origin from penlight lib : https://github.com/lunarmodules/Penlight/blob/master/lua/pl/stringx.lua#L311
function string.justify(str, width, char, align)
    local n = #str
    if width > n then
        if not char then char = ' ' end
        local f1, f2
        if align == "center" then
            local rn = math.ceil((width - n) / 2)
            local ln = width - n - rn
            f1 = string.rep(char, ln)
            f2 = string.rep(char, rn)
        elseif align == "right" then
            f1 = string.rep(char, width - n)
            f2 = ''
        elseif align == "left" then
            f2 = string.rep(char, width - n)
            f1 = ''
        else
            error("Invalid align type")
        end
        return f1 .. str .. f2
    else
        return str
    end
end


function string.tokenizeWithPattern(_string, _sep)
    _sep = _sep or "%s"
    local t = {}
    for str in string.gmatch(_string, _sep) do
        table.insert(t, str)
    end
    return t
end

function string.contains(_string, _sub)
    return string.find(_string, _sub, 1, true) ~= nil
end

function string.startswith(_string, start)
    return string.sub(_string, 1, #start) == start
end

function string.replace(_string, _old, _new)
    local s = _string
    local search_start_idx = 1

    while true do
        local start_idx, end_idx = _string:find(_old, search_start_idx, true)
        if (not start_idx) then
            break
        end

        local postfix = _string:sub(end_idx + 1)
        _string = _string:sub(1, (start_idx - 1)) .. _new .. postfix

        search_start_idx = -1 * postfix:len()
    end

    return s
end

function string.endswith(_string, _ending)
    return _ending == "" or string.sub(_string, -#_ending) == _ending
end

function string.insert(_string, pos, text)
    return string.sub(_string, 1, pos - 1) .. text .. string.sub(_string, pos)
end

function string.complete(_char, _size)
    local s = ""
    for c = 1, _size, 1 do
        s = s .. _char
    end
    return s
end

return string