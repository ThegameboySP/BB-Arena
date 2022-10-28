local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)
local Llama = require(ReplicatedStorage.Packages.Llama)

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local GameEnum = require(ReplicatedStorage.Common.GameEnum)
local e = Roact.createElement

local ThemeController = require(script.Parent.ThemeController)
local mainWidget = require(script.mainWidget)

local SettingsApp = Roact.Component:extend("Settings")

function SettingsApp:render()
    return e(ThemeController, {}, {
        SettingsApp = e(mainWidget, self.props);
    })
end

local typeMap = {
    percentage = "slider";
    boolean = "switch";
    range = "range";
    enum = "enum";
    keybind = "keybind";
    contentImage = "image";
    contentSound = "sound";
}

local groupMap = {
    place = "Place Settings";
    tool = "Tool Settings";
    input = "Input Settings";
    sounds = "Sound Settings";
}

SettingsApp = RoactRodux.connect(
    function(state, props)
        local settingRecordsByGroup = {}
        local settingRecords = {}

        for id, setting in GameEnum.Settings do
            local value = RoduxFeatures.selectors.getLocalSetting(state, id)
            local savedValue = RoduxFeatures.selectors.getSavedSetting(state, nil, id)

            local group = groupMap[setting.group] or error("Unknown group: " .. tostring(setting.group))
            if not settingRecordsByGroup[group] then
                settingRecordsByGroup[group] = {}
            end

            local record = {
                valid = true;
                name = setting.name;
                type = typeMap[setting.type] or error("Unknown type: " .. tostring(setting.type));
                payload = setting.payload;
                value = value;
                description = setting.description;
                id = id;
                order = setting.order;
                isChanged = value ~= savedValue;
            }

            if setting.mobile and UserInputService.TouchEnabled then
                if setting.mobile.value ~= nil then
                    record.value = setting.mobile.value
                end

                if setting.mobile.valid ~= nil then
                    record.valid = setting.mobile.valid
                end
            end

            table.insert(settingRecordsByGroup[group], record)
            settingRecords[id] = record
        end

        for id, setting in settingRecords do
            if GameEnum.Settings[id].invalidates and setting.value == true then
                
                for _, invalidatesId in GameEnum.Settings[id].invalidates do
                    settingRecords[invalidatesId].valid = false
                end
            end
        end
        
        for _, records in settingRecordsByGroup do
            table.sort(records, function(a, b)
                return a.order < b.order
            end)
        end

        return Llama.Dictionary.merge(props, {
            settingRecords = settingRecordsByGroup;
            settingCategories = {
                {
                    name = "Input Settings";
                    imageId = "http://www.roblox.com/asset/?id=4893250303";
                },
                {
                    name = "Tool Settings";
                    imageId = "http://www.roblox.com/asset/?id=491253460";
                },
                {
                    name = "Place Settings";
                    imageId = "http://www.roblox.com/asset/?id=1317886354";
                },
                {
                    name = "Sound Settings";
                    imageId = "http://www.roblox.com/asset/?id=7203392850";
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