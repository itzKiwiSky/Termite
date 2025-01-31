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
    --print("adhsajdahjda")
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
    self.cursorColor = {1, 1, 1}
    self.cursorBackColor = {0, 0, 0}
    self.cursorReversed = false
    self.dirty = false      -- if char on the terminal is 'dirty' means that the terminal engine will render again the char
    
    self.charWidth = charWidth
    self.charHeight = charHeight

    self.charCost = 1
    self.accumulator = 0
    self.stdin = {}     -- used to store the terminal commands --

    self.stateStack = {}        -- save snapshots of the terminal state --
    self.stateStackIndex = #self.stateStack
    self.currentScheme = "basic"

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
                color = self.cursorColor,
                backcolor = self.cursorBackColor,
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

    -- exposing these interfaces to easily integrate new color schemes without modifying the original script --
    self.schemes = {
        basic = {
            ["black"]   = {0, 0, 0},
            ["red"]     = {0.5, 0, 0},
            ["green"]   = {0, 0.5, 0},
            ["yellow"]  = {0.5, 0.5, 0},
            ["blue"]    = {0, 0, 0.5},
            ["magenta"] = {0.5, 0, 0.5},
            ["cyan"]    = {0, 0.5, 0.5},
            ["white"]   = {0.75, 0.75, 0.75},
            ["brightBlack"]   = {0.5, 0.5, 0.5},
            ["brightRed"]     = {1, 0, 0},
            ["brightGreen"]   = {0, 1, 0},
            ["brightYellow"]  = {1, 1, 0},
            ["brightBlue"]    = {0, 0, 1},
            ["brightMagenta"] = {1, 0, 1},
            ["brightCyan"]    = {0, 1, 1},
            ["brightWhite"]   = {1, 1, 1}
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

            -- check terminal bounds --
            if x < 1 or y < 1 or x + w - 1 > self.width or y + h - 1 > self.height then
                return
            end

            for y = y, y + h - 1 do
                for x = x, x + w - 1 do
                    updateStdinChar(self, x, y, " ")
                    self.buffer[y][x] = " "
                end
            end

            --self.dirty = true
            --redrawState(self)
        end,
        ["fill"] = function(self, stylename, x, y, w, h)
            assertType(stylename, "string")
            assertType(x, "number")
            assertType(y, "number")
            assertType(w, "number")
            assertType(h, "number")

            -- check terminal bounds --
            if x < 1 or y < 1 or x + w - 1 > self.width or y + h - 1 > self.height then
                return
            end

            local fillStylesNames = listStyle(self.fillStyles)
            assert(self.fillStyles[stylename] ~= nil, ("[TermiteError] : Invalid style '%s'. expected styles: %s"):format(stylename, table.concat(fillStylesNames, ", ")))

            local char = self.fillStyles[stylename]
            for y = y, (y + h) - 1 do
                for x = x, (x + w) - 1 do
                    --updateStdinChar(self, x, y, char)
                    self.buffer[y][x] = char
                end
            end
        end,
        ["setCursorPos"] = function(self, x, y)
            assertType(x, "number")
            assertType(y, "number")

            -- check if value is place out of bounds --
            if x < 1 or y < 1 or x > self.width or y > self.height then
                return
            end

            self.cursorX, self.cursorY = x or 1, y or 1
        end,
        ["setCursorVisible"] = function(self, val)
            assertType(val, "boolean")

            self.cursorVisible = val
        end,
        ["reverseCursor"] = function(self, val)
            assertType(val, "boolean")
            
            self.cursorReversed = val
        end,
        ["frame"] = function(self, stylename, x, y, w, h)
            assertType(stylename, "string")
            assertType(x, "number")
            assertType(y, "number")
            assertType(w, "number")
            assertType(h, "number")

            -- check terminal bounds --
            if x < 1 or y < 1 or x + w - 1 > self.width or y + h - 1 > self.height then
                return
            end

            local fillStylesNames = listStyle(self.frameStyles)
            assert(self.frameStyles[stylename] ~= nil, ("[TermiteError] : Invalid style '%s'. expected styles: %s"):format(stylename, table.concat(fillStylesNames, ", ")))

            local left, right = x, x + (w - 1)
            local top, bottom = y, y + (h - 1)
            local charStyle = self.frameStyles[stylename]

            -- corners --
            updateStdinChar(self, left, top, utf8Sub(charStyle, 1, 1))
            updateStdinChar(self, right, top, utf8Sub(charStyle, 2, 2))
            updateStdinChar(self, left, bottom, utf8Sub(charStyle, 3, 3))
            updateStdinChar(self, right, bottom, utf8Sub(charStyle, 4, 4))

            -- faces --
            local lineHorizontal = utf8Sub(charStyle, 5, 5)
            local lineVertical = utf8Sub(charStyle, 6, 6)
            for i = left + 1, right - 1, 1 do
                updateStdinChar(self, i, top, lineHorizontal)
                updateStdinChar(self, i, bottom, lineHorizontal)
            end
            for i = top + 1, bottom - 1, 1 do
                updateStdinChar(self, left, i, lineVertical)
                updateStdinChar(self, right, i, lineVertical)
            end
        end,
        ["setCursorColor"] = function(self, colorName)
            assertType(colorName, "string")
            assert(self.schemes[self.currentScheme][colorName], ("[TermiteError] : Invalid color, can't found color named: %s"):format(colorName))
            local color = self.schemes[self.currentScheme][colorName]

            self.cursorColor[1] = color[1]
            self.cursorColor[2] = color[2]
            self.cursorColor[3] = color[3]
            self.cursorColor[4] = color[4] or 1
        end,
        ["setCursorBackColor"] = function(self, colorName)
            assertType(colorName, "string")
            assert(self.schemes[self.currentScheme][colorName], ("[TermiteError] : Invalid color, can't found color named: %s"):format(colorName))
            local color = self.schemes[self.currentScheme][colorName]

            self.cursorBackColor[1] = color[1]
            self.cursorBackColor[2] = color[2]
            self.cursorBackColor[3] = color[3]
            self.cursorBackColor[4] = color[4] or 1
        end,
    }

    -- for easy use, expose all commands as termite functions
    for command, fdata in pairs(self.commands) do
        Termite[command] = function(...)
            --self:execute(fname, ...)
            local args = { ... }
            --table.insert(args, 1, self)
            table.insert(self.stdin, { command = command, args = args })
        end
    end

    self.canvas:renderTo(function()
        love.graphics.clear({0, 0, 0})
    end)

    if options then
        for k, p in pairs(self) do
            if options[k] and type(self[k]) ~= "function" then
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

        self.canvas:renderTo(function()
            love.graphics.push("all")
            love.graphics.origin()

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

--- Update the terminal engine
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
                    self.cursorY = self.height
                    rollup(self, self.cursorY - self.height)
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
                self.commands[charCommand.command](unpack(charCommand.args))
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
    assertType(command, "string")
    table.insert(self.stdin, { command = command, args = { self, ... } })
end

function Termite:print(x, y, ...)
    local text

    if type(x) == "string" then
        text = x
    else
        self:execute("setCursorPos", x, y)
        text = string.format(...)
    end

    for i, p in utf8.codes(text) do
        table.insert(self.stdin, utf8.char(p))
    end
end

function Termite:blit(text, x, y)
    for line in text:gmatch("[^\r\n]+") do
        --local t = ("%s\n"):format(line)
        self:print(x, y, "%s", line)
        y = y + 1
    end
end

return Termite