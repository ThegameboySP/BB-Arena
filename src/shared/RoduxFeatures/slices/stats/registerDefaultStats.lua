local ReplicatedStorage = game:GetService("ReplicatedStorage")

local t = require(ReplicatedStorage.Packages.t)
local Gamemodes = ReplicatedStorage.Common.Gamemodes

local checkRegisteredStat = t.interface({
	default = t.any,
	name = t.string,
	friendlyName = t.string,
	priority = t.number,
	domain = t.optional(t.string),
	persistent = t.optional(t.boolean),
	show = t.optional(t.boolean),
	id = t.number,
})

local function registerDefaultStats()
	local defaultStats = {}
	local registeredStats = {
		KOs = { default = 0, priority = 1, show = true },
		WOs = { default = 0, priority = 0, show = true },
		AlltimeWins = { default = 0 },
		AlltimeLosses = { default = 0 },
		BestKillstreak = { default = 0 },
		-- XP = {default = 0};
		LongRange = { default = {} },
		MediumRange = { default = {} },
		CloseRange = { default = {} },
	}

	for _, gamemode in Gamemodes:GetChildren() do
		local definition = require(gamemode).definition

		for name, stat in definition.stats do
			if registeredStats[name] then
				error(string.format("Duplicate stat name: %q", name))
			end

			local clone = table.clone(stat)
			clone.gamemodeId = definition.nameId
			clone.name = name

			registeredStats[name] = clone
		end

		registeredStats[definition.nameId .. "Wins"] = { default = 0 }
		registeredStats[definition.nameId .. "Losses"] = { default = 0 }
	end

	local registeredStatArray = {}
	for id, stat in registeredStats do
		stat.priority = stat.priority or -1
		stat.name = stat.name or id
		stat.friendlyName = stat.friendlyName or stat.name

		table.insert(registeredStatArray, stat)
	end

	table.sort(registeredStatArray, function(a, b)
		return a.name > b.name
	end)

	for index, stat in registeredStatArray do
		stat.id = index
		assert(checkRegisteredStat(stat))

		registeredStats[stat.id] = stat
		defaultStats[stat.name] = stat.default
	end

	return registeredStats, defaultStats
end

return registerDefaultStats
