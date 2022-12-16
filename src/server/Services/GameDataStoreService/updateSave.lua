local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Llama = require(ReplicatedStorage.Packages.Llama)
local Dictionary = Llama.Dictionary

local function updateStats(new, old)
	old = old or {}

	local newStats = table.clone(old)

	for name, value in new do
		if type(value) == "number" and type(old[name]) == "number" then
			newStats[name] = old[name] + value
		elseif type(value) == "table" then
			newStats[name] = updateStats(value, old[name])
		else
			newStats[name] = value
		end
	end

	return newStats
end

local function updateSave(new, old)
	return Dictionary.merge(new, {
		-- settings can have Llama.None in it (default), so it's important to call merge here.
		settings = Dictionary.merge(old and old.settings or {}, new.settings),
		stats = updateStats(new.stats, old and old.stats),
		timePlayed = (new.timePlayed or 0) + ((old and old.timePlayed) or 0),
	})
end

return updateSave
