
-- ~~~~~~~~~~~~
-- lander.lua
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Lander object for Mars Lander
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local Lander = {}
local bubbleText = {}	-- Text that appears like a bubble



-- ~~~~~~~~~~~~~~~~
-- Local Variables
-- ~~~~~~~~~~~~~~~~

-- TODO: Create the spriteData with width and height automatically (except for animations)
-- local ship = Assets.getImageSet("newship")
local shipImage = {}
shipImage[1] = Assets.getImageSet("newship1")
shipImage[2] = Assets.getImageSet("newship2")
shipImage[3] = Assets.getImageSet("newship3")
shipImage[4] = Assets.getImageSet("newship4")
shipImage[5] = Assets.getImageSet("newship5")

local flame = Assets.getImageSet("flame")
local parachute = Assets.getImageSet("parachute")

local landingSound = Assets.getSound("landingSuccess", "static", 0.1)	-- need to put the source type if specifying the volume
local failSound = Assets.getSound("wrong")
local lowFuelSound = Assets.getSound("lowFuel")
local engineSound = Assets.getSound("engine")



-- ~~~~~~~~~~~~~~~~
-- Local functions
-- ~~~~~~~~~~~~~~~~



local function recalcDefaultMass(lander)
	local result = 0
	-- all the masses are stored in this table so add them up
	for i = 1, #lander.mass do
		result = result + lander.mass[i]
	end
	-- return mass of all the components + mass of fuel
	return (result + lander.fuelCapacity)
end

local function landerHasFuelToThrust(lander, dt)
	-- returns true if the lander has enough fuel for thrust
	-- returns false if not enough fuel to thrust
	-- Note: fuel can be > 0 but still not enough to thrust

	local hasThrusterUpgrade = Lander.hasUpgrade(lander, Fun.getModule(Enum.moduleEfficientThrusters))
	if (lander.fuel - dt) >= 0 or (hasThrusterUpgrade and (lander.fuel - (dt * 0.80)) >= 0) then
		return true
	else
		return false
	end
end

local function parachuteIsDeployed(lander)
	-- return true if lander has a parachute and it is deployed

	for _, moduleItem in pairs(lander.modules) do
		if moduleItem.id == Enum.moduleParachute then
			if moduleItem.deployed then
				return true
			end
		end
	end
	return false
end

local function deployParachute(lander)
	-- sets the 'deployed' status of parachute
	-- assumes the lander has a parachute

	for _, moduleItem in pairs(lander.modules) do
		if moduleItem.id == Enum.moduleParachute then
			moduleItem.deployed = true
			break
		end
	end
end

local function thrustLeft(lander, dt)
	-- TODO: consider the side thrusters moving left/right based on angle and not just movement on the X axis.
	if Lander.hasUpgrade(lander, Fun.getModule(Enum.moduleSideThrusters)) and landerHasFuelToThrust(lander, dt) then
		local forceX = 0.5 * dt
		lander.vx = lander.vx - forceX
		-- opposite engine is on
		lander.rightEngineOn = true
		lander.fuel = lander.fuel - forceX
	end

	-- if trying to side thrust and has parachute and descending and on the screen then ...
	if Lander.hasUpgrade(lander, Fun.getModule(Enum.moduleParachute)) and not landerHasFuelToThrust(lander, dt) then
		if lander.vy > 0 and lander.y > 15 then		-- 15 is enough to clear the fuel gauge
			-- parachutes allow left/right drifting even if no fuel and thrusters available
			deployParachute(lander)
			local forceX = 0.5 * dt
			lander.vx = lander.vx - forceX
		end
	end
end

local function thrustRight(lander, dt)
	if Lander.hasUpgrade(lander, Fun.getModule(Enum.moduleSideThrusters)) and landerHasFuelToThrust(lander, dt) then
		local forceX = 0.5 * dt
		lander.vx	= lander.vx + forceX
		lander.fuel = lander.fuel - forceX
		-- opposite engine is on
		lander.leftEngineOn = true
	end

	-- if trying to side thrust and has parachute and descending and on the screen then ...
	if Lander.hasUpgrade(lander, Fun.getModule(Enum.moduleParachute)) and not landerHasFuelToThrust(lander, dt) then
		if lander.vy > 0 and lander.y > 15 then		-- 15 is enough to clear the fuel gauge
			deployParachute(lander)
			local forceX = 0.5 * dt
			lander.vx = lander.vx + forceX
		end
	end
end

local function moveShip(lander, dt)
	lander.x = lander.x + lander.vx
	lander.y = lander.y + lander.vy

	-- Set left boundary
	if lander.x < ORIGIN_X - (SCREEN_WIDTH / 2) then
		lander.vx = 0
		lander.x =  ORIGIN_X - (SCREEN_WIDTH / 2)
	end

	if not lander.onGround then
		-- apply gravity
		lander.vy = lander.vy + (Enum.constGravity * dt)

		-- parachutes slow descent
		if parachuteIsDeployed(lander) and lander.vy > 0.5 then
			lander.vy = 0.5
		end

-- print(lander.name, Cf.round(lander.vx,2), Cf.round(lander.vy,2), dt)

		-- used to determine speed right before touchdown
		LANDER_VY = lander.vy
		LANDER_VX = lander.vx
	end
end

local function refuelLander(lander, base, dt)
	-- drain fuel from the base and add it to the lander
	-- base is an object/table item from OBJECTS
	local refuelAmount = math.min(base.totalFuel, (lander.fuelCapacity - lander.fuel), dt)
	base.totalFuel	= base.totalFuel - refuelAmount
	lander.fuel		= lander.fuel + refuelAmount
	-- disable the base if the tanks are empty
	if base.totalFuel <= 0 then base.active = false end
end

local function payLanderFromBase(lander, base, baseDistance)
	-- pay some money based on distance to the base
	-- base is an object/table item from OBJECTS
	local distance = math.abs(baseDistance)
	if not base.paid then
		lander.money = Cf.round(lander.money + (100 - distance),0)
		landingSound:play()
	end
end

local function payLanderForControl(lander, base)
	if base.paid == false then
		-- pay for a good vertical speed
		lander.money = Cf.round(lander.money + ((1 - LANDER_VY) * 100),0)
		-- pay for a good horizontal speed
		lander.money = Cf.round(lander.money + (0.60 - LANDER_VX * 100),0)

		if GAME_CONFIG.easyMode and lander.money < 0 then
			lander.money = 0
		end
	end
end

local function checkForDamage(lander)
	-- apply damage if vertical speed is too higher
	if lander.vy > Enum.constVYThreshold then
		local excessSpeed = lander.vy - Enum.constVYThreshold
		lander.health = lander.health - (excessSpeed * 100)
		if lander.health < 0 then lander.health = 0 end
	end
end

local function createBubbleText(lander, text)
	-- creates a bubble object and adds it to the bubble table for Drawing
	local myBubble = {}
	myBubble.text = text
	myBubble.timeleft = 4	-- bubble will last 4 seconds
	myBubble.x = lander.x - WORLD_OFFSET
	myBubble.y = lander.y - 50
	table.insert(bubbleText, myBubble)
end

local function checkForContact(lander, dt)
	-- see if lander has contacted the ground
	local roundedLanderX = Cf.round(lander.x)
	local roundedGroundY
	local onBase = Lander.isOnLandingPad(lander, Enum.basetypeFuel)

	-- see if onGround near a fuel base
	-- bestDistance could be a negative number meaning not yet past the base (but maybe really close to it)
	-- FIXME: Couldn't baseType be a string like "fuelStation" instead of numbers?
	-- 2 = type of base = fuel
	local bestDistance, bestBase = Fun.GetDistanceToClosestBase(lander.x, Enum.basetypeFuel)
	-- bestBase is an object/table item
	-- add money based on alignment to centre of landing pad
	if bestDistance >= -80 and bestDistance <= 40 then
		onBase = true
	end

	-- get the height of the terrain under the lander
	roundedGroundY = Cf.round(GROUND[roundedLanderX],0)

	-- check if lander is at or below the terrain
	-- the offset is the size of the lander image
	-- if lander.y > roundedGroundY - ship.image:getHeight() then		-- 8 = the image offset for visual effect
	if lander.y > roundedGroundY - 20 then		-- 20 = the image offset for visual effect
		-- a heavy landing will cause damage
		checkForDamage(lander)

		if not lander.onGround then

			-- destroy the single use parachute
			if parachuteIsDeployed(lander) then
				-- need to destroy this single-use module
				local moduleIndexToDestroy = 0
				for moduleIndex, moduleItem in pairs(lander.modules) do
					if moduleItem.id == Enum.moduleParachute and moduleItem.deployed then
						moduleIndexToDestroy = moduleIndex
						moduleItem.deployed = false
						break
					end
				end
				assert(moduleIndexToDestroy > 0)
				table.remove(lander.modules, moduleIndexToDestroy)
				-- adjust new mass
				lander.currentMass = recalcDefaultMass(lander)
			end
		end

		local startMoney = lander.money	-- capture this here and do calculation further down

		-- NOTE: if you need to check things on first contact with terrain (like receiving damage) then place
		-- that code above lander.onGround = true

		-- Lander is on ground
		lander.onGround = true
		-- Stop x, y movement
		lander.vx = 0
		if lander.vy > 0 then
			lander.vy = 0
		end

		-- TODO: Move some of the fuel base logic to objects/base.lua
		if onBase and not lander.gameOver then
			refuelLander(lander, bestBase,dt)
			payLanderFromBase(lander, bestBase, bestDistance)
			-- pay the lander on first visit on the base
			-- this is the first landing on this base so pay money based on vertical and horizontal speed
			if not bestBase.paid then
				payLanderForControl(lander, bestBase)

				local stopMoney = lander.money
				local moneyEarned = stopMoney - startMoney
				myBubble = createBubbleText(lander, moneyEarned)

				bestBase.paid = true
			-- check for game-over conditions
			elseif not bestBase.active and lander.fuel <= 1 then
				lander.gameOver = true
			end
		end

		-- check for game-over conditions
		if not onBase and lander.fuel <= 1 then
			lander.gameOver = true
		end
	else
		lander.onGround = false
	end
end

local function playSoundEffects(lander)
	if lander.engineOn then
		engineSound:play()
	else
		engineSound:stop()
	end

	local fuelPercent = lander.fuel / lander.fuelCapacity
	-- play alert if fuel is low (but not empty because that's just annoying)
	if fuelPercent <= 0.33 and fuelPercent > 0.01 then
		lowFuelSound:play()
	end
end

local function buyModule(module, lander)
	-- receives the module object
	-- Enough money to purchase the module
	-- checks if module is allowed
	if module.allowed == nil or module.allowed == true then
		if lander.money >= module.cost then
			if Lander.hasUpgrade(lander, module) then
				-- this module is already purchased
				failSound:play()
				return
			end

			-- TODO: Switch this temporary solution to something more dynamic
			if module.fuelCapacity then
				if module.fuelCapacity > lander.fuelCapacity then
					lander.fuelCapacity = module.fuelCapacity
				else
					-- Downgrading wouldn't be that fun
					return
				end
			end

			-- can purchase this module
			table.insert(lander.modules, module)
			-- pay for it
			lander.money = lander.money - module.cost
			-- add and calculate new mass
			lander.mass[#lander.mass+1] = module.mass
			lander.currentMass = recalcDefaultMass(lander)
		else
			-- play 'failed' sound
			failSound:play()
		end
	end
end

local function altitude(lander)
	-- returns the lander's distance above the ground
	local landerYValue = lander.y
	local groundYValue = GROUND[Cf.round(lander.x,0)]
	return groundYValue - landerYValue
end

local function drawBubbleText()
	-- draws bubbles
	for k,v in pairs(bubbleText) do
		Assets.setFont("font14")
		-- setting alpha is a hack. timeleft starts > 1 but then decreases to zero
		love.graphics.setColor(251/255, 1, 119/255, v.timeleft)
		love.graphics.print("$" .. v.text, Cf.round(v.x - 5), Cf.round(v.y))
		love.graphics.setColor(1, 1, 1, 1)
	end
end

local function updateBubbleText(dt)
	-- apply dt to bubbles so they expire

	for k,v in pairs(bubbleText) do
		v.timeleft = v.timeleft - dt
		if v.timeleft <= 0 then
			table.remove(bubbleText,k)
		else
			v.y = v.y - (dt * 15)	-- bubble floats up
		end
	end
end

local function updateScore(lander)
	-- updates the lander score that is saved in the lander table
	-- this is the same as functions.CalculateScore(). Intention is to deprecate and remove that function and use this.
	-- this procedure does not return the score. It updates the lander table
	lander.score = lander.x - ORIGIN_X

	if lander.score > GAME_SETTINGS.HighScore then
		GAME_SETTINGS.HighScore = lander.score
		Fun.SaveGameSettings() -- this needs to be refactored somehow, not save every change
	end
end

local function drawGuidance(lander)
	-- draw the pointer thingy that shows where the lander is moving

	if Lander.hasUpgrade(lander, Fun.getModule(Enum.moduleGuidance)) then

		local lookahead = 60		-- how far to look ahead
		local x = lander.x + (lander.vx * lookahead) - WORLD_OFFSET
		local y = lander.y + (lander.vy * lookahead)

		-- draw a little cross-hair symbol
		love.graphics.line(x - 7, y, x - 2, y)
		love.graphics.line(x + 7, y, x + 2, y)
		love.graphics.line(x, y - 7, x, y - 2)
		love.graphics.line(x, y + 7, x, y + 2)

	end
end

-- ~~~~~~~~~~~~~~~~~
-- Public functions
-- ~~~~~~~~~~~~~~~~~

function Lander.create(name)
	-- create a lander and return it to the calling sub
	local lander = {}
	lander.x = Cf.round(ORIGIN_X,0)
	lander.y = GROUND[lander.x] - 20	-- 20 is the image offset so it appears to be on the ground
	lander.connectionID = nil	-- used by enet
	-- 270 = up
	lander.angle = 270
	lander.vx = 0
	lander.vy = 0
	lander.engineOn = false
	lander.leftEngineOn = false
	lander.rightEngineOn = false
	lander.onGround = false
	-- Health in percent
	lander.health = 100
	lander.money = 0
	lander.gameOver = false
	lander.score = lander.x - ORIGIN_X
	lander.name = name or CURRENT_PLAYER_NAME
	lander.isBot = false

	if GAME_CONFIG.easyMode then
		lander.money = 9999
	end
	lander.currentMass = 220 		-- default mass
	-- ** if adding attributes then update the RESET function as well

	-- all the items that have mass
	lander.mass = {}
	-- base mass of lander
	table.insert(lander.mass, 100)
	-- volume in arbitrary units
	lander.fuelCapacity = 25
	-- start with a full tank
	lander.fuel = lander.fuelCapacity
	-- this is the mass of an empty tank
	table.insert(lander.mass, 20)
	-- this is the mass of the rangefinder (not yet purchased)
	table.insert(lander.mass, 0)

	-- modules
	-- this will be strings/names of modules
	lander.modules = {}



	return lander
end

function Lander.reset(lander)
	-- resets a single lander. Used in multiplayer mode when you don't want to reset every lander.
	-- this function largely follows same behaviour as the CREATE function

	lander.x = Cf.round(ORIGIN_X,0)
	lander.y = GROUND[lander.x] - 8
	-- lander.connectionID = nil	-- used by enet
	-- 270 = up
	lander.angle = 270
	lander.vx = 0
	lander.vy = 0
	lander.engineOn = false
	lander.leftEngineOn = false
	lander.rightEngineOn = false
	lander.onGround = false
	-- Health in percent
	lander.health = 100
	lander.money = 0
	lander.gameOver = false
	lander.score = lander.x - ORIGIN_X
	lander.currentMass = 220 		-- default mass

	-- mass
	lander.mass = {}
	-- base mass of lander
	table.insert(lander.mass, 100)
	-- volume in arbitrary units
	lander.fuelCapacity = 25
	-- start with a full tank
	lander.fuel = lander.fuelCapacity
	-- this is the mass of an empty tank
	table.insert(lander.mass, 20)

	-- TODO: why is this here?
	-- this is the mass of the rangefinder (not yet purchased)
	table.insert(lander.mass, 0)

	-- modules
	-- this will be strings/names of modules
	lander.modules = {}
end

function Lander.getMass(lander)
	-- return the mass of all the bits on the lander
    local result = 0

    -- all the masses are stored in this table so add them up
    for i = 1, #lander.mass do
        result = result + lander.mass[i]
    end

    -- add the mass of the fuel
    result = result + lander.fuel

    return result
end

function Lander.isOnLandingPad(lander, baseId)
	-- returns a true / false value

    local baseDistance, _ = Fun.GetDistanceToClosestBase(lander.x, baseId)
    if baseDistance >= -80 and baseDistance <= 40 and altitude(lander) < 22 then
        return true
    else
        return false
    end
end

function Lander.hasUpgrade(lander, module)
	for k, landerModule in pairs(lander.modules) do
		if landerModule.id == module.id then
			return true
		end
	end
	return false
end

function Lander.doThrust(lander, dt)
	local hasThrusterUpgrade = Lander.hasUpgrade(lander, Fun.getModule(Enum.moduleEfficientThrusters))
	if landerHasFuelToThrust(lander, dt) then
		local angleRadian = math.rad(lander.angle)
		local forceX = math.cos(angleRadian) * dt
		local forceY = math.sin(angleRadian) * dt

		-- adjust the thrust based on ship mass
		-- less mass = higher ratio = more thrust = less fuel needed to move
		local massRatio = 220 / Lander.getMass(lander)	-- 220 is the mass of a 'normal' lander
		-- for debugging only

		lander.engineOn = true
		forceX = forceX * massRatio
		forceY = forceY * massRatio
		lander.vx = lander.vx + forceX
		lander.vy = lander.vy + forceY

		if hasThrusterUpgrade then
			-- efficient thrusters use 80% fuel compared to normal thrusters
			lander.fuel = lander.fuel - (dt * 0.80)
		else
			lander.fuel = lander.fuel - (dt * 1)
		end

		-- Add smoke particles if available
		if Smoke then
			Smoke.createParticle(lander.x, lander.y, lander.angle)
		end
	else
		-- no fuel to thrust
		--! probably need to make a serious alert here
	end
end

function Lander.update(dt)

	for k, lander in pairs(LANDERS) do

		local keyDown = love.keyboard.isDown

	    if keyDown("up") or keyDown("w") or keyDown("kp8") then
			-- bot has it's own thrust routines
			if not lander.isBot then Lander.doThrust(lander, dt) end
	    end
		-- rotate the lander anti-clockwise
	    if keyDown("left") or keyDown("a") or keyDown("kp4") then
			lander.angle = lander.angle - (90 * dt)
	    end
		-- rotate the lander clockwise
	    if keyDown("right") or keyDown("d") or keyDown("kp6") then
			lander.angle = lander.angle + (90 * dt)
	    end
	    if keyDown("q") or keyDown("kp7") then
	        thrustLeft(lander, dt)
	    end
	    if keyDown("e") or keyDown("kp9") then
	        thrustRight(lander, dt)
	    end

		-- TODO: Calculate the offset so that it doesn't need to be global
		-- Calculate worldOffset for everyone based on lander x position
		WORLD_OFFSET = Cf.round(LANDERS[1].x) - ORIGIN_X

		-- Reset angle if > 360 degree
		if math.max(lander.angle) > 360 then lander.angle = 0 end

		-- Update ship
	    moveShip(lander, dt)
	    playSoundEffects(lander)
	    checkForContact(lander, dt)
		updateScore(lander)
		updateBubbleText(dt)
	end
end

function Lander.draw()
	-- draw the lander and flame
	for landerId, lander in pairs(LANDERS) do
		-- guard against connecting mplayer clients not having complete data
		if landerId == 1 or lander.x ~= nil then
			--local sx, sy = 1.5, 1.5
			local sx, sy = 0.75, 0.75
			local x = lander.x - WORLD_OFFSET
			local y = lander.y
			local ox = shipImage[1].image:getWidth() / 2
			local oy = shipImage[1].image:getHeight() / 2

			-- fade other landers in multiplayer mode
			if landerId == 1 then
				love.graphics.setColor(1,1,1,1)
			else
				love.graphics.setColor(1,1,1,0.5)
			end

			-- draw parachute before drawing the lander
			if parachuteIsDeployed(lander) then
				local parachuteYOffset = y - parachute.image:getHeight()
				local parachuteXOffset = x - parachute.image:getWidth() / 2
				love.graphics.draw(parachute.image, parachuteXOffset, parachuteYOffset)
			end

			-- draw the legs based on distance above the ground (altitude)
			local landerAltitude = altitude(lander)
			local drawImage
			if landerAltitude < 30 then
				drawImage = shipImage[5]
			elseif landerAltitude < 50 then
				drawImage = shipImage[4]
			elseif landerAltitude < 70 then
				drawImage = shipImage[3]
			elseif landerAltitude < 90 then
				drawImage = shipImage[2]
			else
				drawImage = shipImage[1]
			end

			-- TODO: work out why ship.width doesn't work in mplayer mode
			love.graphics.draw(drawImage.image, x,y, math.rad(lander.angle), sx, sy, ox, oy)

			-- draw flames
			local ox = 17	-- the x offset actually makes the flame higher/low because the image is rotated
			local oy = 15
			local sx, sy = 1.5, 1.5
			if lander.engineOn then
				local angle = math.rad(lander.angle)
				love.graphics.draw(flame.image, x, y, angle, sx, sy, ox, oy)
				lander.engineOn = false
			end

			if lander.leftEngineOn then
				local ox = 15	-- the x offset actually makes the flame higher/low because the image is rotated
				local oy = 15
				local angle = math.rad(lander.angle + 90)
				love.graphics.draw(flame.image, x, y, angle, sx, sy, ox, oy)
				lander.leftEngineOn = false
			end
			if lander.rightEngineOn then
				local ox = 15	-- the x offset actually makes the flame higher/low because the image is rotated
				local oy = 15
				local angle = math.rad(lander.angle - 90)
				love.graphics.draw(flame.image, x, y, angle, sx, sy, ox, oy)
				lander.rightEngineOn = false
			end

			-- draw label
			love.graphics.setNewFont(10)
			love.graphics.print(lander.name, x + 17, y - 15)
			love.graphics.setColor(1,1,1,1)

			-- draw bubble text above lander
			drawBubbleText(dt)

			if landerId == 1 then
				drawGuidance(lander)
			end

			love.graphics.circle("line", predictedx - WORLD_OFFSET, predictedy, 5)
			love.graphics.circle("line", predictedx - WORLD_OFFSET, perfecty, 10)
		end
	end
end

function Lander.keypressed(key, scancode, isrepeat)
	-- Let the player buy upgrades when landed on a fuel base
	local lander = LANDERS[1]

	-- TODO: simplify this code
	if key ~= nil and tonumber(key) ~= nil then
		if tonumber(key) > 0 and tonumber(key) <= #SHOP_MODULES then
			if Lander.isOnLandingPad(lander, Enum.basetypeFuel) then
				buyModule(SHOP_MODULES[tonumber(key)], lander)
			end
		end
	end
end


return Lander
