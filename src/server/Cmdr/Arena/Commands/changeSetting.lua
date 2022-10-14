local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameEnum = require(ReplicatedStorage.Common.GameEnum)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local CmdrUtils = require(ReplicatedStorage.Common.Utils.CmdrUtils)

local LocalPlayer = Players.LocalPlayer

local settings = {}
for _, entry in GameEnum.Settings do
	settings[entry.name] = entry
end

local function mapType(setting)
	if setting.type == "range" then
		return CmdrUtils.constrainedInteger(setting.payload.min, setting.payload.max)
	elseif setting.type == "enum" then
		local array = {}
		for name in setting.payload do
			table.insert(array, name)
		end

		return CmdrUtils.enum(setting.name, array)
	end

	return setting.type
end

local function getId(settingName)
	for key, setting in GameEnum.Settings do
		if setting.name == settingName then
			return key
		end
	end
end

return {
	Name = "changeSetting";
	Aliases = {"setting"};
	Description = "Changes a local setting.";
	Group = "Any";
	Args = CmdrUtils.keyValueArgs("setting", 1, function()
		return settings
	end, function(setting, _, context)
		local arg = {
			Name = setting.name;
			Type = mapType(setting);
			Description = setting.description;
		}

		local value
		if LocalPlayer then
			value = RoduxFeatures.selectors.getSavedSetting(context:GetStore("Common").Store:getState(), nil, setting.key)
		end

		return arg, value
	end);

	Run = function(context, settingName, value)
		local store = context:GetStore("Common").Store

		local id = getId(settingName)
		store:dispatch(RoduxFeatures.actions.saveSettings(context.Executor.UserId, {[id] = value}))
	end;
}