local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Rodux = require(ReplicatedStorage.Packages.Rodux)

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local GameEnum = require(ReplicatedStorage.Common.GameEnum)
local actions = RoduxFeatures.actions

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

local function serializeAction(action)
    local serializers = RoduxFeatures.serializers[action.type]
    if serializers then
        return serializers.serialize(action), serializers.id
    end

    return action
end

local function makeServerMiddleware(actionDispatchedRemote)
    return function(nextDispatch)
        return function(action)
            local meta = action.meta
            if meta and meta.realm == "client" then
                return
            end
    
            if not meta or meta.realm ~= "server" then
                local players = if meta and meta.interestedUserIds then mapPlayers(meta.interestedUserIds) else Players:GetPlayers()
                
                local serialized, serializedType = serializeAction(action)

                for _, player in players do
                    if player:GetAttribute("RoduxStateInitialized") then
                        if type(serialized) == "table" then
                            actionDispatchedRemote:FireClient(player, serialized)
                        elseif type(serialized) == "string" then
                            actionDispatchedRemote:FireClient(player, serialized, serializedType)
                        end
                    end
                end
            end
    
            nextDispatch(action)
        end
    end
end

local function roduxServer(root)
    local initStateRemote = root:getRemoteEvent("Rodux_InitState")
    local requestRemote = root:getRemoteEvent("Rodux_Request")
    local actionDispatchedRemote = root:getRemoteEvent("Rodux_ActionDispatched")

    root.Store = Rodux.Store.new(
        RoduxFeatures.reducer,
        nil,
        { Rodux.thunkMiddleware, makeServerMiddleware(actionDispatchedRemote) }
    )

    root.Store:dispatch(actions.merge(initState()))

    local function onPlayerAdded(player)
        local serialized = RoduxFeatures.reducer(root.Store:getState(), RoduxFeatures.actions.serialize())
        initStateRemote:FireClient(player, serialized)
        player:SetAttribute("RoduxStateInitialized", true)
    end

    Players.PlayerAdded:Connect(onPlayerAdded)
    for _, player in pairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end

    requestRemote.OnServerEvent:Connect(function(client, remoteType, settings)
        if remoteType == "SaveSettings" then
            if type(settings) ~= "table" then
                return
            end

            local replicateSettings = {}
            for settingName, setting in settings do
                -- Client must have exploited to send this message.
                if not GameEnum.Settings[settingName] then
                    return
                end

                if GameEnum.Settings[settingName].replicateToAll then
                    replicateSettings[settingName] = setting
                end
            end

            local action = actions.saveSettings(client.UserId, settings)
            action.meta.interestedUserIds = {}
            action.meta.serverRemote = nil

            root.Store:dispatch(action)

            if next(replicateSettings) then
                local replicatedAction = actions.saveSettings(client.UserId, replicateSettings)
                replicatedAction.meta.interestedUserIds = {}

                for _, player in Players:GetPlayers() do
                    if player ~= client then
                        table.insert(replicatedAction.meta.interestedUserIds, player.UserId)
                    end
                end

                root.Store:dispatch(replicatedAction)
            end
        end
    end)
end

return roduxServer