
-- ~~~~~~~~~~~~~~~~~~
-- Mars Lander (2021)
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- https://github.com/togfoxy/MarsLander
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

GAME_VERSION = "1.05"

love.window.setTitle("Mars Lander " .. GAME_VERSION)

-- Directly release messages generated with e.g print for instant feedback
io.stdout:setvbuf("no")

-- Global screen dimensions
SCREEN_WIDTH = 1920
SCREEN_HEIGHT = 1080
-- W = function() return SCREEN_WIDTH end
-- H = function() return SCREEN_HEIGHT end


-- ~~~~~~~~~~~
-- Libraries
-- ~~~~~~~~~~~

Inspect = require 'lib.inspect'
-- https://github.com/kikito/inspect.lua

-- https://love2d.org/wiki/TLfres
-- TLfres = require 'lib.tlfres'

-- https://github.com/coding-jackalope/Slab/wiki
Slab = require 'lib.Slab.Slab'

-- https://github.com/gvx/bitser
Bitser = require 'lib.bitser'

-- https://github.com/megagrump/nativefs
Nativefs = require 'lib.nativefs'

-- https://github.com/camchenry/Sock.lua
Sock = require 'lib.sock'

-- https://github.com/Loucee/Lovely-Toasts
LovelyToasts = require 'lib.lovelyToasts'

-- Gunroar's modified paddy.lua
_class = require 'lib.class'
Paddy = require 'lib.paddy'

-- https://gist.github.com/Vovkiv/c1b3216a07ec642c017200d571a35cc8
Aspect = require("lib.aspect")

-- Common functions
Cf = require 'lib.commonfunctions'

-- Our asset-loader
Assets = require 'lib.assetloader'

-- Gunroar's cheap OS check
OS = require 'lib.oscheck'

-- ~~~~~~~~
-- Assets
-- ~~~~~~~~~

-- Load assets
Assets.loadDirectory("assets")

-- Load fonts
Assets.newFont(14)
Assets.newFont(16)
Assets.newFont(18)
Assets.newFont(20)

-- ~~~~~~~~~~~~~~~~~~
-- Modules / Classes
-- ~~~~~~~~~~~~~~~~~~

-- TODO: Turn global modules / objects to local ones
-- Scripts
Enum		= require 'scripts.enum'		-- ensure Enum is declared first
NewModules  = require 'objects.module'

-- Objects
Smoke 		= require 'objects.smoke'		-- Smoke particles for objects
Lander 		= require 'objects.lander'
Base 		= require 'objects.base'
Building	= require 'objects.building'
Terrain 	= require 'objects.terrain'
-- Other
HUD			= require 'hud'
Cobjs		= require 'createobjects'
Fun			= require 'functions'
Menus		= require 'menus'
EnetHandler = require 'enetstuff'
Bot 		= require 'bot'
AI			= require 'AI'

-- ~~~~~~~~~~~~~~~~~
-- Global variables
-- ~~~~~~~~~~~~~~~~~

CURRENT_SCREEN = {}	-- Current screen / state the user is in

LANDERS = {}
GROUND = {}			-- stores the y value for the ground
OBJECTS = {}		-- stores objects that need to be drawn
SHOP_MODULES = {}
GAME_SETTINGS = {}	-- track game settings
GAME_CONFIG = {}	-- tracks the user defined settings for modules turned on and off
qtable = {}

-- this is the start of the world and the origin that we track as we scroll the terrain left and right
ORIGIN_X = Cf.round(SCREEN_WIDTH / 2, 0)
WORLD_OFFSET = ORIGIN_X

-- track speed of the lander to detect crashes etc
LANDER_VX = 0
LANDER_VY = 0

-- Default Player values
DEFAULT_PLAYER_NAME = 'Player Name'
CURRENT_PLAYER_NAME = DEFAULT_PLAYER_NAME

-- socket stuff
IS_A_CLIENT = false		-- defaults to NOT a client until the player chooses to connect to a host
IS_A_HOST = false			-- Will listen on load but is not a host until someone connects
ENET_IS_CONNECTED = false	-- Will become true when received an acknowledgement from the server
HOST_IP_ADDRESS = ""

-- ~~~~~~~~~~~~~~~~
-- Local variables
-- ~~~~~~~~~~~~~~~

local strCurrentScreen
-- local background = Assets.getImageSet("background1")
local background = Assets.getImageSet("bg_space_seamless_2")
local fground1a = Assets.getImageSet("bd_space_seamless_fl1")
local fground1b = Assets.getImageSet("bd_space_seamless_fl1")
local fground2a = Assets.getImageSet("bg_space_seamless_fl2")
local fground2b = Assets.getImageSet("bg_space_seamless_fl2")

-- ~~~~~~~~~~~~~~~~
-- Local functions
-- ~~~~~~~~~~~~~~~~

local function drawWallpaper()
	-- stretch or shrink the image to fit the window

	-- this is the current size of the window
	local screenwidth, screenheight = love.graphics.getDimensions( )

	local sx = screenwidth / background.width
	local sy = screenheight / background.height
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(background.image, 0, 0, 0, sx, sy)

	-- draw two fground1 side by side for parallax effect
	-- fground1 has two images side by Side
	-- this is fground1A and fground1B
	-- fground1A has an x value and fground1B has an
	local fground1aX = 0
	local fground1bX = screenwidth

	fground1aX = fground1aX - (WORLD_OFFSET / 25)
	fground1aX = fground1aX % (-1 * screenwidth)
	fground1bX = fground1aX + (fground1a.width * sx)

	love.graphics.draw(fground1a.image, fground1aX, 0, 0, sx, sy)
	love.graphics.draw(fground1b.image, fground1bX, 0, 0, sx, sy)

	-- do the same for fground2
	local fground2aX = 0
	local fground2bX = screenwidth

	fground2aX = fground2aX - (WORLD_OFFSET / 10)
	fground2aX = fground2aX % (-1 * screenwidth)
	fground2bX = fground2aX + (fground2a.width * sx)

	love.graphics.draw(fground2a.image, fground2aX, 0, 0, sx, sy)
	love.graphics.draw(fground2b.image, fground2bX, 0, 0, sx, sy)

	love.graphics.setColor(1, 1, 1, 1)
end

local function drawWorld()
	-- draw the surface
	Terrain.draw()
	-- draw world objects
	Building.draw()
	Base.draw()
	-- draw the lander
	Lander.draw()
	-- Draw smoke particles
	Smoke.draw()
	-- draw HUD elements
	HUD.draw()
end


-- ~~~~~~~~~~~~~~~
-- main callbacks
-- ~~~~~~~~~~~~~~~

function love.keypressed(key, scancode, isrepeat)
	-- Back to previous screen
	if key == "escape" then
		Fun.RemoveScreen()
	elseif strCurrentScreen == "World" then
		-- Restart the game. Different to reset a single lander
		if key == "r" then
			Fun.ResetGame()

		-- restart just the player lander (for mulitplayer)
		elseif key == "kpenter" or key == "return" then
			Lander.reset(LANDERS[1])

		-- Pause the game
		elseif key == "p" then
			Fun.AddScreen("Pause")

		-- Open options menu
		elseif key == "o" then
			Fun.AddScreen("Settings")
		elseif key == "t" then
			AI.printQTable(qtable)
		end

		-- update Lander keys
		Lander.keypressed(key, scancode, isrepeat)

	elseif strCurrentScreen == "Pause" then
		if key == "p" then
			Fun.RemoveScreen()
		end
	elseif strCurrentScreen == "Settings" then
		--! typing an 'o' in the player name will close the screen so disabling this code for now
		--if key == "o" then
			--Fun.RemoveScreen()
		--end
	end
end

function love.mousepressed( x, y, button, istouch, presses )
	strCurrentScreen = CURRENT_SCREEN[#CURRENT_SCREEN]
	if strCurrentScreen == "World" then
		HUD.mousepressed( x, y, button, istouch)
	end
end

function love.load()

    if love.filesystem.isFused() then

		-- nullify the assert function for performance reasons
		function assert() end

		-- display = monitor number (1 or 2)
		local flags = {fullscreen = true,display = 1,resizable = true, borderless = false}
        love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT, flags)
    else
		-- display = monitor number (1 or 2)
		local flags = {fullscreen = false,display = 1,resizable = true, borderless = false}
		love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT, flags)
    end

	local socket = require 'socket'	-- socket is native to LOVE but needs a REQUIRE
	HOST_IP_ADDRESS = socket.dns.toip(socket.dns.gethostname())

	GAME_SETTINGS.hostPort = "22122"

	-- Load settings
	Fun.LoadGameSettings()

	-- Restore full screen setting
	-- love.window.setFullscreen(GAME_SETTINGS.FullScreen)
	Aspect.setGame(SCREEN_WIDTH, SCREEN_HEIGHT)
	Aspect.setColor(0, 0, 0, 1)

	-- First screen / entry point
	Fun.AddScreen("MainMenu")

    -- Need to make canvas in or after love.load
    if PADDY then
        local self = PADDY

        self.dpad.canvas = love.graphics.newCanvas(self.dpad.w,self.dpad.h)
        self.buttons.canvas = love.graphics.newCanvas(self.buttons.w,self.buttons.h)
    end

	-- ensure Terrain.init appears before Lander.create (which is inside Fun.ResetGame)
	Terrain.init()
	NewModules.createModules()
	Fun.LoadGameConfig()	-- this has to come after createModules because it modifies modules

	-- Play music
	-- true for "isLooping"
	-- must come after LoadGameConfig()
	if GAME_CONFIG.music then
		Assets.playSound("menuTheme", true)
		Assets.getSound("menuTheme"):setVolume(.2)
	end

	Fun.ResetGame()

	LovelyToasts.options.queueEnabled = true

	-- Initalize GUI Library
	Slab.SetINIStatePath(nil)
	Slab.Initialize()

end

function love.draw()

	-- this comes BEFORE the TLfres.beginRendering
	drawWallpaper()

	-- TLfres.beginRendering(SCREEN_WIDTH,SCREEN_HEIGHT)
	Aspect.start()

	strCurrentScreen = Fun.CurrentScreenName()

	-- TODO: Add a Scene / Screen manager
	if strCurrentScreen == "MainMenu" then
		Menus.DrawMainMenu()
	end

	if strCurrentScreen == "World" then
		drawWorld()
	end

	if strCurrentScreen == "Credits" then
		Menus.DrawCredits()
	end

	if strCurrentScreen == "Pause" then
		drawWorld()
		HUD.drawPause() -- Display on top of world
	end

	if strCurrentScreen == "Settings" then
		Menus.DrawSettingsMenu()
	end

	--! can this be in an 'if' statement and not drawn if not on a SLAB screen?
	Slab.Draw()

	if PADDY then
	    PADDY:draw()
	end

	--* Put this AFTER the slab so that it draws over the slab
	LovelyToasts.draw()

	Aspect.stop()
end

function love.update(dt)

	strCurrentScreen = CURRENT_SCREEN[#CURRENT_SCREEN]

	if strCurrentScreen == "MainMenu"
	or strCurrentScreen == "Credits"
	or strCurrentScreen == "Settings" then
		Slab.Update(dt)
	end

	if strCurrentScreen == "World" or strCurrentScreen == "Pause" or strCurrentScreen == "Settings"then
	    if PADDY then
	        PADDY:update(dt)
	    end
		if strCurrentScreen == "World" then
			Lander.update(dt)
			Smoke.update(dt)
			Base.update(dt)
			Building.update(dt)
		end
	end

	EnetHandler.update(dt)
	LovelyToasts.update(dt)
	Bot.update(dt)
	AI.update(dt)
	Aspect.update()
end
