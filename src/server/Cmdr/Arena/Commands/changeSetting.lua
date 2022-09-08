local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameEnum = require(ReplicatedStorage.Common.GameEnum)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local CmdrUtils = require(ReplicatedStorage.Common.Utils.CmdrUtils)

local LocalPlayer = Players.LocalPlayer

local function mapType(setting)
	if setting.type == "range" then
		return CmdrUtils.constrainedInteger(setting.payload.min, setting.payload.max)
	end

	return setting.type
end

local array = {}
for _, value in GameEnum.Settings do
	table.insert(array, {
		Name = value.name;
		Type = mapType(value);
		Description = value.description;
	})
end
table.freeze(array)

local function getId(setting)
	for key, _setting in GameEnum.Settings do
		if setting.Name == _setting.name then
			return key
		end
	end
end

return {
	Name = "changeSetting";
	Aliases = {"setting"};
	Description = "Changes a local setting.";
	Group = "Any";
	Args = {
		function(context)
			return {
				Type = context.Cmdr.Util.MakeEnumType("setting", array);
				Name = "setting name",
				Description = "The name of the setting"
			}
		end,
		function(context)
			local arg1 = context:GetArgument(1)
			if arg1:Validate() then
				local setting = arg1:GetValue()
				local arg = table.clone(setting)

				if LocalPlayer then
					local value = RoduxFeatures.selectors.getSavedSetting(context:GetStore("Common").Store:getState(), nil, getId(setting))
					arg.Description ..= "\n\nCurrent value: " .. tostring(value)
				end

				return arg
			end
		end
	};

	Run = function(context, setting, value)
		local store = context:GetStore("Common").Store

		local id = getId(setting)
		store:dispatch(RoduxFeatures.actions.saveSettings(context.Executor.UserId, {[id] = value}))
	end;
}