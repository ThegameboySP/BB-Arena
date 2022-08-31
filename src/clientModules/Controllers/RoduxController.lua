local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Root = require(ReplicatedStorage.Common.Root)
local Rodux = require(ReplicatedStorage.Packages.Rodux)

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)

local RoduxController = {
	Name = "RoduxController";
}

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
            state.users[key] = stringIndicesToNumber(value)
        end
    end

    return state
end

local function clientMiddleware(nextDispatch)
    return function(action)
        local meta = action.meta
        if meta and meta.realm == "server" then
            return
        end

        if meta and meta.serverRemote then
            Root:GetServerService("RoduxService")[meta.serverRemote[1]]:FireServer(unpack(meta.serverRemote, 2))

            if meta.interestedUserIds and not table.find(meta.interestedUserIds, LocalPlayer.UserId) then
                return
            end
        end

        nextDispatch(action)
    end
end

function RoduxController:OnInit()
    local RoduxService = Root:GetServerService("RoduxService")

    RoduxService.InitState:Connect(function(state)
        Root.Store = Rodux.Store.new(
            RoduxFeatures.reducer,
            deserialize(state),
            { Rodux.thunkMiddleware, clientMiddleware }
        )
    end)

    RoduxService.ActionDispatched:Connect(function(action)
        Root.Store:dispatch(action)
    end)
end

return RoduxController