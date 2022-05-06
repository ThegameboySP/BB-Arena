local function getAdmin(state, userId)
    return state.users.admins[userId] or 0
end

local function getUserBannedBy(state, userId)
    return state.users.banned[userId]
end

local function canUserBeKickedBy(state, userId, kickingUserId)
    local kickerAdmin = state.users.admins[kickingUserId]
    if kickerAdmin == nil then
        return false
    end

    local whitelisted = state.users.whitelisted[userId]
    if whitelisted and getAdmin(whitelisted) >= kickerAdmin then
        return false
    end

    return kickerAdmin > getAdmin(state, userId)
end

local function isUserBanned(state, userId)
    local bannerId = state.users.banned[userId]
    if bannerId == nil then
        return false
    end
    
    return canUserBeKickedBy(state, userId, bannerId)
end

return {
    getAdmin = getAdmin;
    isUserBanned = isUserBanned;
    getUserBannedBy = getUserBannedBy;
    canUserBeKickedBy = canUserBeKickedBy;
}