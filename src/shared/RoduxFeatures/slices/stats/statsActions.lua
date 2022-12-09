local function setStatVisual(userId, name, value)
	return {
		type = "stats_setVisual",
		payload = {
			userId = userId,
			name = name,
			value = value,
		},
	}
end

local function incrementStat(userId, name, amount)
	return {
		type = "stats_increment",
		payload = {
			userId = userId,
			name = name,
			amount = amount,
		},
	}
end

local function resetUsersStats(userIds)
	return {
		type = "stats_resetUsers",
		payload = {
			userIds = userIds,
		},
	}
end

local function initializeUserStats(userId, stats)
	return {
		type = "stats_initializeUser",
		payload = {
			userId = userId,
			stats = stats,
		},
	}
end

return {
	setStatVisual = setStatVisual,
	incrementStat = incrementStat,
	resetUsersStats = resetUsersStats,
	initializeUserStats = initializeUserStats,
}
