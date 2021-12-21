local aspect =
{
  _VERSION     =  1100,
  _URL         = "https://gist.github.com/Vovkiv/f234b4c9263d4642f87d48ce8db37be8",
  _DEMO        = "https://gist.github.com/Vovkiv/c1b3216a07ec642c017200d571a35cc8",
  _DESCRIPTION = "Can handle best fit scaling for games with specific resolution in Love2d using only scaling",
  _LICENSE     = "None",
  _NAME        = "Aspect Scaling",
}

aspect.scale = 0

aspect.gameWidth    = 800 -- size to which game should be scaled to
aspect.gameHeight   = 600
aspect.windowWidth  = 0 -- size of window, which can be used instead of love's love.graphics.getWidth()|Height()
aspect.windowHeight = 0

aspect.gameAspect   = 0 -- aspect of game, based on gameWidth / gameHeight; updates on every update()
aspect.windowAspect = 0 -- aspect of window, based on love.graphics.getWidth() / love.graphics.getHeight(); updates on every update()

aspect.xOff = 0 -- offset of black bars
aspect.yOff = 0

aspect.x1, aspect.y1, aspect.w1, aspect.h1 = 0, 0, 0, 0 -- data of black bars; if bars left-right then: 1 bar is left, 2 is right
aspect.x2, aspect.y2, aspect.w2, aspect.h2 = 0, 0, 0, 0 --                     if top-bottom then:      1 bar is upper, 2 is bottom

aspect.r, aspect.g, aspect.b, aspect.a = 0, 0, 0, 0 -- colors of black bars; red, green, blue, alpha

aspect.setColor = function(r, g, b, a) -- set color of black bars
  aspect.r = r
  aspect.g = g
  aspect.b = b
  aspect.a = a
end

aspect.getColor = function() -- return all color's of black bars; rgba
  return aspect.r, aspect.g, aspect.b, aspect.a
end

aspect.setGame = function(w, h) -- set virtual size which game should be scaled to
  aspect.gameWidth = w
  aspect.gameHeight = h
end

aspect.getGame = function() -- return game's virtual width and height
  return aspect.gameWidth, aspect.gameHeight
end

aspect.getWindow = function() -- get window's width and height
  return aspect.windowWidth, aspect.windowHeight
end

aspect.update = function()
    local x1, y1, w1, h1, x2, y2, w2, h2
    local scale
    local xOff, yOff
    local a_ -- used to decrease calculations

    local gameWidth, gameHeight = aspect.gameWidth, aspect.gameHeight
    local windowWidth, windowHeight = love.graphics.getWidth(), love.graphics.getHeight()

    local gameAspect = gameWidth / gameHeight
    local windowAspect = windowWidth / windowHeight

    if gameAspect > windowAspect then -- if window height > game height
        scale = windowWidth / gameWidth
        a_ = math.abs((gameHeight * scale - windowHeight) / 2)
        x1, y1, w1, h1 = 0, 0, windowWidth, a_
        x2, y2, w2, h2 = 0, windowHeight, windowWidth, -a_
        xOff, yOff = 0, windowHeight / 2 - (scale * gameHeight) / 2

    elseif gameAspect < windowAspect then -- if window width > game width
        scale = windowHeight / gameHeight
        a_ = math.abs((gameWidth * scale - windowWidth) / 2)
        x1, y1, w1, h1 = 0, 0, a_, windowHeight
        x2, y2, w2, h2 = windowWidth, 0, -a_, windowHeight
        xOff, yOff = windowWidth / 2 - (scale * gameWidth) / 2, 0

    else -- if window and game size equal
        scale = windowWidth / gameWidth
        x1, y1, w1, h1 = 0, 0, 0, 0
        x2, y2, w2, h2 = 0, 0, 0, 0
        xOff, yOff = 0, 0
    end

    aspect.x1, aspect.y1, aspect.w1, aspect.h1 = x1, y1, w1, h1
    aspect.x2, aspect.y2, aspect.w2, aspect.h2 = x2, y2, w2, h2
    aspect.xOff, aspect.yOff = xOff, yOff
    aspect.scale = scale
    aspect.windowWidth, aspect.windowHeight = windowWidth, windowHeight
    aspect.gameAspect, aspect.windowAspect = gameAspect, windowAspect
end

aspect.start = function()
    love.graphics.push()
    love.graphics.translate(aspect.xOff, aspect.yOff) -- create offset of graphics
    local scale = aspect.scale
    love.graphics.scale(scale, scale)
end

aspect.stop = function()
    love.graphics.pop()

    love.graphics.push("all") -- "all" used here to return original colors after stop function
    local r, g, b, a = aspect.r, aspect.g, aspect.b, aspect.a
    local x1, y1, w1, h1 = aspect.x1, aspect.y1, aspect.w1, aspect.h1
    local x2, y2, w2, h2 = aspect.x2, aspect.y2, aspect.w2, aspect.h2
    love.graphics.setColor(r, g, b, a)
    love.graphics.rectangle("fill", x1, y1, w1, h1)
    love.graphics.rectangle("fill", x2, y2, w2, h2)
    love.graphics.pop()
end

aspect.toGame = function(x, y) -- thanslate coordinates from non-scaled to scaled;
                               -- e.g translate real mouse coordinates into scaled area to check collisions
  return (x - aspect.xOff) / aspect.scale, (y - aspect.yOff) / aspect.scale
end

aspect.toGameX = function(x) -- shortcut to only x
  return (x - aspect.xOff) / aspect.scale
end

aspect.toGameY = function(y) -- shortcut to only y
  return (y - aspect.yOff) / aspect.scale
end

aspect.toScreen = function(x, y) -- thanslate coordinates from scaled to non scaled;
                                 -- e.g translate x and y of object inside scaled area
                                 -- to teleport cursor to that object
  return (x * aspect.scale) + aspect.xOff, (y * aspect.scale) + aspect.yOff
end

aspect.toScreenX = function(x) -- shortcut to only x
  return (x * aspect.scale) + aspect.xOff
end

aspect.toScreenY = function(y) -- shortcut to only y
  return (y * aspect.scale) + aspect.yOff
end

return aspect
