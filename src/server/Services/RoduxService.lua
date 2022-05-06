local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")


local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Rodux = require(ReplicatedStorage.Packages.Rodux)

local GameEnum = require(ReplicatedStorage.Common.GameEnum)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local actions = RoduxFeatures.actions
local defaultPermissions = require(ServerScriptService.Server.defaultPermissions)

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
    clone.users = table.clone(state.users)
    for key, value in pairs(state.users) do
        clone.users[key] = numberIndicesToString(value)
    end

    return clone
end

local function initState()
    local admins = table.clone(defaultPermissions.Admins)

    local ownerId = game.PrivateServerOwnerId
	if ownerId then
        admins[ownerId] = GameEnum.AdminTiers.Admin
	end

    return {
        users = {
            admins = admins;
        }
    }
end

function RoduxService:KnitInit()
    Knit.Store = Rodux.Store.new(
        RoduxFeatures.reducer,
        nil,
        { Rodux.thunkMiddleware, self:_makeNetworkMiddleware() }
    )

    Knit.Store:dispatch(actions.merge(initState()))

    local function onPlayerAdded(player)
        self.Client.InitState:Fire(player, serialize(Knit.Store:getState()))
        player:SetAttribute("RoduxStateInitialized", true)
    end

    Players.PlayerAdded:Connect(onPlayerAdded)
    for _, player in pairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end
end

function RoduxService:_makeNetworkMiddleware()
    return function (nextDispatch)
        return function (action)
            self.Client.ActionDispatched:FireFilter(function(player)
                return player:GetAttribute("RoduxStateInitialized") == true 
            end, action)
    
            nextDispatch(action)
        end
    end
end

return RoduxService