-- ~~~~~~~~~~~
-- Module.lua
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Modules for Mars Lander
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local NewModules = {}



function NewModules.createModules()

    SHOP_MODULES = {}

    SHOP_MODULES[Enum.moduleEfficientThrusters] = {}
    SHOP_MODULES[Enum.moduleEfficientThrusters].name = "Efficient thrusters"
    SHOP_MODULES[Enum.moduleEfficientThrusters].cost = 225
    SHOP_MODULES[Enum.moduleEfficientThrusters].mass = 20

    SHOP_MODULES[Enum.moduleLargeTank] = {}
    SHOP_MODULES[Enum.moduleLargeTank].name = "Large fuel tank"
    SHOP_MODULES[Enum.moduleLargeTank].cost = 200
    SHOP_MODULES[Enum.moduleLargeTank].mass = 10
    SHOP_MODULES[Enum.moduleLargeTank].fuelCapacity = 32
    SHOP_MODULES[Enum.moduleLargeTank].fuelCapacity = 32

    SHOP_MODULES[Enum.moduleRangefinder] = {}
    SHOP_MODULES[Enum.moduleRangefinder].name = "Rangefinder"
    SHOP_MODULES[Enum.moduleRangefinder].cost = 175
    SHOP_MODULES[Enum.moduleRangefinder].mass = 5

    SHOP_MODULES[Enum.moduleSideThrusters] = {}
    SHOP_MODULES[Enum.moduleSideThrusters].name = "Side thrusters"
    SHOP_MODULES[Enum.moduleSideThrusters].cost = 185
    SHOP_MODULES[Enum.moduleSideThrusters].mass = 20

    SHOP_MODULES[Enum.moduleParachute] = {}
    SHOP_MODULES[Enum.moduleParachute].name = "Parachute (single use)"
    SHOP_MODULES[Enum.moduleParachute].cost = 100
    SHOP_MODULES[Enum.moduleParachute].mass = 10
    SHOP_MODULES[Enum.moduleParachute].deployed = false
    SHOP_MODULES[Enum.moduleParachute].allowed = true
end

return NewModules
