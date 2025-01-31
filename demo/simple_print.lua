return function()
    function love.load()
        term:print(4, 12, "Features")
        term:print(4, 14, "> Unicode support")
        term.speed = 50
        term:print(4, 15, "> Slow terminal emulation")
        term.speed = 5000
        term:print(4, 16, "> Helpers")
        term:print(4, 16, "> Settings (speed, dimensions, font, ...)")

        term:setCursorColor("brightBlack")
        term:print(4, 17, "> Partially compatible with LV-100 syntax")

        -- this thing should be done because the termite uses strings as colors for better usage --
        local names = {
            "black", "red", "green", "yellow", "blue", "magenta", "cyan", "white",
            "brightBlack", "brightRed", "brightGreen", "brightYellow",
            "brightBlue", "brightMagenta", "brightCyan", "brightWhite"
        }

        term:print(4, 20, "> ")
        local text_line = "2 colors per character !"
        for i = 1,#text_line do
            term:setCursorColor(names[(i % 8) + 1])
            term:setCursorBackColor(names[((i + 6) % 8) + 1])
            term:print(text_line:sub(i, i))
        end

        term:setCursorBackColor("black")
        term:setCursorColor("white")

        term:frame("line", 1, 1, term.width, term.height)
    end
end