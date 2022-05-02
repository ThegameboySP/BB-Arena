local function selectBannedUsers(state)
    local bannedUsers = {}
    local whitelisted = state.gate.whitelisted

    for userId in pairs(state.gate.banned) do
        if not whitelisted[userId] then
            table.insert(bannedUsers, userId)
        end
    end

    return bannedUsers
end

local function isUserBanned(state, userId, bannerId)
    if state.gate.whitelisted[userId] then
        return false
    end

    local userAdmin = state.admins[userId] or 0
    local bannerAdmin = state.admins[bannerId] or 0
    return bannerAdmin > userAdmin
end

return {
    selectBannedUsers = selectBannedUsers;
    isUserBanned = isUserBanned;
}