local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = require(ReplicatedStorage.Common.Root)
local Rodux = require(ReplicatedStorage.Packages.Rodux)

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)

local RoduxController = {
	Name = "RoduxController";
}

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

function RoduxController:OnInit()
    local RoduxService = Root:GetServerService("RoduxService")

    RoduxService.InitState:Connect(function(state)
        Root.Store = Rodux.Store.new(
            RoduxFeatures.reducer,
            deserialize(state),
            { Rodux.thunkMiddleware }
        )
    end)

    RoduxService.ActionDispatched:Connect(function(action)
        Root.Store:dispatch(action)
    end)
end

return RoduxController