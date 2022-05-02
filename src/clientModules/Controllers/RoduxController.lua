local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Rodux = require(ReplicatedStorage.Packages.Rodux)

local RoduxFeatures = ReplicatedStorage.Common.RoduxFeatures

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
    state.permissions.adminTiers = stringIndicesToNumber(state.permissions.adminTiers)
    return state
end

function RoduxController:KnitInit()
    local RoduxService = Knit.GetService("RoduxService")
    local reducers = {}

    for _, item in pairs(RoduxFeatures:GetChildren()) do
        if item:IsA("ModuleScript") then
            local reducer = require(item).reducer
            reducers[item.Name] = reducer
        end
    end

    RoduxService.InitState:Connect(function(state)
        Knit.Store = Rodux.Store.new(
            Rodux.combineReducers(reducers),
            deserialize(state),
            { Rodux.thunkMiddleware }
        )
    end)

    RoduxService.ActionDispatched:Connect(function(action)
        Knit.Store:dispatch(action)
    end)
end

return RoduxController