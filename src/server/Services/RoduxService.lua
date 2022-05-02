local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Rodux = require(ReplicatedStorage.Packages.Rodux)

local RoduxFeatures = ReplicatedStorage.Common.RoduxFeatures

local RoduxService = Knit.CreateService({
    Name = "RoduxService";
    Client = {
        ActionDispatched = Knit.CreateSignal();
        InitState = Knit.CreateSignal();
    };
})

local function numberIndicesToString(map)
    local strMap = {}
    for number, value in pairs(map) do
        strMap[tostring(number)] = value
    end

    return strMap
end

local function serialize(state)
    local clone = table.clone(state)
    clone.permissions = table.clone(state.permissions)
    clone.permissions.adminTiers = numberIndicesToString(state.permissions.adminTiers)
    return clone
end

function RoduxService:KnitInit()
    local reducers = {}

    for _, item in pairs(RoduxFeatures:GetChildren()) do
        if item:IsA("ModuleScript") then
            local reducer = require(item).reducer
            reducers[item.Name] = reducer
        end
    end

    Knit.Store = Rodux.Store.new(
        Rodux.combineReducers(reducers),
        {},
        { Rodux.thunkMiddleware, self:_makeNetworkMiddleware() }
    )

    Players.PlayerAdded:Connect(function(player)
        local state = Knit.Store:getState()
        self.Client.InitState:Fire(player, serialize(state))
        player:SetAttribute("StateInitialized", true)
    end)
end

function RoduxService:_makeNetworkMiddleware()
    return function (nextDispatch)
        return function (action)
            self.Client.ActionDispatched:FireFilter(function(player)
                return player:GetAttribute("StateInitialized") == true 
            end, action)
    
            nextDispatch(action)
        end
    end
end

return RoduxService