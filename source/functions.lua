local functions = {}

local function setDefaultGameConfigs()
	-- sets all game configs to default settings

	GAME_CONFIG = {}
	GAME_CONFIG.showDEBUG = false
	GAME_CONFIG.allowParachutes = true
	GAME_CONFIG.useAdvancedPhysics = false
	GAME_CONFIG.easyMode = false
	GAME_CONFIG.music = true
	GAME_CONFIG.allowGuidance = true
	GAME_CONFIG.botOn = true
	GAME_CONFIG.AIOn = true
end

function functions.configureModules()
	-- modules need to be activated once GAME_SETTINGS is loaded
	-- cycle through all modules and set ACTIVE on those that are configurable

	for _,module in pairs(SHOP_MODULES) do
		if module.id == Enum.moduleParachute then
			module.allowed = GAME_CONFIG.allowParachutes
		end
	end
end

function functions.quitGame()
	-- cleans up before quiting the game

	if ENET_IS_CONNECTED then
		-- test if pressing ESC on main screen (i.e. quiting)
		if #CURRENT_SCREEN == 1 then
			if IS_A_CLIENT then
				EnetHandler.disconnectClient(LANDERS[1].connectionID)
			elseif IS_A_HOST then
				EnetHandler.disconnectHost()
			else
				error("Error 10 occured while player disconnected.")
			end
		end
	end
	love.event.quit()
end

function functions.AddScreen(strNewScreen)
	table.insert(CURRENT_SCREEN, strNewScreen)
end

function functions.RemoveScreen()
	if #CURRENT_SCREEN == 1 then
		functions.quitGame()
	end

	-- save settings if leaving the settings screen
	strCurrentScreen = CURRENT_SCREEN[#CURRENT_SCREEN]
	if strCurrentScreen == "Settings" then
		Fun.SaveGameSettings()
		Fun.SaveGameConfig()
	end
	table.remove(CURRENT_SCREEN)
end

function functions.CurrentScreenName()
	-- returns the current active screen
	return CURRENT_SCREEN[#CURRENT_SCREEN]
end

function functions.SwapScreen(newscreen)
	-- swaps screens so that the old screen is removed from the stack
	-- this adds the new screen then removes the 2nd last screen.

    Fun.AddScreen(newscreen)
    table.remove(CURRENT_SCREEN, #CURRENT_SCREEN - 1)
end

function functions.SaveGameConfig()
	-- save game settings so they can be autoloaded next session
	local savefile
	local serialisedString
	local success, message
	local savedir = love.filesystem.getSource()

    savefile = savedir .. "/savedata/" .. "gameconfig.dat"
    serialisedString = Bitser.dumps(GAME_CONFIG)
    success, message = Nativefs.write(savefile, serialisedString )
end

function functions.LoadGameConfig()
    local savedir = love.filesystem.getSource()
    love.filesystem.setIdentity( savedir )

    local savefile, contents

    savefile = savedir .. "/savedata/" .. "gameconfig.dat"
    contents, _ = Nativefs.read(savefile)
	local success
    success, GAME_CONFIG = pcall(Bitser.loads, contents)		--! should do pcall on all the "load" functions

	if success == false then
		setDefaultGameConfigs()
	end

	-- turn on and off modules
	Fun.configureModules()
end

function functions.SaveGameSettings()
	-- save game settings so they can be autoloaded next session
	local savefile
	local serialisedString
	local success, message
	local savedir = love.filesystem.getSource()

    savefile = savedir .. "/savedata/" .. "settings.dat"
    serialisedString = Bitser.dumps(GAME_SETTINGS)
    success, message = Nativefs.write(savefile, serialisedString )

	savefile = savedir .. "/savedata/" .. "qtable.dat"
    serialisedString = Bitser.dumps(qtable)
    success, message = Nativefs.write(savefile, serialisedString )
end

function functions.LoadGameSettings()
	-- is loaded during love.load

    local savedir = love.filesystem.getSource()
    love.filesystem.setIdentity( savedir )

    local savefile, contents

    savefile = savedir .. "/savedata/" .. "settings.dat"
    contents, _ = Nativefs.read(savefile)
	local success
    success, GAME_SETTINGS = pcall(Bitser.loads, contents)		--! should do pcall on all the "load" functions
	if success == false then
		GAME_SETTINGS = {}
	end

	savefile = savedir .. "/savedata/" .. "qtable.dat"
    contents, _ = Nativefs.read(savefile)
	local success
    success, qtable = pcall(Bitser.loads, contents)		--! should do pcall on all the "load" functions
	if success == false then
		qtable = {}
	end

	--If a player doesn't have 	-- a settings.dat already then all the values in GAME_SETTINGS table are
	-- nil. This sets some reasonable defaults to stop nil value crashes.
	if GAME_SETTINGS.PlayerName == nil then
		GAME_SETTINGS.PlayerName = DEFAULT_PLAYER_NAME
	end
	if GAME_SETTINGS.hostIP == nil then
		GAME_SETTINGS.hostIP = HOST_IP_ADDRESS
	end
	if GAME_SETTINGS.hostPort == nil then
		GAME_SETTINGS.hostPort = "22122"
	end
	if GAME_SETTINGS.FullScreen == nil then
		GAME_SETTINGS.FullScreen = false
	end
	if GAME_SETTINGS.HighScore == nil then
		GAME_SETTINGS.HighScore = 0
	end
	if GAME_SETTINGS.HighScoreName == nil then
		GAME_SETTINGS.HighScoreName = ""
	end

	-- Set the gloal player name to the new value
	CURRENT_PLAYER_NAME = GAME_SETTINGS.PlayerName
end

function functions.SaveGame()
	-- uses the globals because too hard to pass params

    local savefile
    local contents
    local success, message
    local savedir = love.filesystem.getSource()

    savefile = savedir .. "/savedata/" .. "landers.dat"
    serialisedString = Bitser.dumps(LANDERS)
    success, message = Nativefs.write(savefile, serialisedString )

    savefile = savedir .. "/savedata/" .. "ground.dat"
    serialisedString = Bitser.dumps(GROUND)
    success, message = Nativefs.write(savefile, serialisedString )

    savefile = savedir .. "/savedata/" .. "objects.dat"
    serialisedString = Bitser.dumps(OBJECTS)
    success, message = Nativefs.write(savefile, serialisedString )

	LovelyToasts.show("Game saved",3, "middle")
end

function functions.LoadGame()

    local savedir = love.filesystem.getSource()
    love.filesystem.setIdentity( savedir )

    local savefile
    local contents
	local size
	local error = false

	savefile = savedir .. "/savedata/" .. "ground.dat"
	if Nativefs.getInfo(savefile) then
		contents, size = Nativefs.read(savefile)
	    GROUND = bitser.loads(contents)
	else
		error = true
	end

    savefile = savedir .. "/savedata/" .. "objects.dat"
	if Nativefs.getInfo(savefile) then
		contents, size = Nativefs.read(savefile)
	    OBJECTS = bitser.loads(contents)
	else
		error = true
	end

    savefile = savedir .. "/savedata/" .. "landers.dat"
	if Nativefs.getInfo(savefile) then
	    contents, size = Nativefs.read(savefile)
	    LANDERS = bitser.loads(contents)
	else
		error = true
	end

	savefile = savedir .. "/savedata/" .. "qtable.dat"
	if Nativefs.getInfo(savefile) then
	    contents, size = Nativefs.read(savefile)
	    qtable = bitser.loads(contents)
	else
		error = true
	end

	if error then
		-- a file is missing, so display a popup on a new game
		Fun.ResetGame()
		LovelyToasts.show("ERROR: Unable to load game!", 3, "middle")
	end
end

function functions.CalculateScore()
	local score = LANDERS[1].x - ORIGIN_X

	if score > GAME_SETTINGS.HighScore then
		GAME_SETTINGS.HighScore = score
		Fun.SaveGameSettings() -- this needs to be refactored somehow, not save every change
	end

	return score
end

function functions.GetDistanceToClosestBase(xvalue, intBaseType)
	-- returns two values: the distance to the closest base, and the object/table item for that base
	-- if there are no bases (impossible) then the distance value returned will be -1
	-- note: if distance is a negative value then the Lander has not yet passed the base

	local closestdistance = -1
	local closestbase = {}
	local absdist
	local dist
	local realdist

	for k,v in pairs(OBJECTS) do
		if v.objecttype == intBaseType then
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

	-- now we have the closest base, work out the distance to the landing pad for that base
	if closestbase then
		-- the + bit is an offset to calculate the landing pad and not the image
		realdist = xvalue - (closestbase.x + 85)
	end

	return  realdist, closestbase
end


function functions.ResetGame()
	-- this resets the game for all landers - including multiplayer landers

	GROUND = {}
	OBJECTS = {}	-- TODO: don't reset whole table but instead reset status, fuel amounts etc.
	Smoke.destroy()

	-- ensure Terrain.init appears before Lander.create
	Terrain.init()

	-- TODO: mplayer needs to reset without wiping LANDERS
	--       or to wipe LANDERS and recreate each client

	if not ENET_IS_CONNECTED then
		LANDERS = {}
		table.insert(LANDERS, Lander.create())
		LANDERS[1].isPlayer = true
		-- capture the 'normal' mass of the lander into a global variable
		LANDERS[1].currentMass = Lander.getMass(LANDERS[1])

	end

	Fun.processBotsandAI()

end

function functions.getModule(moduleType)
	-- Input: an enum representing the required module type.  eg: moduleRangefinder
	-- OUtput: the module with that module baseType

	for k,v in pairs(SHOP_MODULES) do
		if v.id == moduleType then
			return v
		end
	end
	return nil
end

function functions.countActiveModules()
	-- returns a single count of the number of active modules (active as in set in the OPTIONS menu)
	local count = 0
	for k,module in ipairs(SHOP_MODULES) do
		if module.allowed == nil or module.allowed == true then
			count = count + 1
		end
	end
	return count
end

function functions.getActiveModuleIndexFromSequence(indexNumber)
	-- receive the a number and return the module index that is the x number in the list of modules
	-- NOTE: counts only active moduleSideThrusters
	-- eg: getActiveModuleIndexFromSequence(3) returns k where SHOP_MODULES[k] == the 3rd active module
	-- returns a number

	local i = 0
	for k,module in ipairs(SHOP_MODULES) do
		if module.allowed == nil or module.allowed == true then
			i = i + 1
			if i == indexNumber then
				-- found the module
				return k
			end
		end
	end
	return nil
end

function functions.getAltitude(lander)
	-- returns the lander's distance above the ground
	local landerYValue = lander.y
	local groundYValue = GROUND[Cf.round(lander.x,0)]
	return groundYValue - landerYValue
end

function functions.processBotsandAI()
	-- makes sure bots and AI are on or off according to global setting
	if GAME_CONFIG.botOn then
		-- check if bot already exists
		local botexists = false
		for k,lander in pairs(LANDERS) do
			if lander.isBot then botexists = true end
		end
		if botexists then
			-- bot is on and bot exists. Do nothing.
		else
			local newLander = Lander.create()
			newLander.isBot = true
			newLander.name = "Bot"
			table.insert(LANDERS, newLander)
		end
	else
		-- ensure all bots are destroyed
		for k,lander in pairs(LANDERS) do
			if lander.isBot then
				table.remove(LANDERS, k)
			end
		end
	end

	if GAME_CONFIG.AIOn then
		-- check if AI already exists
		local AIexists = false
		for k,lander in pairs(LANDERS) do
			if lander.isAI then AIexists = true end
		end
		if AIexists then
			-- AI is on and AI exists. Do nothing.
		else
			local newLander = Lander.create()
			newLander.isAI = true
			newLander.name = "AI"
			table.insert(LANDERS, newLander)
		end
	else
		-- ensure all AI are destroyed
		for k,lander in pairs(LANDERS) do
			if lander.isAI then
				table.remove(LANDERS, k)
			end
		end
	end
end

return functions
