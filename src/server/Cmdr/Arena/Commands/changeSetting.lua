local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Settings = require(ReplicatedStorage.Common.StaticData.Settings)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local CmdrUtils = require(ReplicatedStorage.Common.Utils.CmdrUtils)

local LocalPlayer = Players.LocalPlayer

local function mapType(setting)
	if setting.type == "range" then
		return CmdrUtils.constrainedInteger(setting.payload.min, setting.payload.max)
	elseif setting.type == "enum" then
		local array = {}
		for name in setting.payload do
			table.insert(array, name)
		end

		return CmdrUtils.enum(setting.name, array)
	elseif setting.type == "keybind" then
		return "userInput"
	elseif setting.type == "contentImage" then
		return "string"
	end

	return setting.type
end

local function getId(settingName)
	for key, setting in Settings do
		if setting.name == settingName then
			return key
		end
	end
end

local settings = {}
for _, entry in Settings do
	local type = mapType(entry)
	if type then
		local clone = table.clone(entry)
		clone.type = type
		settings[entry.name] = clone
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
			Type = setting.type;
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

		if Settings[id].type == "keybind" then
			value = value.Name
		end
		
		store:dispatch(RoduxFeatures.actions.saveSettings(context.Executor.UserId, {[id] = value}))
	end;
}