local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Rodux = require(ReplicatedStorage.Packages.Rodux)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)

local LocalPlayer = Players.LocalPlayer

local function deserializeAction(serialized, actionType)
    local serializers = RoduxFeatures.serializers[actionType]
    if serializers then
        return serializers.deserialize(serialized)
    end

    error(("No deserializer for action %q"):format(string.byte(actionType)))
end

local function makeClientMiddleware(requestRemote)
    return function(nextDispatch)
        return function(action)
            local meta = action.meta
            if meta and meta.realm == "server" then
                return
            end
    
            if meta and meta.serverRemote and not meta.dispatchedByServer then
                requestRemote:FireServer(unpack(meta.serverRemote))
    
                if meta.interestedUserIds and not table.find(meta.interestedUserIds, LocalPlayer.UserId) then
                    return
                end
            end
    
            nextDispatch(action)
        end
    end
end

local function roduxClient(root)
    local initStateRemote = root:getRemoteEvent("Rodux_InitState")
    local requestRemote = root:getRemoteEvent("Rodux_Request")
    local actionDispatchedRemote = root:getRemoteEvent("Rodux_ActionDispatched")

    initStateRemote.OnClientEvent:Connect(function(state)
        local deserialized = RoduxFeatures.reducer({}, RoduxFeatures.actions.deserialize(state))

        root.Store = Rodux.Store.new(
            RoduxFeatures.reducer,
            deserialized,
            { Rodux.thunkMiddleware, makeClientMiddleware(requestRemote) }
        )
    end)

    actionDispatchedRemote.OnClientEvent:Connect(function(action, serializedType)
        local resolvedAction = action
        if type(action) == "string" then
            resolvedAction = deserializeAction(action, serializedType)
        end

        resolvedAction.meta = resolvedAction.meta or {}
        resolvedAction.meta.dispatchedByServer = true

        root.Store:dispatch(resolvedAction)
    end)
end

return roduxClient