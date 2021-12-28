local AI = {}

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

function AI.update(dt)
    if Fun.CurrentScreenName() == "World" then
        for k, lander in pairs(LANDERS) do
            if lander.isAI then
                -- GetCurrentState(lander)
                -- DetermineAction(lander, dt)
            end
        end
    end
end

return AI