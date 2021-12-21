local AI = {}

local currentAltitude
local currentIsOnBase
local predictedx    -- this is the lookahead ability
local predictedy    -- this is the lookahead ability

local function GetCurrentState(lander)
    currentAltitude = Fun.getAltitude(lander)
    currentIsOnBase = Lander.isOnLandingPad(lander, Enum.basetypeFuel)

    local lookahead = 60		-- how far to look ahead
    predictedx = lander.x + (lander.vx * lookahead) - WORLD_OFFSET
    predictedy = lander.y + (lander.vy * lookahead)


end

local function DetermineAction()

end

local function SetAction()

end

function AI.update(lander, dt)

    GetCurrentState(lander)
    DetermineAction()
    SetAction()


end



return AI
