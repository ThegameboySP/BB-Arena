local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Settings = require(ReplicatedStorage.Common.StaticData.Settings)

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

local function getDefaultForSetting(setting)
	return if UserInputService.TouchEnabled
			and setting.mobile
			and setting.mobile.default ~= nil
		then setting.mobile.default
		else setting.default
end

local function getSavedSetting(state, userId, settingId)
	if not Settings[settingId] then
		return nil
	end

	local default = getDefaultForSetting(Settings[settingId])

	local userSettings = state.users.userSettings[userId or LocalPlayer and LocalPlayer.UserId or 0]
	if userSettings then
		return if userSettings[settingId] ~= nil then userSettings[settingId] else default
	end

	return default
end

local function getLocalSetting(state, settingId)
	if not Settings[settingId] then
		return nil
	end

	local value = state.users.locallyEditedSettings[settingId]
	if value ~= nil then
		if type(value) == "table" and value.default then
			return getDefaultForSetting(Settings[settingId])
		else
			return value
		end
	end

	return getSavedSetting(state, LocalPlayer and LocalPlayer.UserId or 0, settingId)
end

return {
	getAdmin = getAdmin,
	isReferee = isReferee,
	isUserBanned = isUserBanned,
	getUserBannedBy = getUserBannedBy,
	canUserBeKickedBy = canUserBeKickedBy,
	canUserBeLockKicked = canUserBeLockKicked,
	getLocalSetting = getLocalSetting,
	getSavedSetting = getSavedSetting,
}
