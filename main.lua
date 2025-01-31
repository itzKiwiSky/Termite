function love.load()
    terminal = require 'termite'
    moonshine = require 'assets.libraries.moonshine'
    require 'assets.StringTools'
    timer = require 'assets.libraries.timer'

    screen = moonshine(moonshine.effects.crt)
    --.chain(moonshine.effects.vignette)
    .chain(moonshine.effects.glow)

    screen.glow.min_luma = 0.2
    ctrframe = love.graphics.newImage("assets/perfect_crt_noframe.png")

    local termfont = love.graphics.newFont("assets/toshibasat.ttf", 24)

    term = terminal.new(love.graphics.getWidth(), love.graphics.getHeight() - termfont:getHeight(), termfont, nil, nil)
    term.speed = 5000

    love.keyboard.setKeyRepeat(true)

    demos = {}
    demonames = {
        "simple_print",
        "credits"
    }
    for d = 1, #demonames, 1 do
        demos[demonames[d]] = require("demo." .. demonames[d])
    end

    currentDemo = 0

    tmr_anim = timer.new()

    term:setCursorVisible(false)
    term:blit([[
      _______ ______ _____  __  __ _____ _______ ______ 
     |__   __|  ____|  __ \|  \/  |_   _|__   __|  ____|
        | |  | |__  | |__) | \  / | | |    | |  | |__   
        | |  |  __| |  _  /| |\/| | | |    | |  |  __|  
        | |  | |____| | \ \| |  | |_| |_   | |  | |____ 
        |_|  |______|_|  \_\_|  |_|_____|  |_|  |______|
    ]], 1, 2)

    term:frame("line", 1, 1, term.width, term.height)
    term:setCursorColor("brightCyan")
    term:print(2, 10, string.justify("A rewrite of a classic LV-100 terminal emulator", term.width - 4, " ", "center"))
    term:setCursorColor("brightGreen")
    term:print(2, 12, string.justify("by KiwiSky", term.width - 4, " ", "center"))
    term:setCursorColor("white")

    term:print(2, 17, string.justify("Now loading...", term.width - 4, " ", "center"))
    term:frame("line", 5, 18, term.width - 9, 3)

    term:setCursorBackColor("brightYellow")
    tmr_anim:script(function(sleep)
        sleep(0.3)
        local cx = 6
        while cx < term.width - 5 do
            term:print(cx, 19, " ")
            cx = cx + 1
            sleep(0.005)
        end

        term:setCursorBackColor("black")
        term:setCursorColor("white")
        term:clear(1, 1, term.width, term.height)

        currentDemo = 2
        demos[demonames[currentDemo]]()
        love.load()
    end)
end

function love.draw()
    screen(function()
        do
            local scale = 1
            local sx, sy = (love.graphics.getWidth() / term.canvas:getWidth()) * scale, (love.graphics.getHeight() / term.canvas:getHeight()) * scale
            love.graphics.push()
                love.graphics.translate((love.graphics.getWidth() * (1 - scale)) / 2, (love.graphics.getHeight() * (1 - scale)) / 2)
                love.graphics.scale(sx, sy)
                term:draw()
            love.graphics.pop()
        end
        love.graphics.setColor(0.3, 0, 0)
        --love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
    end)
    love.graphics.draw(ctrframe, 0, 0, 0, love.graphics.getWidth() / ctrframe:getWidth(), love.graphics.getHeight() / ctrframe:getHeight())
end

function love.update(elapsed)
    term:update(elapsed)
    if tmr_anim then
        tmr_anim:update(elapsed)
    end
end

function love.keypressed(k)
    if k == "return" then
        if currentDemo > 0 then
            print('das')
            currentDemo = (currentDemo < #demonames) and currentDemo + 1 or 1

            term:setCursorBackColor("black")
            term:setCursorColor("white")
            term:clear(1, 1, term.width, term.height)

            demos[demonames[currentDemo]]()
            love.load()
        end
    end
end