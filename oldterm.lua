-- LV-100

-- TODO : rethink character coloring to simplify stuff

local utf8 = require("utf8")

-- The good old 3-bit color scheme.
local basic_scheme = {
    ["black"] = {0, 0, 0},
    ["blue"] = {0, 0, 0.5},
    ["brightBlack"] = {0.5, 0.5, 0.5},
    ["brightBlue"] = {0, 0, 1},
    ["brightCyan"] = {0, 1, 1},
    ["brightGreen"] = {0, 1, 0},
    ["brightMagenta"] = {1, 0, 1},
    ["brightRed"] = {1, 0, 0},
    ["brightWhite"] = {1, 1, 1},
    ["brightYellow"] = {1, 1, 0},
    ["cyan"] = {0, 0.5, 0.5},
    ["green"] = {0, 0.5, 0},
    ["magenta"] = {0.5, 0, 0.5},
    ["red"] = {0.5, 0, 0},
    ["white"] = {0.75, 0.75, 0.75},
    ["yellow"] = {0.5, 0.5, 0}
}
-- Origin of this snippet : https://stackoverflow.com/a/43139063
local function utf8_sub(s,i,j)
    i=utf8.offset(s,i)
    j=utf8.offset(s,j+1)-1
    return string.sub(s,i,j)
end

local function terminal_update_character(terminal, x, y, newChar)
    terminal.buffer[y][x] = newChar
    local char_color = terminal.cursor_color
    local char_backcolor = terminal.cursor_backcolor
    terminal.state_buffer[y][x].color = {char_color[1], char_color[2], char_color[3], char_color[4]}
    terminal.state_buffer[y][x].backcolor = {char_backcolor[1], char_backcolor[2], char_backcolor[3], char_backcolor[4]}
    terminal.state_buffer[y][x].reversed = terminal.cursor_reversed
    terminal.state_buffer[y][x].dirty = true
end

local function terminal_hide_cursor(terminal)
    table.insert(terminal.stdin, {type="hide_cursor"})
end

local function terminal_show_cursor(terminal)
    table.insert(terminal.stdin, {type="show_cursor"})
end

local function terminal_set_cursor_color(terminal, red, blue, green, alpha)
    -- Argument processing
    if type(red) == "table" and blue == nil then
        red, blue, green, alpha = red[1], red[2], red[3], red[4]
    end
    table.insert(terminal.stdin, {type="cursor_color", red=red, blue=blue, green=green, alpha=(alpha or 1)})
end

local function terminal_set_cursor_backcolor(terminal, red, blue, green, alpha)
    -- Argument processing
    if type(red) == "table" and blue == nil then
        red, blue, green, alpha = red[1], red[2], red[3], red[4]
    end
    table.insert(terminal.stdin, {type="cursor_backcolor", red=red, blue=blue, green=green, alpha=(alpha or 1)})
end


local function terminal_move_to(terminal, x, y)
    table.insert(terminal.stdin, {type="move", x=math.floor(x), y=math.floor(y)})
end

local function terminal_reverse(terminal, set)
    table.insert(terminal.stdin, {type="reverse", value=set})
end

local function terminal_clear(terminal, x, y, w, h)
    x = x or 1
    y = y or 1
    w = w or terminal.width
    h = h or terminal.height
    table.insert(terminal.stdin, {type="clear", x=x, y=y, w=w, h=h})
end

local function terminal_frame(terminal, style, x, y, w, h)
    table.insert(terminal.stdin, {type="frame", style=style, x=math.floor(x), y=math.floor(y), w=math.floor(w), h=math.floor(h)})
end

local function terminal_fill(terminal, style, x, y, w, h)
    table.insert(terminal.stdin, {type="fill", style=style, x=math.floor(x), y=math.floor(y), w=math.floor(w), h=math.floor(h)})
end

local function terminal_frame_shadow(terminal, style, x, y, w, h, light, shadow)
    table.insert(terminal.stdin, {type="frame_shadow", style=style, x=math.floor(x), y=math.floor(y), w=math.floor(w), h=math.floor(h), light=light, shadow=shadow})
end

local function _updateScreen(terminal)
    local char_color = terminal.cursor_color
    local char_backcolor = terminal.cursor_backcolor
    terminal.dirty = true
    for _y = 1, terminal.height, 1 do
        for _x = 1, terminal.width, 1 do
            terminal.state_buffer[_y][_x].color = char_color
            terminal.state_buffer[_y][_x].backcolor = char_backcolor
            terminal.state_buffer[_y][_x].dirty = true
        end
    end
end

local function terminal_get_cursor_color(terminal)
    return terminal.cursor_color, terminal.cursor_backcolor
end

local function terminal_roll_up(terminal, how_many)
    for times = 1, how_many, 1 do
        local first_row = terminal.buffer[1]
        for y = 2,terminal.height, 1 do
            terminal.buffer[y - 1] = terminal.buffer[y]
        end
        terminal.buffer[terminal.height] = first_row
        for i = 1, terminal.width, 1 do
            first_row[i] = ' '
        end 
    end
    _updateScreen(terminal)
end

local function wrap_if_bottom(terminal)
    if terminal.cursor_y >= terminal.height then
        terminal_roll_up(terminal, terminal.cursor_y - terminal.height)
        terminal.cursor_y = terminal.height
        terminal.dirty = true
    end
end

local function getTerminalState(terminal)
    return {
        buffer = terminal.buffer,
        stateBuffer = terminal.state_buffer
    }
end

local function applyTerminalState(terminal, state)
    terminal.buffer = state.buffer
    terminal.state_buffer = state.stateBuffer
end

local function update(terminal, dt)
    local styles = {
        ["line"] = "┌┐└┘─│",
        ["bold"] = "┏┓┗┛━┃",
        ["text"] = "++++-|",
        ["double"] = "╔╗╚╝═║",
        ["block"] = "██████"
    }

    local fillStyles = {
        ["blank"] = " ",
        ["block"] = "█",
        ["semigrid"] = "▓",
        ["halfgrid"] = "▒",
        ["grid"] = "░"
    }

    terminal.dirty = true
    if #terminal.stdin == 0 then return end
    local frame_budget = terminal.speed * dt + terminal.accumulator
    local stdin_index = 1
    while frame_budget > terminal.char_cost do
        local char_or_command = terminal.stdin[stdin_index]
        if char_or_command == nil then break end
        stdin_index = stdin_index + 1
        frame_budget = frame_budget - terminal.char_cost

        if type(char_or_command) == "string" then
            if char_or_command == '\b' then
                terminal.cursor_x = math.max(terminal.cursor_x - 1, 1)
            elseif char_or_command == '\n' then
                terminal.cursor_x = 1
                terminal.cursor_y = terminal.cursor_y + 1
                wrap_if_bottom(terminal)
                terminal.dirty = true
            else
                terminal_update_character(terminal, terminal.cursor_x, terminal.cursor_y, char_or_command)
                terminal.cursor_x = terminal.cursor_x + 1
                if terminal.cursor_x > terminal.width then
                    terminal.cursor_x = 1
                    terminal.cursor_y = terminal.cursor_y + 1
                    wrap_if_bottom(terminal)
                end
                terminal.dirty = true
            end
        elseif char_or_command.type == "clear" then
            local x,y,w,h = char_or_command.x or 1, char_or_command.y or 1, char_or_command.w or terminal.width, char_or_command.h or terminal.h
            for y=y,y+h-1 do
                for x=x,x+w-1 do
                    terminal_update_character(terminal, x, y, " ")
                    terminal.buffer[y][x] = " "
                end
            end
            terminal.dirty = true
        elseif char_or_command.type == "hide_cursor" then
            terminal.show_cursor = false
        elseif char_or_command.type == "show_cursor" then
            terminal.show_cursor = true
        elseif char_or_command.type == "cursor_color" then
            terminal.cursor_color[1] =  char_or_command.red
            terminal.cursor_color[2] = char_or_command.blue
            terminal.cursor_color[3] = char_or_command.green
            terminal.cursor_color[4] = char_or_command.alpha
        elseif char_or_command.type == "cursor_backcolor" then
            terminal.cursor_backcolor[1] =  char_or_command.red
            terminal.cursor_backcolor[2] = char_or_command.blue
            terminal.cursor_backcolor[3] = char_or_command.green
            terminal.cursor_backcolor[4] = char_or_command.alpha
        elseif char_or_command.type == "move" then
            terminal.cursor_x = char_or_command.x
            terminal.cursor_y = char_or_command.y
        elseif char_or_command.type == "reverse" then
            terminal.cursor_reversed = (char_or_command.value ~= nil) and char_or_command.value or not terminal.cursor_reversed
        elseif char_or_command.type == "save" then
            terminal.saved_cursor_x = terminal.cursor_x
            terminal.saved_cursor_y = terminal.cursor_y
        elseif char_or_command.type == "load" then
            terminal.cursor_x = terminal.saved_cursor_x
            terminal.cursor_y = terminal.saved_cursor_y
        elseif char_or_command.type == "fill" then
            local x, y, w, h = char_or_command.x, char_or_command.y, char_or_command.w, char_or_command.h
            local style = char_or_command.style

            local charStyle = fillStyles[style]

            if not charStyle then
                assert(false, string.format("Unrecognized style %s", style))
            end

            local x, y, width, height = char_or_command.x, char_or_command.y, char_or_command.w, char_or_command.h

            local left, right = x, x + (width - 1)
            local top, bottom = y, y + (height - 1)

            for cy = y, y + h, 1 do
                for cx = x, x + w, 1 do
                    terminal_update_character(terminal, cx, cy, charStyle)
                end
            end
        elseif char_or_command.type == "frame" then

            local curStyle = styles[char_or_command.style]
            if not curStyle then
                assert(false, string.format("Unrecognized style %s", char_or_command.style))
            end

            local buffer = terminal.buffer
            local state_buffer = terminal.state_buffer
            local char_color = terminal.cursor_color
            local x,y,width,height = char_or_command.x, char_or_command.y, char_or_command.w, char_or_command.h

            local left, right = x, x + (width - 1)
            local top, bottom = y, y + (height - 1)
            terminal_update_character(terminal, left, top, utf8_sub(curStyle,1,1))
            terminal_update_character(terminal, right, top, utf8_sub(curStyle,2,2))
            terminal_update_character(terminal, left, bottom, utf8_sub(curStyle,3,3))
            terminal_update_character(terminal, right, bottom, utf8_sub(curStyle,4,4))


            local horizontal_char = utf8_sub(curStyle, 5, 5)
            local vertical_char = utf8_sub(curStyle, 6, 6)
            for i=left+1, right-1 do
                terminal_update_character(terminal, i, top, horizontal_char)
                terminal_update_character(terminal, i, bottom, horizontal_char)
            end
            for i=top+1, bottom-1 do
                terminal_update_character(terminal, left, i, vertical_char)
                terminal_update_character(terminal, right, i, vertical_char)
            end
        elseif char_or_command.type == "frame_shadow" then
            local curStyle = styles[char_or_command.style]
            if not curStyle then
                assert(false, string.format("Unrecognized style %s", char_or_command.style))
            end

            local buffer = terminal.buffer
            local state_buffer = terminal.state_buffer
            local char_color= terminal.cursor_color
            local x,y,width,height = char_or_command.x, char_or_command.y, char_or_command.w, char_or_command.h

            local left, right = x, x + (width - 1)
            local top, bottom = y, y + (height - 1)

            local horizontal_char = utf8_sub(curStyle, 5, 5)
            local vertical_char = utf8_sub(curStyle, 6, 6)

            local lg, sh = char_or_command.light, char_or_command.shadow
            local lastCursorColor = terminal.cursor_color

            terminal.cursor_color = basic_scheme[lg]
            terminal_update_character(terminal, left, top, utf8_sub(curStyle, 1, 1))
            for i = left + 1, right - 1, 1 do
                terminal_update_character(terminal, i, top, horizontal_char)
            end
            for i = top + 1, bottom - 1, 1 do
                terminal_update_character(terminal, left, i, vertical_char)
            end
            terminal_update_character(terminal, left, bottom, utf8_sub(curStyle, 3, 3))

            terminal.cursor_color = basic_scheme[sh]
            terminal_update_character(terminal, right, top, utf8_sub(curStyle, 2, 2))
            for i = left + 1, right - 1, 1 do
                terminal_update_character(terminal, i, bottom, horizontal_char)
            end
            for i = top + 1, bottom - 1, 1 do
                terminal_update_character(terminal, right, i, vertical_char)
            end
            terminal_update_character(terminal, right, bottom, utf8_sub(curStyle, 4, 4))

            terminal.cursor_color = lastCursorColor
        else
            assert(false, "Unrecognized command", char_or_command.type)
        end
    end
    terminal.accumulator = frame_budget
    local rest = {}
    for i=stdin_index,#terminal.stdin do
        table.insert(rest, terminal.stdin[i])
    end
    terminal.stdin = rest
end

local function terminal_draw(terminal)
    local char_width, char_height = terminal.char_width, terminal.char_height
    if terminal.dirty then
        local previous_color = {love.graphics.getColor()}
        local previous_canvas = love.graphics.getCanvas()

        love.graphics.push()
        love.graphics.origin()

        love.graphics.setCanvas(terminal.canvas)
        --love.graphics.clear()
        --love.graphics.setFont(terminal.font)
        local font_height = terminal.font:getHeight()
        for y,row in ipairs(terminal.buffer) do
            for x,char in ipairs(row) do
                local state = terminal.state_buffer[y][x]
                if state.dirty then
                    local left, top = (x-1)*char_width, (y-1)*char_height
                    -- Character background
                    if state.reversed then
                        love.graphics.setColor(unpack(state.color))
                    else
                        love.graphics.setColor(unpack(state.backcolor))
                    end
                    love.graphics.rectangle("fill", left, top + (font_height - char_height), terminal.char_width, terminal.char_height)

                    -- Character
                    if state.reversed then
                        love.graphics.setColor(unpack(state.backcolor))
                    else
                        love.graphics.setColor(unpack(state.color))
                    end
                    love.graphics.print(char, terminal.font, left, top)
                    state.dirty = false
                end
            end
        end
        terminal.dirty = false
        love.graphics.pop()

        love.graphics.setCanvas(previous_canvas)
        love.graphics.setColor(unpack(previous_color))
    end

    love.graphics.draw(terminal.canvas)
    if terminal.show_cursor then
        --love.graphics.setFont(terminal.font)
        if love.timer.getTime()%1 > 0.5 then
            love.graphics.print("_", terminal.font, (terminal.cursor_x-1) * char_width, (terminal.cursor_y -1) * char_height)
        end
    end
end

local function terminal_print(terminal, x, y, ...)
    local res_string = nil

    -- argument processing
    -- shortcut : no coordinates => print at cursor position
    if type(x) == "string" then
        res_string = x
    else
        terminal:setCursorPosition(x, y)
        res_string = string.format(...)
    end

    for i,p in utf8.codes(res_string) do
        table.insert(terminal.stdin, utf8.char(p))
    end
end

local function terminal_blit(terminal, x, y, str)
    for line in str:gmatch("[^\r\n]+") do
        terminal_print(terminal, x, y, "%s", line)
        y = y + 1
    end
end



local function terminalPrintf(terminal, _str, _x, _y, _char, _width, _align)
    assert(type(_str) == "string", "Invalid parameter type, expected 'string'. receive: " .. type(_str))
    assert(type(_width) == "number", "Invalid parameter type, expected 'string'. receive: " .. type(_width))

    
    _x = _x or 1
    _y = _y or 1
    _char = _char or " "
    _align = _align or "left"
    --_limit = _limit or terminal.width

    --_just(_str, _width - _x, _char, _align)

    
end

local function blitSprite(terminal, _filename, _x, _y)
    -- do parsing shit --
    local fd = love.filesystem.read(_filename)
    local lines = string.split(fd, "&")
    local sprite = {}

    for _, line in ipairs(lines) do
        local props = string.split(line, ":")
        
        -- treat the response --
        local colorStrRaw, posStr, char = props[1]:gsub("[%[%]]", ""), props[2]:gsub("[{}]", ""), props[3]

        local colorStr = string.split(colorStrRaw, ";")
        local color = {tonumber(colorStr[1]), tonumber(colorStr[2]), tonumber(colorStr[3])}
        local posRaw = string.split(posStr, ";")
        local pos = {tonumber(posRaw[1]), tonumber(posRaw[2])}

        table.insert(sprite, {
            color = color,
            pos = pos,
            char = char
        })
    end

    for _, pixel in ipairs(sprite) do
        if pixel.char ~= "*" then

            if pixel.char == " " then
                terminal_set_cursor_backcolor(terminal, pixel.color)
            else
                terminal_set_cursor_backcolor(terminal, {0, 0, 0, 1})
                terminal_set_cursor_color(terminal, pixel.color)
            end

            terminal_print(terminal, _x + pixel.pos[1], _y + pixel.pos[2], pixel.char)
        end
    end

    terminal_set_cursor_backcolor(terminal, {0, 0, 0, 1})
    terminal_set_cursor_color(terminal, {1, 1, 1, 1})
end


local function terminal_save_position(terminal)
    table.insert(terminal.stdin, {type="save"})

end

local function terminal_load_position(terminal)
    table.insert(terminal.stdin, {type="load"})
end


local function terminal (self, width, height, font, custom_char_width, custom_char_height)
    local char_width = custom_char_width or font:getWidth('█')
    local char_height = custom_char_height or font:getHeight()
    local num_columns = math.floor(width/char_width)
    local num_rows = math.floor(height/char_height)
    local instance = {
        width = math.floor(num_columns),
        height = math.floor(num_rows),
        font = font,

        show_cursor = true,
        cursor_x = 1,
        cursor_y = 1,
        saved_cursor_x = 1,
        saved_cursor_y = 1,
        cursor_color = {1,1,1,1},
        cursor_backcolor = {0,0,0,1},
        cursor_reversed = false,

        dirty = false,
        char_width = char_width,
        char_height = char_height,

        speed = 800,
        char_cost = 1,
        accumulator = 0,
        stdin = {},

        clear_color = {0,0,0},

        canvas = love.graphics.newCanvas(width, height),
        buffer = {},
        state_buffer = {}
    }

    for i = 1,num_rows, 1 do
        local row = {}
        local state_row = {}
        for j=1,num_columns do
            row[j] = ' '
            state_row[j] = {
                color = {1,1,1,1},
                backcolor = {0,0,0,1},
                dirty = true
            }
        end
        instance.buffer[i] = row
        instance.state_buffer[i] = state_row
    end

    instance.update = update
    instance.draw = terminal_draw
    instance.print = terminal_print
    instance.blit = terminal_blit
    instance.clear = terminal_clear
    instance.savePosition = terminal_save_position
    instance.loadPosition = terminal_load_position
    instance.setCursorPosition = terminal_move_to
    instance.hideCursor = terminal_hide_cursor
    instance.showCursor = terminal_show_cursor
    instance.reverseCursor = terminal_reverse
    instance.setCursorColor = terminal_set_cursor_color
    instance.setCursorBackColor = terminal_set_cursor_backcolor
    instance.rollUp = terminal_roll_up
    instance.getCursorColor = terminal_get_cursor_color
    instance.blitSprite = blitSprite

    instance.getTerminalState = getTerminalState
    instance.applyTerminalState = applyTerminalState

    instance.frameShadow = terminal_frame_shadow
    instance.frame = terminal_frame
    instance.fill = terminal_fill

    instance.schemes = {
        basic = basic_scheme
    }

    local previous_canvas = love.graphics.getCanvas()
    love.graphics.setCanvas(instance.canvas)
    love.graphics.clear(instance.clear_color)
    love.graphics.setCanvas(previous_canvas)

    return instance
end

local module = {
    _VERSION = 'lv-100 v0.0.2',
    _DESCRIPTION = "A simple terminal-like emulator for Love2D",
    _URL = "https://github.com/Eiyeron/LV-100",
    _LICENCE = [[
MIT License

Copyright (c) 2018-2024 Florian Dormont, Gabriela Schultz

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]],
    terminal = terminal,
    schemes = {
        basic = basic_scheme
    }
}
setmetatable(module, {__call = module.terminal})

return module