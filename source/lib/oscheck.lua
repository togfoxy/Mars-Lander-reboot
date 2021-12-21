--[[ 
Checks OS of system
    Poops out variables:
        -- string OS
        -- boolean DESKTOP
        -- class PADDY
]]

-- Make variables global

OS = love.system.getOS()
DESKTOP = OS ~= "Android" and OS ~= "IOS"

if not DESKTOP then
    PADDY = Paddy:new()
    love.keyboard._isDown = love.keyboard.isDown
    love.keyboard.isDown = function(k)
        return PADDY:isDown(k)
    end
end

-- Why not
return OS