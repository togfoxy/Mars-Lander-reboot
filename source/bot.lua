local Bot = {}

-- high score = 23,650

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
local closestbase       	-- object
local lookahead = 240		-- how far to look ahead

function Bot.GetDistanceToFueledBase(uuid,xvalue, intBaseType)
	-- uuid is the lander ID. This is needed as each lander has their own instance of fuel bases
	-- returns two values: the distance to the closest base with fuel, and the object/table item for that base
	-- note: if distance is a negative value then the Lander has not yet passed the base
	local closestdistance = -1
	local closestbase = {}
	local absdist
	local dist
	local realdist

	for k,v in pairs(OBJECTS) do
		if v.objecttype == intBaseType then
			if v.fuelLeft[uuid] == nil or v.fuelLeft[uuid] > 1 then
				-- the + bit is an offset to calculate the landing pad and not the image
				absdist = math.abs(xvalue - (v.x + 85))
				-- same but without the math.abs)
				dist = (xvalue - (v.x + 85))
				if closestdistance == -1 or absdist <= closestdistance then
					closestdistance = absdist
					closestbase = v
				end
			end
		end
	end

	-- now we have the closest base, work out the distance to the landing pad for that base
	if closestbase.x ~= nil then
		-- the + bit is an offset to calculate the landing pad and not the image
		realdist = xvalue - (closestbase.x + 85)
	end

	return realdist, closestbase
end

local function GetCurrentState(lander)
    currentAltitude = Fun.getAltitude(lander)       -- distance above ground level
    currentIsOnBase = Lander.isOnLandingPad(lander, Enum.basetypeFuel)

	-- predictedx is the x value the lander is predicted to be at based on current trajectory
	-- predictedy is the y value the lander is predicted to be at based on current trajectory
	-- predictedYgroundValue is the y value for the terrain when looking ahead
    predictedx = lander.x + (lander.vx * lookahead)
    -- negative value means not yet past the base
    currentDistanceToBase, closestbase = Bot.GetDistanceToFueledBase(lander.uuid, predictedx, Enum.basetypeFuel)
    -- searching for a base can outstrip the terrain so guard against that.
    while closestbase.x == nil or predictedx > #GROUND do
        Terrain.generate(SCREEN_WIDTH * 4)
        currentDistanceToBase, closestbase = Bot.GetDistanceToFueledBase(lander.uuid, predictedx, Enum.basetypeFuel)
print("Adding more terrain")
    end

	-- ensure this block is below the above WHILE loop
    predictedy = lander.y + (lander.vy * lookahead)
    predictedYgroundValue = GROUND[Cf.round(predictedx,0)]	

    if predictedYgroundValue == nil then
        print(#GROUND, predictedx, predictedy, predictedYgroundValue)
        error("oops - check the console for debug info")
    end

    -- ensure this is after the terrain.generate
    -- look far ahead for long distances
    if math.abs(currentDistanceToBase) > 2000 then
        lookahead = 240
    else
        lookahead = 120
    end

    -- the perfecty value is a 45 degree angle from the base to the sky
    perfecty = predictedYgroundValue - math.abs(currentDistanceToBase)
    if perfecty < SCREEN_HEIGHT / 3 then perfecty = SCREEN_HEIGHT / 3 end

    perfectvx = currentDistanceToBase / -120        -- some constant that determines best vx

    if predictedy < perfecty then
        toohigh = true
        toolow = false
--print("too high")
    else
        toohigh = false
        toolow = true
--print("too low")
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
--print("too slow")
    else
        tooslow = false
        toofast = true
--print("too fast")
    end

--print("~~~")

end

function Bot.turnTowardsAngle(lander, angle, dt)
    -- given an angle, turn left or right to meet it
    if lander.angle < angle then
        -- turn right/clockwise
        lander.angle = lander.angle + (90 * dt)
        if lander.angle > angle then lander.angle = angle end

    elseif lander.angle > angle then
        -- turn left/anti-clockwise
        lander.angle = lander.angle - (90 * dt)
        if lander.angle < angle then lander.angle = angle end
    else
        -- on target. Do nothing
    end

end

local function DetermineAction(lander, dt)

    local takeaction = false
    local abscurrentDistanceToBase = (math.abs(currentDistanceToBase))

    -- if not on base
    if not currentIsOnBase then takeaction = true end
    -- if tank is full
    if lander.fuel >= lander.fuelCapacity then takeaction = true end
    -- if not near a base
    if abscurrentDistanceToBase > 200 then takeaction = true end

    if takeaction then
        if toolow and tooslow then
            -- turn to 315
            Bot.turnTowardsAngle(lander, 315, dt)
            Lander.doThrust(lander, dt)
        elseif toolow and toofast then
            -- turn to 235
            Bot.turnTowardsAngle(lander, 235, dt)
            Lander.doThrust(lander, dt)
        elseif toohigh and toofast then
            -- turn left
            Bot.turnTowardsAngle(lander, 180, dt)
            if lander.angle < 215 then
                Lander.doThrust(lander, dt)
            end
        elseif toohigh and tooslow then
            Bot.turnTowardsAngle(lander, 359, dt)
            if lander.angle > 345 then
                Lander.doThrust(lander, dt)
            end
        else
            print("undedetected scenario")
        end

    else
        -- is on base or close to base or refuelling
        -- do nothing
    end
end

function Bot.update(dt)

    if Fun.CurrentScreenName() == "World" then
        for k, lander in pairs(LANDERS) do
            if lander.isBot then
                GetCurrentState(lander)
                DetermineAction(lander, dt)
            end
        end
    end
end

return Bot
