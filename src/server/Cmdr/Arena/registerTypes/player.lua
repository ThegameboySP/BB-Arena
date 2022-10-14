local Players = game:GetService("Players")

local function shorthandSingle(text, executor)
	if text == "me" then
		return {executor}
	end
end

local function shorthandMultiple(text, executor)
	if text == "all" then
		return Players:GetPlayers()
	elseif text == "others" then
		local others = Players:GetPlayers()

		for i = 1, #others do
			if others[i] == executor then
				table.remove(others, i)
				break
			end
		end

		return others
	end
end

local function checkShorthands(text, executor, ...)
	for _, func in ipairs({...}) do
		local values = func(text, executor)

		if values then
            return values
        end
	end
end

local function getPlayerByName(name)
    local firstName, secondName = name:match("^([^@]+)@?(.*)$")
	
    if secondName == "" then
        return Players:FindFirstChild(firstName)
	else
    	return Players:FindFirstChild(secondName)
	end
end

local function getPlayersByNames(names)
	local players = {}
	local set = {}

	for _, name in ipairs(names) do
		local player = getPlayerByName(name)
		if player == nil or set[player] then
            continue
        end

		table.insert(players, player)
		set[player] = true
	end

	return players
end

local function mapNames(players)
	local names = {}

	for _, player in ipairs(players) do
        if player.Name == player.DisplayName then
            table.insert(names, player.DisplayName)
        else
            table.insert(names, player.DisplayName .. "@" .. player.Name)
		end
	end

	return names
end

local Util
local playerType = {
	Transform = function(text, executor)
		local shorthand = checkShorthands(text, executor, shorthandSingle)
		if shorthand then
			return mapNames(shorthand)
		end

		local findName = Util.MakeFuzzyFinder(mapNames(Players:GetPlayers()))

		return findName(text)
	end;

	Validate = function(names)
		if names[1] == nil or getPlayerByName(names[1]) == nil then
			return false, "No player with that name could be found."
		end

		return true
	end;

	Autocomplete = function(names)
		return mapNames(getPlayersByNames(names))
	end;

	Parse = function(names)
		return getPlayerByName(names[1])
	end;

	Default = function(executor)
		return mapNames({executor})[1]
	end;
}

return function(registry)
	Util = registry.Cmdr.Util

	local playersType = table.clone(playerType)
	playersType.Listable = true

	playersType.Transform = function(text, executor)
		local shorthand = checkShorthands(text, executor, shorthandSingle, shorthandMultiple)
		if shorthand then
			return mapNames(shorthand), true
		end

		local findNames = Util.MakeFuzzyFinder(mapNames(Players:GetPlayers()))

		return findNames(text)
	end

	playersType.Parse = function(names, returnAll)
		return returnAll and getPlayersByNames(names) or {getPlayerByName(names[1])}
	end

	registry:RegisterType("arenaPlayer", playerType)
	registry:RegisterType("arenaPlayers", playersType, {
		Prefixes = "% teamPlayers";
	})

	registry.Types.player = registry.Types.arenaPlayer
	registry.Types.players = registry.Types.arenaPlayers
end