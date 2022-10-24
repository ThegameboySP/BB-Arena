local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local IsDebug = RunService:IsStudio() and ReplicatedStorage:FindFirstChild("Configuration"):GetAttribute("IsDebug")

local Rodux = require(ReplicatedStorage.Packages.Rodux)
local t = require(ReplicatedStorage.Packages.t)

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local actions = RoduxFeatures.actions
local actionReplicators = require(script.actionReplicators)

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

local function serializeAction(action, state, userIds)
    local serializers = RoduxFeatures.serializers[action.type]
    
    if serializers then
        local serialized
        if serializers.serialize then
            serialized = serializers.serialize(action, state)
        end

        local actionMap
        local replicator = actionReplicators[action.type]
        if replicator and replicator.replicate then
            actionMap = replicator.replicate(userIds, action, state, serialized)
        else
            actionMap = {}
            for _, userId in userIds do
                actionMap[userId] = serialized or action
            end
        end

        return actionMap, serializers.id
    end

    local actionMap = {}
    for _, userId in userIds do
        actionMap[userId] = action
    end

    return actionMap
end

local function getUserIds()
    local userIds = {}
    for _, player in Players:GetPlayers() do
        table.insert(userIds, player.UserId)
    end

    return userIds
end

local function makeServerMiddleware(actionDispatchedRemote, root)
    return function(nextDispatch)
        return function(action)
            local meta = action.meta
            if meta and meta.realm == "client" then
                return
            end
    
            if not meta or meta.realm ~= "server" then
                local userIds = meta and meta.interestedUserIds or getUserIds()
                local actionMap, serializedType = serializeAction(action, root.Store:getState(), userIds)

                for userId, userAction in actionMap do
                    local player = Players:GetPlayerByUserId(userId)

                    if player and player:GetAttribute("RoduxStateInitialized") then
                        if type(userAction) == "table" and userAction.type then
                            actionDispatchedRemote:FireClient(player, userAction)
                        else
                            actionDispatchedRemote:FireClient(player, userAction, serializedType)
                        end
                    end
                end
            end
    
            nextDispatch(action)
        end
    end
end

local function deserializeAction(serialized, actionType, state)
    local serializers = RoduxFeatures.serializers[actionType]
    if serializers then
        return serializers.deserialize(serialized, state)
    end
end

local actionChecker = t.interface({
    type = t.string;
    payload = t.table;
})

local function roduxServer(root)
    local initStateRemote = root:getRemoteEvent("Rodux_InitState")
    local requestRemote = root:getRemoteEvent("Rodux_Request")
    local actionDispatchedRemote = root:getRemoteEvent("Rodux_ActionDispatched")

    root.Store = Rodux.Store.new(
        RoduxFeatures.reducer,
        nil,
        { Rodux.thunkMiddleware, makeServerMiddleware(actionDispatchedRemote, root), IsDebug and RoduxFeatures.middlewares.loggerMiddleware or nil }
    )

    root.Store:dispatch(actions.merge(initState()))

    local function onPlayerAdded(player)
        local serialized = RoduxFeatures.reducer(root.Store:getState(), RoduxFeatures.actions.serialize(player.UserId))
        initStateRemote:FireClient(player, serialized)
        player:SetAttribute("RoduxStateInitialized", true)
    end

    Players.PlayerAdded:Connect(onPlayerAdded)
    for _, player in pairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end

    requestRemote.OnServerEvent:Connect(function(client, action, serializedType)
        if type(action) == "string" and serializedType then
            local ok, deserialized = pcall(deserializeAction, action, serializedType)
            if not ok then
                return
            end

            action = deserialized
        end

        if not actionChecker(action) then
            return
        end

        local replicators = actionReplicators[action.type]

        if replicators and replicators.request then
            local toDispatch = replicators.request(client.UserId, action)
            
            if toDispatch then
                root.Store:dispatch(toDispatch)
            end
        end
    end)
end

return roduxServer