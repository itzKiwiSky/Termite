return function()
    function love.load()
        local loremIpsumExample = [[
this is a long paragraph
Lorem ipsum dolor sit amet, consectetur adipiscing elit. In in velit accumsan, fermentum velit nec, pharetra turpis. 
Pellentesque dictum sagittis velit, sit amet facilisis justo. 
Phasellus sodales eleifend metus ac aliquam. Donec augue nibh, sollicitudin in lobortis non, imperdiet vel dolor. 
Curabitur nec lobortis lacus, sed ultrices purus. Maecenas eget lacus lectus. 
Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. 
Nullam tortor est, congue a blandit eget, lacinia ut ante. Etiam nec erat eu leo porttitor interdum. 
Suspendisse a leo a ante feugiat scelerisque. Etiam ultricies tincidunt ex, eget malesuada elit efficitur non. 
Vestibulum semper nisi ornare ex gravida, nec posuere augue semper. Fusce malesuada accumsan dui in auctor. 
Donec hendrerit nulla ac sapien porta feugiat a a ex. 
        ]]

        term:print(4, 5, "Features")
        term:print(4, 6, "> Unicode support")
        term.speed = 50
        term:print(4, 7, "> Slow terminal emulation")
        term.speed = 5000
        term:print(4, 8, "> Helpers")
        term:print(4, 9, "> Settings (speed, dimensions, font, ...)")

        term:setCursorColor("brightBlack")
        term:print(4, 10, "> Partially compatible with LV-100 syntax")
        term:setCursorColor("white")

        -- this thing should be done because the termite uses strings as colors for better usage --
        local names = {
            "black", "red", "green", "yellow", "blue", "magenta", "cyan", "white",
            "brightBlack", "brightRed", "brightGreen", "brightYellow",
            "brightBlue", "brightMagenta", "brightCyan", "brightWhite"
        }

        term:print(4, 11, "> ")
        local text_line = "2 colors per character !"
        for i = 1,#text_line do
            term:setCursorColor(names[(i % 8) + 1])
            term:setCursorBackColor(names[((i + 6) % 8) + 1])
            term:print(text_line:sub(i, i))
        end

        term:setCursorBackColor("black")
        term:setCursorColor("white")

        term:blit(loremIpsumExample, 2, 13)

        term:print(2, term.height - 6, string.justify("Press [ENTER] to go to next example", term.width - 4, " ", "center"))

        term:frame("line", 1, 1, term.width, term.height)
        term:print(3, 1, "Simple print")
    end
end