local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Root = require(ReplicatedStorage.Common.Root)
local Rodux = require(ReplicatedStorage.Packages.Rodux)

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local actions = RoduxFeatures.actions
local defaultPermissions = require(ServerScriptService.Server.defaultPermissions)

local RoduxService = {
    Name = "RoduxService";
    Client = {
        ActionDispatched = Root.remoteEvent();
        InitState = Root.remoteEvent();
    };
}

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
        if type(value) == "table" then
            clone.users[key] = numberIndicesToString(value)
        end
    end

    return clone
end

local function initState()
    return {
        users = {
            referees = table.clone(defaultPermissions.Referees);
            admins = table.clone(defaultPermissions.Admins);
        }
    }
end

function RoduxService:OnInit()
    Root.Store = Rodux.Store.new(
        RoduxFeatures.reducer,
        nil,
        { Rodux.thunkMiddleware, self:_makeNetworkMiddleware() }
    )

    Root.Store:dispatch(actions.merge(initState()))

    local function onPlayerAdded(player)
        self.Client.InitState:FireClient(player, serialize(Root.Store:getState()))
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