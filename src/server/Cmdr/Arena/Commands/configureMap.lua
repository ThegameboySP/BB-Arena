local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CmdrUtils = require(ReplicatedStorage.Common.Utils.CmdrUtils)

return {
	Name = "configureMap";
	Aliases = {"mcon"};
	Description = "Configures the current map's options.";
	Group = "Admin";
    Args = CmdrUtils.keyValueArgs("Option", 1, function(context)
        local mapScript = context:GetStore("Common").Root:GetSingleton("Map").MapScript
        if mapScript == nil or not mapScript.Options then
            return {}
        end

        local types = {}
        for key, entry in mapScript.Options do
            types[key] = entry.Type
        end

        return types
    end);
}