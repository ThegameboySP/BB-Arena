local Players = game:GetService("Players")

local NAME_FORMAT = ("(%s+)@?(%s*)"):format("[^@]", ".")

local function ShorthandSingle (text, executor)
	if text == "me" then
		return {executor}
	elseif text == "?" then
		local players = Players:GetPlayers()
		return {players[math.random(1, #players)]}
	end
end

local function ShorthandMultiple (text, executor)
	if text == "*" or text == "all" then
		return Players:GetPlayers()
	elseif text == "others" then
		local Others = Players:GetPlayers()
		for i = 1, #Others do
			if Others[i] == executor then
				table.remove(Others, i)
				break
			end
		end
		return Others
	end

	local randomMatch = text:match("%?(%d+)")
	if randomMatch then
		local maxSize = tonumber(randomMatch)
		if maxSize and maxSize > 0 then
			local players = {}
			local remainingPlayers = Players:GetPlayers()
			for i = 1, math.min(maxSize, #remainingPlayers) do
				table.insert(players, table.remove(remainingPlayers, math.random(1, #remainingPlayers)))
			end

			return players
		end
	end
end

local function CheckShorthands (text, executor, ...)
	for _, func in pairs({...}) do
		local values = func(text, executor)

		if values then return values end
	end
end

local function getNames(players)
	local names = {}
	for _, player in ipairs(players) do
		local name, displayName = player.Name, player.DisplayName
		local fullName = displayName
		if name ~= displayName then
			fullName ..= "@" .. name
		end

		table.insert(names, fullName)
	end

	return names
end

local function getPlayerByDisplayName(displayName)
	local lastPlayerFound
	for _, player in pairs(Players:GetPlayers()) do
		if player.DisplayName == displayName then
			if lastPlayerFound then
				return nil
			end

			lastPlayerFound = player
		end
	end

	return lastPlayerFound
end

local function getPlayerByName(name)
	local displayName, name = name:match(NAME_FORMAT)
	return getPlayerByDisplayName(displayName) or Players:FindFirstChild(name)
end

local function getPlayersByNames(names)
	local players = {}
	local set = {}

	for _, name in ipairs(names) do
		local player = getPlayerByName(name)
		if player == nil then continue end
		if set[player] then continue end

		table.insert(players, player)
		set[player] = true
	end

	return players
end

local Util
local playerType = {
	Transform = function (text, executor)
		local shorthand = CheckShorthands(text, executor, ShorthandSingle)
		if shorthand then
			return getNames(shorthand)
		end

		local findName = Util.MakeFuzzyFinder(getNames(Players:GetPlayers()))

		return findName(text)
	end;

	Validate = function (names)
		if names[1] == nil then
			return false, "No player with that name could be found."
		end

		if getPlayerByName(names[1]) == nil then
			return false, "No player with that name could be found."
		end

		return true
	end;

	Autocomplete = function (names)
		return getNames(getPlayersByNames(names))
	end;

	Parse = function (names)
		return getPlayerByName(names[1])
	end;

	Default = function (executor)
		return executor.DisplayName .. "@" .. executor.Name
	end;
}

return function (registry)
	Util = registry.Cmdr.Util

	local arenaPlayers = Util.MakeListableType(playerType)
	arenaPlayers.Transform = function(text, executor)
		local shorthand = CheckShorthands(text, executor, ShorthandSingle, ShorthandMultiple)
		if shorthand then
			return getNames(shorthand), true
		end

		local findNames = Util.MakeFuzzyFinder(getNames(Players:GetPlayers()))

		return findNames(text)
	end

	arenaPlayers.Parse = function(names, returnAll)
		return returnAll and getPlayersByNames(names) or {getPlayerByName(names[1])}
	end

	registry:RegisterType("arenaPlayer", playerType)
	registry:RegisterType("arenaPlayers", arenaPlayers, {
		Prefixes = "% teamPlayers";
	})
end