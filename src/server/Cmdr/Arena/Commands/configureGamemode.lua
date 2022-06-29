local DATA = {}

return {
	Name = "configureGamemode";
	Aliases = {"gcon"};
	Description = "Configures the current gamemode's options.";
	Group = "Admin";
	Args = {
        function(context)
            local currentGamemode = context:GetStore("Common").Root:GetSingleton("Gamemode").CurrentGamemode
            if currentGamemode == nil then
                return
            end
    
            local events = {}
            local entries = context:GetStore(DATA)
            table.clear(entries)

            for name, event in pairs(currentGamemode.definition.cmdrConfig) do
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