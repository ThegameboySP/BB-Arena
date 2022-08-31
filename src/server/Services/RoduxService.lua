local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Root = require(ReplicatedStorage.Common.Root)
local Rodux = require(ReplicatedStorage.Packages.Rodux)

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local actions = RoduxFeatures.actions

local RoduxService = {
    Name = "RoduxService";
    Client = {
        ActionDispatched = Root.remoteEvent();
        InitState = Root.remoteEvent();

        SaveSettings = Root.remoteEvent();
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
    local place = ServerScriptService:FindFirstChild("Place")

    local defaultPermissions
    if place then
        defaultPermissions = place:FindFirstChild("DefaultPermissions")
        defaultPermissions = defaultPermissions and require(defaultPermissions)
    end

    return {
        users = {
            referees = defaultPermissions and table.clone(defaultPermissions.Referees) or {};
            admins = defaultPermissions and table.clone(defaultPermissions.Admins) or {};
        }
    }
end

local function mapPlayers(userIds)
    local players = {}
    for _, userId in userIds do
        table.insert(players, Players:GetPlayerByUserId(userId))
    end

    return players
end

local function serverMiddleware(nextDispatch)
    return function(action)
        local meta = action.meta
        if meta and meta.realm == "client" then
            return
        end

        if not meta or (meta.realm ~= "server" and not meta.dispatchedBy) then
            local players = if meta and meta.interestedUserIds then mapPlayers(meta.interestedUserIds) else Players:GetPlayers()
            
            for _, player in players do
                if player:GetAttribute("RoduxStateInitialized") then
                    RoduxService.Client.ActionDispatched:FireClient(player, action)
                end
            end
        end

        nextDispatch(action)
    end
end

function RoduxService:OnInit()
    Root.Store = Rodux.Store.new(
        RoduxFeatures.reducer,
        nil,
        { Rodux.thunkMiddleware, serverMiddleware }
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

    self.Client.SaveSettings:Connect(function(client, settings)
        if type(settings) ~= "table" then
            return
        end

        local action = actions.saveSettings(client.UserId, settings)
        action.meta = action.meta or {}
        action.meta.dispatchedBy = client
        action.meta.serverRemote = nil

        Root.Store:dispatch(action)
    end)
end

return RoduxService