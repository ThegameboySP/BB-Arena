local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rodux = require(ReplicatedStorage.Packages.Rodux)
local Llama = require(ReplicatedStorage.Packages.Llama)

local Dictionary = Llama.Dictionary

return Rodux.createReducer({}, {
    stats_incrementUser = function(state, action)
        local newStats = Dictionary.copyDeep(state)
        local userId = action.payload.userId

        for category, increment in pairs(action.payload.stats) do
            newStats[category][userId] = (newStats[category][userId] or 0) + increment
        end

        return newStats
    end;
    stats_setUser = function(state, action)
        local newStats = Dictionary.copyDeep(state)
        local userId = action.payload.userId

        for category, value in pairs(action.payload.stats) do
            newStats[category][userId] = value
        end

        return newStats
    end;
    stats_removeCategory = function(state, action)
        local newStats = table.clone(state)
        newStats[action.payload] = nil

        return newStats
    end;
    stats_removeUser = function(state, action)
        local newStats = Dictionary.copyDeep(state)
        local userId = action.payload

        for category in pairs(state) do
            newStats[category][userId] = nil
        end

        return newStats
    end;
})