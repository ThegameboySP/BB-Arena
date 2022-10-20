return function (registry)
    local Util = registry.Cmdr.Util

	local commandType = {
		Transform = function (text)
            local commandNames = {}

            for _, command in registry.Commands do
                table.insert(commandNames, command.Name)

                if command.Aliases then
                    for _, alias in command.Aliases do
                        table.insert(commandNames, alias)
                    end
                end
            end

			local findCommand = Util.MakeFuzzyFinder(commandNames)

			return findCommand(text)
		end;

		Validate = function (commands)
			return #commands > 0, "No command with that name could be found."
		end;

		Autocomplete = function (commands)
			return commands
		end;

		Parse = function (commands)
			return commands[1]
		end;
	}

	registry:RegisterType("arenaCommand", commandType)

	local arenaCommandsType = Util.MakeListableType(commandType)

	local parse = arenaCommandsType.Parse
	arenaCommandsType.Parse = function(...)
		local array = parse(...)

		local dictionary = {}
		for _, commandName in array do
			dictionary[registry:GetCommand(commandName).Name] = true
		end

		local unpackedArray = table.create(#array)
		for commandName in dictionary do
			table.insert(unpackedArray, commandName)
		end

		return unpackedArray
	end

	registry:RegisterType("arenaCommands", arenaCommandsType)

	registry.Types.command = registry.Types.arenaCommand
    registry.Types.commands = registry.Types.arenaCommands
end