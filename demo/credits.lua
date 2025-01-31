return function()
    function love.load()
        term:setCursorVisible(false)
        term:blit([[
          _______ ______ _____  __  __ _____ _______ ______ 
         |__   __|  ____|  __ \|  \/  |_   _|__   __|  ____|
            | |  | |__  | |__) | \  / | | |    | |  | |__   
            | |  |  __| |  _  /| |\/| | | |    | |  |  __|  
            | |  | |____| | \ \| |  | |_| |_   | |  | |____ 
            |_|  |______|_|  \_\_|  |_|_____|  |_|  |______|
        ]], 1, 2)

        term:setCursorColor("brightCyan")
        term:print(2, 10, string.justify("A rewrite of a classic LV-100 terminal emulator", term.width - 4, " ", "center"))
        term:setCursorColor("brightGreen")
        term:print(2, 12, string.justify("by KiwiSky", term.width - 4, " ", "center"))
        term:setCursorColor("white")

        term:frame("line", 4, 14, term.width - 6, 20)
        term:print(6, 14, "libraries and assets")

        term:setCursorColor("brightCyan")
        term:print(6, 16, "LV-100 by Eiyeron")

        term:setCursorColor("magenta")
        term:print(6, 18, "Moonshine shader lib by vlrd")

        term:setCursorColor("green")
        term:print(6, 20, "int10h.org for toshibasat 8x14 font")

        term:setCursorColor("brightMagenta")
        term:blit([[
  ████  ████  
██▒▒▒▒██▒▒▒▒██
██▒▒▒▒▒▒▒▒▒▒██
██▒▒▒▒▒▒▒▒▒▒██
  ██▒▒▒▒▒▒██  
    ██▒▒██    
      ██      
        ]], 50, 16)

        term:frame("line", 1, 1, term.width, term.height)
        term:print(3, 1, "Credits and attribuitions")
    end
end