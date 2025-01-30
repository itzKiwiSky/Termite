local utf8 = require 'utf8'

-- origin: Lume by rxi
local function clearTable(t)
    local function lpiter(x)
        if type(x) == "table" and x[1] ~= nil then
            return ipairs
        elseif type(x) == "table" then
            return pairs
        end
    end

    local curIter = lpiter(t)
    for k in curIter(t) do
        t[k] = nil
    end

    return t
end

-- used internally for better assert --
local function assertType(val, typestr)
    assert(type(val) ==  tostring(typestr), string.format("[TermiteError] : Invalid argument type. Expected '%s', got '%s'", tostring(typestr), type(val)))
end

-- used internally for better error messages --
local function listStyle(styletable)
    local tbl = {}
    for k, v in pairs(styletable) do
        table.insert(tbl, tostring(k))
    end
    return tbl
end

-- Origin lv100 by Eiyeron, OG Origin of this snippet : https://stackoverflow.com/a/43139063
local function utf8Sub(s, i, j)
    i = utf8.offset(s, i)
    j = utf8.offset(s, j + 1) - 1
    return string.sub(s, i, j)
end

local function updateStdinChar(this, x, y, newChar)
    this.buffer[y][x] = newChar
    local charColor = this.cursorColor
    local charBackColor = this.cursorBackColor

    this.stateBuffer[y][x].color = {charColor[1], charColor[2], charColor[3], charColor[4]}
    this.stateBuffer[y][x].backcolor = {charBackColor[1], charBackColor[2], charBackColor[3], charBackColor[4]}
    this.stateBuffer[y][x].reversed = this.cursorReversed
    this.stateBuffer[y][x].dirty = true
end

local function redrawState(this)
    -- force a total redraw of the screen --
    for y = 1, this.height, 1 do
        for x = 1, this.width, 1 do
            this.stateBuffer[y][x].dirty = true
        end
    end
end

-- if the cursor is on the max height of terminal, take a snapshot of the terminal and move all data up --
local function rollup(this, lines)
    local row = #this.buffer
    local col = #this.buffer[1]
    local lines = math.min(lines, row - 1)

    for r = 1, row - 1, 1 do
        this.buffer[r] = this.buffer[r + lines]
    end

    for r = row - lines + 1, row, 1 do
        this.buffer[r] = {}
        for c = 1, col, 1 do
            this.buffer[r][c] = " "
        end

        redrawState(this)
    end
end

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

function Termite.new(width, height, font, customCharW, customCharH, options)
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

    self.stateStack = {}        -- save snapshots of the terminal state --
    self.stateStackIndex = #self.stateStack

    self.clear = {0, 0, 0}

    self.useInterrupt = false
    self.interruptKey = "return"
    self.isInterrupted = false

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
        ["block"] = "█",
        ["semigrid"] = "▓",
        ["halfgrid"] = "▒",
        ["grid"] = "░"
    }

    -- this interface is also exposed to edit --
    -- to easily integrate new commands --
    self.commands = {
        ["clear"] = function(self, x, y, w, h)
            assertType(x, "number")
            assertType(y, "number")
            assertType(w, "number")
            assertType(h, "number")

            for y = y, (y + h) - 1 do
                for x = x, (x + w) - 1 do
                    updateStdinChar(self, x, y, " ")
                    self.buffer[y][x] = " "
                end
            end
        end,
        ["fill"] = function(self, stylename, x, y, w, h)
            assertType(stylename, "string")
            assertType(x, "number")
            assertType(y, "number")
            assertType(w, "number")
            assertType(h, "number")

            local fillStylesNames = listStyle(self.fillStyles)
            assert(self.fillStyles[stylename], ("[TermiteError] : Invalid style '%s'. expected styles: %s"):format(stylename, table.concat(fillStylesNames, ", ")))

            local char = self.fillStyles[stylename]
            for y = y, (y + h) - 1 do
                for x = x, (x + w) - 1 do
                    updateStdinChar(self, x, y, char)
                    self.buffer[y][x] = char
                end
            end
        end,
        ["setCursorPos"] = function(self, x, y)
            assertType(x, "number")
            assertType(y, "number")

            self.cursorX, self.cursorY = x or 1, y or 1
        end,
        ["setCursorVisible"] = function(self, val)
            assertType(val, "boolean")

            self.cursorVisible = val
        end,
        ["reverseCursor"] = function(self, val)
            assertType(val, "boolean")
            
            self.cursorReversed = val
        end
    }

    -- for easy use, expose all commands as termite functions
    for fname, func in pairs(self.commands) do
        Termite[fname] = func
    end

    self.canvas:renderTo(function()
        love.graphics.clear(self.clear)
    end)

    if options then
        for k, p in pairs(self) do
            if options[k] then
                self[k] = options[k]
            end
        end
    end
    
    if self.useInterrupt then
        local ogkeypressed = love.keypressed

        love.keypressed = function(k, scancode, isrepeat)
            if k == self.interruptKey then
                self.isInterrupted = false
            end

            if ogkeypressed then
                ogkeypressed(k, scancode, isrepeat)
            end
        end
    end

    return self
end

--- Draw the terminal
function Termite:draw()
    local chWidth, chHeight = self.charWidth, self.charHeight
    if self.dirty then
        local prevColor = { love.graphics.getColor() }

        love.graphics.push()
        love.graphics.origin()

        self.canvas:renderTo(function()
            local fontHeight = self.font:getHeight()
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
                        love.graphics.rectangle("fill", left, top + (fontHeight - chHeight), self.charWidth, self.charHeight)

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
            self.dirty = false
            love.graphics.pop()
        end)

        love.graphics.setColor(unpack(prevColor))
    end

    love.graphics.draw(self.canvas)
    if self.cursorVisible then
        if love.timer.getTime() % 1 > 0.5 then
            love.graphics.print(self.cursorChar, self.font, (self.cursorX - 1) * chWidth, (self.cursorY -1) * chHeight)
        end
    end
end

--- UPdate the terminal engine
---@param elapsed number
function Termite:update(elapsed)
    if self.useInterrupt then
        if self.isInterrupted then
            return
        end
    end

    self.dirty = true
    if #self.stdin == 0 then return end
    local frameBudget = self.speed * elapsed + self.accumulator

    local stdIndex = 1
    while frameBudget > self.charCost do
        -- simulate the char incrementation in each iteration --
        local charCommand = self.stdin[stdIndex]
        if charCommand == nil then break end
        stdIndex = stdIndex + 1
        frameBudget = frameBudget - self.charCost

        -- detect special characters else execute the command --
        if type(charCommand) == "string" then
            if charCommand == '\b' then
                self.cursorX = math.max(self.cursorX - 1, 1)
            elseif charCommand == '\n' then
                self.cursorX = 1
                self.cursorY = self.cursorY + 1
                
                if self.cursorY > self.height then
                    rollup(self, self.cursorY - self.height)
                    self.cursorY = self.height
                    self.dirty = true
                end

                self.dirty = true
            else
                updateStdinChar(self, self.cursorX, self.cursorY, charCommand)
                self.cursorX = self.cursorX + 1
                if self.cursorX > self.width then
                    self.cursorX = 1
                    self.cursorY = self.cursorY + 1
                    if self.cursorY >= self.height then
                        rollup(self, self.cursorY - self.height)
                    end
                end
                self.dirty = true
            end
        else
            if self.commands[charCommand.command] then
                self.commands[charCommand.command](self, unpack(charCommand.args))
            else
                print(("[TermiteError] : Invalid command name, not found command named '%s'"):format(charCommand.command))
            end
        end
    end

    self.accumulator = frameBudget
    local rest = {}
    for i = stdIndex, #self.stdin do
        table.insert(rest, self.stdin[i])
    end
    self.stdin = rest

    if self.useInterrupt then
        self.isInterrupted = true
    end
end

function Termite:execute(command, ...)
    table.insert(self.stdin, { command = command, args = { ... } })
end

function Termite:puts(x, y, ...)
    local strData
    -- argument processing
    -- shortcut : no coordinates => print at cursor position
    if type(x) == "string" then
        strData = x
    else
        self.cursorX = x
        self.cursorY = y
        strData = string.format(...)
    end

    for i, p in utf8.codes(strData) do
        table.insert(self.stdin, utf8.char(p))
    end
end


--- put this function o love.keypressed --
function Termite:interrupt()
    
end


return Termite