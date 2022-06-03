local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Gamemodes = ReplicatedStorage.Common.Gamemodes

local DATA = {}

return {
	Name = "configureGamemode";
	Aliases = {"gcon"};
	Description = "Configures the current gamemode's options.";
	Group = "Admin";
	Args = {
        function(context)
            local currentGamemode = context:GetStore("Common").currentGamemodeName
            if currentGamemode == nil then
                return
            end
    
            local gamemode = require(Gamemodes:FindFirstChild(currentGamemode))
            local events = {}
            local entries = context:GetStore(DATA)
            table.clear(entries)

            for name, event in pairs(gamemode.definition.cmdrConfig) do
                table.insert(events, name)
                entries[name] = event
            end

            return {
                Type = context.Cmdr.Util.MakeEnumType("Options", events);
                Name = "option name";
            }
        end,
		function(context)
			local arg1 = context:GetArgument(1)
			if arg1:Validate() == false then
				return
			end

            local cmdrType = context:GetStore(DATA)[arg1:GetValue()]
            if type(cmdrType) == "function" then
                return cmdrType(context)
            end

			return cmdrType
		end
	};
}