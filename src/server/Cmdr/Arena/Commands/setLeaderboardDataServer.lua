local confirmTable = {}

local function getKey(...)
	return table.concat({ ... }, "_")
end

return function(context, userId, key, value)
	local confirmKey = getKey(tostring(userId), key, tostring(value))

	if confirmTable[context.Executor.UserId] ~= confirmKey then
		confirmTable[context.Executor.UserId] = confirmKey
		return "Are you sure you want to perform this action? Run the command again to confirm."
	end

	confirmTable[confirmKey] = nil

	local store = context:GetStore("Common").Store
	local place = store:getState().leaderboard.placeByUserId[userId]
	local oldValue
	if place then
		oldValue = store:getState().leaderboard.users[place][key]
	end

	context:GetStore("Common").Root:GetService("GameDataStoreService"):SetLeaderboardData(userId, key, value)

	return string.format(
		"%s: %q %s -> %d",
		tostring(userId),
		key,
		if oldValue then tostring(oldValue) else "unknown",
		value
	)
end
