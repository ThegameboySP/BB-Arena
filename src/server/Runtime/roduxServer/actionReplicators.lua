local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local GameEnum = require(ReplicatedStorage.Common.GameEnum)
local actions = RoduxFeatures.actions

return {
    stats_increment = {
        replicate = function(users, action, state, serializedAction)
            if state.stats.registeredStats[action.payload.name].show then
                local actionsMap = {}
                for _, user in users do
                    actionsMap[user] = serializedAction or action
                end

                return actionsMap
            end

            return {}
        end;
    };
    users_saveSettings = {
        replicate = function(users, action)
            local replicateSettings = {}
            for settingName, setting in action.payload.settings do
                if GameEnum.Settings[settingName].replicateToAll then
                    replicateSettings[settingName] = setting
                end
            end

            if next(replicateSettings) then
                local actionsMap = {}
                local othersAction = actions.saveSettings(action.payload.userId, replicateSettings)
                
                for _, userId in users do
                    actionsMap[userId] = othersAction
                end
    
                actionsMap[action.payload.userId] = action

                return actionsMap
            end

            return {
                [action.payload.userId] = action;
            }
        end;
        request = function(userId, action)
            local settings = action.payload.settings
            if type(settings) ~= "table" then
                return
            end

            for settingName in settings do
                -- Client must have exploited to send this message.
                if not GameEnum.Settings[settingName] then
                    return
                end
            end

            return actions.saveSettings(userId, settings)
        end;
    }
}