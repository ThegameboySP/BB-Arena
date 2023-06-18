local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Rodux = require(ReplicatedStorage.Packages.Rodux)
local Llama = require(ReplicatedStorage.Packages.Llama)
local Dictionary = Llama.Dictionary

local Settings = require(ReplicatedStorage.Common.StaticData.Settings)
local RoduxUtils = require(script.Parent.Parent.Parent.RoduxUtils)

return Rodux.createReducer({
	serverLockedBy = nil,
	banned = {},
	whitelisted = {},
	admins = {},
	referees = {},
	activeUsers = {},

	usersFailedDatastore = {},

	userSettings = {},
	locallyEditedSettings = {},
	userSettingsToSave = {},
}, {
	-- Events
	users_joined = function(state, action)
		return Dictionary.mergeDeep(state, {
			activeUsers = {
				[action.payload.userId] = {
					name = action.payload.name,
					displayName = action.payload.displayName,
					joinedTimestamp = Workspace:GetServerTimeNow(),
					timePlayed = 0,
				},
			},
			userSettings = { [action.payload.userId] = {} },
			userSettingsToSave = { [action.payload.userId] = {} },
		})
	end,
	users_left = function(state, action)
		return Dictionary.mergeDeep(state, {
			activeUsers = { [action.payload.userId] = Llama.None },
			userSettings = { [action.payload.userId] = Llama.None },
			usersFailedDatastore = { [action.payload.userId] = Llama.None },
			userSettingsToSave = { [action.payload.userId] = Llama.None },
		})
	end,
	users_setTimePlayed = function(state, action)
		return Dictionary.mergeDeep(state, {
			activeUsers = { [action.payload.userId] = { timePlayed = action.payload.timePlayed } },
		})
	end,
	users_datastoreFetchFailed = function(state, action)
		return Dictionary.mergeDeep(state, {
			usersFailedDatastore = { [action.payload.userId] = true },
		})
	end,

	rodux_serialize = function(state, action)
		local serialized = {}

		serialized.banned = RoduxUtils.numberIndicesToString(state.banned)
		serialized.whitelisted = RoduxUtils.numberIndicesToString(state.whitelisted)
		serialized.admins = RoduxUtils.numberIndicesToString(state.admins)
		serialized.referees = RoduxUtils.numberIndicesToString(state.referees)
		serialized.activeUsers = RoduxUtils.numberIndicesToString(state.activeUsers)

		serialized.userSettings = {}

		for userId, userSettings in state.userSettings do
			if userId == action.payload.userId then
				serialized.userSettings[tostring(userId)] = userSettings
			else
				serialized.userSettings[tostring(userId)] = {
					weaponTheme = userSettings.weaponTheme,
				}
			end
		end

		return serialized
	end,
	rodux_deserialize = function(state, action)
		local serialized = action.payload.serialized.users
		local patch = {}

		patch.banned = RoduxUtils.stringIndicesToNumber(serialized.banned)
		patch.whitelisted = RoduxUtils.stringIndicesToNumber(serialized.whitelisted)
		patch.admins = RoduxUtils.stringIndicesToNumber(serialized.admins)
		patch.referees = RoduxUtils.stringIndicesToNumber(serialized.referees)
		patch.activeUsers = RoduxUtils.stringIndicesToNumber(serialized.activeUsers)
		patch.userSettings = RoduxUtils.stringIndicesToNumber(serialized.userSettings)

		return Dictionary.merge(state, patch)
	end,

	-- Settings
	users_saveSettings = function(state, action)
		local payload = action.payload

		local toSave = {}
		for id, value in payload.settings do
			if type(value) == "table" and value.default then
				toSave[id] = Llama.None
			else
				toSave[id] = value
			end
		end

		return Dictionary.mergeDeep(state, {
			userSettings = { [payload.userId] = toSave },
			userSettingsToSave = { [payload.userId] = toSave },
		})
	end,
	users_setLocalSetting = function(state, action)
		return Dictionary.mergeDeep(state, {
			locallyEditedSettings = { [action.payload.id] = action.payload.value },
		})
	end,
	users_flushSaveSettings = function(state)
		return Dictionary.merge(state, {
			locallyEditedSettings = {},
		})
	end,
	users_cancelLocalSettings = function(state, action)
		if action.payload.settings then
			local settingsToUndo = {}
			for settingName in action.payload.settings do
				settingsToUndo[settingName] = Llama.None
			end

			return Dictionary.mergeDeep(state, {
				locallyEditedSettings = settingsToUndo,
			})
		end

		return Dictionary.merge(state, {
			locallyEditedSettings = {},
		})
	end,
	users_cancelLocalSetting = function(state, action)
		return Dictionary.mergeDeep(state, {
			locallyEditedSettings = { [action.payload.id] = Llama.None },
		})
	end,
	users_restoreDefaultSettings = function(state, action)
		local default = { default = true }

		local defaultsById = {}
		for id in action.payload.settings or Settings do
			defaultsById[id] = default
		end

		return Dictionary.mergeDeep(state, {
			locallyEditedSettings = defaultsById,
		})
	end,

	-- Permissions/gatekeeping
	users_setAdmin = function(state, action)
		return Dictionary.mergeDeep(state, {
			admins = { [action.payload.userId] = action.payload.admin },
		})
	end,
	users_setReferee = function(state, action)
		return Dictionary.mergeDeep(state, {
			referees = { [action.payload.userId] = action.payload.isReferee or Llama.None },
		})
	end,
	users_setServerLocked = function(state, action)
		return Dictionary.merge(state, {
			serverLockedBy = if action.payload.isLocked then action.payload.userId else Llama.None,
		})
	end,
	users_setBanned = function(state, action)
		if action.payload.isBanned then
			return Dictionary.mergeDeep(state, {
				banned = {
					[action.payload.userId] = action.payload.byUser or true,
				},
			})
		else
			return Dictionary.mergeDeep(state, {
				banned = {
					[action.payload.userId] = Llama.None,
				},
			})
		end
	end,
	users_setWhitelisted = function(state, action)
		if action.payload.isWhitelisted then
			return Dictionary.mergeDeep(state, {
				whitelisted = {
					[action.payload.userId] = action.payload.byUser or true,
				},
			})
		else
			return Dictionary.mergeDeep(state, {
				whitelisted = {
					[action.payload.userId] = Llama.None,
				},
			})
		end
	end,
})
