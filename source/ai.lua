local AI = {}

local currentAltitude
local currentIsOnBase
predictedx = 0   -- this is the lookahead ability
predictedy = 0   -- this is the lookahead ability
perfecty = 0     -- the y value that is just right
local currentDistanceToBase
local predictedYgroundValue  -- the ground y value at the predicted point
local toohigh
local toolow
local tooleft
local tooright
local tooslow
local toofast
local closestbase       -- object

local function GetCurrentState(lander)
    currentAltitude = Fun.getAltitude(lander)       -- distance above ground level
    currentIsOnBase = Lander.isOnLandingPad(lander, Enum.basetypeFuel)

    local lookahead = 120		-- how far to look ahead
    predictedx = lander.x + (lander.vx * lookahead) - WORLD_OFFSET
    predictedy = lander.y + (lander.vy * lookahead)
    predictedYgroundValue = GROUND[Cf.round(predictedx + WORLD_OFFSET,0)]

    -- negative value means not yet past the base
    currentDistanceToBase, closestbase = Fun.GetDistanceToFueledBase(predictedx + WORLD_OFFSET, Enum.basetypeFuel)

    perfecty = predictedYgroundValue - math.abs(currentDistanceToBase)

-- print(predictedYgroundValue, currentDistanceToBase, perfecty)

    perfectvx = currentDistanceToBase / -120        -- some constant that determines best vx

    if predictedy < perfecty then
        toohigh = true
        toolow = false
print("too high")
    else
        toohigh = false
        toolow = true
print("too low")
    end

    if currentDistanceToBase < 0 then
        tooleft = true
        tooright = false
    else
        tooleft = false
        tooright = true
    end

    if lander.vx < perfectvx then
        tooslow = true
        toofast = false
print("too slow")
    else
        tooslow = false
        toofast = true
print("too fast")
    end

print("~~~")

end

local function DetermineAction(lander, dt)

-- print(closestbase.totalFuel)
    if not currentIsOnBase or (math.abs(currentDistanceToBase) > 200) or (lander.fuel >= lander.fuelCapacity) then
        if toolow and tooslow then
            -- turn right
            lander.angle = lander.angle + (90 * dt)
            if lander.angle > 315 then lander.angle = 315 end
            Lander.doThrust(lander, dt)
        end
        if toolow and toofast then
            -- turn left
            lander.angle = lander.angle - (90 * dt)
            if lander.angle < 235 then lander.angle = 235 end
            Lander.doThrust(lander, dt)
        end
        if toohigh and toofast then
            -- turn left
            lander.angle = lander.angle - (90 * dt)
            if lander.angle < 180 then lander.angle = 180 end

            if lander.angle < 215 then
                Lander.doThrust(lander, dt)
            end
        end
    else

    end
end

local function SetAction()

end

function AI.update(lander, dt)

    if Fun.CurrentScreenName() == "World" then
        GetCurrentState(lander)
        DetermineAction(lander, dt)
        SetAction()
    end
end



return AI
