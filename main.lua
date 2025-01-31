function love.load()
    utf8 = require 'utf8'
    terminal = require 'termite'
    inspect = require 'inspect'

    local termfont = love.graphics.newFont("phoenixbios.ttf", 18)

    term = terminal.new(love.graphics.getWidth(), love.graphics.getHeight() - termfont:getHeight(), termfont, nil, nil, {
    useInterrupt = true
    })
    term.speed = 50


    love.keyboard.setKeyRepeat(true)

    --[[
    for i = 1, 1000, 1 do
        term:puts(string.format("hello world %s \n", i))
    end
    ]]--
    
    --print(term.width, term.height)
    term:setCursorBackColor("brightCyan")
    term:setCursorColor("black")
    term:clear(4, 4, term.width - 8, term.height - 8)
    term:puts("Termite terminal emulator", 10, 6)
end

function love.draw()
    do
        local scale = 1
        local sx, sy = (love.graphics.getWidth() / term.canvas:getWidth()) * scale, (love.graphics.getHeight() / term.canvas:getHeight()) * scale
        love.graphics.push()
            love.graphics.translate((love.graphics.getWidth() * (1 - scale)) / 2, (love.graphics.getHeight() * (1 - scale)) / 2)
            love.graphics.scale(sx, sy)
            term:draw()
        love.graphics.pop()
    end
    --love.graphics.draw(ctrframe, 0, 0, 0, love.graphics.getWidth() / ctrframe:getWidth(), love.graphics.getHeight() / ctrframe:getHeight())
end

function love.update(elapsed)
    term:update(elapsed)
end

