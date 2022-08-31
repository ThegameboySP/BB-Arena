local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameEnum = require(ReplicatedStorage.Common.GameEnum)
local actions = require(ReplicatedStorage.Common.RoduxFeatures).actions

local LocalPlayer = Players.LocalPlayer

local array = {}
for _, value in GameEnum.Settings do
	table.insert(array, value.cmdr)
end
table.freeze(array)

local function getId(setting)
	for key, _setting in GameEnum.Settings do
		if setting == _setting.cmdr then
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
					local settings = context:GetStore("Common").Store:getState().users.userSettings[LocalPlayer.UserId]
					arg.Description ..= "\n\nCurrent value: " .. tostring(settings[getId(setting)])
				end

				return arg
			end
		end
	};

	Run = function(context, setting, value)
		local store = context:GetStore("Common").Store

		local id
		for key, _setting in GameEnum.Settings do
			if setting == _setting.cmdr then
				id = key
				break
			end
		end

		store:dispatch(actions.saveSettings(context.Executor.UserId, {[id] = value}))
	end;
}