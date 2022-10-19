local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rodux = require(ReplicatedStorage.Packages.Rodux)
local Llama = require(ReplicatedStorage.Packages.Llama)
local Dictionary = Llama.Dictionary

local GameEnum = require(ReplicatedStorage.Common.GameEnum)
local RoduxUtils = require(script.Parent.Parent.Parent.RoduxUtils)

local defaultSettings = {}
for key, value in GameEnum.Settings do
    defaultSettings[key] = value.default
end

return Rodux.createReducer({
    serverLockedBy = nil;
    banned = {};
    whitelisted = {};
    admins = {};
    referees = {};
    activeUsers = {};

    userSettings = {};
    locallyEditedSettings = {};
}, {
    -- Events
    users_joined = function(state, action)
        return Dictionary.mergeDeep(state, {
            activeUsers = {[action.payload.userId] = true};
            userSettings = {[action.payload.userId] = defaultSettings};
        })
    end;
    users_left = function(state, action)
        return Dictionary.mergeDeep(state, {
            activeUsers = {[action.payload.userId] = Llama.None};
        })
    end;

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
                    weaponTheme = userSettings.weaponTheme;
                }
            end
        end

        return serialized
    end;
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
    end;

    -- Settings
    users_saveSettings = function(state, action)
        local payload = action.payload

        return Dictionary.mergeDeep(state, {
            userSettings = {[payload.userId] = payload.settings};
        })
    end;
    users_setLocalSetting = function(state, action)
        return Dictionary.mergeDeep(state, {
            locallyEditedSettings = {[action.payload.id] = action.payload.value};
        })
    end;
    users_flushSaveSettings = function(state)
        return Dictionary.merge(state, {
            locallyEditedSettings = {};
        })
    end;
    users_cancelLocalSettings = function(state)
        return Dictionary.merge(state, {
            locallyEditedSettings = {};
        })
    end;
    users_cancelLocalSetting = function(state, action)
        return Dictionary.mergeDeep(state, {
            locallyEditedSettings = {[action.payload.id] = Llama.None}
        })
    end;
    users_restoreDefaultSettings = function(state)
        local defaultsById = {}
        for id, setting in GameEnum.Settings do
            defaultsById[id] = setting.default
        end

        return Dictionary.mergeDeep(state, {
            locallyEditedSettings = defaultsById;
        })
    end;

    -- Permissions/gatekeeping
    users_setAdmin = function(state, action)
        return Dictionary.mergeDeep(state, {
            admins = {[action.payload.userId] = action.payload.admin};
        })
    end;
    users_setReferee = function(state, action)
        return Dictionary.mergeDeep(state, {
            referees = {[action.payload.userId] = action.isReferee or Llama.None};
        })
    end;
    users_setServerLocked = function(state, action)
        return Dictionary.merge(state, {
            serverLockedBy = if action.payload.isLocked then action.payload.userId else Llama.None;
        })
    end;
    users_setBanned = function(state, action)
        if action.payload.isBanned then
            return Dictionary.mergeDeep(state, {
                banned = {
                    [action.payload.userId] = action.payload.byUser;
                };
            })
        else
            return Dictionary.mergeDeep(state, {
                banned = {
                    [action.payload.userId] = Llama.None;
                }
            })
        end
    end;
    users_setWhitelisted = function(state, action)
        if action.payload.isWhitelisted then
            return Dictionary.mergeDeep(state, {
                whitelisted = {
                    [action.payload.userId] = action.payload.byUser;
                };
            })
        else
            return Dictionary.mergeDeep(state, {
                whitelisted = {
                    [action.payload.userId] = Llama.None;
                }
            })
        end
    end;
})