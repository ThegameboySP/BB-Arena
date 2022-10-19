local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local GameEnum = require(ReplicatedStorage.Common.GameEnum)

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

local function getSavedSetting(state, userId, settingId)
    local default = GameEnum.Settings[settingId].default

    local userSettings = state.users.userSettings[userId or LocalPlayer and LocalPlayer.UserId or 0]
    if userSettings then
        return if userSettings[settingId] ~= nil then userSettings[settingId] else default
    end

    return default
end

local function getLocalSetting(state, settingId)
    local overriddedSetting = state.users.locallyEditedSettings[settingId]
    if overriddedSetting ~= nil then
        return overriddedSetting
    end

    return getSavedSetting(state, LocalPlayer and LocalPlayer.UserId or 0, settingId)
end

return {
    getAdmin = getAdmin;
    isReferee = isReferee;
    isUserBanned = isUserBanned;
    getUserBannedBy = getUserBannedBy;
    canUserBeKickedBy = canUserBeKickedBy;
    canUserBeLockKicked = canUserBeLockKicked;
    getLocalSetting = getLocalSetting;
    getSavedSetting = getSavedSetting;
}