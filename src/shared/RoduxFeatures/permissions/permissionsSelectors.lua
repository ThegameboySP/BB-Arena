local function canPromote(state, userId, tier)
	if state.bannedUsers[userId] then
		return false
	end
	
	return (state.admins[userId] or 0) < tier
end

local function hasAdminLevel(state, userId, tier)
	if state.bannedUsers[userId] then
		return false
	end

	return (state.admins[userId] or 0) >= tier
end

return {
    canPromote = canPromote;
    hasAdminLevel = hasAdminLevel;
}