
return {
    -- Constants
    constSmokeTimer = 0.5,
    constVYThreshold = 0.60,
    constGravity = 0.6,

    -- enumerators
    basetypeFuel = 2,

    -- TODO: Get rid of those by doing something similar to scripts/modules.lua
    -- this is when we don't care about building1 or building2 i.e. any building (but not fuel)
    basetypeBuilding = 6,
    basetypeBuilding1 = 7,
    basetypeBuilding2 = 8,
    baseMaxFuel = 15,

	-- miscellaneous
	rangefinderMaximumDistance = 4000,

	-- module ID's
	moduleEfficientThrusters = 1,
	moduleLargeTank = 2,
	moduleRangefinder = 3,
	moduleSideThrusters = 4,
	moduleParachute = 5,
    moduleGuidance = 6,

	AIActionNothing = 0,
	AIActionWait = 1,
	AIActionThrust180 = 2,
	AIActionThrust210 = 3,
	AIActionThrust240 = 4,
	AIActionThrust270 = 5,
	AIActionThrust300 = 6,
	AIActionThrust330 = 7,
	AIActionThrust360 = 8,

	AIActionNumbers = 8,		-- this is the maximumn number of options. Set to the last AIAction enum value

    AIMeasureTimer = 0.2        -- how frequently to measure AI actions


}
