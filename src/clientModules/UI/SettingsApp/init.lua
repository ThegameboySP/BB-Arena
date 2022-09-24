local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)
local Llama = require(ReplicatedStorage.Packages.Llama)

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local GameEnum = require(ReplicatedStorage.Common.GameEnum)
local e = Roact.createElement

local ThemeController = require(script.Parent.ThemeController)
local mainWidget = require(script.mainWidget)

local SettingsApp = Roact.Component:extend("Settings")

-- function SettingsApp:init()
--     self.localEdits = {}
-- end

-- function SettingsApp:getChangedSettings(newSettingRecords)
--     local changed = {}

--     -- Only iterate over new, since new setting entries should never happen.
--     for name, settings in newSettingRecords do
--         local oldSettings = self.props.settingRecords[name]

--         for id, setting in settings do
--             if setting.value ~= oldSettings[id].value then
--                 changed[id] = setting.value
--             end
--         end
--     end

--     return changed
-- end

-- function SettingsApp:shouldUpdate(newProps)
--     if newProps == self.props then
--         return false
--     end

--     for id, value in self:getChangedSettings(newProps.settingRecords) do
--         if self.localEdits[id] ~= value then
--             return true
--         end
--     end

--     return false
-- end

-- function SettingsApp:render()
--     return e(ThemeController, {}, {
--         SettingsApp = e(mainWidget, Llama.Dictionary.merge(self.props, {
--             onSettingChanged = function(settingId, value)
--                 self.localEdits[settingId] = value
--                 self.props.onSettingChanged(settingId, value)
--             end;
--             onSettingsSaved = function()
--                 table.clear(self.localEdits)
--                 self.props.onSettingChanged()
--             end;
--             onSettingsCanceled = function()
--                 table.clear(self.localEdits)
--                 self.props.onSettingChanged()
--             end
--         }));
--     })
-- end

function SettingsApp:render()
    return e(ThemeController, {}, {
        SettingsApp = e(mainWidget, self.props);
    })
end

function SettingsApp:willUnmount()
    self.props.onSettingsCanceled()
end

local typeMap = {
    percentage = "slider";
    boolean = "switch";
    range = "range";
    enum = "enum";
}

local groupMap = {
    place = "Place Settings";
    tool = "Tool Settings";
}

SettingsApp = RoactRodux.connect(
    function(state, props)
        local settingRecords = {}

        for id, setting in GameEnum.Settings do
            local value = RoduxFeatures.selectors.getLocalSetting(state, id)
            local savedValue = RoduxFeatures.selectors.getSavedSetting(state, nil, id)

            local group = groupMap[setting.group] or error("Unknown group: " .. tostring(setting.group))
            if not settingRecords[group] then
                settingRecords[group] = {}
            end
            
            table.insert(settingRecords[group], {
                name = setting.name;
                type = typeMap[setting.type] or error("Unknown type: " .. tostring(setting.type));
                payload = setting.payload;
                value = value;
                description = setting.description;
                id = id;
                order = setting.order;
                isChanged = value ~= savedValue;
            })
        end

        for _, records in settingRecords do
            table.sort(records, function(a, b)
                return a.order < b.order
            end)
        end

        return Llama.Dictionary.merge(props, {
            settingRecords = settingRecords;
            settingCategories = {
                {
                    name = "Place Settings";
                    imageId = "http://www.roblox.com/asset/?id=1317886354";
                },
                {
                    name = "Tool Settings";
                    imageId = "http://www.roblox.com/asset/?id=491253460";
                },
            };
        })
    end,
    function(dispatch)
        return {
            onSettingChanged = function(settingId, value)
                dispatch(RoduxFeatures.actions.setLocalSetting(settingId, value))
            end;
            onSettingsSaved = function()
                dispatch(RoduxFeatures.actions.flushSaveSettings())
            end;
            onSettingsCanceled = function()
                dispatch(RoduxFeatures.actions.cancelLocalSettings())
            end;
            onSettingCanceled = function(id)
                dispatch(RoduxFeatures.actions.cancelLocalSetting(id))
            end;
            onRestoreDefaults = function()
                dispatch(RoduxFeatures.actions.restoreDefaultSettings())
            end;
        }
    end
)(SettingsApp)

return SettingsApp