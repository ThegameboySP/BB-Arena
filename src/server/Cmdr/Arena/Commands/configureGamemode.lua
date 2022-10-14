local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CmdrUtils = require(ReplicatedStorage.Common.Utils.CmdrUtils)

return {
	Name = "configureGamemode";
	Aliases = {"gcon"};
	Description = "Configures the current gamemode's options.";
	Group = "Admin";
	Args = CmdrUtils.keyValueArgs("Option", 1, function(context)
        local currentGamemode = context:GetStore("Common").Root:GetSingleton("Gamemode").CurrentGamemode
        if currentGamemode == nil then
            return {}
        end

        return currentGamemode.definition.cmdrConfig
    end)
}