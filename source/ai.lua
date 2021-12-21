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

local function GetCurrentState(lander)
    currentAltitude = Fun.getAltitude(lander)       -- distance above ground level
    currentIsOnBase = Lander.isOnLandingPad(lander, Enum.basetypeFuel)

    local lookahead = 60		-- how far to look ahead
    predictedx = lander.x + (lander.vx * lookahead) - WORLD_OFFSET
    predictedy = lander.y + (lander.vy * lookahead)
    predictedYgroundValue = GROUND[Cf.round(predictedx + WORLD_OFFSET,0)]

    -- negative value means not yet past the base
    currentDistanceToBase, _ = Fun.GetDistanceToClosestBase(predictedx, Enum.basetypeFuel)

    perfecty = predictedYgroundValue + currentDistanceToBase
    perfectvx = currentDistanceToBase / -120        -- some constant that determines best vx

    if predictedy < perfecty then
        toohigh = true
        toolow = false
print("trajectory too high")
    else
        toohigh = false
        toolow = true
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
    else
        tooslow = false
        toofast = true
    end

end

local function DetermineAction(lander, dt)

    if not currentIsOnBase then
        if toolow then
            Lander.doThrust(lander, dt)
        end
        if toofast then -- turn left
            lander.angle = lander.angle - (90 * dt)
            if lander.angle < 225 then lander.angle = 225 end
            if lander.angle < 0 then lander.angle = 360 end
            Lander.doThrust(lander, dt)
        end
        if tooslow then
            lander.angle = lander.angle + (90 * dt)
            if lander.angle > 315 then lander.angle = 315 end
        	if lander.angle > 360 then lander.angle = 0 end
        end
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
