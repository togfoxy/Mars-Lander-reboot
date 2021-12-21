-- ~~~~~~~~~~~
-- Module.lua
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Modules for Mars Lander
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local NewModules = {}



function NewModules.createModules()

    SHOP_MODULES = {}

    local myModule = {}
    myModule.id = Enum.moduleEfficientThrusters
    myModule.name = "Efficient thrusters"
    myModule.cost = 225
    myModule.mass = 20
    table.insert(SHOP_MODULES, myModule)

    myModule = {}
    myModule.id = Enum.moduleLargeTank
    myModule.name = "Large fuel tank"
    myModule.cost = 200
    myModule.mass = 10
    myModule.fuelCapacity = 32
    myModule.fuelCapacity = 32
    table.insert(SHOP_MODULES, myModule)

    myModule = {}
    myModule.id = Enum.moduleRangefinder
    myModule.name = "Rangefinder"
    myModule.cost = 175
    myModule.mass = 5
    table.insert(SHOP_MODULES, myModule)

    myModule = {}
    myModule.id = Enum.moduleSideThrusters
    myModule.name = "Side thrusters"
    myModule.cost = 185
    myModule.mass = 20
    table.insert(SHOP_MODULES, myModule)

    myModule = {}
    myModule.id = Enum.moduleParachute
    myModule.name = "Parachute (single use)"
    myModule.cost = 100
    myModule.mass = 10
    myModule.deployed = false
    myModule.allowed = true
    table.insert(SHOP_MODULES, myModule)

    myModule = {}
    myModule.id = Enum.moduleGuidance
    myModule.name = "Guidance unit"
    myModule.cost = 150
    myModule.mass = 5
    myModule.allowed = true
    table.insert(SHOP_MODULES, myModule)
end

return NewModules
