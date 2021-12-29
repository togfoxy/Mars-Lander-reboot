local AI = {}

-- high score = 48,000

local currentAltitude
local currentIsOnBase
predictedx = 0   -- this is the lookahead ability
predictedy = 0   -- this is the lookahead ability
perfecty = 0     -- the y value that is just right
perfectvx = 0
local currentDistanceToBase
local predictedYgroundValue		-- the ground y value at the predicted point
local toohigh, toolow
local tooslow, toofast
local tooleft, tooright
local onground
local closestbase       		-- object
local lookahead = 240			-- how far to look ahead
local ygap1, vxgap1				-- how far the predicted location is off-target
local ygap2, vxgap2
local nextaction = 0
local index1, index2

function AI.printQTable(qt)
	-- prints the provided qtable out to the console with a small amount of formatting
	-- print table
	print("***************************************")
	for index, data in pairs(qt) do
		print(index)

		for key, value in pairs(data) do
			print('\t', key, value)
		end
	end
	print("***************************************")
end

local function setTooHighTooLow(lander)
	if toohigh == nil then
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
		if currentDistanceToBase < 0 then
			tooleft = true
			tooright = false
		else
			tooleft = false
			tooright = true
		end
	end
end

local function GetDistanceToFueledBase(uuid, xvalue, intBaseType)
	-- uuid is the lander ID. This is needed as each lander has their own instance of fuel bases
	-- returns two values: the distance to the closest base with fuel, and the object/table item for that base
	-- note: if distance is a negative value then the Lander has not yet passed the base
	local closestdistance = -1
	local closestbase = {}
	local absdist
	local realdist

	for k,v in pairs(OBJECTS) do
		if v.objecttype == intBaseType then
	-- print(Inspect(v))
	-- print(uuid)
			if v.fuelLeft[uuid] == nil then v.fuelLeft[uuid] = Enum.baseMaxFuel end

			if (v.fuelLeft[uuid] == nil or v.fuelLeft[uuid] > 1) then
			 	if (v.hasLanded[uuid] == nil or v.hasLanded[uuid] == false) then
					-- the + bit is an offset to calculate the landing pad and not the image
					absdist = math.abs(xvalue - (v.x + 85))
					if closestdistance == -1 or absdist <= closestdistance then
						closestdistance = absdist
						closestbase = v
					end
				end
			end
		end
	end
	-- print("~~~")

	-- now we have the closest base, work out the distance to the landing pad for that base
	if closestbase.x ~= nil then
		-- the + bit is an offset to calculate the landing pad and not the image
		realdist = xvalue - (closestbase.x + 85)
	end
	return realdist, closestbase
end

local function GetCurrentState(lander)
	if lander.onGround then onground = true end
	-- predictedx is the x value the lander is predicted to be at based on current trajectory
	-- predictedy is the y value the lander is predicted to be at based on current trajectory
	-- predictedYgroundValue is the y value for the terrain when looking ahead
    predictedx = lander.x + (lander.vx * lookahead)
	if predictedx < 0 then predictedx = 0 end
    -- negative value means not yet past the base
    currentDistanceToBase, closestbase = GetDistanceToFueledBase(lander.uuid, predictedx, Enum.basetypeFuel)
	if currentDistanceToBase == nil then
		print(predictedx, #GROUND)
		error("Error. Check debug")
	end


	-- the AI will sometimes target a base that is well behind it. Guard against that.
	if currentDistanceToBase > 1000 then
		-- erase the fuel from the far away base and search again
		closestbase.fuelLeft[lander.uuid] = 0
		currentDistanceToBase, closestbase = GetDistanceToFueledBase(lander.uuid, predictedx, Enum.basetypeFuel)
	end

    -- searching for a base can outstrip the terrain so guard against that.
    while closestbase.x == nil or predictedx > #GROUND do
		print("Adding more terrain for AI")
        Terrain.generate(SCREEN_WIDTH * 4)
        currentDistanceToBase, closestbase = GetDistanceToFueledBase(lander.uuid, predictedx, Enum.basetypeFuel)
    end

	currentIsOnBase = Lander.isOnLandingPad(lander, Enum.basetypeFuel)
	if currentIsOnBase then
		if closestbase[lander.uuid] == nil then closestbase[lander.uuid] = {} end
		closestbase[lander.uuid].hasLanded = true
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
	-- print(currentDistanceToBase, perfectvx)

	-- return the two key values
	yvariable = perfecty - predictedy		-- this is the y gap
	vxvariable = lander.vx - perfectvx		-- this is the vx gap

	-- print(yvariable ,vxvariable)
	return yvariable ,vxvariable
end

local function constructQTableIndex(lander)
	local ind1, ind2
	ind1 = ""
	if onground then
		ind1 = "onground"
	end
	if tooleft then
		ind1 = ind1 .. "tooleft"
	else
		ind1 = ind1 .. "tooright"
	end
	if not onground then
		if toohigh then
			ind1 = ind1 .. "toohigh"
		elseif toolow then
			ind1 = ind1 .. "toolow"
		else
			ind1 = ind1 .. "rightalt"
		end
		if tooslow then
			ind1 = ind1 .. "tooslow"
		elseif toofast then
			ind1 = ind1 .. "toofast"
		else
			ind1 = ind1 .. "rightspeed"
		end
	end

	-- create index2
	if lander.currentAction == Enum.AIActionWait then
		ind2 = "Wait"
	elseif lander.currentAction == Enum.AIActionThrust180 then
		ind2 = "Thrust180"
	elseif lander.currentAction == Enum.AIActionThrust210 then
		ind2 = "Thrust210"
	elseif lander.currentAction == Enum.AIActionThrust240 then
		ind2 = "Thrust240"
	elseif lander.currentAction == Enum.AIActionThrust270 then
		ind2 = "Thrust270"
	elseif lander.currentAction == Enum.AIActionThrust300 then
		ind2 = "Thrust300"
	elseif lander.currentAction == Enum.AIActionThrust330 then
		ind2 = "Thrust330"
	elseif lander.currentAction == Enum.AIActionThrust360 then
		ind2 = "Thrust360"
	else
		-- has no current action
		ind2 = nil
	end

	return ind1, ind2
end

local function DetermineAction(lander, dt)

	local explorerate = 15		-- %
	local takeaction = false

	predictedx = lander.x + (lander.vx * lookahead)
	currentDistanceToBase, closestbase = GetDistanceToFueledBase(lander.uuid, predictedx, Enum.basetypeFuel)
    local abscurrentDistanceToBase = (math.abs(currentDistanceToBase))

    -- if not on base
    if not currentIsOnBase then takeaction = true end
    -- if tank is full
    if lander.fuel >= lander.fuelCapacity then takeaction = true end
    -- if not near a base
    if (abscurrentDistanceToBase > 200 and not currentIsOnBase) then takeaction = true end

	if takeaction then
		-- lander is not on base or not refueling so contue to determine action
		-- check if lander already has an action
		if lander.currentAction == Enum.AIActionNothing then
			-- lander chooses to explore or exploit
			if love.math.random(1,100) <= explorerate then
				-- explorative. Choose any random action
				lander.currentAction = love.math.random(1, Enum.AIActionNumbers)
			else
				-- exploit the qtable
				-- construct index
				-- index2 is set here and then overwritten below
				index1, index2 = constructQTableIndex(lander)

				-- scan all actions for index1 and choose the highest value
				local largestvalue = -999
				if qtable[index1] ~= nil then
					for k, v in pairs(qtable[index1]) do
						if v > largestvalue then
							index2 = k
							largestValue = v
						end
					end
				end
				-- check if an action is actually chosen from the qtable
				if index2 == nil then
					-- explorative. Choose any random action
					lander.currentAction = love.math.random(1, Enum.AIActionNumbers)
				end
			end
		end
	else
		-- lander is on base or refueling or not needing a decision
	end
	index1, index2 = constructQTableIndex(lander)
	-- print(nextaction)
end

local function ExecuteAction(lander, dt)
	if lander.currentAction ~= Enum.AIActionNothing then
		if lander.currentAction == Enum.AIActionWait then
			-- lander will wait for a specified time before choosing a new action
			lander.currentActionTimer = lander.currentActionTimer + dt
			if lander.currentActionTimer > Enum.AIWaitTimerThreshold then
				lander.currentActionTimer = 0
				lander.currentAction = Enum.AIActionNothing
			end
		elseif lander.currentAction == Enum.AIActionThrust180 then
			Bot.turnTowardsAngle(lander, 180, dt)
			if lander.angle < 190 then
                Lander.doThrust(lander, dt)
            end
		elseif lander.currentAction == Enum.AIActionThrust210 then
			Bot.turnTowardsAngle(lander, 210, dt)
			if lander.angle > 200 and lander.angle < 220 then
                Lander.doThrust(lander, dt)
            end
		elseif lander.currentAction == Enum.AIActionThrust240 then
			Bot.turnTowardsAngle(lander, 240, dt)
			if lander.angle > 230 and lander.angle < 250 then
                Lander.doThrust(lander, dt)
            end
		elseif lander.currentAction == Enum.AIActionThrust270 then
			Bot.turnTowardsAngle(lander, 270, dt)
			if lander.angle > 260 and lander.angle < 280 then
                Lander.doThrust(lander, dt)
            end
		elseif lander.currentAction == Enum.AIActionThrust300 then
			Bot.turnTowardsAngle(lander, 300, dt)
			if lander.angle > 290 and lander.angle < 310 then
                Lander.doThrust(lander, dt)
            end
		elseif lander.currentAction == Enum.AIActionThrust330 then
			Bot.turnTowardsAngle(lander, 330, dt)
			if lander.angle > 320 and lander.angle < 340 then
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

		-- all actions expire after a time - even good actions
		lander.currentActionTimer = lander.currentActionTimer + dt
	end
end

local function RewardAction(lander, dt)
	-- local index1, index2
	local rewardvalue = 0

	-- only take measurements when the engine is actually on and impacting speed/direction
	if lander.currentAction ~= Enum.AIActionNothing and lander.engineOn and index2 ~= nil then
		-- update the Qtable

		-- larger is better
		rewardvalue = (math.abs(ygap1) - math.abs(ygap2)) + ((math.abs(vxgap1) - math.abs(vxgap2)) * 2000)

	print(index1, index2, Cf.round(rewardvalue,2), Cf.round(lander.angle,0), Cf.round(ygap1,4), Cf.round(ygap2,4), Cf.round(vxgap1,4), Cf.round(vxgap2,4))

		-- assign rewardvalue to the qtable, creating the element if necessary
		if qtable[index1] == nil then
			qtable[index1] = {}
		end
		if qtable[index1][index2] == nil then
			qtable[index1][index2] = rewardvalue
		else
			-- do some dodgy averaging
			qtable[index1][index2] = (qtable[index1][index2] + rewardvalue) / 2
		end

		-- clear a action that has a really low reward
		if rewardvalue < -5 then
			lander.currentAction = Enum.AIActionNothing
		end

		if lander.currentActionTimer > Enum.AIWaitTimerThreshold then
			lander.currentActionTimer = 0
			if rewardvalue < 10 then
				lander.currentAction = Enum.AIActionNothing
			end
		end
	end

	-- clear these for the next pass
	ygap1 = nil
	ygap2 = nil
	vxgap1 = nil
	vxgap2 = nil

	toohigh = nil
	toolow = nil
	tooslow = nil
	toofast = nil
	tooleft = nil
	tooright = nil
	onground = nil
end

function AI.update(dt)
    if Fun.CurrentScreenName() == "World" then
        for k, lander in pairs(LANDERS) do
            if lander.isAI then
				if ygap1 == nil then
					ygap1, vxgap1 = GetCurrentState(lander)
					setTooHighTooLow(lander)		-- set this on the first pass and then compare it on the 2nd pass
				else
					ygap2, vxgap2 = GetCurrentState(lander)
				end
                DetermineAction(lander, dt)
				ExecuteAction(lander, dt)
				if ygap2 ~= nil then
					RewardAction(lander, dt)
				end
            end
        end
    end
end

return AI
