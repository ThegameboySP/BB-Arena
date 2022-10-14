local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CmdrUtils = require(ReplicatedStorage.Common.Utils.CmdrUtils)

local args = {{
	Type = "players";
	Name = "players";
	Description = "Players to set";  
}}

local keyValueArgs = CmdrUtils.keyValueArgs("stat", 2, function(context)
	local state = context:GetStore("Common").Store:getState()
	return state.stats.visibleRegisteredStats
end, function(_, name, context)
	local state = context:GetStore("Common").Store:getState()
	return {
		Type = type(state.stats.registeredStats[name].default);
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