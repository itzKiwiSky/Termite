function love.load()
    utf8 = require 'utf8'
    terminal = require 'termite'

    needTrigger = false
    canProceed = not needTrigger

    local termfont = love.graphics.newFont("phoenixbios.ttf", 18)

    term = terminal.new(love.graphics.getWidth(), love.graphics.getHeight() - termfont:getHeight(), termfont)
    term.speed = 500

    love.keyboard.setKeyRepeat(true)

    --term:execute("setcursorpos", { 20, 20 })


    for i = 1, 100, 1 do
        term:puts(string.format("hello world %s \n", i))
    end

    term:execute("clear", {x = 1, y = 1, w = 5, h = 5})
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
    if canProceed then
        term:update(elapsed)
        if needTrigger then
            canProceed = false
        end
    end
end

function love.keypressed(k)
    if k == "return" then
        canProceed = true
    end
    if k == "f1" then
        needTrigger = not needTrigger
    end
end