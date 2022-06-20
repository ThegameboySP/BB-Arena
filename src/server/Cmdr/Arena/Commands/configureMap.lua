local DATA = {}

return {
	Name = "configureMap";
	Aliases = {"mcon"};
	Description = "Configures the current map's options.";
	Group = "Admin";
	Args = {
        function(context)
            local mapScript = context:GetStore("Common").Knit.GetSingleton("Map").MapScript
            if mapScript == nil or not mapScript.Options then
                return
            end
    
            local options = {}
            local entries = context:GetStore(DATA)
            table.clear(entries)

            for name, event in pairs(mapScript.Options) do
                table.insert(options, name)
                entries[name] = event
            end

            return {
                Type = context.Cmdr.Util.MakeEnumType("Options", options);
                Name = "option name";
            }
        end,
		function(context)
			local arg1 = context:GetArgument(1)
			if arg1:Validate() == false then
				return
			end

            local cmdrType = context:GetStore(DATA)[arg1:GetValue()].Type
            if type(cmdrType) == "function" then
                return cmdrType(context)
            end

			return cmdrType
		end
	};
}