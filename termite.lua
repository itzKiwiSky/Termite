local utf8 = require 'utf8'

--- @class Termite
local Termite = {
    _NAME = "Termite",
    _VERSION = '0.0.1',
    _DESCRIPTION = "A rewrite of LV-100 terminal emulator for Love2D",
    _URL = "",
    _LICENCE = [[
        MIT License

        Copyright (c) 2025 Felicia Schultz

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
}

Termite.__index = Termite

-- Origin lv100 by Eiyeron, OG Origin of this snippet : https://stackoverflow.com/a/43139063
local function utf8Sub(s, i, j)
    i = utf8.offset(s, i)
    j = utf8.offset(s, j + 1) - 1
    return string.sub(s, i, j)
end

function Termite.new(width, height, font, customCharW, customCharH)
    local self = setmetatable({}, Termite)
    
    local charWidth = customCharW or font:getWidth('█')
    local charHeight = customCharH or font:getHeight()
    local numCols = math.floor(width / charWidth)
    local numRows = math.floor(height / charHeight)
    

    self.width = math.floor(numCols)
    self.height = math.floor(numRows)
    self.font = font

    self.cursorVisible = true
    self.cursorX = 1
    self.cursorY = 1
    self.savedCursorX = 1
    self.savedCursorY = 1
    self.cursorColor = {1, 1, 1, 1}
    self.cursorBackColor = {0, 0, 0, 1}
    self.cursorReversed = false
    self.dirty = false      -- if char on the terminal is 'dirty' means that the terminal engine will render again the char
    
    self.charWidth = charWidth
    self.charHeight = charHeight

    self.charCost = 1
    self.accumulator = 0
    self.stdin = {}     -- used to store the terminal commands --

    self.clear = {0, 0, 0}

    self.canvas = love.graphics.newCanvas(width, height)
    self.buffer = {}
    self.stateBuffer = {}

    for i = 1,numRows, 1 do
        local row = {}
        local stateRow = {}
        for j = 1, numCols do
            row[j] = ' '
            stateRow[j] = {
                color = {1, 1, 1, 1},
                backcolor = {0, 0, 0, 1},
                dirty = true
            }
        end
        self.buffer[i] = row
        self.stateBuffer[i] = stateRow
    end

    local styles = {
        ["line"] = "┌┐└┘─│",
        ["bold"] = "┏┓┗┛━┃",
        ["text"] = "++++-|",
        ["double"] = "╔╗╚╝═║",
        ["block"] = "██████"
    }

    -- expose some customization parameter --
    self.cursorChar = "_"
    self.speed = 800

    --self.print = terminal_print
    --self.blit = terminal_blit
    --self.clear = terminal_clear
    --self.savePosition = terminal_save_position
    --self.loadPosition = terminal_load_position
    --self.setCursorPosition = terminal_move_to
    --self.hideCursor = terminal_hide_cursor
    --self.showCursor = terminal_show_cursor
    --self.reverseCursor = terminal_reverse
    --self.setCursorColor = terminal_set_cursor_color
    --self.setCursorBackColor = terminal_set_cursor_backcolor
    --self.rollUp = terminal_roll_up
    --self.getCursorColor = terminal_get_cursor_color
    --self.blitSprite = blitSprite

    --self.getTerminalState = getTerminalState
    --self.applyTerminalState = applyTerminalState

    --self.frameShadow = terminal_frame_shadow
    --self.frame = terminal_frame
    --self.fill = terminal_fill

    -- exposing these interfaces to easily integrate new color schemes without modifying the original script --
    self.schemes = {
        basic = {
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
    }

    self.frameStyles = {
        ["line"] = "┌┐└┘─│",
        ["bold"] = "┏┓┗┛━┃",
        ["text"] = "++++-|",
        ["double"] = "╔╗╚╝═║",
        ["block"] = "██████"
    }

    self.fillStyles = {
        {
            ["blank"] = " ",
            ["block"] = "█",
            ["semigrid"] = "▓",
            ["halfgrid"] = "▒",
            ["grid"] = "░"
        }
    }

    -- this interface is also exposed to edit --
    -- to easily integrate new commands --
    self.commands = {
        ["clear"] = function()
            
        end
    }

    local prevCanvas = love.graphics.getCanvas()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(self.clear_color)
    love.graphics.setCanvas(prevCanvas)

    return self
end

--- @class Termite.draw
--- Draw the terminal to the screen
function Termite:draw()
    local chWidth, chHeight = self.charWidth, self.charHeight
    if terminal.dirty then
        local prevColor = { love.graphics.getColor() }
        local prevCanvas = love.graphics.getCanvas()

        love.graphics.push()
        love.graphics.origin()

        love.graphics.setCanvas(self.canvas)
            local font_height = self.font:getHeight()
            for y, row in ipairs(self.buffer) do
                for x, char in ipairs(row) do
                    local state = self.stateBuffer[y][x]
                    if state.dirty then
                        local left, top = (x - 1) * chWidth, (y - 1) * chHeight
                        -- Character background
                        if state.reversed then
                            love.graphics.setColor(unpack(state.color))
                        else
                            love.graphics.setColor(unpack(state.backcolor))
                        end
                        love.graphics.rectangle("fill", left, top + (font_height - chHeight), self.charWidth, self.charHeight)

                        -- Character
                        if state.reversed then
                            love.graphics.setColor(unpack(state.backcolor))
                        else
                            love.graphics.setColor(unpack(state.color))
                        end
                        love.graphics.print(char, self.font, left, top)
                        state.dirty = false
                    end
                end
            end
            terminal.dirty = false
            love.graphics.pop()
        love.graphics.setCanvas(prevCanvas)

        love.graphics.setColor(unpack(prevColor))
    end

    love.graphics.draw(self.canvas)
    if self.cursorVisible then
        if love.timer.getTime() % 1 > 0.5 then
            love.graphics.print(self.cursorChar, self.font, (self.cursorX - 1) * chWidth, (self.cursorY -1) * chHeight)
        end
    end
end

function Termite:update(elapsed)
    
end

return Termite