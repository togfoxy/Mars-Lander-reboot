local AI = {}

local currentAltitude
local currentIsOnBase
predictedx = 0   -- this is the lookahead ability
predictedy = 0   -- this is the lookahead ability
perfecty = 0     -- the y value that is just right
local currentDistanceToBase
local predictedYgroundValue		-- the ground y value at the predicted point
local toohigh, toolow
local tooleft, tooright
local tooslow, toofast
local closestbase       		-- object
local lookahead = 240			-- how far to look ahead
local ygap, vxgap				-- how far the predicted location is off-target
local nextaction = 0

local function GetDistanceToFueledBase(uuid,xvalue, intBaseType)
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
    currentDistanceToBase, closestbase = GetDistanceToFueledBase(lander.uuid, predictedx, Enum.basetypeFuel)
    -- searching for a base can outstrip the terrain so guard against that.
    while closestbase.x == nil or predictedx > #GROUND do
        Terrain.generate(SCREEN_WIDTH * 4)
        currentDistanceToBase, closestbase = GetDistanceToFueledBase(lander.uuid, predictedx, Enum.basetypeFuel)
    end

	-- ensure this block is below the above WHILE loop
    predictedy = lander.y + (lander.vy * lookahead)
    predictedYgroundValue = GROUND[Cf.round(predictedx,0)]	

    if predictedYgroundValue == nil then
        print(#GROUND, predictedx, predictedy, predictedYgroundValue)
        error("oops - check the console for debug info")
    end
    
    -- look far ahead for long distances
	-- ensure this is after the terrain.generate
    if math.abs(currentDistanceToBase) > 2000 then
        lookahead = 240
    else
        lookahead = 120
    end

    -- the perfecty value is a 45 degree angle from the base to the sky
    perfecty = predictedYgroundValue - math.abs(currentDistanceToBase)
    if perfecty < SCREEN_HEIGHT / 3 then perfecty = SCREEN_HEIGHT / 3 end

    perfectvx = currentDistanceToBase / -120        -- some constant that determines best vx

    if predictedy < perfecty * 0.9 then
        toohigh = true
        toolow = false
    elseif predictedy > perfectvx * 1.1 then
        toohigh = false
        toolow = true
	else
		toohigh = false 
		toolow = false 
    end

    if currentDistanceToBase < 0 then
        tooleft = true
        tooright = false
    else
        tooleft = false
        tooright = true
    end

    if lander.vx < perfectvx * 0.9 then
        tooslow = true
        toofast = false
    elseif lander.vx > perfectvx * 1.1 then
        tooslow = false
        toofast = true
	else 
		tooslow = false 
		toofast = false 
    end
	
	-- capture the 'before' state so it can be checked after an action
	ygap = perfecty - predictedy
	dxgap = lander.vx - perfectvx

end

local function printQTable(qt)
	-- prints the provided qtable out to the console with a small amount of formatting
	-- print table
	for index, data in pairs(qt) do
		print(index)

		for key, value in pairs(data) do
			print('\t', key, value)
		end
	end
end

function AI.initialise()
	local qtable = {}
	qtable["toolowtoofast"] = {}
	qtable["toolowtoofast"]["nothrust"] = nil
	qtable["toolowtoofast"]["nothrust"] = 1.5
	
	qtable["toolowtoofast"]["thrust270"] = nil
	qtable["toolowtoofast"]["thrust270"] = 2.2
	
end

local function DetermineAction(lander, dt)

	local explorerate = 25		-- %
	
	-- check if lander already has an action
	if lander.currentAction == Enum.AIActionNothing then
	
		if love.math.random(1,100) <= explorerate then
			-- explorative. Choose any random action
			nextaction = love.math.random(1, Enum.AIActionNumbers)
nextaction = 6	
			lander.measureNow = false		
		else 
		
		
		end 

	end
	
-- print(nextaction)

	lander.currentAction = nextaction
	
	
end

local function ExecuteAction(lander, dt)

	if lander.currentAction ~= Enum.AIActionNothing then
	
		if lander.currentAction == Enum.AIActionWait then
	
		elseif lander.currentAction == Enum.AIActionThrust180 then
			Bot.turnTowardsAngle(lander, 180, dt)
			if lander.angle < 190 then
                Lander.doThrust(lander, dt)
            end
		elseif lander.currentAction == Enum.AIActionThrust210 then
			Bot.turnTowardsAngle(lander, 210, dt)
			if lander.angle > 200 or lander.angle < 220 then
                Lander.doThrust(lander, dt)
            end
		elseif lander.currentAction == Enum.AIActionThrust240 then
			Bot.turnTowardsAngle(lander, 240, dt)
			if lander.angle > 230 or lander.angle < 250 then
                Lander.doThrust(lander, dt)
            end
		
		elseif lander.currentAction == Enum.AIActionThrust270 then
			Bot.turnTowardsAngle(lander, 270, dt)
			if lander.angle > 260 or lander.angle < 280 then
                Lander.doThrust(lander, dt)
            end		
		elseif lander.currentAction == Enum.AIActionThrust300 then
			Bot.turnTowardsAngle(lander, 300, dt)
			if lander.angle > 290 or lander.angle < 310 then
                Lander.doThrust(lander, dt)
            end		
		elseif lander.currentAction == Enum.AIActionThrust330 then
			Bot.turnTowardsAngle(lander, 330, dt)
			if lander.angle > 320 or lander.angle < 340 then
                Lander.doThrust(lander, dt)
            end		
		elseif lander.currentAction == Enum.AIActionThrust360 then
			Bot.turnTowardsAngle(lander, 359, dt)
			if lander.angle > 350 then
                Lander.doThrust(lander, dt)
            end		
		else 
			error("Something impossible happened.")
		end
	end

end

local function MeasureAction(lander, dt)
	-- capture new gapy and new gapdx to see if AI is doing the right thing.
	
	if lander.measureNow then
	
		predictedx = lander.x + (lander.vx * lookahead)
		currentDistanceToBase, closestbase = Bot.GetDistanceToFueledBase(lander.uuid, predictedx, Enum.basetypeFuel)
		
		if math.abs(currentDistanceToBase) > 2000 then
			lookahead = 240
		else
			lookahead = 120
		end	
		
		predictedYgroundValue = GROUND[Cf.round(predictedx,0)]	
		perfecty = predictedYgroundValue - math.abs(currentDistanceToBase)
		if perfecty < SCREEN_HEIGHT / 3 then perfecty = SCREEN_HEIGHT / 3 end
		
		perfectvx = currentDistanceToBase / -120        -- some constant that determines best vx
		
		newygap = perfecty - predictedy
		newdxgap = lander.vx - perfectvx
		
print(ygap, newygap)
		
		if newygap > ygap and newdxgap > dxgap then
			-- wrong action
			lander.currentAction = AIActionNothing
		end
		
	else 
	
		lander.measureNow = true 
	end
	
end

function AI.update(dt)
    if Fun.CurrentScreenName() == "World" then
        for k, lander in pairs(LANDERS) do
            if lander.isAI then
				GetCurrentState(lander)
                DetermineAction(lander, dt)
				ExecuteAction(lander, dt)
				MeasureAction(lander, dt)
            end
        end
    end
	

end

return AI