local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CmdrUtils = require(ReplicatedStorage.Common.Utils.CmdrUtils)

local args = {{
	Type = "players";
	Name = "players";
	Description = "Players to set";  
}}

local function mapStats(stats, registered)
	local strings = {}

	for key in stats do
		if type(key) == "string" then
			strings[registered[key].friendlyName] = true
		end
	end

	return strings
end

local function getStatFromFriendlyName(stats, friendlyName)
	for _, stat in stats.registeredStats do
		if stat.friendlyName == friendlyName and stats.visibleRegisteredStats[stat.name] then
			return stat
		end
	end
end

local keyValueArgs = CmdrUtils.keyValueArgs("stat", 2, function(context)
	local state = context:GetStore("Common").Store:getState()
	return mapStats(state.stats.visibleRegisteredStats, state.stats.registeredStats)
end, function(_, name, context)
	local state = context:GetStore("Common").Store:getState()
	return {
		Type = type(getStatFromFriendlyName(state.stats, name).default);
		Name = name;
	}
end)

for _, arg in keyValueArgs do
	table.insert(args, arg)
end

return {
	Name = "setStat";
	Aliases = {"set"};
	Description = "Sets multiple players' stats.";
	Group = "Admin";
	Args = args;
}