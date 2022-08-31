local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Rodux = require(ReplicatedStorage.Packages.Rodux)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)

local LocalPlayer = Players.LocalPlayer

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
            -- Assume this key is a UserId.
            local tableKey = next(value)
            if type(tableKey) == "string" and tonumber(tableKey) then
                state.users[key] = stringIndicesToNumber(value)
            end
        end
    end

    return state
end

local function makeClientMiddleware(requestRemote)
    return function(nextDispatch)
        return function(action)
            local meta = action.meta
            if meta and meta.realm == "server" then
                return
            end
    
            if meta and meta.serverRemote then
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
        root.Store = Rodux.Store.new(
            RoduxFeatures.reducer,
            deserialize(state),
            { Rodux.thunkMiddleware, makeClientMiddleware(requestRemote) }
        )
    end)

    actionDispatchedRemote.OnClientEvent:Connect(function(action)
        root.Store:dispatch(action)
    end)
end

return roduxClient