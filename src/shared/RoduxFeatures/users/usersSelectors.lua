local function getAdmin(state, userId)
    return state.users.admins[userId] or 0
end

local function isReferee(state, userId)
    return state.users.referees[userId] or false
end

local function getUserBannedBy(state, userId)
    return state.users.banned[userId]
end

local function canUserBeKickedBy(state, userId, kickingUserId)
    return getAdmin(state, kickingUserId) > getAdmin(state, userId)
end

local function canUserBeLockKicked(state, userId)
    local lockedBy = state.users.serverLockedBy

    local whitelistedBy = state.users.whitelisted[userId]
    if getAdmin(state, whitelistedBy) >= getAdmin(state, lockedBy) then
        return false
    end

    return canUserBeKickedBy(state, userId, lockedBy)
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
    isReferee = isReferee;
    isUserBanned = isUserBanned;
    getUserBannedBy = getUserBannedBy;
    canUserBeKickedBy = canUserBeKickedBy;
    canUserBeLockKicked = canUserBeLockKicked;
}