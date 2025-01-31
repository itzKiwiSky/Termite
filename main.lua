function love.load()
    terminal = require 'termite'
    local termfont = love.graphics.newFont("assets/phoenixbios.ttf", 18)

    term = terminal.new(love.graphics.getWidth(), love.graphics.getHeight() - termfont:getHeight(), termfont, nil, nil)
    term.speed = 500

    love.keyboard.setKeyRepeat(true)

    term:blit([[

::::::::::: :::::::::: :::::::::  ::::    ::::  ::::::::::: ::::::::::: :::::::::: 
    :+:     :+:        :+:    :+: +:+:+: :+:+:+     :+:         :+:     :+:        
    +:+     +:+        +:+    +:+ +:+ +:+:+ +:+     +:+         +:+     +:+        
    +#+     +#++:++#   +#++:++#:  +#+  +:+  +#+     +#+         +#+     +#++:++#   
    +#+     +#+        +#+    +#+ +#+       +#+     +#+         +#+     +#+        
    #+#     #+#        #+#    #+# #+#       #+#     #+#         #+#     #+#        
    ###     ########## ###    ### ###       ### ###########     ###     ########## 

    ]], 1, 2)
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

