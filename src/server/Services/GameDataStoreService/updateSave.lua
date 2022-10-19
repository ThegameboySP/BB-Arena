local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Llama = require(ReplicatedStorage.Packages.Llama)
local Dictionary = Llama.Dictionary

local function updateStats(new, old)
    old = old or {}
    
    local newStats = table.clone(old)

    for name, value in new do
        if type(value) == "number" and type(old[name]) == "number" then
            newStats[name] = old[name] + value
        else
            newStats[name] = value
        end
    end

    return newStats
end

local function updateSave(new, old)
    return Dictionary.merge(new, {
        stats = updateStats(new.stats, old and old.stats);
    })
end

return updateSave