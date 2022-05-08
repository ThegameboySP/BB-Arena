local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Rodux = require(ReplicatedStorage.Packages.Rodux)

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)

local RoduxController = Knit.CreateController({
	Name = "RoduxController";
})

local function stringIndicesToNumber(map)
    local numberMap = {}
    for str, value in pairs(map) do
        numberMap[tonumber(str)] = value
    end

    return numberMap
end

local function deserialize(state)
    for key, value in pairs(state.users) do
        if type(value) == "table" then
            state.users[key] = stringIndicesToNumber(value)
        end
    end

    return state
end

function RoduxController:KnitInit()
    local RoduxService = Knit.GetService("RoduxService")

    RoduxService.InitState:Connect(function(state)
        Knit.Store = Rodux.Store.new(
            RoduxFeatures.reducer,
            deserialize(state),
            { Rodux.thunkMiddleware }
        )
    end)

    RoduxService.ActionDispatched:Connect(function(action)
        Knit.Store:dispatch(action)
    end)
end

return RoduxController